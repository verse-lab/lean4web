[![GitHub license](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://github.com/leanprover-community/lean4web/blob/main/LICENSE)
[![(Runtime) Build and Test](https://github.com/leanprover-community/lean4web/actions/workflows/build.yml/badge.svg)](https://github.com/leanprover-community/lean4web/actions/workflows/build.yml)

# Lean 4 Web

This is a web version of Lean 4. There is a playground hosted at [live.lean-lang.org](https://live.lean-lang.org) and one at [lean.math.hhu.de](https://lean.math.hhu.de).

In contrast to the [Lean 3 web editor](https://github.com/leanprover-community/lean-web-editor), in this web editor, the Lean server is
running on a web server, and not in the browser.

## Scope of lean4web

- Provide a clean, minimalistic and easily accessible way to run some (smallish) Lean snippets
- Provide a simple way to run [MWEs](https://leanprover-community.github.io/mwe.html) from [Zulip](https://leanprover.zulipchat.com) with the latest [Mathlib](https://github.com/leanprover-community/mathlib4) installed.
- Provide a easy way to demonstrate some Lean code in talks/lecutres.
- Provide a easy way for newcomers to doodle with Lean before installing it.
- Provide a way to run some Lean code in a mobile context.

Currently, serious Lean code development and larger projects are considered out-of-scope. For these, it might be more suitable to look at a setup using Codespaces or Gitpot.

While `lean4web` looks very similar to VSCode with the [Lean4 extension](https://marketplace.visualstudio.com/items?itemName=leanprover.lean4) installed - and it reuses much of that code - `lean4web` does not claim to be feature complete.

## Running with Docker (Veil-focused setup)

This repository currently ships a Docker/Compose setup that builds and runs the top-level `lean4web` app together with the `Veil` project in `Projects/Veil` (which is a Git submodule).

### Quick start (short form)

```bash
git submodule update --init --recursive
docker compose build
docker compose up
```

### 1. Initialize/update submodules

If this is a fresh clone, run:

```bash
git submodule update --init --recursive
```

If you already initialized submodules before, the shorter form also works:

```bash
git submodule update
```

Why this matters:

- `Projects/Veil` is a submodule (see `.gitmodules`).
- The web UI config currently points at `Veil` examples by default.
- The Docker image build copies `Projects/` into the image and then builds `Projects/Veil` during the Lean build stage.
- If the submodule is missing, the image may still build, but the app will not have the expected Veil sources/examples.

### 2. Build the Docker image(s)

```bash
docker compose build
```

What this does in this repository:

- Builds the `lean4web` service image from the top-level `Dockerfile` (target `production`).
- Pulls (or reuses) `nginx` and `certbot` images for the other Compose services.

The top-level `Dockerfile` is a multi-stage build:

- `base`: installs Ubuntu packages, Bubblewrap, Node.js, and `elan` + Lean toolchains.
- `node-builder`: installs npm dependencies and builds the client (`client/dist`).
- `lean-builder`: copies `Projects/` and runs `lake build` for `Projects/Veil`.
- `production`: assembles the runtime image, copies built assets/artifacts, and starts via `docker-entrypoint.sh`.

Notes:

- The first build can take a while because it compiles Lean dependencies and the Veil project.
- The runtime container starts as a non-root `lean` user.
- The entrypoint checks Bubblewrap availability before starting the Node server.

### 3. Run the container with `docker compose run`

`docker compose run` needs a **service name**. In this Compose file, the app service is `lean4web`.

Minimal one-off run (starts the app container):

```bash
docker compose run --rm lean4web
```

If you want to open the app from your host browser, publish a port explicitly (the service only uses `expose`, not `ports`):

```bash
docker compose run --rm -p 8080:8080 lean4web
```

Then open `http://localhost:8080`.

Important runtime details:

- The Compose file enables `privileged`, `SYS_ADMIN`, and unconfined AppArmor/seccomp for the `lean4web` service so Bubblewrap can create namespaces.
- On startup, `docker-entrypoint.sh` prints Bubblewrap status, available Lean toolchains, and discovered projects, then launches `node server/index.mjs`.
- If Bubblewrap cannot run, the entrypoint exits unless `ALLOW_NO_BUBBLEWRAP=true` is set (not recommended for production).

### Optional: run the full Compose stack (nginx + certbot + app)

If you want the reverse proxy/certbot services too (instead of a one-off app container), use:

```bash
docker compose up
```

This is separate from `docker compose run` and is the better choice for running the whole stack defined in `docker-compose.yml`.

## Contribution

If you experience any problems, or have feature requests, please open an issue here!

PRs fixing issues are very welcome!

For new features, it's best to write an issue first to discuss them: For example, some functionality might be better implemented in [lean4monaco](https://github.com/hhu-adam/lean4monaco) which provides the key features and a discussion might be helpful to figure this out.

## Documentation

- [User Manual](./doc/Usage.md): Specification of `lean4web` features for the end user.
- [Installation](./doc/Installation.md): Instructions to install your own instance of `lean4web` on your own server
- [Development](./doc/Development.md): Instructions to contribute to `lean4web` itself
