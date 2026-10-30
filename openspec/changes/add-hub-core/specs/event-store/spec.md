# Spec Delta

## Purpose

Defines how the hub keeps the current set of events, merges duplicates, expires old events and tells subscribers about every change.

## ADDED Requirements

### Requirement: Event identity
The hub SHALL identify an event by its plugin id and its event id together. The hub SHALL set the event's `plugin` field from the sending client's registered id.

#### Scenario: Two plugins use the same event id
- **WHEN** `linux-notify` and `mac-notify` both emit an event with id `42`
- **THEN** the hub stores two separate events

### Requirement: Emit permission
The hub SHALL accept an emitted event only if its kind matches one of the client's allowed emit patterns. Otherwise the hub SHALL send `error` with code `forbidden`.

#### Scenario: Kind outside manifest
- **WHEN** a client allowed to emit `notification.*` emits kind `agent.prompt`
- **THEN** the hub rejects the event with code `forbidden`

### Requirement: Emit replaces an existing event
When a client emits an event with an id it already used, the hub SHALL replace the stored event and SHALL clear its read state.

#### Scenario: Re-emit
- **WHEN** a plugin emits event `a` twice with different titles
- **THEN** the store has one event `a` with the second title and `read: false`

### Requirement: Update
An `event.update` SHALL change only the given fields of an existing event from the same client. The hub SHALL reject an update for an unknown event with code `not_found`.

#### Scenario: Update unread count
- **WHEN** a plugin updates the title of its event `a`
- **THEN** the stored event has the new title and keeps its other fields

### Requirement: Retract
An `event.retract` SHALL remove the client's own event. Retracting an unknown event SHALL succeed without error.

#### Scenario: Message read at the source
- **WHEN** a plugin retracts its event `a`
- **THEN** the hub removes event `a` and sends `remove` to subscribers

### Requirement: Read state
The hub SHALL mark an event as read when it receives an `ack` command with target `hub` and that event's id. A read event SHALL stay in the store.

#### Scenario: User acknowledges
- **WHEN** the dashboard sends an `ack` for event `a`
- **THEN** event `a` has `read: true` and subscribers get an `upsert`

### Requirement: Dedupe
When an event has a `dedupeKey` equal to that of a stored event from another plugin, received within 10 minutes, the hub SHALL show only one event. The merged event SHALL stay until every contributing plugin has retracted its copy.

#### Scenario: Same message from two plugins
- **WHEN** two plugins emit events with the same `dedupeKey` one minute apart
- **THEN** subscribers see one event

#### Scenario: One copy retracted
- **WHEN** one of the two plugins retracts its copy
- **THEN** subscribers still see the event

### Requirement: Expiry
The hub SHALL remove an event when its `expiresAt` time passes, and SHALL send `remove` to subscribers.

#### Scenario: Expired event
- **WHEN** an event has `expiresAt` 10 seconds in the future
- **THEN** the hub removes it within 2 seconds after that time

### Requirement: Store limit
The hub SHALL keep at most 500 events. When the limit is reached, the hub SHALL remove the oldest read event first, then the oldest unread event.

#### Scenario: Limit reached
- **WHEN** the store has 500 events and a new event arrives
- **THEN** the hub removes the oldest read event and stores the new one

### Requirement: Events outlive connections
The hub SHALL keep a plugin's events when that plugin disconnects.

#### Scenario: Collector restarts
- **WHEN** a collector disconnects and reconnects
- **THEN** its earlier events are still in the store

### Requirement: Subscriptions
A `subscribe` message SHALL carry a filter by kind patterns, machines and plugins. An empty filter SHALL match all events. The hub SHALL first send an `upsert` for every matching stored event, then send every later change that matches.

#### Scenario: Dashboard connects
- **WHEN** the dashboard subscribes with an empty filter while 3 events are stored
- **THEN** it receives 3 `upsert` messages, followed by live changes

#### Scenario: Filtered subscription
- **WHEN** a client subscribes to kind `agent.*`
- **THEN** it does not receive events of kind `notification.chat`
