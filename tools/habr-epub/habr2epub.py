#!/usr/bin/env python3
"""Сборка EPUB из статей Хабра по списку глав из epub-навигатора.

Навигатор — это epub, где каждая глава представлена блоком
<div class="item"> со ссылкой на публикацию. Скрипт вытягивает из него
структуру (разделы, номера, названия, URL), скачивает тексты статей,
чистит разметку до валидного XHTML, тянет картинки и собирает EPUB 3
с оглавлением (nav.xhtml + toc.ncx) и отдельным файлом на главу.

Работает на голой стандартной библиотеке. Главы, которые скачать не
удалось, попадают в книгу как страница-заглушка со ссылкой на оригинал,
поэтому результат всегда остаётся валидным epub.

    python3 habr2epub.py navigator.epub -o hamming.epub

Повторные запуски берут скачанное из кеша (--cache-dir), так что
докачать пропущенные главы можно тем же вызовом.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import posixpath
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
import uuid
import zipfile
from html.parser import HTMLParser

USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)
ARTICLE_ID_RE = re.compile(r"/(?:articles|post|blog/[^/]+)/(\d+)")


# --------------------------------------------------------------------------
# 1. Разбор навигатора
# --------------------------------------------------------------------------


class NavigatorParser(HTMLParser):
    """Достаёт разделы (h2) и главы (div.item) из index.xhtml навигатора."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.chapters: list[dict] = []
        self.section = ""
        self._h2_buf: list[str] | None = None
        self._field: str | None = None
        self._buf: list[str] = []
        self._item: dict | None = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        classes = (a.get("class") or "").split()
        if tag == "h2":
            self._h2_buf = []
        elif tag == "div" and "item" in classes:
            self._item = {"id": a.get("id", ""), "section": self.section}
        elif self._item is not None and tag == "div":
            for name in ("label", "title", "blurb"):
                if name in classes:
                    self._field, self._buf = name, []
        elif self._item is not None and tag == "a" and a.get("href"):
            self._item.setdefault("url", a["href"])

    def handle_endtag(self, tag):
        if tag == "h2" and self._h2_buf is not None:
            self.section = "".join(self._h2_buf).strip()
            self._h2_buf = None
        elif tag == "div" and self._field:
            self._item[self._field] = " ".join("".join(self._buf).split())
            self._field, self._buf = None, []
        elif tag == "div" and self._item is not None and not self._field:
            if self._item.get("url"):
                self.chapters.append(self._item)
            self._item = None

    def handle_data(self, data):
        if self._h2_buf is not None:
            self._h2_buf.append(data)
        elif self._field:
            self._buf.append(data)


def chapters_from_epub(path: str) -> list[dict]:
    with zipfile.ZipFile(path) as zf:
        names = [n for n in zf.namelist() if n.endswith((".xhtml", ".html"))]
        # index.xhtml вперёд, дальше — всё остальное, вдруг блоки лежат там
        names.sort(key=lambda n: (0 if "index" in posixpath.basename(n) else 1, n))
        for name in names:
            parser = NavigatorParser()
            parser.feed(zf.read(name).decode("utf-8", "replace"))
            parser.close()
            if parser.chapters:
                return parser.chapters
    raise SystemExit(f"в {path} не нашлось блоков <div class=\"item\"> со ссылками")


# --------------------------------------------------------------------------
# 2. Загрузка
# --------------------------------------------------------------------------


class Fetcher:
    def __init__(self, cache_dir: str, delay: float = 1.0, retries: int = 3):
        self.cache_dir = cache_dir
        self.delay = delay
        self.retries = retries
        self._last = 0.0
        os.makedirs(cache_dir, exist_ok=True)

    def _cache_path(self, url: str) -> str:
        return os.path.join(self.cache_dir, hashlib.sha1(url.encode()).hexdigest())

    def get(self, url: str) -> bytes:
        path = self._cache_path(url)
        if os.path.exists(path) and os.path.getsize(path) > 0:
            with open(path, "rb") as fh:
                return fh.read()
        wait = self.delay - (time.time() - self._last)
        if wait > 0:
            time.sleep(wait)
        last_error: Exception | None = None
        for attempt in range(self.retries):
            try:
                req = urllib.request.Request(
                    url,
                    headers={
                        "User-Agent": USER_AGENT,
                        "Accept-Language": "ru,en;q=0.8",
                    },
                )
                with urllib.request.urlopen(req, timeout=60) as resp:
                    data = resp.read()
                self._last = time.time()
                with open(path, "wb") as fh:
                    fh.write(data)
                return data
            except (urllib.error.URLError, OSError) as exc:
                last_error = exc
                time.sleep(2 ** attempt)
        raise IOError(f"{url}: {last_error}")


