# Proposal

## Why

Every Glance component talks to the hub: plugins, the dashboard and later the voice agent. They need one shared, versioned message format before any of them can be built. A shared package with types and runtime schemas lets the hub reject bad messages and lets plugins in other languages check their output.

## What Changes

- Set up the npm workspaces monorepo with `packages/` and `plugins/` folders, TypeScript config, lint and test tooling.
- Add `packages/protocol` with the protocol v0 message types and runtime schemas.
- Define the event model, the command model and the plugin manifest.
- Export the schemas as JSON Schema files, so plugins in other languages can use them.

## Capabilities

### New Capabilities

- `protocol`: The Glance wire protocol. Message envelope, client and hub message types, the event and command models, the plugin manifest, limits and versioning.

### Modified Capabilities

None.

## Impact

- New code: repo root config and `packages/protocol`.
- New dependencies: TypeScript, a schema library, a test runner.
- Every later change depends on this package.

## Out of scope

- The hub server, the dashboard and all plugins. Later changes build them.
- A2UI surface payloads. The protocol reserves the `surface.update` and `surface` message types, but the payload schema comes in a later change.
- Persistence formats.
