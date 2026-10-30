# Spec Delta

## Purpose

Lets the user drop or change incoming events with rules in a config file, without changing plugin code.

## ADDED Requirements

### Requirement: Rules file
The hub SHALL load an ordered list of rules from `~/.config/glance/rules.json`. A missing file SHALL mean no rules.

#### Scenario: No rules file
- **WHEN** the rules file does not exist
- **THEN** the hub stores every valid event unchanged

### Requirement: Match conditions
A rule SHALL match an event when all of its conditions match. Conditions SHALL be: plugin id, kind pattern, app, machine, title text contained case-insensitively, and a time window by weekday and local time. A rule with no conditions SHALL match every event.

#### Scenario: Match on app and kind
- **WHEN** a rule has `app: "Spotify"` and `kind: "notification.*"` and Spotify sends a desktop notification
- **THEN** the rule matches

#### Scenario: Time window
- **WHEN** a rule has a window of 22:00 to 07:00 on all days and an event arrives at 23:30 local time
- **THEN** the rule matches

### Requirement: Rule effects
A rule SHALL have one or more effects: `drop`, `priority` with a new priority value, and `expiresIn` with a duration in seconds.

#### Scenario: Lower priority at night
- **WHEN** a night rule sets `priority: "low"` and a `normal` event arrives at night
- **THEN** the stored event has priority `low`

### Requirement: Evaluation order
The hub SHALL apply every matching rule in file order. A later rule's `priority` or `expiresIn` SHALL replace an earlier one. A matching `drop` SHALL stop evaluation and the event SHALL NOT be stored.

#### Scenario: Drop stops evaluation
- **WHEN** rule 1 drops terminal notifications and rule 2 sets all events to `high`
- **THEN** a terminal notification is not stored

### Requirement: Applies to emits and updates
The hub SHALL apply rules to emitted events and to the result of updates. Rules SHALL NOT change events already in the store when the rules file changes.

#### Scenario: Rules change
- **WHEN** the user adds a drop rule while matching events are already shown
- **THEN** the shown events stay, and new matching events are dropped

### Requirement: Dropped events are silent
A dropped event SHALL NOT cause an error to the sending plugin. A later retract of a dropped event id SHALL succeed.

#### Scenario: Plugin retracts a dropped event
- **WHEN** a plugin retracts an event that a rule dropped
- **THEN** the hub accepts the retract without error

### Requirement: Reload on change
The hub SHALL reload the rules within 2 seconds after the file changes. If the new file is invalid, the hub SHALL keep the previous rules, log the reason, and emit a `high` priority event from the hub that describes the error.

#### Scenario: Invalid edit
- **WHEN** the user saves the rules file with a syntax error
- **THEN** the old rules stay active and the dashboard shows a card that names the error

### Requirement: Rules test command
`glance-hub rules test <event file>` SHALL print which rules match the event and the resulting event or the word `dropped`.

#### Scenario: Dry run
- **WHEN** the user runs the test command with a sample Spotify event
- **THEN** the output lists the matching rule numbers and shows `dropped`
