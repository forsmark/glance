# Design

## Context

On recent macOS versions, Notification Center stores delivered notifications in a SQLite database under `~/Library/Group Containers/group.com.apple.usernoted/db2/`. Access needs Full Disk Access. The layout is not documented. Community reverse engineering describes a `record` table with a record id, an app reference, a delivery date and a `data` column with a binary plist that holds title, subtitle and body. Verify this on the actual Mac before writing the reader. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- Correct events or no events. Never emit garbled data after a macOS update.
- One binary that holds Full Disk Access.

**Non-Goals:**

- Support for macOS versions older than the one on the work Mac.

## Decisions

### Read-only polling

Open the database read-only with `node:sqlite` every second and select records newer than the last seen id. Compare the set of ids delivered within the window to find removed records. SQLite in WAL mode allows a reader next to the writer.

Alternatives: file system events on the database files. They fire on every internal write and still need a query, so polling is simpler and the cost is small.

### Plist parsing

Parse the `data` blob with `bplist-parser`. Map known keys to title, subtitle and body. If a required key is missing in a record, skip that record and log it.

### Schema check

At start, check that the expected tables and columns exist. If not, emit the schema change event and stop reading. The check makes macOS updates fail loudly.

### App names

Map bundle ids to display names with `mdfind` and the app's `Info.plist`, and cache the result. Fall back to the bundle id.

### Event ids and dedupe

The event id is `r-<record id>`. No `dedupeKey` in this change.

### Opening apps

Run `open -b <bundle id>` with `execFile`, never through a shell. Check the bundle id against the set seen in the database first.

### Single executable

Bundle the plugin to one JavaScript file and build a Node single executable application. Sign it ad hoc with `codesign --sign -`. Grant Full Disk Access to this binary in System Settings.

### Service

Install a launchd agent in `~/Library/LaunchAgents/` with `KeepAlive` and `RunAtLoad`.

## Risks / Trade-offs

- [Defender flags the reads] → Test with a small script first, before building the plugin. If Defender blocks it, stop and choose another source.
- [macOS changes the database] → The schema check stops the reader and shows a card.
- [Rebuilding the binary changes its ad hoc signature and macOS drops Full Disk Access] → Document that Full Disk Access must be granted again after each rebuild. If this becomes annoying, sign with a stable self-signed certificate.
- [Company policy on message content] → `hideBody` lets the user send only sender and app.
- [Notification Center removes records on its own schedule] → Cards may disappear before the user sees them. The plugin uses database state as truth because it matches what the Mac shows.
