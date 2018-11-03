#!/bin/bash

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Create the 'template_hstore' template db
"${psql[@]}" <<- 'EOSQL'
CREATE DATABASE template_hstore;
UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_hstore';
EOSQL

# Load HStore into both template_database and $POSTGRES_DB
for DB in template_hstore "$POSTGRES_DB"; do
	echo "Loading HStore extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS hstore;
EOSQL
done
