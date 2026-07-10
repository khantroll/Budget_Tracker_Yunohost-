#!/bin/bash

# Node version pinned by upstream (see package.json -> volta.node).
# Recheck this against a fresh `git show <tag>:package.json` on upgrade.
nodejs_version=23

# Fixed Redis logical DB for this app. Since multi_instance=false there's
# no risk of this app colliding with itself, but if you run other apps that
# also hard-code redis db numbers on the same YunoHost box, bump this.
redis_db=3

# Backend/frontend live in this npm workspace monorepo under packages/.
# Workspace names, from root package.json: "packages/backend", "packages/frontend".
backend_workspace="packages/backend"
frontend_workspace="packages/frontend"
