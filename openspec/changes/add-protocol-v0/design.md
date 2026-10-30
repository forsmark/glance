# Design

## Context

The repo has no code yet. `PLAN.md` describes the protocol in sections "Plugin model" and "Protocol v0". This change turns that into a package. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- One source of truth for message shapes. TypeScript types come from the runtime schemas, not the other way round.
- Validation that the hub and the TypeScript SDK both use.
- JSON Schema output for clients in other languages.

**Non-Goals:**

- Transport code. The package has no WebSocket or HTTP code.
- A2UI payload schemas.

## Decisions

### Monorepo with npm workspaces

Use npm workspaces with `packages/*` and `plugins/*`. Each package builds with `tsc` to ESM.

Alternatives: pnpm workspaces is faster, but npm needs no extra tool on the Mac. Turborepo or Nx are more than this project needs.

### Zod 4 for schemas

Write the schemas in Zod 4 and infer the TypeScript types from them. Use Zod's JSON Schema conversion to produce the files for other languages.

Alternatives: TypeBox produces JSON Schema directly and is also a good fit. Zod has better error messages and is more familiar. If the JSON Schema output from Zod turns out to be poor, switch to TypeBox before other packages depend on the schema API.

### Discriminated unions on `type`

Client messages and hub messages are two separate discriminated unions on `type`. A validator for each direction prevents a client from sending a hub message type.

### Hub-owned fields are rejected, not stripped

Client schemas use strict objects and do not contain `plugin` or `confirmed`. A client that sends them gets a validation error. Stripping them silently would hide plugin bugs.

### Event identity

A plugin sets the event `id`. The hub identifies an event by the pair of plugin id and event id. Two plugins cannot collide, and a plugin can retract its own events without knowing hub ids.

### Testing

Use Vitest. Keep a folder of valid and invalid example messages as fixtures. The same fixtures test the Zod validators and the exported JSON Schema, which proves they agree.

## Risks / Trade-offs

- [Protocol v0 changes often in early builds] → The version stays 0 until the first three plugins work. Breaking changes inside version 0 are allowed until then.
- [Zod JSON Schema output does not match Zod behavior for some refinements] → The shared fixture tests catch differences. Avoid custom refinements that JSON Schema cannot express.
- [Size limits are guesses] → They live in one constants module and are easy to change.
