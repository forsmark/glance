# Proposal

## Why

Claude Code sessions on both computers stop and wait for input, and it is easy to miss this when the KVM shows the other computer. Claude Code hooks give exact signals for this, so it is the first and most useful plugin. Building it also creates the plugin SDK that later plugins share.

## What Changes

- Add `packages/sdk`, a TypeScript library for plugin authors.
- The SDK covers long-lived clients and one-shot HTTP clients, plus a shared config file format.
- Add `plugins/claude-hooks`, a hook command for Claude Code on both computers.
- The hook command shows a card when a session needs input and when it finishes a turn, and removes the card when the user answers.
- Add an installer that adds the hooks to `~/.claude/settings.json` without removing existing hooks.

## Capabilities

### New Capabilities

- `plugin-sdk`: What the SDK guarantees to plugin authors: connection, reconnection, state replay, commands and config.
- `claude-hooks`: Which Claude Code events produce which Glance events, and how the hook behaves on failure.

### Modified Capabilities

None.

## Impact

- New code: `packages/sdk` and `plugins/claude-hooks`.
- Changes `~/.claude/settings.json` on both computers through the installer.
- Requires Node 24 on the Mac to run the hook command.

## Out of scope

- Approving or denying Claude Code permission prompts from the dashboard. That needs the `POST /v0/decisions` endpoint and comes in a later change.
- Showing Claude Code output or transcripts.
