# Proposal

## Why

With three plugins running, some events will be noise: duplicates from the terminal, chatty apps, or low-value notifications at night. The user needs a way to drop or change events without editing plugin code.

## What Changes

- Add a rules stage in the hub between validation and the event store.
- Rules live in `~/.config/glance/rules.json` and reload when the file changes.
- A rule matches on plugin, kind, app, machine, title text and time of day.
- A rule can drop an event, change its priority, or set its expiry.
- Add `glance-hub rules test` to show which rules match a sample event.

## Capabilities

### New Capabilities

- `event-rules`: How the hub matches events against user rules and changes or drops them.

### Modified Capabilities

None.

## Impact

- Changes `packages/hub` from `add-hub-core`.
- New config file: `~/.config/glance/rules.json`.

## Out of scope

- Rules based on the active machine. That needs the active machine indicator.
- The AI routing agent. It comes later as a `processor` plugin.
- A rules editor in the dashboard.
