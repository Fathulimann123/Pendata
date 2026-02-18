#!/bin/bash
echo "Starting Development Environment..."

# Activate venv
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "[ERROR] Virtual environment (venv) not found. Please run run.sh install first."
    exit 1
fi

# Run the dev server with MODE explicitly set
export MODE=DEVELOPMENT
python3 scripts/dev_server.py
