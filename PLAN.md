# Glance

Glance collects events from many sources and shows them on one small touch display on the desk. Sources plug in through one plugin interface.

## Goal

The desk has two computers on one KVM switch:

- A personal Linux workstation. Ubuntu 26.04, GNOME 50 on Wayland, AMD RX 9060 XT.
- A work MacBook Pro. M3 Max.

The KVM shows only one computer at a time. Glance shows important events from both computers at all times, on a separate display. First sources:

- Claude Code asks for input or permission on either computer.
- Desktop notifications on the workstation.
- Notifications on the Mac, such as Teams and Outlook.

Later sources and features:

- Personal email.
- Chat networks through Beeper.
- Rich panels from agents, described with A2UI.
- Actions from the touch display and from a voice agent on the workstation.

## Design principles

1. **The hub knows nothing about sources.** Teams, Claude Code and email are all plugins. The hub only moves events, commands and UI.
2. **One protocol for everything.** Every plugin, the dashboard and the voice agent talk to the hub with the same JSON protocol.
3. **Plugins run as separate processes.** A crash in a plugin does not stop the hub. Plugins can use any language, and they can run on any machine on the tailnet.
4. **Plugins send data, not code.** Plugins never send HTML or JavaScript to the dashboard. The dashboard renders events and A2UI with its own components.
5. **Build the protocol with real plugins.** Write protocol v0 now. Build only what the first three plugins need. Add features when a plugin needs them.

## Hardware

| Item | Purpose |
|---|---|
| UGREEN DisplayPort KVM switch, 2 PC, 2 monitors | Shares the two monitors and USB devices between the computers. |
| Portable touch monitor | The Glance display. It must support touch over a plain USB cable. |
| HDMI cable to the touch monitor | Connects the workstation's `HDMI-A-1` port to the touch monitor. |
| Raspberry Pi Pico or ESP32, plus a relay or optocoupler | Switches the KVM. Optional, for a later step. |

The workstation drives the touch monitor directly. The touch monitor's video and USB cables never go through the KVM. Touch input works no matter which computer the KVM shows.

The workstation connects to the KVM with `DP-1` and `DP-2`. Both big monitors need DisplayPort inputs.

## The Linux EDID requirement

When the KVM switches to the Mac, the workstation must not see its big monitors disconnect. If it does, GNOME moves every window onto the touch monitor and buries the dashboard.

The UGREEN KVM does not emulate EDID. The workstation does it in software instead. The kernel keeps `DP-1` and `DP-2` forced "connected" with a saved EDID. See "KVM window handling".

## Architecture

```
                       +-------------------- Workstation --------------------+
                       |                                                     |
  Mac                  |   +---------------- Hub ----------------+           |
  +---------------+    |   |                                     |           |
  | mac-notify    | ---+-> |  ingest -> rules -> store -> fanout | --> Dashboard (touch, HDMI-A-1)
  | claude-hooks  | ---+-> |                                     | <-> Voice agent
  | beeper*       | <--+-- |  command router   surface registry  |           |
  +---------------+    |   +-------------------------------------+           |
                       |      ^          ^          ^         |              |
                       |  linux-notify claude-hooks email*   kvm-switch*     |
                       +-----------------------------------------------------+
                                                      * = later
```

Both machines are on the Tailscale network. The hub listens only on localhost and on the Tailscale interface. The work VPN is split tunnel, so it does not block this.

The dashboard is off while the workstation sleeps. This is accepted.

## Plugin model

### Clients and roles

Everything that connects to the hub is a client. A client declares one or more roles:

| Role | What it does | Examples |
|---|---|---|
| `source` | Emits events. | `linux-notify`, `mac-notify`, `email`, `beeper` |
| `action` | Handles commands for its own events or abilities. | `mac-notify` opens apps, `kvm-switch` switches the KVM |
| `surface` | Publishes A2UI panels. | A calendar panel, the voice agent's transcript |
| `processor` | Reads events before storage and can change, merge or drop them. | Later: the AI routing agent |
| `view` | Receives events and surfaces and sends user commands. | The dashboard |
| `controller` | Sends commands on behalf of the user. | The voice agent |

