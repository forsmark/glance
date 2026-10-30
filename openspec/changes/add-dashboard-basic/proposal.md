# Proposal

## Why

The hub holds events, but nothing shows them. A basic dashboard proves the whole path from plugin to screen and is the base for the touch display later.

## What Changes

- Add `packages/dashboard`, a web app that the hub serves at `/`.
- The dashboard connects to the hub as a `view` client and subscribes to all events.
- It shows events as cards, sorted by priority and time, with group stacking.
- Tapping a card acknowledges it. Action buttons send commands and show the result.
- It shows the connection state and reconnects on its own.
- The layout targets a small landscape touch display, but works in a normal browser window.

## Capabilities

### New Capabilities

- `dashboard`: What the dashboard shows and how the user interacts with it.

### Modified Capabilities

None.

## Impact

- New code: `packages/dashboard`.
- Small change in `packages/hub`: serve the built dashboard files at `/`.
- New dependencies: a UI library and a build tool.

## Out of scope

- The Electron window and placement on the touch monitor. That comes after the hardware arrives.
- A2UI surfaces.
- The active machine indicator.
- Settings screens. Configuration stays in files.
