#!/bin/bash
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
docker exec postgres pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} > data/postgres/backup_$TIMESTAMP.sql
