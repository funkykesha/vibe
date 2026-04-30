## Why

Models are failing to load during probe phase, showing ❌ status during startup. Initial investigation suggested incorrect endpoint routing, but deeper analysis revealed that external models (Claude, Google, DeepSeek) with `namespace: "external"` correctly route to `/raw/openrouter/v1` but require sec-review approval which hasn't been obtained. Only internal communal models (`deepseek-v3-1-terminus`, `deepseek-v3-2`) work correctly.

## Investigation Findings

### Working Models
- `deepseek-v3-1-terminus`: ✅ Routes to `/raw/internal/deepseek-v3-1-terminus/v1/chat/completions`
- `deepseek-v3-2`: ✅ Routes to `/raw/internal/deepseek-v3-2/v1/chat/completions`
- `glm-4-7`: ✅ Routes to `/raw/internal/glm-latest/v1/chat/completions`

### Failing Models (All External)
- `anthropic` models (`claude-*`): Routes to `/raw/anthropic/v1/messages` but returns 404/unauthorized
- `google` models (`gemini-*`): Routes to `/raw/openrouter/v1/chat/completions` but returns 404/unauthorized
- `deepseek` external models (`deepseek-chat`, `deepseek-reasoner`): Routes to `/raw/openrouter/v1/chat/completions` but returns 404/unauthorized

### Root Cause
Documentation referenced `/google/v1` and `/raw/internal/deepseek/v1` endpoints which DO NOT exist in the current Eliza API instance. Current routing logic is CORRECT - external models properly route to OpenRouter, but fail due to missing sec-review approval.

## What Changes

**NO CODE CHANGES REQUIRED** - The routing logic in `lib/eliza-client/routing.js` is already correct for this Eliza API instance.

**Documentation Updates Required:**
- Update `/Users/agaibadulin/Desktop/projects/vibe/eliza-proxy/docs/eliza-api-models-guide.md` to remove incorrect endpoint references
- Add note that external models require sec-review approval

**Action Items:**

## Decision Taken

**Decision:** Document current limitations rather than obtaining sec-review (for now)

**Rationale:**
- Sec-review process is external to this project
- Current token works correctly with internal/communal models
- Documentation now accurately reflects what's available
- Users who need external models can pursue sec-review independently

## Model Availability with Current Token

**Working Models:**
- `deepseek-v3-1-terminus` ✅ - Internal DeepSeek V3.1 Terminus
- `deepseek-v3-2` ✅ - Internal DeepSeek V3.2
- `glm-4-7` ✅ - Internal GLM 4 7B

**Not Available (Require Sec-Review):**
- Claude (claude-*) - External Anthropic models
- Google (gemini-*) - External Google models  
- DeepSeek external (deepseek-chat, deepseek-reasoner) - External DeepSeek
- OpenAI (gpt-*) - External OpenAI models
- Other external providers

**Documentation Updated:**
- `docs/eliza-api-models-guide.md` - Removed incorrect endpoints, added availability notes
- `CLAUDE.md` - Added model availability section

## Capabilities

### New Capabilities
- `understand-model-availability`: Understand the difference between internal (communal) and external models, and why external models fail probe

### Modified Capabilities
- None

## Impact

**Affected Code:**
- None - routing.js is already correct

**Affected APIs:**
- None - API behavior unchanged

**Behavioral Changes:**
- None - the changes would only be to documentation and token permissions

**Lessons Learned:**
1. External vs internal model distinction matters
2. Sec-review is required for external model access
3. Documentation from Arcadia may not match this specific Eliza instance
4. Current routing correctly handles both internal and external models
