const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const { loadConfig } = require("./config");

function planChanges(options = {}) {
  const repoRoot = resolveRepoRoot(options.cwd || process.cwd());
  const { config } = loadConfig(repoRoot);
  const mode = options.staged ? "staged" : "working_tree";

  const trackedRecords = options.staged
    ? parseNameStatus(runGit(repoRoot, ["diff", "--staged", "--name-status"]))
    : collectWorkingTreeRecords(repoRoot);

  const groups = buildGroups({
    config,
    mode,
    records: trackedRecords,
    repoRoot,
  });

  return {
    repo_root: repoRoot,
    mode,
    groups,
  };
}

function collectWorkingTreeRecords(repoRoot) {
  const staged = parseNameStatus(runGit(repoRoot, ["diff", "--staged", "--name-status"]));
  const unstaged = parseNameStatus(runGit(repoRoot, ["diff", "--name-status"]));
  const untracked = parseStatusUntracked(runGit(repoRoot, ["status", "--short", "--untracked-files=all"]));

  const byKey = new Map();
  for (const record of [...staged, ...unstaged, ...untracked]) {
    byKey.set(recordKey(record), record);
  }
  return Array.from(byKey.values());
}

function diffGroup(options = {}) {
  const plan = planChanges(options);
  const group = plan.groups.find((item) => item.id === options.groupId);
  if (!group) {
    const error = new Error(`Unknown group id: ${options.groupId}`);
    error.code = "GROUP_NOT_FOUND";
    throw error;
  }

  return renderGroupDiff({
    group,
    mode: plan.mode,
    repoRoot: plan.repo_root,
  });
}

function renderGroupDiff({ group, mode, repoRoot }) {
  const renameFiles = group.files.filter((file) => file.old_path && file.new_path);
  const regularPaths = group.files
    .map((file) => file.path)
    .filter(Boolean);
  const seen = new Set();
  const targets = [];

  for (const target of [...regularPaths, ...renameFiles.flatMap((file) => [file.old_path, file.new_path])]) {
    if (!seen.has(target)) {
      seen.add(target);
      targets.push(target);
    }
  }

  let output = "";
  const diffArgs = mode === "staged" ? ["diff", "--staged"] : ["diff", "HEAD"];

  if (targets.length > 0) {
    output += runGit(repoRoot, [...diffArgs, "--", ...targets], { allowFailure: true });
  }

  const untracked = group.files.filter((file) => file.status === "??" && file.path);
  for (const file of untracked) {
    output += runGit(repoRoot, ["diff", "--no-index", "--", "/dev/null", file.path], {
      allowFailure: true,
    });
  }

  return output.trimEnd();
}

function buildGroups({ config, mode, records, repoRoot }) {
  const groups = new Map();

  for (const record of records) {
    const fileGroup = groupRecord(record, config, repoRoot);
    const key = fileGroup.id;

    if (!groups.has(key)) {
      groups.set(key, {
        id: fileGroup.id,
        group_type: fileGroup.groupType,
        scope: fileGroup.scope,
        path: fileGroup.path,
        candidate_type: fileGroup.candidateType,
        _pathsForCommands: [...fileGroup.pathsForCommands],
        files: [],
      });
    }

    const group = groups.get(key);
    group.files.push(formatFileRecord(record));
    for (const groupPath of fileGroup.pathsForCommands) {
      if (!group._pathsForCommands.includes(groupPath)) {
        group._pathsForCommands.push(groupPath);
      }
    }
    group.candidate_type = mergeCandidateType(group.candidate_type, inferCandidateType(record, fileGroup));
  }

  return Array.from(groups.values())
    .map((group) => finalizeGroup(group, mode))
    .sort((left, right) => left.id.localeCompare(right.id));
}

function finalizeGroup(group, mode) {
  const paths = [...group._pathsForCommands].sort();
  const diffCommandBase = mode === "staged" ? "git diff --staged --" : "git diff HEAD --";

  return {
    id: group.id,
    group_type: group.group_type,
    scope: group.scope,
    ...(group.path ? { path: group.path } : {}),
    candidate_type: group.candidate_type,
    files: group.files,
    diff_command: `${diffCommandBase} ${paths.join(" ")}`.trim(),
    stage_command: `git add ${paths.join(" ")}`.trim(),
  };
}

function mergeCandidateType(current, next) {
  if (current === "unknown") {
    return next;
  }
  if (next === "unknown" || current === next) {
    return current;
  }
  return current;
}

function inferCandidateType(record, fileGroup) {
  if (fileGroup.groupType === "cross_project_move") {
    return "refactor";
  }

  const paths = [record.path, record.old_path, record.new_path].filter(Boolean);
  const lower = paths.map((item) => item.toLowerCase());

  if (lower.some((item) => item.includes("__tests__/") || item.endsWith(".test.ts") || item.endsWith(".spec.ts"))) {
    return "test";
  }
  if (lower.some((item) => item.endsWith(".md") || item.startsWith("docs/"))) {
    return "docs";
  }
  if (lower.some((item) => item === "package.json" || item.endsWith("package-lock.json") || item.endsWith("pnpm-lock.yaml") || item.endsWith("yarn.lock"))) {
    return "chore";
  }
  if (lower.some((item) => item.startsWith(".github/") || item.includes("/.github/") || item.includes("github/workflows"))) {
    return "ci";
  }
  if (lower.some((item) => path.basename(item) === "dockerfile" || item.endsWith("docker-compose.yml") || item.endsWith("docker-compose.yaml") || item.endsWith("compose.yml") || item.endsWith("compose.yaml"))) {
    return "build";
  }
  if (lower.some(isConfigPath)) {
    return "chore";
  }
  return "unknown";
}

