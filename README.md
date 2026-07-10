# budgettracker_ynh

Unofficial YunoHost package for https://github.com/letehaha/budget-tracker,
adapted from its Docker/Traefik-based self-hosting setup to run natively
(no Docker) under YunoHost's own nginx + PostgreSQL + systemd.

**Architecture decisions made for you:**
- Single domain, path-based (e.g. `domain.tld/budgettracker`), not the
  upstream default of two subdomains.
- PostgreSQL via YunoHost's native `database` resource.
- Redis via system `redis-server` package (dedicated logical DB, see
  `scripts/_common.sh`), not Docker.
- Currency-rate sidecars (frankfurter, currency-rates-api) intentionally
  left out — add them later as separate systemd services if you want them.

## Before you run this

GitHub blocked automated directory/file browsing while I was researching,
so I could not directly inspect `packages/backend/package.json` and
`packages/frontend/package.json`. The package assumes:

1. Root `package.json` defines npm workspaces `packages/backend` and
   `packages/frontend`, and `npm ci` at the repo root installs both.
2. `packages/backend/package.json` has `build`, `start`, and `migrate`
   scripts (the self-hosting doc confirms `migrate` exists; `build`/`start`
   are inferred from a standard TS backend).
3. `packages/frontend/package.json` has a `build` script that shells out to
   `vite build`, so a trailing `-- --base=/budgettracker/` CLI override
   works to fix asset paths for subpath hosting.
4. The backend reads its config from a `.env` file in its working directory
   via `dotenv` (or similar) — needed so both the systemd service and the
   one-off `migrate` command see the same values written to `install_dir/.env`.

**Before installing**, clone the repo locally and check `package.json` at
each of those three levels. If script names differ, adjust
`scripts/install` and `scripts/upgrade` accordingly (search for
`--workspace=$backend_workspace` / `$frontend_workspace`).

## URL wiring (why the values are what they are)

- `AUTH_ORIGIN` = `https://domain.tld` — a browser Origin never includes a
  path, so this is domain-only regardless of where the app is mounted.
- `BETTER_AUTH_URL` = `VITE_APP_API_HTTP` = `https://domain.tld/budgettracker`
  — nginx forwards `/budgettracker/api/*` to the backend's own `/api/*`
  (stripping the YunoHost path prefix), and the backend already prefixes
  its own routes with `/api/v1` internally. So the "public base" the
  frontend/auth library needs is the app's path root, not `.../api`.

If upstream changes how `VITE_APP_API_HTTP` or `BETTER_AUTH_URL` are
consumed internally, re-derive this from `docs/self-hosting.md` in the repo
rather than trusting this note blindly on a future upgrade.

## Known rough edges

- Sources are fetched via a pinned `git clone --branch v0.16.5` in
  `scripts/install`/`upgrade` rather than YunoHost's usual
  `resources.sources` + sha256 tarball flow, since upstream doesn't publish
  standalone release archives. Fine for personal use; would need reworking
  to submit to the official YunoHost app catalog.
- If the frontend's router uses "history" mode with a hardcoded base of
  `/`, deep links under the subpath may not resolve correctly even though
  the initial load will. Vite's `--base` flag only fixes asset URLs, not
  client-side router base — check `packages/frontend` router config if you
  hit this.
- Redis DB index is hardcoded (`redis_db=3` in `_common.sh`); bump it if
  another app on the same box already claims that index.

## Install

```
sudo yunohost app install ./budgettracker_ynh --args domain=yourdomain.tld&path=/budgettracker
```
