# Spec Delta

## Purpose

Shows notifications delivered on the work Mac in Glance, removes them when they are cleared on the Mac, and lets the dashboard bring the source app to the front.

## ADDED Requirements

### Requirement: New notification
Within 3 seconds of a notification being delivered on the Mac, the plugin SHALL emit an event with the app's display name as `app`, the notification title as `title`, and the subtitle and body joined as `body`.

#### Scenario: Teams message
- **WHEN** a Teams message notification is delivered on the Mac
- **THEN** Glance shows a card with app `Microsoft Teams` within 3 seconds

### Requirement: Kind mapping
The plugin SHALL map app bundle ids to event kinds from a table in its config. The defaults SHALL map Teams to `notification.chat`, Outlook to `notification.mail`, and every other app to `notification.app`.

#### Scenario: Outlook mail
- **WHEN** an Outlook notification is delivered
- **THEN** the event has kind `notification.mail`

#### Scenario: Unknown app
- **WHEN** a notification from an app not in the table is delivered
- **THEN** the event has kind `notification.app`

### Requirement: Cleared notification
When a notification leaves the Notification Center database, the plugin SHALL retract its event within 3 seconds.

#### Scenario: User clears it on the Mac
- **WHEN** the user clears a notification in Notification Center
- **THEN** the card disappears from Glance within 3 seconds

### Requirement: Recent state on start
On start, the plugin SHALL emit events for notifications still in the database that were delivered within a configurable window, default 12 hours.

#### Scenario: Plugin restarts
- **WHEN** the plugin restarts while 2 recent notifications are in Notification Center
- **THEN** Glance shows those 2 cards after the restart

### Requirement: Hidden bodies
For apps listed in the `hideBody` setting, the plugin SHALL NOT include the body in the event. The title and app SHALL still be sent.

#### Scenario: Teams body hidden
- **WHEN** `hideBody` contains the Teams bundle id and a Teams message arrives
- **THEN** the event has the sender in the title and no body

### Requirement: Open app command
The plugin SHALL handle the `open-app` command for its own events by bringing the event's app to the front. It SHALL open only apps it has seen in the database. It SHALL NOT pass command input to a shell.

#### Scenario: Open Teams
- **WHEN** the dashboard sends `open-app` for a Teams event
- **THEN** Teams comes to the front on the Mac and the result is `ok: true`

#### Scenario: Unknown app
- **WHEN** a command asks to open a bundle id that the plugin has not seen
- **THEN** the result is `ok: false` and no app opens

### Requirement: Open action on events
Each event SHALL carry one action with id `open-app` and a label that names the app.

#### Scenario: Card shows open button
- **WHEN** a Teams event is shown on the dashboard
- **THEN** the card has a button labeled to open Teams

### Requirement: Missing access
If the plugin cannot read the database, it SHALL emit one event with kind `notification.app` and priority `high` that tells the user to grant Full Disk Access, and SHALL retry every 30 seconds.

#### Scenario: Full Disk Access not granted
- **WHEN** the plugin runs without Full Disk Access
- **THEN** the dashboard shows a card that says Full Disk Access is missing on the Mac

### Requirement: Schema change
If the database layout does not match what the plugin expects, the plugin SHALL emit one `high` priority event that says so and SHALL stop reading, instead of emitting wrong data.

#### Scenario: macOS update changes the database
- **WHEN** the expected table or column is missing
- **THEN** the dashboard shows a card that says the Mac notification reader needs an update
