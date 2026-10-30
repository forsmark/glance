# Design

## Context

The hub from `add-hub-core` validates events and passes them to the store. This change adds one stage between the two. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- Rules that are easy to write by hand and easy to test.
- No effect on the hub when the rules file is absent.

**Non-Goals:**

- Regular expressions, scripting or plugin-provided rules.

## Decisions

### File format

```json
{
  "rules": [
    { "name": "no spotify", "match": { "app": "Spotify" }, "drop": true },
    { "name": "quiet nights",
      "match": { "window": { "from": "22:00", "to": "07:00" } },
      "priority": "low" }
  ]
}
```

Plain JSON, validated with a Zod schema in the hub. `window` takes optional `days` as a list of weekday names. A window where `from` is later than `to` crosses midnight.

Alternatives: YAML is nicer to edit but adds a parser and indentation errors. JSON with a schema gives exact error messages.

### Pure rule engine

The engine is a pure function from rules, event and local time to a result: dropped, or the changed event plus the list of matched rule names. The hub and the test command both call it. Tests do not need a running hub.

### Hub events

The hub registers itself as an internal source with plugin id `hub` and emits kind `system.rules-error` for invalid rule files. The hub retracts that event when a valid file loads.

### File watching

Use `fs.watch` on the config folder, because editors often replace the file instead of writing in place. Debounce reloads by 300 ms.

## Risks / Trade-offs

- [A broad drop rule hides important events] → The test command shows the effect before saving. The hub logs every drop at debug level.
- [Local time and daylight saving] → Windows use the system time zone at the moment of evaluation.
