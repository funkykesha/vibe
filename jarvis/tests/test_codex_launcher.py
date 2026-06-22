import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from codex_launcher import build_applescript  # noqa: E402


def test_includes_dir_codex_and_prompt():
    s = build_applescript("write tests", "/Users/me/prog", "codex")
    assert "cd '/Users/me/prog'" in s
    assert 'write text "codex"' in s
    assert "write tests" in s
    assert "create tab" in s


def test_escapes_double_quotes_in_prompt():
    s = build_applescript('add a "hello" banner', "/tmp", "codex")
    # The embedded quotes must be backslash-escaped, not raw.
    assert r'\"hello\"' in s


def test_custom_codex_command():
    s = build_applescript("do it", "/tmp", "codex --model gpt-5")
    assert 'write text "codex --model gpt-5"' in s
