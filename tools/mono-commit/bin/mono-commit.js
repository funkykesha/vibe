#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { getDefaultConfigYaml, loadConfig } = require("../lib/config");
const { diffGroup, planChanges, resolveRepoRoot } = require("../lib/planner");

function main(argv) {
  const [command, ...rest] = argv;

  try {
    switch (command) {
      case "plan":
        handlePlan(rest);
        return;
      case "diff":
        handleDiff(rest);
        return;
      case "config":
        handleConfig(rest);
        return;
      case undefined:
      case "--help":
      case "-h":
        printHelp();
        return;
      default:
        fail(`Unknown command: ${command}`);
    }
  } catch (error) {
    fail(error.message || String(error));
  }
}

function handlePlan(args) {
  const flags = new Set(args);
  const staged = flags.has("--staged");
  const json = flags.has("--json");
  const plan = planChanges({ cwd: process.cwd(), staged });

  if (!json) {
    fail("Only --json output is supported in MVP.");
  }

  process.stdout.write(`${JSON.stringify(plan, null, 2)}\n`);
}

function handleDiff(args) {
  const groupId = args[0];
  const staged = args.includes("--staged");
  if (!groupId) {
    fail("Usage: mono-commit diff <group-id> [--staged]");
  }

  const output = diffGroup({
    cwd: process.cwd(),
    groupId,
    staged,
  });

  process.stdout.write(output ? `${output}\n` : "");
}

function handleConfig(args) {
  const subcommand = args[0];
  if (subcommand !== "init") {
    fail("Usage: mono-commit config init");
  }

  const repoRoot = resolveRepoRoot(process.cwd());
  const { configPath, exists } = loadConfig(repoRoot);
  if (exists) {
    fail(`Config already exists: ${configPath}`);
  }

  fs.writeFileSync(path.join(repoRoot, ".mono-commit.yml"), getDefaultConfigYaml(), "utf8");
  process.stdout.write(`${configPath}\n`);
}

function printHelp() {
  process.stdout.write(`mono-commit

Usage:
  mono-commit plan --json [--staged]
  mono-commit diff <group-id> [--staged]
  mono-commit config init
`);
}

function fail(message) {
  process.stderr.write(`${message}\n`);
  process.exit(1);
}

main(process.argv.slice(2));
