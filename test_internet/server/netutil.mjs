import { runCommand } from './runCommand.mjs';

const IPIFY_URL = 'https://api.ipify.org';

export async function defaultRouteIface() {
  const { code, stdout } = await runCommand('route', ['-n', 'get', 'default'], { timeoutMs: 5000 });
  if (code !== 0) return null;
  const m = stdout.match(/interface:\s*(\S+)/);
  return m ? m[1] : null;
}

export async function ifaceIp(iface) {
  const { code, stdout } = await runCommand('ifconfig', [iface], { timeoutMs: 5000 });
  if (code !== 0) return null;
  const m = stdout.match(/inet (\d+\.\d+\.\d+\.\d+)/);
  return m ? m[1] : null;
}

export async function publicIp({ iface = null } = {}) {
  const args = ['-s', '--max-time', '8'];
  if (iface) args.push('--interface', iface);
  args.push(IPIFY_URL);
  const { code, stdout } = await runCommand('curl', args, { timeoutMs: 10_000 });
  const out = stdout.trim();
  if (code === 0 && /^\d+\.\d+\.\d+\.\d+$/.test(out)) return out;
  return null;
}
