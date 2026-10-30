# Tasks

## 1. Capture

- [ ] 1.1 Record real `busctl monitor --json=short` output for a `notify-send`, a replacement and a close on this machine, and verify the fixture file contains the call, the reply and the signal
- [ ] 1.2 Create `plugins/linux-notify` with its manifest and SDK dependency, and verify it builds
- [ ] 1.3 Implement the line parser and the call-to-reply id mapping, and verify unit tests against the recorded fixtures
- [ ] 1.4 Implement monitor process spawning with restart within 5 seconds, and verify a test that kills the child process

## 2. Mapping

- [ ] 2.1 Implement event creation with urgency mapping and default expiry, and verify unit tests for urgency 0, 1, 2 and missing
- [ ] 2.2 Implement markup stripping and entity decoding, and verify unit tests for each allowed tag and for entities
- [ ] 2.3 Implement replacement and close handling, and verify unit tests from the recorded fixtures
- [ ] 2.4 Implement `ignoreApps`, and verify a unit test with an ignored app

## 3. Service and docs

- [ ] 3.1 Add `glance-linux-notify.service` and an install script, and verify the service runs after login with `systemctl --user status`
- [ ] 3.2 Write `plugins/linux-notify/README.md` covering registration, config and install, and verify the steps by following them

## 4. Integration check

- [ ] 4.1 With the hub and dashboard running, send, replace and dismiss notifications with `notify-send` and GNOME, and verify the card appears, updates and disappears
