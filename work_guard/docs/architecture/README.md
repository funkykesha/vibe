# WorkGuard architecture (C4)

Diagrams use [Mermaid C4](https://mermaid.js.org/syntax/c4.html) syntax.

| Order | Document | Purpose | Status |
| --- | --- | --- | --- |
| 1 | [c4-context.md](c4-context.md) | System context, trust boundaries, external systems | Current |
| 2 | [c4-containers.md](c4-containers.md) | Runtime containers and local coordination boundaries | Current |
| 3 | [c4-components-core.md](c4-components-core.md) | Python core internals and module responsibilities | Current |
| 4 | [c4-dynamic-swift-ipc.md](c4-dynamic-swift-ipc.md) | Swift menu agent to Python IPC flow | Current |
| 5 | [c4-dynamic-launchagent-install.md](c4-dynamic-launchagent-install.md) | Rebuild/install and LaunchAgent flow contract | Planned |
| 6 | [c4-deployment.md](c4-deployment.md) | Installed desktop footprint and launch ownership | Current |

Current product behavior and operator workflow: [README.md](../../README.md)

History lives in `.memory-bank/project-context/review-history/` and should be treated as archive, not current architecture guidance.
