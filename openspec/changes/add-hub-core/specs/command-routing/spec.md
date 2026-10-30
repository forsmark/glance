# Spec Delta

## Purpose

Defines how a command from a view or controller reaches the plugin that handles it, and how the result returns to the sender.

## ADDED Requirements

### Requirement: Route to target
The hub SHALL send a command to the connected client whose id equals the command's `target`, if that client is allowed to handle the command's action.

#### Scenario: Open app
- **WHEN** the dashboard sends a command with target `mac-notify` and action `open-app`
- **THEN** the hub sends a `command` message to `mac-notify`

### Requirement: Hub target
A command with target `hub` SHALL be handled by the hub. Version 0 SHALL support the action `ack`. Other actions SHALL fail with code `not_handled`.

#### Scenario: Unknown hub action
- **WHEN** a client sends a command with target `hub` and action `reboot`
- **THEN** the hub answers with an error result with code `not_handled`

### Requirement: Event-linked commands
When a command has an `eventId` and target is not `hub`, the target SHALL be the plugin that emitted that event. Otherwise the hub SHALL reject the command with code `forbidden`.

#### Scenario: Wrong target for event
- **WHEN** a command names an event from `mac-notify` but has target `linux-notify`
- **THEN** the hub rejects it with code `forbidden`

### Requirement: Unavailable target
When the target is not connected or does not handle the action, the hub SHALL return an error result to the sender with code `target_unavailable` or `not_handled`.

#### Scenario: Mac is asleep
- **WHEN** the dashboard sends a command to `mac-notify` while it is disconnected
- **THEN** the dashboard receives an error result with code `target_unavailable`

### Requirement: Results return to sender
The hub SHALL forward a `command.result` to the client that sent the command. If no result arrives within 30 seconds, the hub SHALL send the sender an error result with code `timeout`.

#### Scenario: Successful result
- **WHEN** `mac-notify` sends `command.result` with `ok: true` for a command from the dashboard
- **THEN** the dashboard receives the result

#### Scenario: No result
- **WHEN** the target does not answer within 30 seconds
- **THEN** the sender receives an error result with code `timeout`

### Requirement: Confirmed flag
The hub SHALL set `confirmed: true` on a command sent by a client with the `view` role and `confirmed: false` on a command sent by a client with only the `controller` role. A plugin SHALL refuse an outbound action, such as sending a message, when `confirmed` is false.

#### Scenario: Voice agent asks to send a reply
- **WHEN** the voice agent sends a `reply` command
- **THEN** the target plugin receives it with `confirmed: false`
