# Design

## Context

The hub's HTTP endpoints from `add-hub-core` accept one-shot emits and retracts. Claude Code runs hook commands with a JSON object on standard input. The object includes the hook event name, the session id and the working directory. The `Notification` hook also includes a message. Check the current Claude Code hooks documentation for exact field names before implementing. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- An SDK that `linux-notify` and `mac-notify` can use without changes.
- A hook that adds no noticeable delay to Claude Code.

**Non-Goals:**

- Permission decisions from the dashboard.
- Per-project settings.

## Decisions

### SDK shape

```ts
const plugin = await createPlugin(manifest);   // loads config, connects
plugin.emit(event); plugin.update(id, fields); plugin.retract(id);
plugin.onCommand("open-app", async (cmd) => ({ ok: true }));

await postEvent(config, event, { timeoutMs: 2000 });
await deleteEvent(config, id, { timeoutMs: 2000 });
```

The SDK keeps live events in a `Map`. Replay sends them in emit order after each `welcome`.

### Hook mapping

| Claude Code hook | Glance effect |
|---|---|
| `Notification` | Emit `agent.prompt`, priority `high` |
| `Stop` | Emit `agent.done`, priority `normal`, expires in 2 hours |
| `UserPromptSubmit` | Retract the session's event |
| `SessionEnd` | Retract the session's event |

The event `group` is the project folder path, so several sessions in one project stack together.

### One command for all hooks

One command, `glance-claude-hook`, reads the hook event name from its input and picks the mapping. The installer registers it for all four hooks. This keeps one file to update.

### Runtime

The hook is a single bundled JavaScript file run by Node. It uses the SDK's one-shot client with a 2 second timeout. Node start time is about 50 ms, which is acceptable.

Alternative: a shell script with `curl`. It starts faster, but JSON handling in shell is fragile and it cannot share the SDK and protocol validation.

### Registration

Each computer registers its own `claude-hooks` client with the hub, with ids `claude-hooks-workstation` and `claude-hooks-mac`. Separate tokens mean one computer's token can be revoked alone.

### Installer

The installer reads `~/.claude/settings.json`, writes a timestamped backup, adds a hook entry per event if no entry with the `glance-claude-hook` command exists, and writes the file back with the same formatting.

## Risks / Trade-offs

- [Claude Code changes hook names or input fields] → The hook validates its input and logs unknown shapes instead of failing silently. The README links to the hooks docs.
- [Node is missing on the Mac] → The installer checks for Node 24 and stops with a message if it is missing.
- [The same prompt also produces a desktop notification] → `linux-notify` or `mac-notify` may show a second card. Drop it with a rule in `add-event-rules`.
