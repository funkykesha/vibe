# Fix visual-explainer plugin.json path traversal error

## Context

`/doctor` reports: `Plugin (visual-explainer): Path escapes plugin directory: ./ (skills)`

Both `plugin.json` files contain `"skills": ["./"]` — the loader treats `./` as a path traversal out of the plugin directory. Skills live in `commands/` subdirectory, not the root. Fix: replace `"./"` with `"commands"`.

## Files to modify

1. `~/.claude/plugins/cache/visual-explainer-marketplace/visual-explainer/0.7.1/.claude-plugin/plugin.json`
2. `~/.claude/plugins/marketplaces/visual-explainer-marketplace/plugins/visual-explainer/.claude-plugin/plugin.json`

## Change

In both files:
```json
// before
"skills": ["./"]

// after
"skills": ["commands"]
```

## Verification

After edit: run `/reload-plugins` → `/doctor` should show no errors for visual-explainer.
