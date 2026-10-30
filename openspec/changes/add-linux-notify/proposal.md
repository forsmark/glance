# Proposal

## Why

Desktop notifications on the workstation are invisible while the KVM shows the Mac. The freedesktop notification calls on the session D-Bus contain everything needed to show them in Glance, and a passive monitor can read them without changing the desktop.

## What Changes

- Add `plugins/linux-notify`, a long-lived plugin on the workstation.
- It watches `org.freedesktop.Notifications` calls on the session bus with `busctl monitor`.
- It emits an event per notification, updates it when an app replaces the notification, and retracts it when the notification closes.
- It strips the limited markup that the notification spec allows from bodies.
- A config option ignores selected apps.
- A systemd user unit runs the plugin.

## Capabilities

### New Capabilities

- `linux-notify`: How workstation desktop notifications become Glance events.

### Modified Capabilities

None.

## Impact

- New code: `plugins/linux-notify`.
- Depends on `packages/sdk` from `add-claude-hooks`.
- Requires `busctl`, which is part of systemd on Ubuntu.
- New service: `glance-linux-notify.service` as a systemd user unit.

## Out of scope

- Notification actions, such as reply buttons from other apps.
- Notification images and icons.
- Notifications sent before the plugin started.