def article_id(url: str) -> str | None:
    m = ARTICLE_ID_RE.search(urllib.parse.urlsplit(url).path)
    return m.group(1) if m else None


class ElementExtractor(HTMLParser):
    """Возвращает внутренний HTML первого элемента, прошедшего проверку."""

    def __init__(self, match):
        super().__init__(convert_charrefs=False)
        self.match = match
        self.result: str | None = None
        self._depth = 0
        self._tag = ""
        self._parts: list[str] = []

    def handle_starttag(self, tag, attrs):
        if self.result is not None:
            return
        if self._depth:
            if tag == self._tag:
                self._depth += 1
            self._parts.append(self.get_starttag_text() or "")
        elif self.match(tag, dict(attrs)):
            self._tag, self._depth, self._parts = tag, 1, []

    def handle_startendtag(self, tag, attrs):
        if self._depth and self.result is None:
            self._parts.append(self.get_starttag_text() or "")

    def handle_endtag(self, tag):
        if self.result is not None or not self._depth:
            return
        if tag == self._tag:
            self._depth -= 1
            if self._depth == 0:
                self.result = "".join(self._parts)
                return
        self._parts.append(f"</{tag}>")

    def _raw(self, text):
        if self._depth and self.result is None:
            self._parts.append(text)

    handle_data = _raw
    handle_entityref = lambda self, name: self._raw(f"&{name};")
    handle_charref = lambda self, name: self._raw(f"&#{name};")
    handle_comment = lambda self, data: None


def extract_body(html: str) -> str | None:
    """Тело статьи со страницы Хабра (старая и новая вёрстка)."""

    def match(tag, attrs):
        if tag != "div":
            return False
        classes = (attrs.get("class") or "").split()
        return (
            attrs.get("id") == "post-content-body"
            or "article-formatted-body" in classes
            or "post__text" in classes
        )

    parser = ElementExtractor(match)
    parser.feed(html)
    parser.close()
    return parser.result


def fetch_article(fetcher: Fetcher, url: str) -> tuple[str | None, str]:
    """(заголовок, html тела). Сначала пробуем API, потом страницу."""
    aid = article_id(url)
    if aid:
        api = f"https://habr.com/kek/v2/articles/{aid}/?fl=ru&hl=ru"
        try:
            data = json.loads(fetcher.get(api).decode("utf-8", "replace"))
            body = data.get("textHtml") or (data.get("body") or {}).get("textHtml")
            if body:
                title = data.get("titleHtml") or data.get("title")
                return (re.sub(r"<[^>]+>", "", title).strip() if title else None), body
        except (IOError, ValueError, AttributeError):
            pass
    html = fetcher.get(url).decode("utf-8", "replace")
    body = extract_body(html)
    if not body:
        raise IOError("не удалось найти тело статьи в HTML")
    m = re.search(r"<title>(.*?)</title>", html, re.S | re.I)
    title = re.sub(r"\s*/\s*Хабр\s*$", "", m.group(1)).strip() if m else None
    return title, body


# --------------------------------------------------------------------------
# 3. Приведение HTML к XHTML
# --------------------------------------------------------------------------

