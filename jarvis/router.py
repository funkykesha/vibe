"""
Command router — turns a transcript into an Action.

Iteration 1 keeps this deliberately dumb: a heuristic decides whether the
assistant answers itself (ANSWER) or delegates the prompt to a Codex agent
(DELEGATE). The reasoning/tool-use voice layer (Gemini Live, see
ARCHITECTURE.md) will replace these heuristics in a later iteration — this
module is the seam where that decision lives.
"""

import re
from dataclasses import dataclass
from enum import Enum


class Intent(Enum):
    DELEGATE = "delegate"   # hand the prompt to a Codex agent
    ANSWER = "answer"       # assistant handles it conversationally
    HANGUP = "hangup"       # end the call


@dataclass
class Action:
    intent: Intent
    prompt: str = ""        # text to forward to Codex (DELEGATE only)


# Phrases that end the call. The button click also ends it; this is the
# voice equivalent of "положить трубку".
_HANGUP = re.compile(
    r"\b(положи(ть)? трубку|заверши(ть)? (звонок|разговор)|пока,? джарвис|hang ?up|"
    r"end call|stop call)\b",
    re.IGNORECASE,
)

# Imperative verbs that signal a coding task worth delegating to Codex.
_DELEGATE = re.compile(
    r"\b(запусти codex|codex|сделай|напиши|поправь|исправь|почини|"
    r"добав(ь|ить)|реализуй|отрефактори|зарефактори|собери|задеплой|"
    r"проверь код|напиши тесты|"
    r"build|implement|fix|refactor|write (a |the )?(code|test)|run codex|"
    r"create (a |the )?(function|class|file|script))\b",
    re.IGNORECASE,
)


def classify(text: str) -> Action:
    """Map raw transcript text to an Action. Whitespace-only -> ANSWER (no-op)."""
    stripped = text.strip()
    if not stripped:
        return Action(Intent.ANSWER)
    if _HANGUP.search(stripped):
        return Action(Intent.HANGUP)
    if _DELEGATE.search(stripped):
        return Action(Intent.DELEGATE, prompt=stripped)
    return Action(Intent.ANSWER)
