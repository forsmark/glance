# Spec Delta

## Purpose

Gives plugin authors a TypeScript library that handles the hub connection, reconnection and state replay, so each plugin only maps its source to events.

## ADDED Requirements

### Requirement: Plugin config file
The SDK SHALL load plugin config from `~/.config/glance/<plugin-id>.json`. The file SHALL contain the hub URL, the token and the machine name, plus plugin-specific settings. The SDK SHALL fail with a clear message when the file or a required field is missing.

#### Scenario: Missing token
- **WHEN** a plugin starts and its config file has no token
- **THEN** the plugin exits with a message that names the file and the missing field

### Requirement: Connect and hello
A long-lived client SHALL connect to the hub, send `hello` with its manifest, and report success or the hub's error code to the plugin.

#### Scenario: Rejected hello
- **WHEN** the hub answers `hello` with code `unauthorized`
- **THEN** the SDK reports the error and does not retry until the plugin restarts

### Requirement: Reconnect
After a lost connection, the SDK SHALL reconnect with backoff from 1 to 30 seconds. It SHALL NOT retry after `unauthorized`, `forbidden` or `unsupported_protocol`.

#### Scenario: Hub restarts
- **WHEN** the hub restarts
- **THEN** the plugin reconnects within 30 seconds without plugin code doing anything

### Requirement: State replay
The SDK SHALL remember every event the plugin emitted and did not retract. After each successful `hello`, it SHALL emit them all again.

#### Scenario: Hub lost its events
- **WHEN** the hub restarts while a plugin has 2 live events
- **THEN** the hub has those 2 events again after the plugin reconnects

### Requirement: Offline emits
While disconnected, the SDK SHALL accept emit, update and retract calls and apply them to its remembered state, so the replay after reconnect sends the current state.

#### Scenario: Event retracted while offline
- **WHEN** a plugin emits event `a` and retracts it while the hub is down
- **THEN** the hub does not receive event `a` after reconnect

### Requirement: Command handlers
The SDK SHALL let a plugin register a handler per command action. It SHALL send `command.result` with the handler's result, or with `ok: false` if the handler throws.

#### Scenario: Handler throws
- **WHEN** a command handler throws an error
- **THEN** the SDK sends `command.result` with `ok: false` and the error message

### Requirement: One-shot HTTP client
The SDK SHALL provide functions to emit and retract one event over HTTP, with a timeout set by the caller.

#### Scenario: Hub unreachable
- **WHEN** a one-shot emit cannot reach the hub within the timeout
- **THEN** the function returns a failure result and does not throw