VOID = {"br", "hr", "img"}
DROP_TREE = {
    "script", "style", "noscript", "iframe", "form", "button", "input",
    "select", "textarea", "object", "embed", "canvas", "svg", "video", "audio",
}
KEEP = {
    "p", "br", "hr", "h1", "h2", "h3", "h4", "h5", "h6", "em", "i", "strong",
    "b", "u", "s", "sub", "sup", "small", "blockquote", "pre", "code", "ul",
    "ol", "li", "dl", "dt", "dd", "table", "thead", "tbody", "tfoot", "tr",
    "th", "td", "caption", "img", "a", "figure", "figcaption", "div", "span",
}
BLOCK = {
    "p", "div", "ul", "ol", "li", "blockquote", "pre", "h1", "h2", "h3", "h4",
    "h5", "h6", "table", "tr", "td", "th", "figure", "hr", "dl", "dt", "dd",
}
# новый тег -> какие открытые теги он неявно закрывает
IMPLICIT_CLOSE = {
    "li": {"li"},
    "dt": {"dt", "dd"},
    "dd": {"dt", "dd"},
    "tr": {"tr", "td", "th"},
    "td": {"td", "th"},
    "th": {"td", "th"},
    "p": {"p"},
}
ATTRS = {
    "a": {"href", "title"},
    "img": {"src", "alt", "title"},
    "td": {"colspan", "rowspan"},
    "th": {"colspan", "rowspan"},
}
SAFE_SCHEMES = ("http:", "https:", "mailto:")
BAD_CHARS = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")


def esc(text: str, quote: bool = False) -> str:
    text = BAD_CHARS.sub("", text)
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return text.replace('"', "&quot;") if quote else text


class Sanitizer(HTMLParser):
    """HTML Хабра -> валидный XHTML. Попутно собирает адреса картинок."""

    def __init__(self, base_url: str, anchor_prefix: str):
        super().__init__(convert_charrefs=True)
        self.base_url = base_url
        self.prefix = anchor_prefix
        self.images: list[str] = []
        self._out: list[str] = []
        self._stack: list[str] = []
        self._drop: str | None = None
        self._drop_depth = 0
        self._pre = 0

    # -- helpers -----------------------------------------------------------
    def _close(self, tag: str) -> None:
        self._out.append(f"</{tag}>")
        self._stack.pop()

    def _close_implicit(self, tag: str) -> None:
        closers = IMPLICIT_CLOSE.get(tag, set())
        while self._stack and self._stack[-1] in closers:
            self._close(self._stack[-1])
        if tag in BLOCK and "p" in self._stack:
            while self._stack and self._stack[-1] != "p":
                self._close(self._stack[-1])
            if self._stack:
                self._close("p")

    def _url(self, raw: str) -> str:
        url = urllib.parse.urljoin(self.base_url, raw.strip())
        return url

    def _attrs(self, tag: str, attrs: dict) -> str:
        out = []
        allowed = ATTRS.get(tag, set())
        for name in sorted(allowed):
            value = attrs.get(name)
            if tag == "img" and name == "src":
                value = attrs.get("data-src") or attrs.get("src")
            if not value:
                continue
            if name in ("href", "src"):
                value = value.strip()
                if name == "href" and value.startswith("#"):
                    value = "#" + self.prefix + value[1:]
                else:
                    value = self._url(value)
                    if not value.lower().startswith(SAFE_SCHEMES):
                        continue
                    if tag == "img":
                        self.images.append(value)
            out.append(f' {name}="{esc(value, quote=True)}"')
        if (ident := attrs.get("id")):
            out.append(f' id="{esc(self.prefix + ident, quote=True)}"')
        return "".join(out)

    # -- HTMLParser hooks --------------------------------------------------
    def handle_starttag(self, tag, attrs):
        if self._drop:
            if tag == self._drop:
                self._drop_depth += 1
            return
        if tag in DROP_TREE:
            self._drop, self._drop_depth = tag, 1
            return
        if tag not in KEEP:  # section/article/header/font/… — разворачиваем
            return
        a = dict(attrs)
        if tag == "img" and not (a.get("src") or a.get("data-src")):
            return
        self._close_implicit(tag)
        rendered = f"<{tag}{self._attrs(tag, a)}"
        if tag in VOID:
            self._out.append(rendered + "/>")
            return
        self._out.append(rendered + ">")
        self._stack.append(tag)
        if tag == "pre":
            self._pre += 1

    def handle_startendtag(self, tag, attrs):
        if tag in VOID or tag in DROP_TREE or tag not in KEEP:
            self.handle_starttag(tag, attrs)
            if tag not in VOID and tag in KEEP and self._stack[-1:] == [tag]:
                self._close(tag)
        else:
            self.handle_starttag(tag, attrs)
            if self._stack[-1:] == [tag]:
                self._close(tag)

    def handle_endtag(self, tag):
        if self._drop:
            if tag == self._drop:
                self._drop_depth -= 1
                if self._drop_depth == 0:
                    self._drop = None
            return
        if tag in VOID or tag not in self._stack:
            return
        while self._stack:
            top = self._stack[-1]
            self._close(top)
            if top == "pre":
                self._pre = max(0, self._pre - 1)
            if top == tag:
                break

    def handle_data(self, data):
        if self._drop:
            return
        if not self._pre:
            data = data.replace("\r", "")
        self._out.append(esc(data))

    def handle_comment(self, data):
        pass

    def close(self):
        super().close()
        while self._stack:
            self._close(self._stack[-1])

    @property
    def xhtml(self) -> str:
        text = "".join(self._out)
        text = re.sub(r"(?:\s*<p>\s*</p>\s*)+", "\n", text)
        return text.strip()


