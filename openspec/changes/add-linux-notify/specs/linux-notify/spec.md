# Spec Delta

## Purpose

Shows desktop notifications from the Linux workstation in Glance, including replacements and closes, without changing how the desktop shows them.

## ADDED Requirements

### Requirement: Passive capture
The plugin SHALL observe notification calls on the user's session bus without replacing or delaying the desktop's notification server.

#### Scenario: Desktop still shows notifications
- **WHEN** the plugin runs and an app sends a notification
- **THEN** GNOME shows the notification as before, and Glance shows it too

### Requirement: New notification
For each `Notify` call, the plugin SHALL emit an event with kind `notification.desktop`, the app name as `app`, the summary as `title` and the body as `body`.

#### Scenario: Simple notification
- **WHEN** the user runs `notify-send "Build done" "All tests passed"`
- **THEN** Glance shows a card with title `Build done` and body `All tests passed`

### Requirement: Urgency mapping
The plugin SHALL map the notification urgency hint 0 to priority `low`, 1 or missing to `normal`, and 2 to `urgent`.

#### Scenario: Critical notification
- **WHEN** an app sends a notification with urgency 2
- **THEN** the event has priority `urgent`

### Requirement: Plain text body
The plugin SHALL remove notification markup tags from the body and decode XML entities, so the event body is plain text.

#### Scenario: Bold markup
- **WHEN** a notification body is `<b>3</b> new &amp; unread`
- **THEN** the event body is `3 new & unread`

### Requirement: Replacement
When a `Notify` call replaces an existing notification id, the plugin SHALL replace the matching Glance event instead of creating a new one.

#### Scenario: Progress notification
- **WHEN** an app sends a notification and then replaces it twice
- **THEN** Glance shows one card with the latest content

### Requirement: Close
When the notification server reports that a notification closed, the plugin SHALL retract the matching event.

#### Scenario: User dismisses on the desktop
- **WHEN** the user dismisses a notification in GNOME
- **THEN** the card disappears from Glance

### Requirement: Default expiry
Each event SHALL expire after a configurable time, default 12 hours, so notifications that never close do not stay forever.

#### Scenario: Old notification
- **WHEN** a notification was never closed and 12 hours pass
- **THEN** the card is gone

### Requirement: Ignored apps
The plugin SHALL NOT emit events for apps listed in its `ignoreApps` setting.

#### Scenario: Ignored app
- **WHEN** `ignoreApps` contains `Spotify` and Spotify sends a notification
- **THEN** no event is emitted

### Requirement: Monitor recovery
If the bus monitor process exits, the plugin SHALL restart it within 5 seconds and log the exit.

#### Scenario: Monitor crashes
- **WHEN** the monitor process is killed
- **THEN** the plugin starts a new one, and later notifications appear in Glance
