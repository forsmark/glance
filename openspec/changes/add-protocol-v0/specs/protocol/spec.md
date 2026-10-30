# Spec Delta

## Purpose

Defines the versioned JSON message format that every Glance client and the hub use to exchange events, commands and surfaces.

## ADDED Requirements

### Requirement: Message envelope
Every protocol message SHALL be one JSON object with a string `type` field. A message with no `type`, an unknown `type`, or invalid JSON SHALL be invalid.

#### Scenario: Valid message
- **WHEN** a client sends `{"type":"event.emit", ...}` with a valid event
- **THEN** the message passes validation

#### Scenario: Unknown type
- **WHEN** a client sends `{"type":"event.explode"}`
- **THEN** the message fails validation with a reason that names the unknown type

### Requirement: Protocol version
The protocol SHALL have an integer version. This change defines version 0. A `hello` message SHALL state the protocol version the client speaks.

#### Scenario: Supported version
- **WHEN** a client sends `hello` with `protocol: 0`
- **THEN** the message passes validation

#### Scenario: Missing version
- **WHEN** a client sends `hello` without a `protocol` field
- **THEN** the message fails validation

### Requirement: Client message types
The protocol SHALL define these client-to-hub message types: `hello`, `event.emit`, `event.update`, `event.retract`, `command.send`, `command.result`, `surface.update` and `subscribe`.

#### Scenario: Each client type validates
- **WHEN** a valid example of each client message type is validated
- **THEN** each one passes

### Requirement: Hub message types
The protocol SHALL define these hub-to-client message types: `welcome`, `command`, `command.result`, `event`, `surface` and `error`. The hub sends `command.result` to the client that sent the command.

#### Scenario: Error message carries a reason
- **WHEN** the hub sends an `error` message
- **THEN** it has a machine-readable `code` and a human-readable `message`, and it MAY reference the rejected message id

### Requirement: Event model
An event SHALL have `id`, `machine`, `kind`, `title`, `priority` and `time`. It MAY have `body`, `app`, `icon`, `group`, `dedupeKey`, `expiresAt` and `actions`. `priority` SHALL be one of `low`, `normal`, `high` or `urgent`. `time` and `expiresAt` SHALL be ISO 8601 timestamps.

#### Scenario: Minimal event
- **WHEN** an event has only the required fields with valid values
- **THEN** it passes validation

#### Scenario: Bad priority
- **WHEN** an event has `priority: "critical"`
- **THEN** it fails validation

### Requirement: Hub event message
The hub `event` message SHALL carry an `op` of `upsert` or `remove`. An `upsert` SHALL carry the full event, including the hub-owned fields `plugin` and `read`. A `remove` SHALL carry only the plugin id and event id.

#### Scenario: Upsert carries hub fields
- **WHEN** the hub sends an `event` message with `op: "upsert"`
- **THEN** the event in it has `plugin` and `read` fields

#### Scenario: Remove carries identity only
- **WHEN** the hub sends an `event` message with `op: "remove"`
- **THEN** it has `plugin` and `id` and no other event fields

### Requirement: Event plugin field is hub-owned
The `plugin` and `read` fields of an event SHALL be set only by the hub. A client message that contains either field on an event SHALL be invalid.

#### Scenario: Plugin tries to set its id
- **WHEN** a client sends `event.emit` with an event that has `plugin: "other"`
- **THEN** the message fails validation

### Requirement: Event kind format
An event `kind` SHALL be two or more lowercase segments separated by dots. Segments SHALL contain only `a-z`, `0-9` and `-`.

#### Scenario: Valid kind
- **WHEN** an event has `kind: "notification.chat"`
- **THEN** the kind passes validation

#### Scenario: Single segment
- **WHEN** an event has `kind: "notification"`
- **THEN** the kind fails validation

### Requirement: Plain text bodies
Event `title` and `body` SHALL be plain text. Consumers SHALL NOT interpret them as HTML or Markdown.

#### Scenario: HTML in body
- **WHEN** an event body contains `<script>alert(1)</script>`
- **THEN** the event passes validation, and the text is defined as literal characters, not markup

### Requirement: Event actions
An event action SHALL have an `id` and a `label`. It MAY have a `style` of `default`, `primary` or `danger`. An event SHALL have at most 4 actions.

#### Scenario: Too many actions
- **WHEN** an event has 5 actions
- **THEN** it fails validation

### Requirement: Command model
A command SHALL have `id`, `target` and `action`. It MAY have `eventId` and `args`. The `confirmed` field SHALL be set only by the hub, and a client message that contains it SHALL be invalid.

#### Scenario: Client sets confirmed
- **WHEN** a client sends `command.send` with `confirmed: true`
- **THEN** the message fails validation

### Requirement: Plugin manifest
A plugin manifest SHALL have `id`, `version`, `protocol` and `roles`. It MAY have `emits`, `handles`, `surfaces` and `config`. `roles` SHALL contain one or more of `source`, `action`, `surface`, `processor`, `view` and `controller`. `id` SHALL be lowercase kebab-case.

#### Scenario: Valid manifest
- **WHEN** a manifest has `id: "mac-notify"`, `version: "0.1.0"`, `protocol: 0`, `roles: ["source","action"]`
- **THEN** it passes validation

#### Scenario: Unknown role
- **WHEN** a manifest has `roles: ["admin"]`
- **THEN** it fails validation

### Requirement: Emit patterns
Entries in a manifest's `emits` list SHALL be event kinds or kinds with `*` as the last segment. A kind SHALL match a pattern if it is equal to it, or if the pattern ends in `*` and the kind starts with the part before `*`.

#### Scenario: Wildcard match
- **WHEN** the pattern is `notification.*` and the kind is `notification.chat`
- **THEN** the kind matches

#### Scenario: Wildcard does not match a different prefix
- **WHEN** the pattern is `notification.*` and the kind is `mail.new`
- **THEN** the kind does not match

### Requirement: Size limits
The protocol SHALL limit sizes: a message at most 256 KiB, `title` at most 200 characters, `body` at most 4000 characters, and string ids at most 128 characters.

#### Scenario: Body too long
- **WHEN** an event body has 4001 characters
- **THEN** the event fails validation

### Requirement: JSON Schema export
The protocol SHALL be published as JSON Schema files, one per message type plus the manifest, so clients in other languages can validate messages.

#### Scenario: Non-TypeScript client
- **WHEN** a developer validates a message with the exported JSON Schema in another language
- **THEN** the result matches the result of the TypeScript validator for the same message
