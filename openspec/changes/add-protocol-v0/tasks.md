# Tasks

## 1. Monorepo setup

- [ ] 1.1 Create the root `package.json` with npm workspaces for `packages/*` and `plugins/*`, and verify `npm install` succeeds
- [ ] 1.2 Add a shared `tsconfig.base.json` for Node 24 ESM, and verify an empty package builds with `tsc`
- [ ] 1.3 Add Vitest, ESLint and Prettier at the root, and verify `npm test` and `npm run lint` run with no packages failing
- [ ] 1.4 Add `.gitignore` and `.editorconfig`, and verify `git status` does not list `node_modules` or build output

## 2. Protocol package

- [ ] 2.1 Create `packages/protocol` with Zod 4 as a dependency, and verify it builds
- [ ] 2.2 Add the limits constants module, and verify the values match the spec
- [ ] 2.3 Add the event, action and command schemas, and verify fixture tests cover required fields, priority values, kind format, action count and hub-owned fields
- [ ] 2.4 Add the manifest schema and the emit pattern matcher, and verify tests cover valid manifests, unknown roles and wildcard matching
- [ ] 2.5 Add the client and hub message unions, and verify every message type in the spec has a valid and an invalid fixture
- [ ] 2.6 Export inferred TypeScript types and `parseClientMessage` and `parseHubMessage` functions, and verify an error result contains a code and a reason

## 3. JSON Schema export

- [ ] 3.1 Add a build step that writes one JSON Schema file per message type plus the manifest to `packages/protocol/schema/`, and verify the files exist after `npm run build`
- [ ] 3.2 Run the fixture folder against the exported JSON Schema with a JSON Schema validator, and verify the results match the Zod results for every fixture
- [ ] 3.3 Write `packages/protocol/README.md` with the message list and an example of each, and verify the examples pass validation in a test
