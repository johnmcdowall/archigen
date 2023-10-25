#!/bin/bash
set -eou pipefail

REDIS_PORT=6379
export REDIS_URL="redis://127.0.0.1:$REDIS_PORT/"

DATABASE_PORT=5432
export DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:$DATABASE_PORT/"

export LAUNCHY_APPLICATION=arc

# Unmount and remove the temporary directories
cleanup() {
    echo "*** Clean up"
    if [ -f tmp/docker-compose.yml ]; then (cd tmp && docker-compose down); fi
    exit
}

# Always run the cleanup function on script exit (even error!)
trap cleanup INT TERM ERR SIGTERM SIGCHLD

(cd tmp && docker-compose up -d)

(cd tmp/archigentest && foreman start -p 3000 && exit 1)

(cd tmp/archingentest && docker-compose down)