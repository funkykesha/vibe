## 1. Investigation

- [x] 1.1 Analyze model probe failure patterns
- [x] 1.2 Compare current routing against documentation
- [x] 1.3 Test actual endpoints via curl requests
- [x] 1.4 Identify root cause: external models require sec-review

## 2. Findings

- [x] 2.1 Document which models work: internal/communal models (deepseek-v3-1-terminus, deepseek-v3-2, glm-4-7)
- [x] 2.2 Document which models fail: external models (claude-*, gemini-*, deepseek-chat, deepseek-reasoner, deepseek-ai/deepseek-r1)
- [x] 2.3 Confirm routing is correct: external models → OpenRouter, internal models → specific endpoints
- [x] 2.4 Verify no code changes needed

## 3. Documentation Updates

- [x] 3.1 Update docs/eliza-api-models-guide.md to remove incorrect endpoint references (e.g., /google/v1)
- [x] 3.2 Add note in documentation about external models requiring sec-review
- [x] 3.3 Document which models are currently available with current token

## 4. Next Steps

- [x] 4.1 Decide: obtain sec-review for external models OR document current limitations
- [x] 4.2 Update CHANGELOG or README with current model availability
- [x] 4.3 Archive this change as "investigation-only" since no code changes were needed