def sanitize(body_html: str, base_url: str, prefix: str) -> tuple[str, list[str]]:
    parser = Sanitizer(base_url, prefix)
    parser.feed(body_html)
    parser.close()
    return parser.xhtml, parser.images


# --------------------------------------------------------------------------
# 4. Картинки
# --------------------------------------------------------------------------

IMG_TYPES = {
    ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
    ".gif": "image/gif", ".svg": "image/svg+xml", ".webp": "image/webp",
}


def download_images(fetcher: Fetcher, urls: list[str], out_dir: str) -> dict[str, tuple[str, str]]:
    """url -> (имя файла в OEBPS/images, media-type). Недоступное пропускаем."""
    os.makedirs(out_dir, exist_ok=True)
    mapping: dict[str, tuple[str, str]] = {}
    for url in dict.fromkeys(urls):
        ext = posixpath.splitext(urllib.parse.urlsplit(url).path)[1].lower()
        ext = ext if ext in IMG_TYPES else ".jpg"
        name = hashlib.sha1(url.encode()).hexdigest()[:16] + ext
        target = os.path.join(out_dir, name)
        if not os.path.exists(target):
            try:
                data = fetcher.get(url)
            except IOError as exc:
                print(f"    картинка пропущена: {url} ({exc})", file=sys.stderr)
                continue
            with open(target, "wb") as fh:
                fh.write(data)
        mapping[url] = (name, IMG_TYPES[ext])
    return mapping


def rewrite_images(xhtml: str, mapping: dict[str, tuple[str, str]]) -> str:
    def repl(m: re.Match) -> str:
        url = m.group(1).replace("&amp;", "&")
        entry = mapping.get(url)
        return f'src="images/{entry[0]}"' if entry else 'src=""'

    xhtml = re.sub(r'src="([^"]*)"', repl, xhtml)
    # картинки, которые скачать не вышло, выкидываем целиком
    return re.sub(r'<img(?=[^>]*\ssrc=""[\s/>])[^>]*/>', "", xhtml)


# --------------------------------------------------------------------------
# 5. Сборка EPUB
# --------------------------------------------------------------------------

