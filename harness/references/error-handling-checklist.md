# Error Handling & Hardening Checklist

Shared reference for Refiner, Integrator, and Builder agents.
Read this when checking error handling quality on code changes.

## API Call Protection

- [ ] Every async API call wrapped in try/catch (or equivalent error boundary)
- [ ] Catch blocks handle specific error types, not just generic `catch(e)`
- [ ] Error handling matches the project's existing pattern from `context.md`
- [ ] Failed API calls don't silently return empty data (no swallowed errors)

## User-Facing Error States

- [ ] Error messages are user-friendly (not raw stack traces or "Error: [object Object]")
- [ ] Loading states exist for all async operations (buttons disabled, spinners shown)
- [ ] Empty states handled (what shows when there's no data? Not a blank page.)
- [ ] Network failure gracefully handled (offline, timeout, 5xx → clear user message)

## Data Persistence

- [ ] Data survives page refresh (not just in-memory state)
- [ ] Failed writes show error to user (not silent failure)
- [ ] Optimistic updates have rollback on failure

## Form & Input Handling

- [ ] Required fields enforced before submission
- [ ] Validation errors shown inline (not just console.log)
- [ ] Submit button disabled during pending request (prevent double-submit)
- [ ] Long-running operations show progress indication

## Edge Cases

- [ ] Null/undefined values handled where upstream can return them
- [ ] Array operations check for empty arrays before accessing indices
- [ ] Race conditions handled (concurrent requests, rapid state changes)
- [ ] Component unmount during async operation doesn't cause state updates on unmounted component
