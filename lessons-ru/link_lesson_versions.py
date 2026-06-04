#!/usr/bin/env python3
"""Insert a cross-version navigation block into every lesson file across the three
Russian collections (compact / extended / full translation) and refresh their READMEs.

Idempotent: keyed off the ``<!-- nav -->`` marker. Re-running replaces the block.
"""
import os

# All three collections live alongside this script, inside the lessons-ru folder.
REPO = os.path.dirname(os.path.abspath(__file__))

VERSIONS = [
    ("lesson-summaries", "Кратко"),
    ("lesson-summaries-full", "Расширенно"),
    ("lesson-originals-ru", "Полный перевод"),
]

GITHUB_BASE = "https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn"

# Canonical lesson subpaths (without .md), identical across all three folders.
SUBPATHS = [
    "stage-1/ai-capabilities-through-games",
    "stage-1/building-prototype",
    "stage-1/complete-project-practice",
    "stage-1/finding-great-idea",
    "stage-1/integrating-ai-capabilities",
    "stage-1/introduction-to-ai-ide",
    "stage-1/learning-map",
    "stage-2/frontend/design-to-code",
    "stage-2/frontend/figma-mastergo",
    "stage-2/frontend/hogwarts-portraits",
    "stage-2/frontend/llm-skills-beautiful",
    "stage-2/frontend/lovart-assets",
    "stage-2/frontend/modern-component-library",
    "stage-2/frontend/multi-product-ui",
    "stage-2/frontend/ui-design",
    "stage-2/backend/ai-interface-code",
    "stage-2/backend/database-supabase",
    "stage-2/backend/git-workflow",
    "stage-2/backend/modern-cli",
    "stage-2/backend/stripe-payment",
    "stage-2/backend/zeabur-deployment",
    "stage-2/ai-capabilities/dify-knowledge-base",
    "stage-3/core-skills/agent-teams",
    "stage-3/core-skills/basics",
    "stage-3/core-skills/claude-agent-sdk",
    "stage-3/core-skills/long-running-tasks",
    "stage-3/core-skills/mcp",
    "stage-3/core-skills/mobile-development",
    "stage-3/core-skills/skills",
    "stage-3/core-skills/spec-coding",
    "stage-3/core-skills/superpowers",
    "stage-3/core-skills/workflow",
    "stage-3/cross-platform/android-app",
    "stage-3/cross-platform/browser-ai-extension",
    "stage-3/cross-platform/choose-platform",
    "stage-3/cross-platform/electron-voice-to-text",
    "stage-3/cross-platform/ios-app",
    "stage-3/cross-platform/nft-minting",
    "stage-3/cross-platform/pwa-local-app",
    "stage-3/cross-platform/qt-industrial-hmi",
    "stage-3/cross-platform/vscode-extension",
    "stage-3/cross-platform/wechat-miniprogram",
    "stage-3/cross-platform/wechat-miniprogram-backend",
    "stage-3/ai-advanced/langgraph-advanced-rag",
    "stage-3/ai-advanced/llamaindex-enterprise-knowledge-base",
    "stage-3/ai-advanced/rag-introduction",
    "stage-3/personal-brand/personal-website-blog",
]

MARKER = "<!-- nav -->"


def nav_block(current_folder, subpath):
    """Build the nav paragraph for a file in *current_folder* about *subpath*."""
    cur_file_dir = os.path.dirname(os.path.join(current_folder, subpath + ".md"))
    parts = []
    for folder, label in VERSIONS:
        if folder == current_folder:
            parts.append(f"**{label}**")
        else:
            target = os.path.join(folder, subpath + ".md")
            rel = os.path.relpath(target, start=cur_file_dir)
            parts.append(f"[{label}]({rel})")
    parts.append(f"[Оригинал 中文]({GITHUB_BASE}/{subpath}/index.md)")
    return f"{MARKER}\n**📚 Версии:** " + " · ".join(parts) + "\n"


def strip_existing_nav(lines):
    """Remove a previously inserted nav block (marker + following non-blank lines)."""
    out = []
    i = 0
    while i < len(lines):
        if lines[i].strip() == MARKER:
            i += 1
            while i < len(lines) and lines[i].strip() != "":
                i += 1
            # skip one trailing blank separator if present
            if i < len(lines) and lines[i].strip() == "":
                i += 1
            continue
        out.append(lines[i])
        i += 1
    return out


def insertion_index(lines):
    """Where to insert nav: after YAML frontmatter if present, else after the
    first heading block (H1 + optional `> Этап` quote line)."""
    i = 0
    if lines and lines[0].strip() == "---":
        i = 1
        while i < len(lines) and lines[i].strip() != "---":
            i += 1
        i = i + 1 if i < len(lines) else len(lines)
        while i < len(lines) and lines[i].strip() == "":
            i += 1
        return i
    # no frontmatter: skip leading blanks, the H1, then an optional `> Этап` quote
    while i < len(lines) and lines[i].strip() == "":
        i += 1
    if i < len(lines) and lines[i].lstrip().startswith("#"):
        i += 1
        j = i
        while j < len(lines) and lines[j].strip() == "":
            j += 1
        if j < len(lines) and lines[j].lstrip().startswith(">"):
            i = j + 1
    return i


def process_file(folder, subpath):
    path = os.path.join(REPO, folder, subpath + ".md")
    if not os.path.exists(path):
        return False
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    lines = strip_existing_nav(lines)
    idx = insertion_index(lines)
    block = nav_block(folder, subpath) + ""
    block_lines = ["", *block.rstrip("\n").split("\n"), ""]
    new_lines = lines[:idx] + block_lines + lines[idx:]
    # collapse accidental triple blanks at the seam
    text = "\n".join(new_lines)
    while "\n\n\n\n" in text:
        text = text.replace("\n\n\n\n", "\n\n\n")
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    return True


def main():
    written, missing = 0, []
    for folder, _ in VERSIONS:
        for subpath in SUBPATHS:
            if process_file(folder, subpath):
                written += 1
            else:
                missing.append(f"{folder}/{subpath}.md")
    print(f"nav inserted into {written} files")
    if missing:
        print("MISSING (skipped):")
        for m in missing:
            print("  " + m)


if __name__ == "__main__":
    main()
