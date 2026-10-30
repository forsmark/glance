# Tasks

## 1. Feasibility on the Mac

- [ ] 1.1 Write a small script that reads the Notification Center database with Defender running, and verify it lists recent notifications without a Defender alert
- [ ] 1.2 Dump the table layout and three sample plists, remove personal content, save them as fixtures, and verify the fixtures match the assumptions in design.md or update design.md

## 2. Reader

- [ ] 2.1 Create `plugins/mac-notify` with its manifest and SDK dependency, and verify it builds
- [ ] 2.2 Implement the schema check, and verify tests with a fixture database and with a database missing a column
- [ ] 2.3 Implement polling for new and removed records, and verify tests that add and delete rows in a fixture database
- [ ] 2.4 Implement plist parsing to title, subtitle and body, and verify tests against the saved fixtures
- [ ] 2.5 Implement the missing access event and 30 second retry, and verify a test where the database file cannot be opened

## 3. Mapping

- [ ] 3.1 Implement the kind table with defaults and config overrides, and verify tests for Teams, Outlook and an unknown app
- [ ] 3.2 Implement app name lookup with cache and fallback, and verify a test with a known and an unknown bundle id
- [ ] 3.3 Implement `hideBody` and the start window, and verify tests for each
- [ ] 3.4 Implement the `open-app` action and command handler with the seen-apps check and `execFile`, and verify tests for a seen and an unseen bundle id

## 4. Packaging

- [ ] 4.1 Build the single executable and sign it ad hoc, and verify the binary runs on the Mac without Node on the path
- [ ] 4.2 Add the launchd agent and an install script, and verify the agent runs after login with `launchctl list`
- [ ] 4.3 Write `plugins/mac-notify/README.md` covering registration, config, Full Disk Access, rebuilds and install, and verify the steps by following them on the Mac

## 5. Integration check

- [ ] 5.1 With the hub and dashboard running on the workstation, send a Teams test message to yourself, clear it on the Mac, and verify the card appears and disappears
- [ ] 5.2 Tap the open button on a Teams card, and verify Teams comes to the front on the Mac
