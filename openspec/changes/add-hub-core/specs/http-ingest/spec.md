# Spec Delta

## Purpose

Lets short-lived clients, such as Claude Code hook scripts, emit and retract events over HTTP without keeping a WebSocket open.

## ADDED Requirements

### Requirement: Bearer authentication
Every HTTP endpoint SHALL require an `Authorization: Bearer <token>` header with a registered token. A missing or unknown token SHALL get status 401.

#### Scenario: No token
- **WHEN** a request to `POST /v0/events` has no `Authorization` header
- **THEN** the hub answers with status 401

### Requirement: Emit over HTTP
`POST /v0/events` SHALL accept one event as the JSON body. The hub SHALL apply the same validation and permission checks as for `event.emit`. On success it SHALL answer with status 202.

#### Scenario: Valid event
- **WHEN** a registered client posts a valid event of an allowed kind
- **THEN** the hub answers with 202 and subscribers receive an `upsert`

#### Scenario: Invalid event
- **WHEN** a client posts an event with no title
- **THEN** the hub answers with 400 and a JSON body with `code` and `message`

#### Scenario: Forbidden kind
- **WHEN** a client posts an event of a kind outside its emit patterns
- **THEN** the hub answers with 403

### Requirement: Retract over HTTP
`DELETE /v0/events/:id` SHALL retract the caller's own event with that id and answer with status 204, also when the event does not exist.

#### Scenario: Retract
- **WHEN** a client deletes its event `a`
- **THEN** the hub answers with 204 and subscribers receive a `remove`

### Requirement: Request size
The hub SHALL reject a request body larger than the protocol message limit with status 413.

#### Scenario: Huge body
- **WHEN** a client posts a 1 MiB body
- **THEN** the hub answers with 413

### Requirement: Health check
`GET /v0/health` SHALL answer with status 200 without authentication, and SHALL return no event data.

#### Scenario: Health
- **WHEN** a client requests `GET /v0/health`
- **THEN** the hub answers with 200
