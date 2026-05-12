const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const { planChanges } = require("../lib/planner");

function run(cmd, args, cwd) {
  return execFileSync(cmd, args, {
    cwd,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

function initRepo() {
  const repoDir = fs.mkdtempSync(path.join(os.tmpdir(), "mono-commit-"));
  run("git", ["init", "-q"], repoDir);
  run("git", ["config", "user.name", "Test User"], repoDir);
  run("git", ["config", "user.email", "test@example.com"], repoDir);
  return repoDir;
}

test("plan groups project changes and root files", () => {
  const repoDir = initRepo();
  fs.mkdirSync(path.join(repoDir, "packages/ui/src"), { recursive: true });
  fs.writeFileSync(path.join(repoDir, "packages/ui/package.json"), JSON.stringify({ name: "@repo/ui" }, null, 2));
  fs.writeFileSync(path.join(repoDir, "packages/ui/src/Button.tsx"), "export const Button = 1;\n");
  fs.writeFileSync(path.join(repoDir, "README.md"), "hello\n");
  run("git", ["add", "."], repoDir);
  run("git", ["commit", "-m", "init"], repoDir);

  fs.writeFileSync(path.join(repoDir, "packages/ui/src/Button.tsx"), "export const Button = 2;\n");
  fs.writeFileSync(path.join(repoDir, "README.md"), "changed\n");

  const plan = planChanges({ cwd: repoDir, staged: false });
  assert.equal(plan.mode, "working_tree");
  assert.equal(plan.groups.length, 2);

  const pkg = plan.groups.find((group) => group.id === "packages-ui");
  assert.equal(pkg.scope, "ui");
  assert.equal(pkg.path, "packages/ui");
  assert.equal(pkg.diff_command, "git diff HEAD -- packages/ui");

  const root = plan.groups.find((group) => group.id === "root");
  assert.equal(root.scope, "repo");
});

test("plan keeps R100 rename within one project", () => {
  const repoDir = initRepo();
  fs.mkdirSync(path.join(repoDir, "packages/ui/src"), { recursive: true });
  fs.writeFileSync(path.join(repoDir, "packages/ui/package.json"), JSON.stringify({ name: "@repo/ui" }, null, 2));
  fs.writeFileSync(path.join(repoDir, "packages/ui/src/Button.tsx"), "export const Button = 1;\n");
  run("git", ["add", "."], repoDir);
  run("git", ["commit", "-m", "init"], repoDir);

  run("git", ["mv", "packages/ui/src/Button.tsx", "packages/ui/src/Icon.tsx"], repoDir);

  const plan = planChanges({ cwd: repoDir, staged: false });
  const pkg = plan.groups.find((group) => group.id === "packages-ui");
  assert.equal(pkg.group_type, "project");
  assert.equal(pkg.files.length, 1);
  assert.match(pkg.files[0].status, /^R\d+$/);
  assert.equal(pkg.files[0].old_path, "packages/ui/src/Button.tsx");
  assert.equal(pkg.files[0].new_path, "packages/ui/src/Icon.tsx");
});

test("plan creates one cross_project_move group for partial rename", () => {
  const repoDir = initRepo();
  fs.mkdirSync(path.join(repoDir, "packages/ui"), { recursive: true });
  fs.mkdirSync(path.join(repoDir, "packages/shared"), { recursive: true });
  fs.writeFileSync(path.join(repoDir, "packages/ui/package.json"), JSON.stringify({ name: "@repo/ui" }, null, 2));
  fs.writeFileSync(path.join(repoDir, "packages/shared/package.json"), JSON.stringify({ name: "@repo/shared" }, null, 2));
  fs.writeFileSync(
    path.join(repoDir, "packages/ui/Button.tsx"),
    [
      "export const line1 = 'a';",
      "export const line2 = 'b';",
      "export const line3 = 'c';",
      "export const line4 = 'd';",
      "export const line5 = 'e';",
      "export const line6 = 'f';",
      "export const line7 = 'g';",
      "export const line8 = 'h';",
      "export const line9 = 'i';",
      "export const line10 = 'j';",
      "",
    ].join("\n")
  );
  run("git", ["add", "."], repoDir);
  run("git", ["commit", "-m", "init"], repoDir);

  run("git", ["mv", "packages/ui/Button.tsx", "packages/shared/Button.tsx"], repoDir);
  fs.writeFileSync(
    path.join(repoDir, "packages/shared/Button.tsx"),
    [
      "export const line1 = 'a';",
      "export const line2 = 'b';",
      "export const line3 = 'c';",
      "export const line4 = 'd-changed';",
      "export const line5 = 'e';",
      "export const line6 = 'f';",
      "export const line7 = 'g-changed';",
      "export const line8 = 'h';",
      "export const line9 = 'i';",
      "export const line10 = 'j-changed';",
      "",
    ].join("\n")
  );
  run("git", ["add", "-A"], repoDir);

  const plan = planChanges({ cwd: repoDir, staged: false });
  const move = plan.groups.find((group) => group.group_type === "cross_project_move");
  assert.ok(move);
  assert.equal(move.scope, "ui,shared");
  assert.equal(move.candidate_type, "refactor");
  assert.equal(move.path, undefined);
  assert.equal(move.diff_command, "git diff HEAD -- packages/shared packages/ui");
  assert.match(move.files[0].status, /^R\d+$/);
  assert.notEqual(move.files[0].status, "R100");
  assert.equal(move.files[0].old_path, "packages/ui/Button.tsx");
  assert.equal(move.files[0].new_path, "packages/shared/Button.tsx");
});
