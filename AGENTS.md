## Monorepo commits

When asked to prepare commit messages:
1. Run `mono-commit plan --staged --json`.
2. For each group, run its `diff_command`.
3. Generate one Conventional Commit message per group.
4. Do not create commit candidates for packages only affected through dependency graph.
5. Treat `cross_project_move` as one atomic commit.
6. Output only changed group, proposed commit message, and exact git commands.
7. Never run `git commit` unless explicitly asked.
