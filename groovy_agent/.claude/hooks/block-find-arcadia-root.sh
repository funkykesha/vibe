#!/bin/bash
# Block `find` commands targeting arcadia root directories
# Prevents full-repo scans that are slow and wasteful
# Allows find with specific subdirectory paths
#
# Install: add to settings.json hooks section:
#   "hooks": {
#     "Bash": {
#       "pre": [{ "command": "bash ai/artifacts/hooks/block-find-arcadia-root.sh" }]
#     }
#   }

CMD=$(jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

FIRST_WORD=$(echo "$CMD" | awk '{print $1}')
[ "$FIRST_WORD" != "find" ] && exit 0

FIND_PATH=$(echo "$CMD" | awk '{print $2}')
[ -z "$FIND_PATH" ] && exit 0

# Expand ~ to home dir
FIND_PATH="${FIND_PATH/#\~/$HOME}"

# Resolve relative paths using cwd
if [[ "$FIND_PATH" == "." || "$FIND_PATH" == "./" || "$FIND_PATH" == ".." ]]; then
  CWD=$(jq -r '.cwd // empty')
  if [ -n "$CWD" ]; then
    FIND_PATH="$CWD"
  fi
fi

# Block arcadia root or worktree root (no subdirectory)
# Block: ~/arcadia, ~/arcadia/, ~/arcadia-foo, ~/arcadia-foo/
# Allow: ~/arcadia/taxi/services/..., ~/arcadia-foo/junk/...
if echo "$FIND_PATH" | grep -qE "^${HOME}/arcadia(-[^/]+)?/?$"; then
  echo '{"decision":"block","reason":"Never run find at arcadia root — too many files. Use ast-index or ask for the specific path."}'
  exit 0
fi

exit 0
