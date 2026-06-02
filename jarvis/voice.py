"""
Voice layer abstraction.

The assistant doesn't own the microphone in iteration 1. Voice input is
provided by **Handy** (https://github.com/cjpais/Handy), a local
push-to-talk speech-to-text app the user installs separately on the Mac.
Handy dictates recognised text straight into the focused field — so the
overlay's text field IS the integration point.

`VoiceProvider` is the seam that later iterations swap for a real
conversational/streaming backend (e.g. Gemini Live, see ARCHITECTURE.md).
Iteration 1 ships two providers:

  - HandyVoiceProvider: passthrough. Transcript text arrives from the overlay
    text field (filled by Handy dictation). No audio handling here.
  - StubVoiceProvider: returns canned transcripts, for offline testing of the
    router/launcher pipeline without AppKit or a microphone.
"""

from abc import ABC, abstractmethod
from typing import Callable, List


class VoiceProvider(ABC):
    """A call-oriented voice source. `submit` feeds one transcript turn."""

    @abstractmethod
    def start_call(self, on_transcript: Callable[[str], None]) -> None:
        ...

    @abstractmethod
    def end_call(self) -> None:
        ...


class HandyVoiceProvider(VoiceProvider):
    """
    Passthrough provider. The overlay captures dictated text (from Handy) and
    calls `submit(text)`; we forward it to the active call's callback.
    """

    def __init__(self) -> None:
        self._on_transcript: Callable[[str], None] | None = None

    def start_call(self, on_transcript: Callable[[str], None]) -> None:
        self._on_transcript = on_transcript

    def submit(self, text: str) -> None:
        if self._on_transcript is not None:
            self._on_transcript(text)

    def end_call(self) -> None:
        self._on_transcript = None


class StubVoiceProvider(VoiceProvider):
    """Emits a fixed list of transcripts on call start. Test/dev only."""

    def __init__(self, transcripts: List[str]) -> None:
        self._transcripts = transcripts

    def start_call(self, on_transcript: Callable[[str], None]) -> None:
        for t in self._transcripts:
            on_transcript(t)

    def end_call(self) -> None:
        pass


def make_provider(name: str) -> VoiceProvider:
    if name == "handy":
        return HandyVoiceProvider()
    if name == "stub":
        return StubVoiceProvider([])
    raise ValueError(f"unknown voice provider: {name!r}")
