const fs = require("fs");
const path = require("path");

const DEFAULT_CONFIG = {
  project_roots: [
    "apps/*",
    "packages/*",
    "services/*",
    "libs/*",
    "tools/*",
    "docs",
    "infra",
  ],
  scope_from: ["package_json_name", "path"],
  root_scope: "repo",
};

function loadConfig(repoRoot) {
  const configPath = path.join(repoRoot, ".mono-commit.yml");
  if (!fs.existsSync(configPath)) {
    return { config: { ...DEFAULT_CONFIG }, configPath, exists: false };
  }

  const raw = fs.readFileSync(configPath, "utf8");
  const parsed = parseSimpleYaml(raw);
  return {
    config: {
      ...DEFAULT_CONFIG,
      ...parsed,
      project_roots: parsed.project_roots || DEFAULT_CONFIG.project_roots,
      scope_from: parsed.scope_from || DEFAULT_CONFIG.scope_from,
      root_scope: parsed.root_scope || DEFAULT_CONFIG.root_scope,
    },
    configPath,
    exists: true,
  };
}

function parseSimpleYaml(raw) {
  const result = {};
  let currentKey = null;

  for (const line of raw.split(/\r?\n/)) {
    if (!line.trim() || line.trim().startsWith("#")) {
      continue;
    }

    const keyMatch = line.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (keyMatch) {
      const [, key, value] = keyMatch;
      currentKey = key;
      if (!value) {
        result[key] = [];
      } else {
        result[key] = stripQuotes(value.trim());
      }
      continue;
    }

    const itemMatch = line.match(/^\s*-\s*(.+)$/);
    if (itemMatch && currentKey) {
      if (!Array.isArray(result[currentKey])) {
        result[currentKey] = [];
      }
      result[currentKey].push(stripQuotes(itemMatch[1].trim()));
    }
  }

  return result;
}

function stripQuotes(value) {
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    return value.slice(1, -1);
  }
  return value;
}

function getDefaultConfigYaml() {
  return `project_roots:
  - apps/*
  - packages/*
  - services/*
  - libs/*
  - tools/*
  - docs
  - infra
scope_from:
  - package_json_name
  - path
root_scope: repo
`;
}

module.exports = {
  DEFAULT_CONFIG,
  getDefaultConfigYaml,
  loadConfig,
};
