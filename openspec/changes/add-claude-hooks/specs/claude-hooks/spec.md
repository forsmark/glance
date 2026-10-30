# Spec Delta

## Purpose

Turns Claude Code hook events on either computer into Glance events, so the user sees when a session needs input or has finished.

## ADDED Requirements

### Requirement: One event per session
The plugin SHALL use the Claude Code session id as the event id. Each session SHALL have at most one Glance event at a time.

#### Scenario: Prompt after finish
- **WHEN** a session finishes a turn and later asks for permission
- **THEN** the dashboard shows one card for that session, with the permission state

### Requirement: Needs input
On a Claude Code `Notification` hook, the plugin SHALL emit an event with kind `agent.prompt`, priority `high`, the project folder name in the title and the notification message as the body.

#### Scenario: Permission prompt
- **WHEN** Claude Code in `~/dev/glance` asks for permission to run a command
- **THEN** the dashboard shows a high priority card with title text that contains `glance` and the message from Claude Code

### Requirement: Turn finished
On a Claude Code `Stop` hook, the plugin SHALL emit an event with kind `agent.done`, priority `normal`, and an expiry 2 hours later.

#### Scenario: Turn ends
- **WHEN** Claude Code finishes a turn
- **THEN** the dashboard shows a normal priority card for that session, which expires after 2 hours

### Requirement: Answered
When the user submits a prompt in a session, or the session ends, the plugin SHALL retract that session's event.

#### Scenario: User answers
- **WHEN** the user types a new prompt in a session that has a card
- **THEN** the card disappears from the dashboard

### Requirement: Machine name
Every event SHALL carry the machine name from the plugin config.

#### Scenario: Mac session
- **WHEN** a session on the Mac asks for input
- **THEN** the card shows the Mac's machine name

### Requirement: Never block Claude Code
The hook command SHALL finish within 3 seconds and SHALL always exit with status 0 and print nothing to standard output. On failure it SHALL write the error to a log file.

#### Scenario: Hub is down
- **WHEN** the hub is not running and a hook fires
- **THEN** the hook exits with status 0 within 3 seconds, and Claude Code continues as normal

### Requirement: Safe install
The installer SHALL add the Glance hooks to `~/.claude/settings.json` and SHALL keep all existing settings and hooks. It SHALL write a backup of the file first. Running it twice SHALL NOT add duplicate hooks.

#### Scenario: Existing hooks
- **WHEN** the settings file already has a `Stop` hook from another tool
- **THEN** after install both hooks are present and a backup file exists

#### Scenario: Second install
- **WHEN** the user runs the installer twice
- **THEN** each Glance hook appears once
