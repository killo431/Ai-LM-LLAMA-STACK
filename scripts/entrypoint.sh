#!/bin/bash
/usr/local/bin/import_models_rocm.sh
exec ollama serve
