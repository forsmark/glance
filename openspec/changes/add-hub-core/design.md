# Design

## Context

`packages/protocol` from `add-protocol-v0` provides the message schemas. The hub runs on the workstation as the user, not as root. The Mac reaches it over Tailscale. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- A small hub that can run for weeks without a restart.
- All permission checks in one place.
- Fast tests that run the hub in-process against fake clients.

**Non-Goals:**

- Horizontal scale. One hub, a few clients.
- Persistence. A restart loses events. Notifications are short-lived, and plugins re-emit their current state on reconnect.

## Decisions

### Libraries

Use `node:http` for HTTP and the `ws` package for WebSockets on the same port. The HTTP surface is four routes, so a framework is not needed.

Alternatives: Fastify gives routing and schema validation, but the protocol package already validates. Hono is small, but adds a second routing model next to `ws`.

### Module structure

- `registry`: loads `clients.json`, checks tokens, holds registrations.
- `store`: events, dedupe groups, expiry timer, limit. Emits change events. Has no network code.
- `router`: pending commands, timeouts, forwarding.
- `ws-server` and `http-server`: transport only. They parse messages with the protocol package, check roles with `registry`, and call `store` or `router`.
- `cli`: `glance-hub serve`, `glance-hub add-client <manifest>`, `glance-hub revoke <id>`, `glance-hub list`.

The `store` and `router` take a clock argument, so tests can control time for expiry, dedupe windows and timeouts.

### Configuration

- `~/.config/glance/hub.json`: port, default `7710`, and listen addresses. If no addresses are set, the hub listens on `127.0.0.1` and on the address from `tailscale ip -4`.
- `~/.config/glance/clients.json`: registrations with token hashes. Mode `0600`.

Tokens are 32 random bytes in base64url. The hub stores a SHA-256 hash. A slow hash is not needed for random tokens of this length.

### Listening on Tailscale only

The hub binds one server per address, not `0.0.0.0`. If the Tailscale address is missing at start, the hub listens on loopback only, logs a warning, and retries the Tailscale address every 30 seconds. This handles the case where `tailscaled` starts after the hub.

### Dedupe groups

The store keeps a map from `dedupeKey` to a group of contributing events. The first event in a group is the visible one. Subscribers see the group as one event with the visible event's identity. The group is removed when its last member is retracted. A new event with the same key after the 10 minute window starts a new group.

### Service

Ship `glance-hub.service` as a systemd user unit with `Restart=on-failure`. Install it with a script that copies the unit and runs `systemctl --user enable --now`.

## Risks / Trade-offs

- [Events are lost on restart] → Plugins re-emit current state on connect. The Mac collector can do this from the Notification Center database.
- [Tailscale address changes] → Tailscale addresses are stable per device. The retry loop handles a late start.
- [Dedupe merges events that only look the same] → Plugins choose `dedupeKey`. No plugin sets it in version 0, so the logic is tested but not yet used in practice.
- [Commands from `view` are always confirmed] → This assumes every `view` client is a screen a human taps. Register only the dashboard as a `view`.
