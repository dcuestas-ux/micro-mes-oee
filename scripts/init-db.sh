#!/bin/bash
docker exec -i postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < /ddl.sql
docker exec -i postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < /patch.sql
echo "Database initialized."