One plugin can have several roles. For example, `beeper` is a `source` and an `action`, because it can also send replies.

### Manifest

Each plugin has a `glance.plugin.json` file:

```json
{
  "id": "mac-notify",
  "version": "0.1.0",
  "protocol": 0,
  "roles": ["source", "action"],
  "emits": ["notification.*"],
  "handles": ["open-app"],
  "surfaces": [],
  "config": { "pollMs": { "type": "number", "default": 1000 } }
}
```

The hub uses the manifest to check what a plugin is allowed to do. A plugin can emit only the event kinds in `emits`. It receives only the commands in `handles`.

### Running plugins

- **Local plugins** run on the workstation. The hub starts them from the `plugins/` folder, restarts them on crash, and passes their config and token.
- **Remote plugins** run on another machine, such as the Mac. They start through launchd or similar and connect to the hub themselves.
- **One-shot plugins** are short scripts that cannot keep a connection open. Claude Code hooks are the main example. They use the HTTP endpoints instead of the WebSocket.

### Authentication

- Each plugin has its own token. The hub maps the token to the plugin's manifest.
- A token gives only the permissions in that manifest.
- The dashboard and the voice agent have their own tokens with the `view` and `controller` roles.

## Protocol v0

JSON messages over one WebSocket connection per client. Every message has a `type` field. The `packages/protocol` package holds the TypeScript types and runtime schemas, and the hub validates every message against them.

### Messages from client to hub

| Type | Purpose |
|---|---|
| `hello` | Sends the token and manifest. The hub answers with `welcome` or closes the connection. |
| `event.emit` | Adds a new event. |
| `event.update` | Changes an event, for example a new unread count. |
| `event.retract` | Removes an event, for example after you read the Teams message on the Mac. |
| `command.send` | Asks the hub to route a command. Only `view` and `controller` clients. |
| `command.result` | Reports the result of a command this client handled. |
| `surface.update` | Sends A2UI messages for one of this client's surfaces. |
| `subscribe` | Asks for events and surfaces that match a filter. Only `view`, `controller` and `processor` clients. |

### Messages from hub to client

| Type | Purpose |
|---|---|
| `welcome` | Confirms the connection and sends the plugin's config. |
| `command` | A command for this client to handle. |
| `event` | An event that matches this client's subscription. |
| `surface` | A surface update that matches this client's subscription. |
| `error` | A message was rejected, with the reason. |

### HTTP endpoints for one-shot plugins

| Endpoint | Purpose |
|---|---|
| `POST /v0/events` | Emits one event. |
| `DELETE /v0/events/:id` | Retracts one event. |
| `POST /v0/decisions` | Creates an event with actions and waits for the user's choice, up to a timeout. Used for Claude Code permission prompts. |

### Event model

```ts
type GlanceEvent = {
  id: string;            // unique, set by the plugin
  plugin: string;        // set by the hub from the token, never by the plugin
  machine: string;       // "workstation", "mac"
  kind: string;          // namespaced, for example "notification.chat", "agent.prompt", "mail.new"
  title: string;
  body?: string;         // plain text only, never HTML
  app?: string;          // "Microsoft Teams", "Claude Code"
  icon?: string;         // a name from the dashboard's icon set
  priority: "low" | "normal" | "high" | "urgent";
  group?: string;        // events with the same group stack together, for example one chat thread
  dedupeKey?: string;    // events with the same key from different plugins merge into one
  time: string;          // ISO 8601
  expiresAt?: string;    // the hub removes the event after this time
  actions?: { id: string; label: string; style?: "default" | "primary" | "danger" }[];
};

type GlanceCommand = {
  id: string;
  target: string;        // a plugin id, or "hub"
  action: string;        // "ack", "open-app", "approve", "deny", "reply", "switch"
  eventId?: string;
  args?: Record<string, unknown>;
  confirmed?: boolean;   // set by the hub when the user confirmed on the dashboard
};
```

