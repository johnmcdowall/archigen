#!/bin/bash
set -eou pipefail

REDIS_PORT=6379
export REDIS_URL="redis://127.0.0.1:$REDIS_PORT/"

DATABASE_PORT=5432
export DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:$DATABASE_PORT/"

# Unmount and remove the temporary directories
cleanup() {
    echo "*** Clean up"
    if [ -f tmp/docker-compose.yml ]; then (cd tmp && docker-compose down); fi
    exit
}

# Always run the cleanup function on script exit (even error!)
trap cleanup INT TERM ERR

rm -rf tmp/

mkdir tmp

cat <<EOT >> tmp/docker-compose.yml
version: '3.2'
services:
  redis: 
    image: redis:latest
    ports:
      - '127.0.0.1:$REDIS_PORT:$REDIS_PORT'
  db:
    image: postgres:13.2
    ports:
      - '127.0.0.1:$DATABASE_PORT:$DATABASE_PORT'
    environment:
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_USER=postgres
EOT

(cd tmp && docker-compose down && docker-compose up -d)

(cd tmp && rails new archigentest -a propshaft --js vite -d postgresql -m ../template.rb)

(cd tmp/archigentest && foreman start -p 3000)

cleanup