STYLE = """\
body { font-family: Georgia, 'Times New Roman', serif; line-height: 1.5;
       margin: 0 5%; hyphens: auto; }
h1 { font-size: 1.5em; line-height: 1.25; margin: 1em 0 0.2em; }
h2 { font-size: 1.25em; margin: 1.4em 0 0.3em; }
h3, h4 { font-size: 1.1em; margin: 1.2em 0 0.3em; }
p { margin: 0.6em 0; text-align: justify; }
img { max-width: 100%; height: auto; }
figure { margin: 1em 0; text-align: center; }
figcaption, .caption { font-size: 0.85em; color: #555; }
pre { white-space: pre-wrap; word-wrap: break-word; font-size: 0.85em;
      background: #f4f4f4; padding: 0.6em; border-radius: 4px; }
code { font-family: 'DejaVu Sans Mono', monospace; font-size: 0.9em; }
blockquote { margin: 1em 1.5em; font-style: italic; color: #333; }
table { border-collapse: collapse; margin: 1em 0; font-size: 0.9em; }
td, th { border: 1px solid #bbb; padding: 0.3em 0.5em; }
.chapter-label { font-size: 0.85em; letter-spacing: 0.08em;
                 text-transform: uppercase; color: #777; margin: 2em 0 0; }
.blurb { font-style: italic; color: #555; margin: 0 0 1.5em; }
.source { margin-top: 2.5em; font-size: 0.85em; color: #777;
          border-top: 1px solid #ddd; padding-top: 0.6em; }
.missing { border: 1px solid #d33; background: #fff5f5; padding: 0.8em;
           border-radius: 4px; }
"""

PAGE = """\
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ru" lang="ru">
<head><meta charset="utf-8"/><title>{title}</title>
<link rel="stylesheet" type="text/css" href="style.css"/></head>
<body>
{body}
</body>
</html>
"""


def chapter_page(ch: dict, content: str) -> str:
    parts = []
    if ch.get("label"):
        parts.append(f'<p class="chapter-label">{esc(ch["label"])}</p>')
    parts.append(f"<h1>{esc(ch['title'])}</h1>")
    if ch.get("blurb"):
        parts.append(f'<p class="blurb">{esc(ch["blurb"])}</p>')
    parts.append(content)
    parts.append(
        f'<p class="source">Источник: <a href="{esc(ch["url"], True)}">'
        f'{esc(ch["url"])}</a></p>'
    )
    return PAGE.format(title=esc(ch["title"]), body="\n".join(parts))


def placeholder(ch: dict, reason: str) -> str:
    return (
        f'<div class="missing"><p>Текст этой главы не удалось загрузить '
        f"({esc(reason)}).</p><p>Запустите сборку ещё раз — уже скачанные "
        f"главы возьмутся из кеша, докачается только эта.</p></div>"
    )


def opf(meta: dict, chapters: list[dict], images: dict[str, tuple[str, str]]) -> str:
    items = [
        '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>',
        '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>',
        '<item id="css" href="style.css" media-type="text/css"/>',
        '<item id="title" href="title.xhtml" media-type="application/xhtml+xml"/>',
    ]
    spine = ['<itemref idref="title"/>']
    for ch in chapters:
        items.append(
            f'<item id="{ch["file_id"]}" href="{ch["file"]}" '
            f'media-type="application/xhtml+xml"/>'
        )
        spine.append(f'<itemref idref="{ch["file_id"]}"/>')
    for i, (name, mime) in enumerate(sorted(set(images.values()))):
        items.append(f'<item id="img{i}" href="images/{name}" media-type="{mime}"/>')
    return f"""<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid" xml:lang="ru">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="bookid">urn:uuid:{meta['uuid']}</dc:identifier>
    <dc:title>{esc(meta['title'])}</dc:title>
    <dc:creator>{esc(meta['creator'])}</dc:creator>
    <dc:contributor>{esc(meta['contributor'])}</dc:contributor>
    <dc:language>ru</dc:language>
    <dc:source>{esc(meta['source'])}</dc:source>
    <meta property="dcterms:modified">{meta['modified']}</meta>
  </metadata>
  <manifest>
    {chr(10).join('    ' + i for i in items).strip()}
  </manifest>
  <spine toc="ncx">
    {chr(10).join('    ' + s for s in spine).strip()}
  </spine>
</package>
"""


