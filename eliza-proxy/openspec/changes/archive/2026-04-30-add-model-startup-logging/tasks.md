## 1. Create Formatting Module

- [x] 1.1 Create `lib/format-startup.js` with ANSI color constants
- [x] 1.2 Implement `groupByProvider(models)` function to group models by provider
- [x] 1.3 Implement `getModelStatus(model)` to return colored ✅/❌/⏳ symbol
- [x] 1.4 Implement `formatProgressBar(completed, total)` to return bar string (20 chars)
- [x] 1.5 Implement `formatGroupLine(provider, models)` to format models inline with wrapping
- [x] 1.6 Implement `formatGroup(provider, models)` to return complete group output
- [x] 1.7 Export all functions and ANSI constants
- [ ] 1.8 Test formatting functions with various model counts and terminal widths

## 2. Modify ElizaClient Initialization

- [x] 2.1 Update `createElizaClient()` in `lib/eliza-client/index.js` to accept `onModelProbed` callback parameter
- [x] 2.2 Modify `startProbeIfNeeded()` to invoke `onModelProbed(provider, model, status)` when each model completes
- [x] 2.3 Ensure callback is called with:
  - provider name (string)
  - model object with `id`, `provider`, `probe` status
  - timing: after each individual model probe completes
- [x] 2.4 Make callback optional (handle gracefully if not provided)
- [x] 2.5 Verify probe logic is unchanged, callback is non-blocking

## 3. Integrate Startup Logging in Server

- [x] 3.1 Modify `server.js` to track model state during startup
- [x] 3.2 Add state object to track `rawModels`, `completedByProvider` (models that have finished probing)
- [x] 3.3 Call `eliza.getModels()` with `onModelProbed` callback when server starts
- [x] 3.4 In callback, update state and format output:
  - Get provider name from model
  - Add model to `completedByProvider[provider]`
  - Get all raw models for that provider
  - Call `formatGroup(provider, models)` 
  - Write formatted output to stdout
- [x] 3.5 Ensure groups are displayed only once (not redisplayed for every model update in same group)
- [x] 3.6 Verify output appears after startup but before "listening on port" message

## 4. Handle Edge Cases

- [x] 4.1 Handle empty model list (no models available)
- [x] 4.2 Handle probe failures gracefully (show ❌ status, not errors)
- [x] 4.3 Handle provider with 0 models (skip from output)
- [x] 4.4 Handle long model names that exceed line width (verify wrapping works)
- [x] 4.5 Handle mixed in-progress and completed models in same group (show ⏳ + ✅/❌)
- [x] 4.6 Handle terminal without ANSI support (verify output still readable)

## 5. Testing & Validation

- [x] 5.1 Run `npm start` and verify output appears as models complete
- [x] 5.2 Verify groups appear in order of completion, not alphabetical
- [x] 5.3 Verify models within group are sorted alphabetically
- [x] 5.4 Verify progress bar updates correctly (X/Y increments)
- [x] 5.5 Verify color codes work (green ✅, red ❌)
- [x] 5.6 Verify wrapping: test with wide terminal (160 chars) and narrow (80 chars)
- [x] 5.7 Verify no screen flicker or excessive redrawing
- [x] 5.8 Verify `/v1/models` and `/v1/health` endpoints still work (no regression)
- [x] 5.9 Verify no performance impact: probe still completes in ~3-5 sec
- [x] 5.10 Run `npm test` to ensure no test breakage

## 6. Cleanup & Documentation

- [x] 6.1 Remove old `lib/format-startup.js` file if it still exists from earlier attempt
- [x] 6.2 Update `README.md` (optional) with example of startup output
- [x] 6.3 Ensure no console.error or debug logs left behind
- [x] 6.4 Verify code follows project style (no linting issues)
- [x] 6.5 Create commit with message describing feature
