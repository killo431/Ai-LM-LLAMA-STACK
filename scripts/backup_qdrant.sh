#!/bin/bash
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
tar -czf data/qdrant/backup_$TIMESTAMP.tar.gz data/qdrant/
