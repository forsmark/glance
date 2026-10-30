# Tasks

## 1. Setup

- [ ] 1.1 Create `packages/dashboard` with React, Vite and `@glance/protocol`, and verify `npm run build` writes `dist/`
- [ ] 1.2 Add a lint rule that bans `dangerouslySetInnerHTML` in the package, and verify lint fails on a test file that uses it
- [ ] 1.3 Make the hub serve `packages/dashboard/dist` at `/`, and verify `curl http://127.0.0.1:7710/` returns the page

## 2. Connection

- [ ] 2.1 Implement token reading from the fragment, storage and the no-token message, and verify tests for first load, stored token and no token
- [ ] 2.2 Implement the WebSocket client with `hello`, `subscribe`, message validation and backoff reconnect, and verify a test against an in-process hub that restarts
- [ ] 2.3 Implement the event reducer for `upsert` and `remove`, and verify unit tests for add, replace, remove and reload after reconnect

## 3. Cards and layout

- [ ] 3.1 Implement event cards with plain text rendering and 4 line cut, and verify a component test with markup in the body
- [ ] 3.2 Implement ordering, priority styling and read dimming, and verify a test of the sort order for mixed priorities and read states
- [ ] 3.3 Implement group stacks with counts, and verify a test with 3 events in one group
- [ ] 3.4 Implement the empty state and the connection indicator, and verify both by stopping the hub with the dashboard open
- [ ] 3.5 Check the layout at 1920 by 1080 and 1280 by 720, and verify no horizontal scroll and 44 pixel touch targets in browser dev tools

## 4. Interaction

- [ ] 4.1 Implement acknowledge for cards and stacks, and verify a test that the right `ack` commands are sent
- [ ] 4.2 Implement action buttons with result display and the second tap for `danger` actions, and verify tests for success, failure and confirm
- [ ] 4.3 Write `packages/dashboard/README.md` with how to register the dashboard and open it, and verify the steps work as written

## 5. Integration check

- [ ] 5.1 Run the hub and dashboard, post test events of each priority with `curl`, and verify the cards, order, ack and stacking by hand
