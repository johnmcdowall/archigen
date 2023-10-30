#!/bin/bash
set -eou pipefail

REDIS_PORT=6379
export REDIS_URL="redis://127.0.0.1:$REDIS_PORT/"

DATABASE_PORT=5432
export DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:$DATABASE_PORT/"

(cd tmp/archigentest && bin/rails c)
