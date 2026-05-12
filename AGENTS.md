## Monorepo commits

Default behavior when asked to prepare commit messages:
1. Run `mono-commit plan --staged --json`.
2. If no staged groups exist, run `mono-commit plan --json`.
3. For each group, run its `diff_command`.
4. Generate one Conventional Commit message per group.
5. Do not create commit candidates for packages only affected through dependency graph.
6. Treat `cross_project_move` as one atomic commit.
7. Output only changed group, proposed commit message, and exact git commands.
8. Do not run `git commit` unless explicitly asked.

Exception for daily automation:
1. If the automation explicitly asks to commit automatically, use `mono-commit` groups as the only commit boundary.
2. Commit one group at a time with one Conventional Commit message per group.
3. Before each commit, stage only the current group's files via the group's `stage_command` and verify the staged diff matches that group.
4. After all group commits succeed, run `git push origin main`.
5. Stop on the first failure and report the exact command and error.