When the user taps an event action, the hub sends the command to the plugin that emitted the event.

`dedupeKey` matters because one message can arrive twice. For example, a Teams message can come from `mac-notify` and later also from a direct Teams plugin.

## Dashboard rendering

The dashboard renders in three tiers:

1. **Event cards.** The dashboard builds a card from the event fields. Every plugin gets this with no UI work.
2. **A2UI surfaces.** Plugins and agents describe rich panels in A2UI, a JSON format for agent-generated UI. Examples are a calendar view, a build status, or the voice agent's transcript. The dashboard renders them with its own fixed component catalog. A2UI sends no code, so plugins cannot run scripts on the dashboard.
3. **Built-in views.** The active machine indicator and similar core views are part of the dashboard.

The A2UI specification is still changing. At the time of writing, v0.9 is the current stable version and v1.0 is a release candidate. Pin one version and keep the A2UI code behind one adapter module.

## Rules

The hub applies rules between ingest and storage. Rules start as a config file:

- Drop events by plugin, kind or app.
- Change priority, for example "Teams messages from my manager are high".
- Quiet hours.
- Dim events from the machine the KVM shows.

Later, the AI routing agent becomes a `processor` plugin. It can apply rules that a config file cannot express.

## Security

- Email and chat content comes from other people. Treat it as untrusted. The dashboard shows `body` as plain text.
- The voice agent and the AI router will read untrusted text, so a message can contain prompt injection. Any outbound action, such as sending a reply or approving a Claude Code tool call, needs a tap on the dashboard. The hub marks such commands with `confirmed`.
- Plugin tokens limit each plugin to its manifest.
- Plugin secrets, such as email passwords or the Beeper token, stay in the plugin's config on the machine where it runs. The hub does not store them.

## Plugins

### First plugins

| Plugin | Machine | How it works |
|---|---|---|
| `claude-hooks` | Both | One-shot. `Notification` and `Stop` hooks post events. Later, a `PermissionRequest` or `PreToolUse` hook uses `POST /v0/decisions`. On timeout the hook returns nothing, and Claude Code falls back to the terminal prompt. Check the current hook docs for the input and output format. |
| `linux-notify` | Workstation | Runs `busctl --user monitor --json=short --match "interface=org.freedesktop.Notifications,member=Notify"` and emits each notification. |
| `mac-notify` | Mac | Polls the Notification Center database under `~/Library/Group Containers/group.com.apple.usernoted/db2/` with `node:sqlite` and `bplist-parser`. Built as a Node single executable application, so Full Disk Access goes to one binary. Retracts events when notifications leave the database. Handles `open-app`. Reports display connect and disconnect for the active machine indicator. |

### Later plugins

| Plugin | Machine | Notes |
|---|---|---|
| `kvm-switch` | Workstation | Talks to a Pi Pico over USB serial. The Pico drives a relay or optocoupler across the KVM desk controller button. |
| `email` | Workstation | IMAP IDLE for personal email. Work Outlook already arrives through `mac-notify`. |
| `beeper` | The machine that runs Beeper Desktop | Beeper Desktop has a local API with token access. Third-party tools report it at `http://localhost:23373` with scoped read and write tokens. Check Beeper's own docs. Handles `reply` with confirmation. |
| `calendar` | Workstation | Shows the next meeting as an A2UI surface. |
| `voice-agent` | Workstation | A `controller` and `surface` client. Sends commands and shows its transcript. |
| `router` | Workstation | The AI routing agent as a `processor`. |

## Active machine

The forced connectors hide display disconnects on the workstation. The Mac still sees its displays connect and disconnect, so the hub uses the Mac signal:

- Mac displays connected: the KVM shows the Mac.
- Mac displays disconnected: the KVM shows the workstation.

## KVM window handling

### Linux: force the connectors on

The kernel keeps a connector "connected" with a saved EDID:

