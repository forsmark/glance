# Tasks

## 1. Package and config

- [ ] 1.1 Create `packages/hub` with dependencies on `@glance/protocol` and `ws`, and verify it builds
- [ ] 1.2 Add config loading for `hub.json` with defaults, and verify tests cover missing file, defaults and overrides
- [ ] 1.3 Add the registry: load and save `clients.json`, hash tokens, check subsets, and verify tests cover valid token, unknown token, file mode `0600` and subset checks

## 2. Event store

- [ ] 2.1 Implement emit, re-emit, update and retract with identity by plugin and event id, and verify unit tests for each `event-store` scenario
- [ ] 2.2 Implement read state through the `ack` path, and verify a test that an acked event stays with `read: true`
- [ ] 2.3 Implement dedupe groups with the 10 minute window, and verify tests for merge, partial retract and window expiry with a fake clock
- [ ] 2.4 Implement expiry and the 500 event limit, and verify tests with a fake clock and a full store
- [ ] 2.5 Implement subscriptions with snapshot then live changes and filter matching, and verify tests for empty and filtered subscriptions

## 3. Command router

- [ ] 3.1 Implement routing to connected targets and the `hub` target with `ack`, and verify tests for each `command-routing` scenario
- [ ] 3.2 Implement event-linked target checks, unavailable target, and the 30 second timeout, and verify tests with a fake clock
- [ ] 3.3 Set the `confirmed` flag by sender role, and verify tests for a `view` sender and a `controller` sender

## 4. Transports

- [ ] 4.1 Implement the WebSocket server with the `hello` handshake, 5 second hello timeout, role checks and invalid message errors, and verify integration tests with fake clients over a real socket
- [ ] 4.2 Implement ping every 30 seconds and close after two missed pings, and verify a test with a client that stops answering
- [ ] 4.3 Implement `POST /v0/events`, `DELETE /v0/events/:id` and `GET /v0/health` with bearer auth and size limits, and verify integration tests for each `http-ingest` scenario
- [ ] 4.4 Implement listening on loopback and the Tailscale address with the retry loop, and verify by hand that `curl` to the LAN address is refused and `curl` to the Tailscale address answers

## 5. CLI and service

- [ ] 5.1 Implement `glance-hub serve`, `add-client`, `revoke` and `list`, and verify `add-client` prints a token once and `revoke` closes an open connection in a test
- [ ] 5.2 Add `glance-hub.service` and an install script, and verify `systemctl --user status glance-hub` shows it running after install
- [ ] 5.3 Write `packages/hub/README.md` covering config, client registration and the service, and verify the documented commands run as written

## 6. Integration check

- [ ] 6.1 Run the hub, register a test source and a test view, emit an event over HTTP, and verify the view receives it with `websocat` or a small script
