#!/usr/bin/env python3
"""
Pre-task hook for automatic markdown conversion.
Converts supported office documents to markdown on session start,
and prevents agent from bloating context by reading originals.
"""

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

SUPPORTED_ORIGINAL_FORMATS = {
}

EXCLUDE_DIRS = {
    '.venv', 'venv', 'env', '.env', '__pycache__',
    'node_modules', '.git', '.vscode', '.idea',
    'dist', 'build', 'target', 'bin', 'obj',
    '.claude', '.opencode', '.memory-bank'
}


def find_original_files(root_dir: Path, recursive: bool = True) -> list[Path]:
    files = []

    if recursive:
        for ext in SUPPORTED_ORIGINAL_FORMATS:
            for file_path in root_dir.rglob(f'*{ext}'):
                if any(excl in file_path.parts for excl in EXCLUDE_DIRS):
                    continue
                files.append(file_path)
    else:
        for ext in SUPPORTED_ORIGINAL_FORMATS:
            for file_path in root_dir.glob(f'*{ext}'):
                files.append(file_path)

    return sorted(files)


def markitdown_available() -> bool:
    try:
        from markitdown import MarkItDown
        return True
    except ImportError:
        return False


def convert_with_markitdown(file_path: Path) -> bool:
    try:
        from markitdown import MarkItDown
        md = MarkItDown()
        result = md.convert(str(file_path))

        md_path = file_path.with_suffix('.md')
        with open(md_path, 'w', encoding='utf-8') as f:
            f.write(result.text_content)

        return True
    except Exception as e:
        print(f"✗ Failed to convert {file_path.name}: {e}")
        return False


def run_pre_task():
    cwd = Path.cwd()

    if not markitdown_available():
        print("[md-converter] markitdown not installed. Install with:")
        print("  pip install 'markitdown[docx,pdf,pptx]'")
        return False

    # Find original files
    original_files = find_original_files(cwd, recursive=True)

    if not original_files:
        return False

    files_to_convert = []
    for orig_file in original_files:
        md_file = orig_file.with_suffix('.md')

        if not md_file.exists():
            files_to_convert.append(orig_file)
        elif orig_file.stat().st_mtime > md_file.stat().st_mtime:
            files_to_convert.append(orig_file)

    if not files_to_convert:
        print(f"[md-converter] All {len(original_files)} files already converted")
        return False

    print(f"[md-converter] Converting {len(files_to_convert)}/{len(original_files)} files...")

    success_count = 0
    for file_path in files_to_convert:
        if convert_with_markitdown(file_path):
            success_count += 1

    print(f"[md-converter] ✓ Converted {success_count}/{len(files_to_convert)} files")

    return success_count > 0


def pre_read_file_check(file_path: str) -> bool:
    path = Path(file_path)

    ext = path.suffix.lower()
    if ext in SUPPORTED_ORIGINAL_FORMATS:
        md_path = path.with_suffix('.md')

        if md_path.exists():
            md_mtime = md_path.stat().st_mtime
            orig_mtime = path.stat().st_mtime

            if md_mtime >= orig_mtime:
                print(f"[md-converter] Note: Consider reading {md_path.name} instead of {path.name}")
                return True

    return True


if __name__ == '__main__':
    run_pre_task()
