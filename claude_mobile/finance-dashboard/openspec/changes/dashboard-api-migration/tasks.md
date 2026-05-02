## 1. Initial Read And Import

- [ ] 1.1 Load accounts and settings from backend on dashboard startup.
- [ ] 1.2 Detect existing `fin-v3` localStorage data and offer a clear import path if backend is empty.
- [ ] 1.3 Do not invent salary history from non-persisted salary inputs.

## 2. API Writes

- [ ] 2.1 Replace localStorage settings persistence with partial API updates.
- [ ] 2.2 Replace account balance persistence with API updates.
- [ ] 2.3 Prevent stale whole-array writes from overwriting newer backend state.

## 3. States And Races

- [ ] 3.1 Add loading, save-pending, save-failed, and retry states.
- [ ] 3.2 Check `response.ok` and surface API errors.
- [ ] 3.3 Ignore or cancel stale fetch responses.

## 4. Verification

Entry criteria:
- `backend-foundation` exposes accounts/settings APIs and static dashboard serving.
- Current `fin-v3` localStorage shape is still readable for optional import.

Exit criteria:
- Dashboard uses backend APIs as source of truth.
- Current salary and capital calculations remain behaviorally unchanged.

- [ ] 4.1 Verify salary calculations match the localStorage version.
- [ ] 4.2 Verify capital totals match the localStorage version.
- [ ] 4.3 Verify failed API writes do not display as successfully saved.
- [ ] 4.4 Run `openspec status --change "dashboard-api-migration"`.
