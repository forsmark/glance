# Design

## Context

The hub from `add-hub-core` serves HTTP and WebSocket on one port. The dashboard runs in a normal browser now and in an Electron window later. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- A dashboard that is readable from a normal sitting distance on a 13 to 16 inch display.
- No dependency on Electron, so the same build works in a browser.

**Non-Goals:**

- Offline use. Without the hub there is nothing to show.
- Theming or user settings.

## Decisions

### React with Vite

Use React and Vite. The build output is static files in `packages/dashboard/dist`. The hub serves that folder at `/`.

Alternatives: Preact or Solid are smaller, but bundle size does not matter on a local network. React is the most familiar choice.

### Protocol client in the browser

The dashboard imports the types and parser from `@glance/protocol` and validates hub messages. It keeps the event list in one reducer keyed by plugin and event id. `upsert` and `remove` map directly to reducer actions.

### Token in the URL fragment

The browser never sends the fragment to the server, so the token does not appear in hub logs. The dashboard moves it to `localStorage` and clears the fragment. Electron will later pass the token the same way.

### Plain text rendering

Render title and body as React text nodes only. Never use `dangerouslySetInnerHTML`. A lint rule bans it in this package.

### Visual design

Dark background, because the display sits next to the main monitors and should not draw the eye when idle. Priority uses a colored edge on each card plus a text label, so color is not the only signal. Use one type scale tuned for distance reading. Keep motion to short fades.

### Command results

The dashboard keeps a map from command id to card. When a `command.result` arrives, it shows the state on that card for 3 seconds.

## Risks / Trade-offs

- [Token in `localStorage` can be read by any script on the page] → The page loads no third-party scripts and renders no HTML from events.
- [Many events slow the list] → The hub caps the store at 500 events. Render at most the first 100 cards and show a count for the rest.
