# StartWatch IPC Protocol (PR1-6)

## Scope

Current active protocol is short-lived request/response JSON over Unix socket.

Socket path:

`~/.local/state/startwatch/sock`

## Connection Lifecycle

1. Client connects to socket.
2. Client writes exactly one JSON request.
3. Client calls write-half shutdown (`SHUT_WR`).
4. Server decodes request and writes one JSON response.
5. Both sides close connection.

## Requests

`IPCRequest` supports:

- `triggerCheck`
- `getStatus`
- `startService(name)`
- `stopService(name)`
- `restartService(name)`
- `quit`

## Responses

`IPCResponse` supports:

- `ok`
- `error(message)`
- `statusSnapshot([CodableCheckResult])`
- `executeInTerminal({ serviceName, command })`

## Semantics

- `triggerCheck` schedules async check and returns `ok`.
- `getStatus` returns daemon in-memory snapshot.
- lifecycle commands return one of:
  - `ok`
  - `executeInTerminal(...)` for non-background service actions
  - `error(...)`
- `quit` requests daemon shutdown.

## Timeouts

Client timeout behavior:

- connect timeout: 3s
- response timeout: 5s

Failures distinguish:

- daemon offline (connect failure/timeout)
- daemon unresponsive (connect ok, no response in time)

## Deferred Stage III Work

Out of PR1-6 scope:

- persistent `subscribe`
- push `serviceChanged` stream
- active length-prefix framing for control path

These may be introduced in a later stage without changing PR1-6 behavior.