def nav_xhtml(meta: dict, chapters: list[dict]) -> str:
    lines = ["<ol>", '  <li><a href="title.xhtml">Титул</a></li>']
    section = None
    open_sub = False
    for ch in chapters:
        if ch.get("section") != section:
            if open_sub:
                lines.append("    </ol></li>")
            section = ch.get("section")
            if section:
                lines.append(f"  <li><a href=\"{ch['file']}\">{esc(section)}</a><ol>")
                open_sub = True
            else:
                open_sub = False
        label = f"{ch['label']}. " if ch.get("label") else ""
        indent = "      " if open_sub else "  "
        lines.append(
            f"{indent}<li><a href=\"{ch['file']}\">{esc(label + ch['title'])}</a></li>"
        )
    if open_sub:
        lines.append("    </ol></li>")
    lines.append("</ol>")
    body = "\n".join(lines)
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="ru" lang="ru">
<head><meta charset="utf-8"/><title>Оглавление</title></head>
<body>
  <nav epub:type="toc" id="toc">
    <h1>Оглавление</h1>
{body}
  </nav>
</body>
</html>
"""


def toc_ncx(meta: dict, chapters: list[dict]) -> str:
    points = []
    for i, ch in enumerate(chapters, start=2):
        label = f"{ch['label']}. " if ch.get("label") else ""
        points.append(
            f'    <navPoint id="np{i}" playOrder="{i}">\n'
            f"      <navLabel><text>{esc(label + ch['title'])}</text></navLabel>\n"
            f'      <content src="{ch["file"]}"/>\n'
            f"    </navPoint>"
        )
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="ru">
  <head>
    <meta name="dtb:uid" content="urn:uuid:{meta['uuid']}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle><text>{esc(meta['title'])}</text></docTitle>
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>Титул</text></navLabel>
      <content src="title.xhtml"/>
    </navPoint>
{chr(10).join(points)}
  </navMap>
</ncx>
"""


def title_page(meta: dict, chapters: list[dict], failed: list[dict]) -> str:
    body = [
        f"<h1>{esc(meta['title'])}</h1>",
        f"<p><b>{esc(meta['creator'])}</b></p>",
        f"<p>{esc(meta['contributor'])}</p>",
        f"<p>Глав в книге: {len(chapters)}.</p>",
    ]
    if failed:
        missing = ", ".join(esc(c.get("label") or c["title"]) for c in failed)
        body.append(f'<p class="missing">Не загрузились: {missing}.</p>')
    body.append(
        '<p class="source">Тексты собраны из публикаций перевода на Хабре; '
        "права принадлежат авторам оригинала и перевода. Сборка — для личного "
        "офлайн-чтения.</p>"
    )
    return PAGE.format(title=esc(meta["title"]), body="\n".join(body))


def write_epub(path: str, meta: dict, chapters: list[dict], pages: dict[str, str],
               images: dict[str, tuple[str, str]], image_dir: str,
               failed: list[dict]) -> None:
    with zipfile.ZipFile(path, "w") as zf:
        zf.writestr(
            zipfile.ZipInfo("mimetype"), "application/epub+zip",
            compress_type=zipfile.ZIP_STORED,
        )
        zf.writestr(
            "META-INF/container.xml",
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">\n'
            "  <rootfiles>\n"
            '    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>\n'
            "  </rootfiles>\n</container>\n",
            zipfile.ZIP_DEFLATED,
        )
        write = lambda name, data: zf.writestr(name, data, zipfile.ZIP_DEFLATED)
        write("OEBPS/style.css", STYLE)
        write("OEBPS/content.opf", opf(meta, chapters, images))
        write("OEBPS/nav.xhtml", nav_xhtml(meta, chapters))
        write("OEBPS/toc.ncx", toc_ncx(meta, chapters))
        write("OEBPS/title.xhtml", title_page(meta, chapters, failed))
        for ch in chapters:
            write(f"OEBPS/{ch['file']}", pages[ch["file"]])
        for name, _ in sorted(set(images.values())):
            with open(os.path.join(image_dir, name), "rb") as fh:
                write(f"OEBPS/images/{name}", fh.read())


# --------------------------------------------------------------------------
# 6. main
# --------------------------------------------------------------------------


TRANSLIT = {
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "e",
    "ж": "zh", "з": "z", "и": "i", "й": "y", "к": "k", "л": "l", "м": "m",
    "н": "n", "о": "o", "п": "p", "р": "r", "с": "s", "т": "t", "у": "u",
    "ф": "f", "х": "h", "ц": "c", "ч": "ch", "ш": "sh", "щ": "sch", "ъ": "",
    "ы": "y", "ь": "", "э": "e", "ю": "yu", "я": "ya",
}


