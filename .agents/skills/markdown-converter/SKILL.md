---
name: markdown-converter
scope: builtin
version: 1.0.0
author: Codex
description: Convert office documents to markdown automatically to reduce context usage
---

# Markdown Converter

Convert office documents (Excel, Word, PDF, PowerPoint) to markdown format automatically. This reduces context usage and improves readability.

## Supported Formats

- **Documents**: .docx, .doc, .txt, .rtf
- **Spreadsheets**: .xlsx, .xls, .csv, .tsv
- **Presentations**: .pptx, .ppt
- **PDF**: .pdf
- **Web/Other**: .html, .htm, .xml, .json

## Usage

### CLI Tool

Run the converter from any directory:

```bash
# Convert all files in current directory
markdown-converter

# Recursive conversion (including subdirectories)
markdown-converter -r

# Skip files that already have .md version
markdown-converter -r --skip-existing

# Convert specific file
markdown-converter path/to/file.xlsx

# Convert specific directory
markdown-converter path/to/docs/ -r

# List supported formats
markdown-converter --formats
```

### CLI Options

- `-r, --recursive` - Search recursively in subdirectories
- `-s, --skip-existing` - Skip files that already have .md version
- `--formats` - List all supported file formats
- `-o, --output PATH` - Output directory for converted files

### Skill Integration

The converter is automatically invoked through hooks when:
1. A session starts with files in supported formats
2. You explicitly request conversion via the skill

## Behavior

**Automatic Conversion on Session Start**:
- Scans current directory for supported formats
- Converts to .md files next to originals
- Originals are still readable on explicit request

**Context Management**:
- Agent prefers reading .md versions when available
- Original files are not blocked, but discouraged
- Markdown versions use ~40-50% less space

**Excluded Directories**:
- `.venv`, `venv`, `env`, `node_modules`
- `.git`, `.vscode`, `.idea`
- `dist`, `build`, `target`, `bin`, `obj`

## Examples

```bash
# Convert finance files
markdown-converter -r

# View what will be converted
python3 /path/to/.Codex/bin/markdown-converter --formats
```

## Requirements

Requires `markitdown` library with format support:

```bash
pip install "markitdown[docx,pdf,pptx]"
```

## Technical Details

- Uses [Microsoft's markitdown](https://github.com/microsoft/markitdown) library
- Preserves structure and formatting
- Creates .md files alongside originals
- Handles nested directory structures
- Skips already-converted files with `--skip-existing`
