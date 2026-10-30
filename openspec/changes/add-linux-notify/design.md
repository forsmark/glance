# Design

## Context

GNOME Shell owns `org.freedesktop.Notifications` on the session bus. Apps call `Notify`, which returns a notification id. GNOME sends a `NotificationClosed` signal with that id when the notification closes. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- No effect on the desktop's own notifications.
- No native Node modules.

**Non-Goals:**

- Reading notifications that existed before the plugin started. GNOME has no API to list them.

## Decisions

### `busctl monitor` as the source

Spawn:

```sh
busctl --user monitor --json=short \
  --match "interface=org.freedesktop.Notifications,member=Notify" \
  --match "interface=org.freedesktop.Notifications,member=NotificationClosed" \
  --match "type=method_return,sender=org.freedesktop.Notifications"
```

Each output line is one JSON message. This uses the D-Bus monitor interface, which is passive.

Alternatives: the `dbus-next` package needs eavesdrop or monitor support that is awkward from Node. `dbus-monitor` has no JSON output.

During implementation, check that the third match catches the `Notify` replies on GNOME 50. If it does not, match all method returns from the notification server's unique name and filter in code.

### Mapping ids

A `Notify` call does not contain the new notification id. The reply does. The plugin keeps a map from the call's serial to the pending call, and the reply's `reply_cookie` gives the id. A second map goes from notification id to Glance event id.

The Glance event id is `n-<notification id>`. When a call has a non-zero `replaces_id`, the plugin re-emits the event with that id.

### Markup stripping

Remove tags with a small tag scanner, then decode the five XML entities and numeric entities. The notification spec allows only `b`, `i`, `u`, `a` and `img`, so a full HTML parser is not needed.

### Service

Ship `glance-linux-notify.service` as a systemd user unit. It starts after `graphical-session.target`, so the session bus exists.

## Risks / Trade-offs

- [`busctl` output format changes in a systemd update] → Parse defensively and log lines that do not match. Tests use recorded output from this machine.
- [Some apps send many notifications] → Use `ignoreApps` now and rules later.
- [Claude Code or the terminal also send a desktop notification] → This duplicates `claude-hooks` cards. Ignore the terminal app or add a rule.