def slug(text: str, fallback: str) -> str:
    text = unicodedata.normalize("NFKD", text.lower())
    text = "".join(TRANSLIT.get(ch, ch) for ch in text)
    text = re.sub(r"[^a-z0-9]+", "-", text).strip("-")
    return text or fallback


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("navigator", help="epub-навигатор со списком глав (или .json)")
    ap.add_argument("-o", "--out", default="book.epub", help="куда писать epub")
    ap.add_argument("--cache-dir", default=".habr-cache", help="кеш скачанного")
    ap.add_argument("--delay", type=float, default=1.0, help="пауза между запросами, с")
    ap.add_argument("--limit", type=int, help="взять только первые N глав")
    ap.add_argument("--no-images", action="store_true", help="не тянуть картинки")
    ap.add_argument("--offline", action="store_true",
                    help="ничего не качать: только то, что уже в кеше")
    ap.add_argument("--title", default="Ричард Хэмминг — Искусство заниматься "
                                       "наукой и инженерным делом")
    ap.add_argument("--author", default="Ричард Хэмминг")
    ap.add_argument("--translator", default="Перевод: сообщество Хабра (MagisterLudi)")
    args = ap.parse_args(argv)

    if args.navigator.endswith(".json"):
        with open(args.navigator, encoding="utf-8") as fh:
            chapters = json.load(fh)
    else:
        chapters = chapters_from_epub(args.navigator)
    if args.limit:
        chapters = chapters[: args.limit]
    print(f"глав в навигаторе: {len(chapters)}")

    fetcher = Fetcher(args.cache_dir, delay=args.delay)
    image_dir = os.path.join(args.cache_dir, "images")
    pages: dict[str, str] = {}
    all_images: dict[str, tuple[str, str]] = {}
    failed: list[dict] = []

    for i, ch in enumerate(chapters):
        ch["file_id"] = f"ch{i:02d}"
        ch["file"] = f"{ch['file_id']}-{slug(ch['title'], ch['file_id'])[:40]}.xhtml"
        print(f"[{i + 1}/{len(chapters)}] {ch.get('label', '')} {ch['title']}")
        content, reason = None, ""
        try:
            if args.offline and not os.path.exists(
                fetcher._cache_path(ch["url"])
            ) and not (
                (aid := article_id(ch["url"]))
                and os.path.exists(fetcher._cache_path(
                    f"https://habr.com/kek/v2/articles/{aid}/?fl=ru&hl=ru"))
            ):
                raise IOError("офлайн-режим, в кеше нет")
            _, body = fetch_article(fetcher, ch["url"])
            xhtml, images = sanitize(body, ch["url"], f"{ch['file_id']}-")
            if not args.no_images and images:
                mapping = download_images(fetcher, images, image_dir)
                all_images.update(mapping)
                xhtml = rewrite_images(xhtml, mapping)
            else:
                xhtml = rewrite_images(xhtml, {})
            content = xhtml
        except (IOError, ValueError) as exc:
            reason = str(exc)
            print(f"    не скачалось: {reason}", file=sys.stderr)
            failed.append(ch)
        pages[ch["file"]] = chapter_page(ch, content or placeholder(ch, reason))

    meta = {
        "uuid": str(uuid.uuid5(uuid.NAMESPACE_URL, "habr2epub:" + args.title)),
        "title": args.title,
        "creator": args.author,
        "contributor": args.translator,
        "source": chapters[0]["url"] if chapters else "https://habr.com/",
        "modified": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }
    write_epub(args.out, meta, chapters, pages, all_images, image_dir, failed)
    ok = len(chapters) - len(failed)
    size = os.path.getsize(args.out) / 1024
    print(f"\nготово: {args.out} ({size:.0f} КБ), глав с текстом {ok}/{len(chapters)}")
    if failed:
        print("без текста: " + ", ".join(c.get("label") or c["title"] for c in failed))
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
