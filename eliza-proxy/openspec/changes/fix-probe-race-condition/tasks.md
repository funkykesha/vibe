## 1. Variable Initialization

- [x] 1.1 Initialize `totalModels = 0` explicitly (line ~30)
- [x] 1.2 Initialize `completedProbeCount = 0` (line ~31)
- [x] 1.3 Add `modelsLoaded = false` flag (line ~32 after other variables)

## 2. Exit Logic Guard

- [x] 2.1 Update `onModelUpdate` callback exit condition to check `modelsLoaded` flag
- [x] 2.2 Ensure both `modelsLoaded` and `completedProbeCount === totalModels` are checked with AND logic
- [x] 2.3 Verify condition is `if (shouldExitAfterProbe && modelsLoaded && completedProbeCount === totalModels)` (line ~68)

## 3. Set Flag After Model Fetch

- [x] 3.1 Locate the async callback where `totalModels` is set (line ~204)
- [x] 3.2 Set `modelsLoaded = true` immediately after `totalModels = calculatedTotalCount`
- [x] 3.3 Ensure flag is set in all code paths where totalModels is assigned

## 4. Verification

- [x] 4.1 Run existing tests to ensure normal exit behavior still works
- [ ] 4.2 Add test case for race condition: fast probe completes before totalModels is set
- [ ] 4.3 Test zero models scenario: verify server exits when no models available
- [ ] 4.4 Verify backward compatibility: `--exit-after-probe` flag behavior unchanged
