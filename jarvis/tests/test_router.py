import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from router import classify, Intent  # noqa: E402


def test_delegate_on_coding_verb():
    assert classify("напиши скрипт для бэкапа").intent is Intent.DELEGATE
    assert classify("запусти codex в проекте api").intent is Intent.DELEGATE
    assert classify("fix the failing test").intent is Intent.DELEGATE


def test_delegate_preserves_prompt():
    a = classify("поправь баг в логине")
    assert a.intent is Intent.DELEGATE
    assert a.prompt == "поправь баг в логине"


def test_hangup():
    assert classify("положи трубку").intent is Intent.HANGUP
    assert classify("пока, джарвис").intent is Intent.HANGUP
    assert classify("hang up").intent is Intent.HANGUP


def test_answer_default():
    assert classify("как дела?").intent is Intent.ANSWER
    assert classify("какая погода завтра").intent is Intent.ANSWER


def test_empty_is_answer_noop():
    assert classify("   ").intent is Intent.ANSWER
