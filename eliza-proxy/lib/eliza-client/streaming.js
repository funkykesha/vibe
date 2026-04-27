'use strict';

/**
 * Normalize Anthropic or OpenAI SSE streams into a unified async generator.
 *
 * @param {ReadableStream} body  - WHATWG ReadableStream from fetch response
 * @param {'anthropic'|'openai'} format
 * @yields {{ delta: string, done: boolean, usage?: { input: number, output: number }, error?: string }}
 */
async function* normalizeStream(body, format) {
  const reader = body.getReader();
  const decoder = new TextDecoder();
  let buf = '';
  let stopped = false;

  function* parseBuf() {
    const lines = buf.split('\n');
    buf = lines.pop();
    for (const line of lines) {
      const trimmed = line.trim();

      // Skip non-data lines (comments, event: lines, blank lines)
      if (!trimmed.startsWith('data:')) continue;

      const raw = trimmed.slice('data:'.length).trim();

      // Handle OpenAI [DONE] sentinel
      if (raw === '[DONE]') {
        yield { delta: '', done: true };
        stopped = true;
        return;
      }

      let obj;
      try {
        obj = JSON.parse(raw);
      } catch {
        // Silently skip malformed JSON
        continue;
      }

      if (format === 'anthropic') {
        yield* handleAnthropic(obj);
      } else {
        yield* handleOpenAI(obj);
      }
    }
  }

  try {
    while (!stopped) {
      const { value, done } = await reader.read();
      if (done) break;
      buf += decoder.decode(value, { stream: true });
      yield* parseBuf();
    }
    if (!stopped) {
      buf += decoder.decode(); // flush TextDecoder
      yield* parseBuf();
    }
  } finally {
    reader.releaseLock();
  }
}

/**
 * Handle one parsed Anthropic SSE event.
 * @param {object} obj
 */
function* handleAnthropic(obj) {
  const type = obj.type;

  if (type === 'content_block_delta') {
    const text = obj.delta && obj.delta.text;
    if (typeof text === 'string') {
      yield { delta: text, done: false };
    }
  } else if (type === 'message_delta') {
    const usage = obj.usage;
    if (usage) {
      yield {
        delta: '',
        done: false,
        usage: { input: usage.input_tokens ?? 0, output: usage.output_tokens },
      };
    }
  } else if (type === 'message_stop') {
    yield { delta: '', done: true };
  } else if (type === 'error') {
    const message = obj.error && obj.error.message ? obj.error.message : 'Unknown error';
    yield { delta: '', done: true, error: message };
  }
  // All other event types (message_start, content_block_start, ping, etc.) are skipped
}

/**
 * Handle one parsed OpenAI SSE event.
 * A single chunk can have both content delta AND finish_reason.
 * Emit delta first (if non-empty), then usage (if present), then done (if finish_reason).
 * @param {object} obj
 */
function* handleOpenAI(obj) {
  const choices = obj.choices;
  let finishReason = null;
  let contentDelta = null;

  if (Array.isArray(choices) && choices.length > 0) {
    const choice = choices[0];
    finishReason = choice.finish_reason || null;
    const delta = choice.delta;
    if (delta && typeof delta.content === 'string' && delta.content !== '') {
      contentDelta = delta.content;
    }
  }

  // Emit content delta first
  if (contentDelta !== null) {
    yield { delta: contentDelta, done: false };
  }

  // Emit usage chunk before done (Rev 2: top-level usage field)
  if (obj.usage) {
    yield {
      delta: '',
      done: false,
      usage: { input: obj.usage.prompt_tokens, output: obj.usage.completion_tokens },
    };
  }

  // All finish_reason values (stop, length, content_filter) map to done:true — callers cannot distinguish
  if (finishReason !== null) {
    yield { delta: '', done: true };
  }
}

module.exports = { normalizeStream };
