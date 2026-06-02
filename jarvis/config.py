"""
Jarvis configuration.

Single JSON file at ~/.config/jarvis/config.json. Created with defaults on
first run. Secrets (API keys for future voice providers) come from the
environment, never from this file.
"""

import json
import os
from dataclasses import dataclass, asdict
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "jarvis"
CONFIG_PATH = CONFIG_DIR / "config.json"

# Where Codex sessions are launched. The concept calls this "base prog".
DEFAULT_BASE_DIR = str(Path.home() / "prog")
# Command that starts an interactive Codex session inside the new iTerm tab.
DEFAULT_CODEX_CMD = "codex"


@dataclass
class Config:
    base_dir: str = DEFAULT_BASE_DIR
    codex_cmd: str = DEFAULT_CODEX_CMD
    # Voice provider id: "handy" (default, external dictation app) or "stub".
    voice_provider: str = "handy"

    @classmethod
    def load(cls) -> "Config":
        if CONFIG_PATH.exists():
            data = json.loads(CONFIG_PATH.read_text())
            known = {k: v for k, v in data.items() if k in cls.__annotations__}
            return cls(**known)
        cfg = cls()
        cfg.save()
        return cfg

    def save(self) -> None:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        CONFIG_PATH.write_text(json.dumps(asdict(self), indent=2, ensure_ascii=False))

    @property
    def base_dir_expanded(self) -> str:
        return os.path.expanduser(os.path.expandvars(self.base_dir))
