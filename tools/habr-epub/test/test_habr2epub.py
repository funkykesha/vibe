#!/usr/bin/env python3
"""Тесты сборщика: разбор навигатора, санитайзер, сборка epub целиком.

Сеть не нужна: статьи-фикстуры отдаются через file:// URL.

    python3 test/test_habr2epub.py
"""

import os
import sys
import tempfile
import unittest
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import habr2epub as h  # noqa: E402

NAV_ITEM = (
    '<div class="item" id="c{i}"><div class="label">Глава {i}</div>'
    '<div class="title">{title}</div><div class="blurb">Описание {i}.</div>'
    '<a class="read" href="{url}">→ Читать</a></div>'
)

ARTICLE = """<!DOCTYPE html><html><head><title>{title} / Хабр</title>
<script>var x = 1 < 2 && 3 > 2;</script></head><body>
<header>шапка сайта</header>
<div id="post-content-body">
  <p>Первый абзац с <b>жирным</b> и <i>курсивом</i>, а также &laquo;кавычками&raquo; и AT&amp;T.
  <p>Абзац без закрывающего тега — браузер закрывает сам.
  <ul><li>пункт один<li>пункт два</ul>
  <img src="/img/pic.png" alt="схема">
  <img data-src="//habrastorage.org/lazy.jpg" alt="ленивая">
  <blockquote>Цитата <a href="https://example.com/a?x=1&y=2">со ссылкой</a>.</blockquote>
  <pre><code>if (a &lt; b) {{ return a; }}</code></pre>
  <table><tr><td>ячейка<td>вторая<tr><td colspan="2">во всю ширину</table>
  <div class="spoiler"><span id="anchor">якорь</span> <a href="#anchor">к якорю</a></div>
  <font color="red">устаревший тег разворачивается</font>
  <iframe src="https://youtube.com/embed/xxx"></iframe>
</div>
<footer>подвал сайта</footer></body></html>
"""


def make_navigator(path, urls):
    items = "\n".join(
        NAV_ITEM.format(i=i, title=f"Тестовая глава {i}", url=u)
        for i, u in enumerate(urls, start=1)
    )
    index = (
        '<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html>'
        '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Оглавление</title></head>'
        f"<body><h1>Оглавление</h1><h2>Раздел A</h2>{items}</body></html>"
    )
    with zipfile.ZipFile(path, "w") as zf:
        zf.writestr("mimetype", "application/epub+zip")
        zf.writestr("OEBPS/index.xhtml", index)


class TestNavigator(unittest.TestCase):
    def test_real_navigator(self):
        real = os.environ.get("NAVIGATOR_EPUB")
        if not real or not os.path.exists(real):
            self.skipTest("NAVIGATOR_EPUB не задан")
        chapters = h.chapters_from_epub(real)
        self.assertEqual(len(chapters), 32)
        self.assertTrue(all(c["url"].startswith("https://habr.com/") for c in chapters))
        self.assertTrue(all(c["title"] and c["label"] for c in chapters))
        self.assertGreater(len({c["section"] for c in chapters}), 5)

    def test_fixture_navigator(self):
        with tempfile.TemporaryDirectory() as tmp:
            nav = os.path.join(tmp, "nav.epub")
            make_navigator(nav, ["https://habr.com/ru/articles/1/"])
            chapters = h.chapters_from_epub(nav)
            self.assertEqual(len(chapters), 1)
            self.assertEqual(chapters[0]["section"], "Раздел A")
            self.assertEqual(chapters[0]["label"], "Глава 1")
            self.assertEqual(chapters[0]["blurb"], "Описание 1.")


