## 1. Code Documentation Improvements

- [x] 1.1 Add comment for CLI flag parsing (lines 17-19) - COMPLETED
- [x] 1.2 Add comment explaining purpose of `shouldExitAfterProbe` variable - COMPLETED
- [x] 1.3 Add constants section with `FINAL_DISPLAY_DELAY_MS` constant and comment - COMPLETED
- [x] 1.4 Add comments for probe tracking variables (`totalModels`, `completedProbeCount`) - COMPLETED

## 2. Logic Documentation

- [x] 2.1 Add comment in `onModelUpdate` callback explaining tracking logic - COMPLETED
- [x] 2.2 Add comment explaining the exit condition check - COMPLETED
- [x] 2.3 Add comment explaining the setTimeout delay purpose in exit logic - COMPLETED
- [x] 2.4 Add comment on line with `process.exit(0)` explaining clean exit

## 3. Edge Case Documentation

- [x] 3.1 Add TODO/FIXME comment for race condition with `totalModels` initialization
- [x] 3.2 Consider adding `modelsLoaded` flag to prevent race condition
- [x] 3.3 Document edge case handling for zero models (if implemented)

## 4. Verification

- [x] 4.1 Verify all comments are clear and concise (not overly verbose) - COMPLETED
- [x] 4.2 Verify comments explain "why" rather than restating code - COMPLETED
- [x] 4.3 Run tests to ensure no behavior was introduced - COMPLETED
- [x] 4.4 Verify server still works with and without `--exit-after-probe` flag - COMPLETED
