#!/bin/bash

# Directory containing docs
DOCS_DIR="./docs"

# URL of LightRAG service
LAGRAG_URL="http://localhost:9621"

# Loop through files
for file in "$DOCS_DIR"/*; do
  if [[ -f "$file" ]]; then
    filename=$(basename "$file")
    echo "Uploading file: $filename"

    # Upload using multipart form
    curl -s -X POST "$LAGRAG_URL/documents/file" \
      -F "file=@$file" \
      -F "description=$filename"

    echo ""  # newline
  fi
done
