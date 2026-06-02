import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from voice import HandyVoiceProvider, StubVoiceProvider  # noqa: E402


def test_handy_passthrough():
    got = []
    p = HandyVoiceProvider()
    p.start_call(got.append)
    p.submit("напиши тесты")
    assert got == ["напиши тесты"]
    p.end_call()
    p.submit("ignored after hangup")  # no active call -> dropped
    assert got == ["напиши тесты"]


def test_stub_emits_on_start():
    got = []
    p = StubVoiceProvider(["one", "two"])
    p.start_call(got.append)
    assert got == ["one", "two"]
