#!/usr/bin/env python3
"""Convert files to Markdown using markitdown library."""
from pathlib import Path
from markitdown import MarkItDown


def convert_file(file_path, output_path):
    try:
        md = MarkItDown()
        result = md.convert(str(file_path))

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(result.text_content)

        print(f"✓ {file_path.name} → {output_path.name}")
        return True
    except Exception as e:
        print(f"✗ {file_path.name}: {e}")
        return False


def main():
    current_dir = Path('.')
    files = list(current_dir.glob('*.xlsx')) + list(current_dir.glob('*.docx'))

    print(f"Found {len(files)} file(s)\n")

    successes = 0
    for file_path in files:
        output_path = file_path.with_suffix('.md')
        if convert_file(file_path, output_path):
            successes += 1

    print(f"\n✓ Done! {successes}/{len(files)} converted")


if __name__ == '__main__':
    main()
