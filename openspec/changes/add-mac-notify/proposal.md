# Proposal

## Why

Teams and Outlook notifications on the work Mac are the main reason for Glance. macOS has no public API to read other apps' notifications. The Notification Center database holds delivered notifications and can be read with Full Disk Access, which the user can grant on this Mac.

## What Changes

- Add `plugins/mac-notify`, a long-lived plugin on the Mac.
- It polls the Notification Center database and emits an event per delivered notification.
- It retracts the event when the notification leaves the database, for example when the user clears it.
- It maps known apps to event kinds, such as Teams to `notification.chat`.
- It handles the `open-app` command to bring an app to the front.
- A setting hides message bodies for selected apps.
- It ships as a single executable, so Full Disk Access applies to one binary.
- A launchd user agent runs it.

## Capabilities

### New Capabilities

- `mac-notify`: How Mac notifications become Glance events and how the `open-app` command behaves.

### Modified Capabilities

None.

## Impact

- New code: `plugins/mac-notify`.
- Depends on `packages/sdk` from `add-claude-hooks`.
- Needs Full Disk Access for the plugin binary on the work Mac.
- Microsoft Defender runs on the Mac and may flag the database reads.

## Out of scope

- Reading notifications through the Accessibility API.
- Microsoft Graph or any other cloud API.
- Display connect events for the active machine indicator. That comes with the indicator.
- Notification actions from other apps, such as Teams reply buttons.
