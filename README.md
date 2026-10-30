# Glance

Glance collects notifications and prompts from several computers and shows them on one small touch display on the desk.

The project is in the planning phase. No application code exists yet.

## The problem

A Linux workstation and a work MacBook share two monitors and the keyboard and mouse through a KVM switch. The KVM shows only one computer at a time, so notifications from the other computer go unseen. Examples are a Teams message on the Mac, or a Claude Code session that waits for input.

Glance puts a small touch monitor next to the main monitors. The workstation drives it directly, outside the KVM. It shows important events from both computers at all times.

## How it works

- A **hub** on the workstation receives events, keeps the current set, and sends commands back to their source.
- **Plugins** collect events and send them to the hub. Every source is a plugin, and the hub knows nothing about specific sources.
- The **dashboard** shows the events on the touch display and sends actions, such as acknowledge or open app.
- All parts use one JSON protocol over WebSocket. Short-lived scripts use HTTP.
- The machines connect over Tailscale.

First plugins:

| Plugin | Machine | Source |
|---|---|---|
| `claude-hooks` | Both | Claude Code hooks: a session needs input or has finished |
| `linux-notify` | Workstation | Desktop notifications from the session D-Bus |
| `mac-notify` | Mac | The macOS Notification Center database |

Planned later: email, chat through Beeper, a calendar panel, rich panels in A2UI, KVM switching, and a voice agent.

## Repository layout

| Path | Contents |
|---|---|
| `PLAN.md` | The overall plan: hardware, architecture, plugin model, protocol and build order |
| `openspec/` | [OpenSpec](https://github.com/Fission-AI/OpenSpec) change proposals with specs, designs and tasks |
| `tools/edid-force-test.sh` | A step-by-step test that keeps a monitor "connected" in the Linux kernel when its cable is unplugged |

## The KVM and EDID

When a KVM switches away from a computer, that computer can see its monitors disconnect and move all windows onto the remaining display. That would bury the dashboard.

On Linux, the kernel can keep a connector forced on with a saved EDID. `tools/edid-force-test.sh` tests this. It passed on both HDMI and DisplayPort on the workstation. See "KVM window handling" in `PLAN.md`.

Run the test with a monitor that does not show your terminal:

```sh
./tools/edid-force-test.sh
```

The script needs sudo. It undoes its changes when it exits. To undo by hand:

```sh
./tools/edid-force-test.sh reset DP-2
```

## Build order

The changes in `openspec/changes/` are in this order:

1. `add-protocol-v0`: monorepo setup and the protocol package
2. `add-hub-core`: the hub server
3. `add-dashboard-basic`: the dashboard web app
4. `add-claude-hooks`: the plugin SDK and the Claude Code plugin
5. `add-linux-notify`: workstation notifications
6. `add-mac-notify`: Mac notifications
7. `add-event-rules`: user rules to drop or change events

Show the status of all changes:

```sh
openspec list
```

## Stack

TypeScript on Node 24, in an npm workspaces monorepo.
