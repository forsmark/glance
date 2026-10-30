# Spec Delta

## Purpose

Shows the hub's current events on a touch-friendly screen and lets the user acknowledge events and trigger their actions.

## ADDED Requirements

### Requirement: Connect as a view
The dashboard SHALL connect to the hub as a registered client with the `view` role and SHALL subscribe to all events.

#### Scenario: Start with events in the hub
- **WHEN** the dashboard opens while the hub has 3 events
- **THEN** the dashboard shows 3 cards

### Requirement: Token handling
The dashboard SHALL read its token from the URL fragment on first load and keep it in browser storage. It SHALL NOT send the token in a URL query or path.

#### Scenario: First load
- **WHEN** the user opens `http://127.0.0.1:7710/#token=abc`
- **THEN** the dashboard connects with token `abc` and removes the fragment from the address bar

#### Scenario: No token
- **WHEN** the dashboard has no token
- **THEN** it shows a message that explains how to get one, and does not connect

### Requirement: Event cards
Each card SHALL show the app, title, body, machine and age of the event. The dashboard SHALL render title and body as plain text.

#### Scenario: Markup in body
- **WHEN** an event body contains `<b>hi</b>`
- **THEN** the card shows the literal text `<b>hi</b>`

#### Scenario: Long body
- **WHEN** a body is longer than 4 lines on the card
- **THEN** the card cuts it at 4 lines, and a tap on the card body shows the full text

### Requirement: Ordering
The dashboard SHALL show unread events before read events. Within each part it SHALL order by priority, `urgent` first, then by time, newest first.

#### Scenario: Urgent arrives
- **WHEN** an `urgent` event arrives while 5 `normal` unread events are shown
- **THEN** the urgent event is the first card

### Requirement: Priority styling
The dashboard SHALL style each priority so it is clear at a glance, and SHALL style read events as dimmed.

#### Scenario: Read event
- **WHEN** an event becomes read
- **THEN** its card is dimmed and moves below the unread cards

### Requirement: Group stacking
Events with the same `group` value from the same plugin SHALL show as one stack with the newest event on top and a count.

#### Scenario: Chat thread
- **WHEN** 3 events arrive with the same group
- **THEN** the dashboard shows one stack with a count of 3

### Requirement: Acknowledge by tap
A tap on a card's acknowledge control SHALL send an `ack` command for that event. For a stack, it SHALL acknowledge every event in the stack.

#### Scenario: Tap acknowledge
- **WHEN** the user taps acknowledge on an unread card
- **THEN** the dashboard sends `ack` and the card shows as read after the hub's `upsert`

### Requirement: Event actions
The dashboard SHALL show a button for each event action. A tap SHALL send the command to the event's plugin and SHALL show the result on the card. A `danger` action SHALL need a second tap to confirm.

#### Scenario: Action succeeds
- **WHEN** the user taps an action and the plugin answers `ok: true`
- **THEN** the card shows a short success state

#### Scenario: Action fails
- **WHEN** the hub answers with code `target_unavailable`
- **THEN** the card shows that the target machine is not connected

### Requirement: Connection state
The dashboard SHALL show when it is not connected to the hub. It SHALL reconnect with backoff from 1 to 30 seconds and SHALL reload the event list after it reconnects.

#### Scenario: Hub restarts
- **WHEN** the hub stops and starts again
- **THEN** the dashboard shows a disconnected state, reconnects, and shows the current events

### Requirement: Touch layout
Every control SHALL have a touch target of at least 44 by 44 CSS pixels. The layout SHALL work at 1920 by 1080 and at 1280 by 720 with no horizontal scroll.

#### Scenario: Small display
- **WHEN** the window is 1280 by 720
- **THEN** all cards fit the width and there is no horizontal scroll

### Requirement: Empty state
When there are no events, the dashboard SHALL show a calm empty state with the current time.

#### Scenario: No events
- **WHEN** the hub has no events
- **THEN** the dashboard shows the empty state
