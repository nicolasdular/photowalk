# Repository Guidelines

## Project Structure & Module Organization

Domain contexts and schemas live in `lib/photowalk`, while web-facing LiveViews, controllers, and components sit in `lib/photowalk_web`. Place shared UI in `lib/photowalk_web/components` and LiveViews in `lib/photowalk_web/live` so routes join the right `live_session` and inherit `current_scope`. Tailwind and Vite assets stay in `assets` (`css/app.css`, `src`, `public`), database artifacts in `priv`, and release configs in `rel`. Tests mirror this layout under `test`, with helpers and factories in `test/support`.

## Build, Test, and Development Commands

- `mix setup` pulls Hex deps, runs migrations + seeds, and installs JS/CSS via Bun.
- `mix phx.server` (or `iex -S mix phx.server`) runs the dev server with hot reload.
- `mix test` executes the ExUnit suite inside a sandboxed DB.
- `mix ecto.reset` recreates the schema; rely on it when migrations drift.
- `mix assets.build` produces dev bundles; `mix assets.deploy` minifies for production.
- `mix precommit` enforces warnings-as-errors, prunes unused deps, formats, and tests.
- `mix openapi.gen.spec` regenerates the openAPI spec for the frontend

## Coding Style & Naming Conventions

Use `mix format` before committing; keep functions small, prefer pipelines, and reserve `?` suffixes for predicate functions. Stick to snake_case file names (`user_profile_live.ex`), and expose shared HEEx components via `lib/photowalk_web/components`. Fetch external APIs with `Req` only. Tailwind usage should stay utility-first: keep the Phoenix 1.8 import block in `assets/css/app.css` and configure custom rules in plain CSS instead of `@apply`. React modules in `assets/src` follow PascalCase components and camelCase hooks.

## Testing Guidelines

Author unit tests next to the code they exercise (`lib/foo` ↔ `test/foo`). Use `PhotowalkWeb.ConnCase` for HTTP layers, `Photowalk.DataCase` for context logic, and `Photowalk.Factory` helpers for fixtures. Run `mix test.watch` while iterating, and add regression tests for every bug fix or migration. Aim for meaningful coverage of edge cases rather than duplicating UI happy paths.

## Commit & Pull Request Guidelines

Follow the existing concise, imperative commit tone (`Add docs helpers`, `Improve the design`) and keep each message scoped to one logical change. Squash noisy commits before merge. PRs should summarize intent, link issues, list manual/automated tests, and provide screenshots or GIFs for UI adjustments. Call out new env vars, migrations, or background jobs so reviewers can verify locally.

## Security & Configuration Tips

Manage secrets via environment variables or Dokku config (`SECRET_KEY_BASE`, `RESEND_API_KEY`, S3 keys) and document additions in PRs. Keep sensitive logic in `config/runtime.exs`, and never store credentials in Git. Validate uploads and outbound requests server-side and prefer signed S3 URLs via `Waffle`/`ExAws`.