class TestSanitizer(unittest.TestCase):
    def setUp(self):
        body = h.extract_body(ARTICLE.format(title="T"))
        self.assertIsNotNone(body)
        self.xhtml, self.images = h.sanitize(body, "https://habr.com/ru/articles/1/", "ch01-")

    def test_wellformed(self):
        ET.fromstring(f"<root>{self.xhtml}</root>")  # бросит при кривом XML

    def test_drops_scripts_and_frames(self):
        self.assertNotIn("iframe", self.xhtml)
        self.assertNotIn("youtube", self.xhtml)
        self.assertNotIn("шапка сайта", self.xhtml)
        self.assertNotIn("подвал сайта", self.xhtml)

    def test_unwraps_unknown_tags(self):
        self.assertNotIn("<font", self.xhtml)
        self.assertIn("устаревший тег разворачивается", self.xhtml)

    def test_entities_and_escaping(self):
        self.assertIn("AT&amp;T", self.xhtml)
        self.assertIn("«кавычками»", self.xhtml)
        self.assertIn("if (a &lt; b)", self.xhtml)

    def test_image_urls_absolutised(self):
        self.assertIn("https://habr.com/img/pic.png", self.images)
        self.assertIn("https://habrastorage.org/lazy.jpg", self.images)

    def test_anchors_prefixed(self):
        self.assertIn('id="ch01-anchor"', self.xhtml)
        self.assertIn('href="#ch01-anchor"', self.xhtml)

    def test_table_and_list_structure(self):
        root = ET.fromstring(f"<root>{self.xhtml}</root>")
        self.assertEqual(len(root.findall(".//li")), 2)
        self.assertEqual(len(root.findall(".//tr")), 2)
        self.assertEqual(root.find(".//td[@colspan]").get("colspan"), "2")

    def test_unclosed_paragraphs_split(self):
        root = ET.fromstring(f"<root>{self.xhtml}</root>")
        self.assertGreaterEqual(len(root.findall("./p")), 2)

    def test_missing_images_dropped(self):
        cleaned = h.rewrite_images(self.xhtml, {})
        self.assertNotIn("<img", cleaned)
        ET.fromstring(f"<root>{cleaned}</root>")


class TestSlug(unittest.TestCase):
    def test_cyrillic_transliterated(self):
        self.assertEqual(h.slug("Теория информации", "x"), "teoriya-informacii")
        self.assertEqual(h.slug("Цифровые фильтры — 1", "x"), "cifrovye-filtry-1")
        self.assertEqual(h.slug("!!!", "ch07"), "ch07")


class TestBuild(unittest.TestCase):
    def test_full_build_from_file_urls(self):
        with tempfile.TemporaryDirectory() as tmp:
            urls = []
            for i in (1, 2, 3):
                p = os.path.join(tmp, f"a{i}.html")
                with open(p, "w", encoding="utf-8") as fh:
                    fh.write(ARTICLE.format(title=f"Статья {i}"))
                urls.append(urllib.parse.urljoin("file://", urllib.request.pathname2url(p)))
            urls.append("file:///nope/missing.html")  # намеренно битая глава
            nav = os.path.join(tmp, "nav.epub")
            make_navigator(nav, urls)
            out = os.path.join(tmp, "book.epub")
            rc = h.main([nav, "-o", out, "--cache-dir", os.path.join(tmp, "cache"),
                         "--delay", "0", "--no-images"])
            self.assertEqual(rc, 1)  # одна глава не скачалась
            self.check_epub(out, chapters=4, missing=1)

    def check_epub(self, path, chapters, missing):
        with zipfile.ZipFile(path) as zf:
            self.assertIsNone(zf.testzip())
            info = zf.infolist()[0]
            self.assertEqual(info.filename, "mimetype")
            self.assertEqual(info.compress_type, zipfile.ZIP_STORED)
            self.assertEqual(zf.read("mimetype").decode(), "application/epub+zip")

            names = set(zf.namelist())
            opf = ET.fromstring(zf.read("OEBPS/content.opf"))
            ns = {"opf": "http://www.idpf.org/2007/opf"}
            hrefs = {i.get("href"): i.get("id")
                     for i in opf.findall(".//opf:manifest/opf:item", ns)}
            for href in hrefs:
                self.assertIn(f"OEBPS/{href}", names, f"в манифесте есть {href}, в zip нет")
            ids = set(hrefs.values())
            spine = [r.get("idref") for r in opf.findall(".//opf:spine/opf:itemref", ns)]
            self.assertEqual(len(spine), chapters + 1)
            for idref in spine:
                self.assertIn(idref, ids)

            for name in names:
                if name.endswith((".xhtml", ".opf", ".ncx", ".xml")):
                    ET.fromstring(zf.read(name))  # всё должно быть валидным XML

            nav = ET.fromstring(zf.read("OEBPS/nav.xhtml"))
            xh = "{http://www.w3.org/1999/xhtml}"
            links = [a.get("href") for a in nav.iter(f"{xh}a")]
            self.assertEqual(len(links), chapters + 2)  # + титул + раздел
            for href in links:
                self.assertIn(f"OEBPS/{href.split('#')[0]}", names)

            ncx = ET.fromstring(zf.read("OEBPS/toc.ncx"))
            nn = "{http://www.daisy.org/z3986/2005/ncx/}"
            self.assertEqual(len(list(ncx.iter(f"{nn}navPoint"))), chapters + 1)

            body = "".join(zf.read(n).decode() for n in names if n.endswith(".xhtml"))
            self.assertEqual(body.count("Текст этой главы не удалось загрузить"), missing)


if __name__ == "__main__":
    unittest.main(verbosity=2)
