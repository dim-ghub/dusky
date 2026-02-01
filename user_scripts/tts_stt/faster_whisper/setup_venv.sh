#!/bin/bash
set -euo pipefail

# Configuration
readonly VENV_DIR="${HOME}/contained_apps/uv/fasterwhisper_cpu"
readonly VENV_PYTHON="${VENV_DIR}/bin/python3"

echo "Creating virtual environment at: ${VENV_DIR}"

# Create directory if it doesn't exist
mkdir -p "$(dirname "$VENV_DIR")"

# Create virtual environment
if [[ ! -d "$VENV_DIR" ]]; then
	echo "Creating new virtual environment..."
	python3 -m venv "$VENV_DIR"
else
	echo "Virtual environment already exists at ${VENV_DIR}"
fi

# Activate and install dependencies
echo "Installing faster-whisper..."
source "${VENV_DIR}/bin/activate"
pip install --upgrade pip
pip install faster-whisper

echo "Virtual environment setup complete!"
echo "Python executable: ${VENV_PYTHON}"
