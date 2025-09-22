#!/bin/bash
set -e

# Clone LightRAG
if [ ! -d "lightrag" ]; then
  git clone https://github.com/HKUDS/LightRAG.git lightrag
else
  echo "lightrag directory already exists. Skipping clone."
fi

# Clone MyCrewAI
if [ ! -d "crewai" ]; then
  git clone https://github.com/Coopaguard/MyCrewAI.git crewai
else
  echo "crewai directory already exists. Skipping clone."
fi

echo "Source code for LightRAG and MyCrewAI fetched successfully."
