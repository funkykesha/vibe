import { spawn } from 'node:child_process';

export function runCommand(cmd, args, { timeoutMs = 60_000, stdin = null } = {}) {
  return new Promise((resolve) => {
    const t0 = Date.now();
    let child;
    try {
      child = spawn(cmd, args, { stdio: ['pipe', 'pipe', 'pipe'] });
    } catch (err) {
      resolve({
        stdout: '',
        stderr: String(err),
        code: 127,
        durationSec: 0,
      });
      return;
    }

    let stdout = '';
    let stderr = '';
    let killed = false;
    const timer = setTimeout(() => {
      killed = true;
      try {
        child.kill('SIGKILL');
      } catch {}
    }, timeoutMs);

    child.stdout.on('data', (b) => {
      stdout += b.toString('utf8');
    });
    child.stderr.on('data', (b) => {
      stderr += b.toString('utf8');
    });
    child.on('error', (err) => {
      clearTimeout(timer);
      resolve({
        stdout,
        stderr: stderr || String(err),
        code: 127,
        durationSec: (Date.now() - t0) / 1000,
      });
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      resolve({
        stdout,
        stderr: killed ? stderr || `timeout after ${timeoutMs}ms` : stderr,
        code: killed ? 124 : code ?? 0,
        durationSec: (Date.now() - t0) / 1000,
      });
    });

    if (stdin != null) {
      try {
        child.stdin.end(stdin);
      } catch {}
    } else {
      child.stdin.end();
    }
  });
}