function isConfigPath(item) {
  const base = path.basename(item);
  return (
    base.endsWith(".json") ||
    base.endsWith(".yaml") ||
    base.endsWith(".yml") ||
    base.endsWith(".toml") ||
    base.endsWith(".ini") ||
    base.endsWith(".conf") ||
    base.endsWith(".config.js") ||
    base.endsWith(".config.ts")
  );
}

function groupRecord(record, config, repoRoot) {
  if (record.old_path && record.new_path) {
    const oldGroup = classifyPath(record.old_path, config, repoRoot);
    const newGroup = classifyPath(record.new_path, config, repoRoot);

    if (oldGroup.id === newGroup.id) {
      return oldGroup;
    }

    const scope = [oldGroup.scope, newGroup.scope].filter(Boolean).join(",");
    const id = `move-${sanitizeForId(oldGroup.scope)}-to-${sanitizeForId(newGroup.scope)}`;
    return {
      id,
      groupType: "cross_project_move",
      scope,
      path: null,
      candidateType: "refactor",
      pathsForCommands: uniquePaths([oldGroup.path, newGroup.path]),
    };
  }

  return classifyPath(record.path, config, repoRoot);
}

function classifyPath(filePath, config, repoRoot) {
  const segments = filePath.split("/").filter(Boolean);
  const first = segments[0] || "";
  const second = segments[1] || "";

  for (const pattern of config.project_roots) {
    if (pattern.endsWith("/*")) {
      const root = pattern.slice(0, -2);
      if (first === root && second) {
        const groupPath = `${first}/${second}`;
        return {
          id: `${root}-${sanitizeForId(second)}`,
          groupType: "project",
          scope: resolveScope(groupPath, second, config, repoRoot),
          path: groupPath,
          candidateType: "unknown",
          pathsForCommands: [groupPath],
        };
      }
      continue;
    }

    if (first === pattern || filePath === pattern) {
      return {
        id: sanitizeForId(pattern),
        groupType: pattern,
        scope: pattern,
        path: pattern,
        candidateType: pattern === "docs" ? "docs" : "unknown",
        pathsForCommands: [pattern],
      };
    }
  }

  return {
    id: "root",
    groupType: "root",
    scope: config.root_scope,
    path: null,
    candidateType: "unknown",
    pathsForCommands: [segments[0] ? filePath.split("/")[0] === filePath ? filePath : filePath : "."],
  };
}

function resolveScope(groupPath, fallbackScope, config, repoRoot) {
  for (const strategy of config.scope_from) {
    if (strategy === "package_json_name") {
      const packageJsonPath = path.join(repoRoot, groupPath, "package.json");
      if (fs.existsSync(packageJsonPath)) {
        try {
          const parsed = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
          if (parsed.name && typeof parsed.name === "string") {
            return parsed.name.split("/").pop();
          }
        } catch (_error) {
          // Ignore invalid package.json in MVP and fall back to path-based scope.
        }
      }
    }

    if (strategy === "path") {
      return fallbackScope;
    }
  }

  return fallbackScope;
}

function formatFileRecord(record) {
  if (record.old_path && record.new_path) {
    return {
      status: record.status,
      old_path: record.old_path,
      new_path: record.new_path,
    };
  }

  return {
    status: record.status,
    path: record.path,
  };
}

function parseNameStatus(output) {
  const records = [];
  for (const line of output.split(/\r?\n/)) {
    if (!line.trim()) {
      continue;
    }
    const parts = line.split("\t");
    const status = parts[0];
    if (status.startsWith("R")) {
      records.push({
        status,
        old_path: parts[1],
        new_path: parts[2],
      });
      continue;
    }
    records.push({
      status,
      path: parts[1],
    });
  }
  return records;
}

function parseStatusUntracked(output) {
  const records = [];
  for (const line of output.split(/\r?\n/)) {
    if (!line.startsWith("?? ")) {
      continue;
    }
    records.push({
      status: "??",
      path: line.slice(3),
    });
  }
  return records;
}

function recordKey(record) {
  if (record.old_path && record.new_path) {
    return `${record.status}:${record.old_path}:${record.new_path}`;
  }
  return `${record.status}:${record.path}`;
}

function runGit(repoRoot, args, options = {}) {
  try {
    return execFileSync("git", args, {
      cwd: repoRoot,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
  } catch (error) {
    if (options.allowFailure) {
      return error.stdout || "";
    }
    throw new Error((error.stderr || error.message || "").trim());
  }
}

function resolveRepoRoot(cwd) {
  return execFileSync("git", ["rev-parse", "--show-toplevel"], {
    cwd,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

function sanitizeForId(value) {
  return String(value || "group")
    .replace(/[^A-Za-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .toLowerCase();
}

function uniquePaths(items) {
  return [...new Set(items.filter(Boolean))];
}

module.exports = {
  diffGroup,
  planChanges,
  parseNameStatus,
  parseStatusUntracked,
  resolveRepoRoot,
};
