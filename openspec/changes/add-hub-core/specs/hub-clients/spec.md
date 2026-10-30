# Spec Delta

## Purpose

Controls which clients may connect to the hub and what each client may do, based on a registration made by the user.

## ADDED Requirements

### Requirement: Client registration
The user SHALL register each client before it can connect. A registration SHALL contain a client id, roles, allowed emit patterns, allowed commands and a secret token. The registration tool SHALL create the token and show it once.

#### Scenario: Register a plugin from its manifest
- **WHEN** the user registers a client from a manifest file
- **THEN** the hub stores the id, roles, emits and handles from the manifest and prints a new token

#### Scenario: Revoke a client
- **WHEN** the user revokes a client
- **THEN** the hub closes that client's open connections and rejects its token from then on

### Requirement: Token storage
The hub SHALL store only a hash of each token. The registration file SHALL be readable only by the user who runs the hub.

#### Scenario: Registration file permissions
- **WHEN** the registration tool writes the file
- **THEN** the file mode is `0600`

### Requirement: Hello handshake
A WebSocket client SHALL send `hello` as its first message within 5 seconds. The hub SHALL answer with `welcome` if the token is valid and the manifest is allowed, or with `error` and then close the connection.

#### Scenario: Valid hello
- **WHEN** a client sends `hello` with a registered token and a manifest within its registration
- **THEN** the hub sends `welcome`

#### Scenario: Bad token
- **WHEN** a client sends `hello` with an unknown token
- **THEN** the hub sends `error` with code `unauthorized` and closes the connection

#### Scenario: No hello
- **WHEN** a client sends nothing for 5 seconds after connecting
- **THEN** the hub closes the connection

### Requirement: Manifest must fit registration
The manifest in `hello` SHALL have the registered id. Its roles, emit patterns and commands SHALL each be a subset of the registration. Otherwise the hub SHALL reject the `hello` with code `forbidden`.

#### Scenario: Plugin claims an extra role
- **WHEN** a client registered with roles `source` sends a manifest with roles `source` and `controller`
- **THEN** the hub rejects the `hello` with code `forbidden`

### Requirement: Unsupported protocol version
The hub SHALL reject a `hello` whose protocol version it does not support, with code `unsupported_protocol`.

#### Scenario: Future version
- **WHEN** a client sends `hello` with `protocol: 1`
- **THEN** the hub sends `error` with code `unsupported_protocol` and closes the connection

### Requirement: Role permissions
The hub SHALL accept a message only if the client's roles allow it: `event.*` messages need `source`, `command.send` needs `view` or `controller`, `command.result` needs `action`, and `subscribe` needs `view`, `controller` or `processor`.

#### Scenario: Source tries to send a command
- **WHEN** a client with only the `source` role sends `command.send`
- **THEN** the hub sends `error` with code `forbidden` and does not route the command

### Requirement: Invalid messages
The hub SHALL answer an invalid message with an `error` that has code `invalid_message`, and SHALL keep the connection open.

#### Scenario: Malformed event
- **WHEN** a connected source sends `event.emit` with an event that has no title
- **THEN** the hub sends `error` with code `invalid_message` and keeps the connection open

### Requirement: Network exposure
The hub SHALL listen only on the loopback interface and on the Tailscale interface address.

#### Scenario: LAN connection attempt
- **WHEN** a device on the local network connects to the workstation's LAN address on the hub port
- **THEN** the connection is refused

### Requirement: Liveness
The hub SHALL ping each WebSocket client every 30 seconds and SHALL close a connection that does not answer two pings in a row.

#### Scenario: Mac goes to sleep
- **WHEN** the Mac sleeps and its collector stops answering pings
- **THEN** the hub closes the connection within 90 seconds
