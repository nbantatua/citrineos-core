#!/usr/bin/env bash
set -e

# Start Hasura GraphQL Engine on port 8090 (auto-applies /hasura-metadata)
export HASURA_GRAPHQL_SERVER_PORT=8090
export HASURA_GRAPHQL_METADATA_DIR=/hasura-metadata
graphql-engine serve &

# Start Next.js Operator UI on port 3000
cd /app/apps/operator-ui
exec /usr/local/bin/node node_modules/.bin/next start -p 3000 -H 0.0.0.0