```sh
# Save the real EDID while the monitor is connected
cat /sys/class/drm/card1-DP-2/edid > dp2.edid

# Give the kernel that EDID
sudo sh -c 'cat dp2.edid > /sys/kernel/debug/dri/1/DP-2/edid_override'

# Force the connector to stay connected
echo on | sudo tee /sys/class/drm/card1-DP-2/status

# Undo
echo detect | sudo tee /sys/class/drm/card1-DP-2/status
echo reset | sudo tee /sys/kernel/debug/dri/1/DP-2/edid_override
```

`tools/edid-force-test.sh` runs these steps one at a time and finds the right paths.

For a permanent setup, use the kernel parameters `drm.edid_firmware=DP-1:edid/dp1.bin,DP-2:edid/dp2.bin video=DP-1:e video=DP-2:e`. Put the EDID files in `/lib/firmware/edid/` and include them in the initramfs.

### Mac: restore windows

A Hammerspoon script uses `hs.screen.watcher`. On disconnect it saves the frame of every window. On reconnect it restores them. A delay of one or two seconds is acceptable.

### If the EDID method fails through the KVM

Choose one:

1. A GNOME Shell extension that saves window positions on disconnect and restores them on reconnect. The dashboard is briefly covered on each switch.
2. Inline DisplayPort EDID emulators between the workstation and the KVM.
3. A separate small computer to drive the touch monitor and run the hub.

## Dashboard window

- An Electron window, fullscreen on `HDMI-A-1`.
- Start Electron with `--ozone-platform=x11` so it runs through XWayland and can place itself. If placement is unreliable, write a small GNOME Shell extension that moves the window.
- Keep the GNOME setting "workspaces on primary display only" enabled.
- If touches land on the wrong screen, set the mapping in the `org.gnome.desktop.peripherals.touchscreen` settings.

## Repository layout

TypeScript on Node, as an npm workspaces monorepo:

```
glance/
  packages/
    protocol/     message types and runtime schemas, shared by everything
    sdk/          helpers for plugin authors: connect, emit, retract, onCommand, publishSurface
    hub/          the hub server
    dashboard/    the web UI and the Electron shell
  plugins/
    claude-hooks/
    linux-notify/
    mac-notify/
  tools/
    edid-force-test.sh
```

A plugin in another language implements the protocol directly. The schemas in `packages/protocol` are the reference.

## Build order

1. Run `tools/edid-force-test.sh`. Done 2026-10-30: passed on `HDMI-A-1` and `DP-2`.
2. Write `packages/protocol` with the v0 types and schemas.
3. Build the hub: WebSocket, HTTP endpoints, tokens, manifest checks, in-memory store. No rules yet.
4. Build a basic dashboard that shows event cards in a normal browser window.
5. Write `packages/sdk` and the `claude-hooks` plugin on both computers.
6. Build the `linux-notify` plugin.
7. Test the Mac database reader with Defender running. Then build the `mac-notify` plugin.
8. Add the rules config.
9. Buy the KVM and the touch monitor. Set up the permanent forced connectors and Hammerspoon.
10. Move the dashboard into the Electron window on the touch monitor. Set up touch input.
11. Add the active machine indicator.
12. Add actions: acknowledge, then Claude Code decisions, then `open-app`.
13. Add A2UI surface support when the first plugin needs it.
14. Add later plugins one at a time.

Steps 1 to 8 do not need the KVM or the touch monitor.

## Open questions and risks

- 2026-10-30: the EDID test passed on `HDMI-A-1` and `DP-2`. Windows stayed during unplug, and the picture returned without a retrain on both. Run the test once more through the KVM when it arrives, because a KVM switch may not behave exactly like an unplugged cable.
- Defender may flag a process that reads the Notification Center database. Test this before step 7.
- Apple may change the database path or schema in a future macOS release.
- The A2UI specification is still changing. Pin a version.
- The Beeper local API details come from third-party tools. Check Beeper's documentation before building the plugin.
- The connector type of the KVM desk controller is unknown. Check it when the KVM arrives.
- Company policy on copying Teams message content to a personal device. Forward only the sender and app name if in doubt.
