# Tasks

## 1. Engine

- [ ] 1.1 Add the rules file schema to `packages/hub`, and verify tests for a valid file and for each kind of invalid field
- [ ] 1.2 Implement condition matching for plugin, kind, app, machine, title and time window, and verify unit tests for each condition and for windows across midnight
- [ ] 1.3 Implement effects and evaluation order with `drop` stopping evaluation, and verify unit tests for the evaluation order scenarios

## 2. Hub integration

- [ ] 2.1 Insert the engine between validation and the store for emits and updates, and verify integration tests that a dropped event is not stored and causes no error
- [ ] 2.2 Accept retracts of dropped event ids, and verify an integration test
- [ ] 2.3 Implement file watching with debounce, keep old rules on invalid files, and emit and retract `system.rules-error`, and verify integration tests for a valid edit and an invalid edit

## 3. Test command and docs

- [ ] 3.1 Implement `glance-hub rules test <event file>`, and verify its output for a matching and a non-matching sample event
- [ ] 3.2 Document the rules format with examples in `packages/hub/README.md`, and verify each example passes the schema in a test

## 4. Integration check

- [ ] 4.1 Add a rule that drops terminal notifications on the workstation, trigger a Claude Code prompt, and verify only the `claude-hooks` card appears
