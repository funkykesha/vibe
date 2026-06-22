import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

import config  # noqa: E402
from config import Config  # noqa: E402


def test_defaults_and_roundtrip(tmp_path, monkeypatch):
    cfg_dir = tmp_path / ".config" / "jarvis"
    monkeypatch.setattr(config, "CONFIG_DIR", cfg_dir)
    monkeypatch.setattr(config, "CONFIG_PATH", cfg_dir / "config.json")

    cfg = Config.load()  # creates with defaults
    assert cfg.voice_provider == "handy"
    assert cfg.codex_cmd == "codex"
    assert (cfg_dir / "config.json").exists()

    cfg.base_dir = "$HOME/work"
    cfg.save()
    again = Config.load()
    assert again.base_dir == "$HOME/work"


def test_base_dir_expanded(monkeypatch):
    monkeypatch.setenv("HOME", "/Users/tester")
    cfg = Config(base_dir="$HOME/prog")
    assert cfg.base_dir_expanded == "/Users/tester/prog"


def test_voice_provider_factory():
    from voice import make_provider, HandyVoiceProvider, StubVoiceProvider

    assert isinstance(make_provider("handy"), HandyVoiceProvider)
    assert isinstance(make_provider("stub"), StubVoiceProvider)
