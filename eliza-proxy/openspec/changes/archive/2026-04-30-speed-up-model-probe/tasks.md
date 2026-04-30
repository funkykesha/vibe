## 1. Update probe timeout

- [x] 1.1 Change `REQUEST_TIMEOUT_MS` from 4000 to 1000 in `lib/eliza-client/probe.js`
- [x] 1.2 Verify tests still pass: `npm test`

## 2. Verification

- [x] 2.1 Run `npm start` and measure probe completion time
- [x] 2.2 Confirm all models complete within 1-2 minutes (sequential) or 30-40s (if concurrent)
- [x] 2.3 Verify /v1/health and /v1/models endpoints respond correctly
- [x] 2.4 Check that timeout-failed models are marked with status 0 (unavailable)
