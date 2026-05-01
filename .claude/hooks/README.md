# Markdown Converter Hook

This hook automatically converts office documents to markdown format to reduce context usage.

## Installation

1. Ensure requirements are installed:
```bash
pip install "markitdown[docx,pdf,pptx]"
```

2. The hook is located at:
   `.claude/hooks/pre-task-markdown-converter.py`

## How It Works

**On Session Start**:
1. Scans current directory recursively
2. Finds supported formats (.xlsx, .docx, .pdf, etc.)
3. Converts files without existing .md or outdated .md versions
4. Reports conversion count

**On File Read**:
1. Checks if agent tries to read original format
2. If .md version exists and is newer, suggests reading it
3. **Does not block** original file reading (per user preference)

## To Enable

Add to your `.claude/config.json` or equivalent configuration:

```json
{
  "hooks": {
    "pre-task": [
      {
        "command": "python3",
        "args": [
          "/path/to/.claude/hooks/pre-task-markdown-converter.py"
        ]
      }
    ]
  }
}
```

**For Claude Code** (claude.ai/code):

Add to `CLAUDE.md` or create `.claude-hooks/pre-task.md`:

```markdown
## Pre-Task Hooks

```bash
python3 .claude/hooks/pre-task-markdown-converter.py
```
```

## Supported Formats

- Documents: .docx, .doc, .txt, .rtf
- Spreadsheets: .xlsx, .xls, .csv, .tsv
- Presentations: .pptx, .ppt
- PDF: .pdf
- Web/Data: .html, .htm, .xml, .json

## Excluded Directories

The hook automatically excludes these directories:
- `.venv`, `venv`, `env`, `node_modules`
- `.git`, `.vscode`, `.idea`
- `dist`, `build`, `target`, `bin`, `obj`
- `.claude`, `.opencode`, `.memory-bank`

## Manual Testing

Run the hook manually to test:

```bash
cd /your/project/directory
python3 .claude/hooks/pre-task-markdown-converter.py
```

Expected output:
```
[md-converter] Converting 3/10 files...
[md-converter] ✓ Converted 3/3 files
```

Or if all files are already converted:
```
[md-converter] All 10 files already converted
```

## Troubleshooting

**Hook not running**: Check if path is correct and executable
```
chmod +x .claude/hooks/pre-task-markdown-converter.py
```

**markitdown not found**: Install with format support
```bash
pip install "markitdown[docx,pdf,pptx]"
```

**Files not converting**: Check file permissions and markitdown support for format
