# Proposal

## Why

Glance needs one process that every client connects to. The hub receives events from plugins, keeps the current set, sends it to the dashboard, and routes commands back. Without it, no plugin or view can do anything.

## What Changes

- Add `packages/hub`, a Node server for the workstation.
- WebSocket endpoint for long-lived clients, with `hello` authentication.
- Client registry: each client has a token that maps to its allowed id, roles, event kinds and commands.
- In-memory event store with emit, update, retract, read state, dedupe and expiry.
- Subscriptions: views get a snapshot and then live changes.
- Command routing from views and controllers to plugins, with results returned to the sender.
- HTTP endpoints for one-shot clients to emit and retract events.
- A command-line tool to register clients and create tokens.
- A systemd user unit to run the hub.

## Capabilities

### New Capabilities

- `hub-clients`: Client registration, tokens, the `hello` handshake and permission checks.
- `event-store`: How the hub stores, merges, expires and broadcasts events.
- `command-routing`: How commands travel from views and controllers to plugins and how results return.
- `http-ingest`: HTTP endpoints for clients that cannot keep a WebSocket open.

### Modified Capabilities

None.

## Impact

- New code: `packages/hub`.
- Depends on `packages/protocol` from `add-protocol-v0`.
- New dependencies: a WebSocket library and an HTTP server.
- New config: `~/.config/glance/hub.json` and `~/.config/glance/clients.json`.
- New service: `glance-hub.service` as a systemd user unit.

## Out of scope

- Starting and supervising local plugins. Plugins start on their own for now.
- The `POST /v0/decisions` endpoint. It comes with Claude Code permission decisions.
- Rules. They come in `add-event-rules`.
- A2UI surfaces. The hub rejects `surface.update` with a `not_supported` error for now.
- Persistence across restarts.
