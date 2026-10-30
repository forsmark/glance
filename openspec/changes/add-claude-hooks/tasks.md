# Tasks

## 1. Plugin SDK

- [ ] 1.1 Create `packages/sdk` depending on `@glance/protocol`, and verify it builds
- [ ] 1.2 Implement config loading from `~/.config/glance/<plugin-id>.json` with clear errors, and verify tests for a valid file, a missing file and a missing field
- [ ] 1.3 Implement the long-lived client with `hello`, backoff reconnect and no retry on fatal codes, and verify tests against an in-process hub
- [ ] 1.4 Implement live event memory, offline emit, update and retract, and replay after `welcome`, and verify a test that restarts the hub and checks its events
- [ ] 1.5 Implement command handlers with automatic `command.result`, and verify tests for a returning and a throwing handler
- [ ] 1.6 Implement the one-shot `postEvent` and `deleteEvent` with timeout, and verify a test against a hub that does not answer
- [ ] 1.7 Write `packages/sdk/README.md` with a minimal plugin example, and verify the example runs against a local hub

## 2. Hook command

- [ ] 2.1 Create `plugins/claude-hooks` with its manifest and a bundled `glance-claude-hook` command, and verify the bundle runs with `node`
- [ ] 2.2 Implement input parsing and the four hook mappings, and verify unit tests with sample input for each hook
- [ ] 2.3 Implement the 3 second limit, exit status 0, no standard output and the error log, and verify a test with the hub stopped
- [ ] 2.4 Check the current Claude Code hooks documentation for field names, and verify the sample inputs in the tests match it

## 3. Installer

- [ ] 3.1 Implement the settings installer with backup and duplicate checks, and verify tests with an empty file, a file with other hooks, and a second run
- [ ] 3.2 Add a Node version check to the installer, and verify it stops with a message when Node is older than 24
- [ ] 3.3 Write `plugins/claude-hooks/README.md` covering registration, config and install on each computer, and verify the steps by following them on the workstation

## 4. Integration check

- [ ] 4.1 Install on the workstation, start a Claude Code session, trigger a permission prompt, answer it, and verify the card appears and then disappears on the dashboard
- [ ] 4.2 Install on the Mac and repeat 4.1 over Tailscale, and verify the card shows the Mac's machine name
