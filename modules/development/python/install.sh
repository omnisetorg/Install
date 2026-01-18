#!/bin/bash
# Python Installation
set -euo pipefail

OPTIONS="${2:-}"

echo "Installing Python 3..."

sudo apt-get update
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

# Ensure pip is up to date
python3 -m pip install --upgrade pip

# Create alias if python doesn't exist
if ! command -v python &>/dev/null; then
    echo "alias python='python3'" >> ~/.bashrc
    echo "alias pip='pip3'" >> ~/.bashrc
fi

echo "Python $(python3 --version) installed"

# Install optional packages
if [[ "$OPTIONS" == *"virtualenv"* ]]; then
    pip3 install --user virtualenv
fi
if [[ "$OPTIONS" == *"pipenv"* ]]; then
    pip3 install --user pipenv
fi
if [[ "$OPTIONS" == *"poetry"* ]]; then
    curl -sSL https://install.python-poetry.org | python3 -
fi
if [[ "$OPTIONS" == *"jupyter"* ]]; then
    pip3 install --user jupyter
fi
if [[ "$OPTIONS" == *"requests"* ]]; then
    pip3 install --user requests
fi
if [[ "$OPTIONS" == *"numpy"* ]]; then
    pip3 install --user numpy
fi
if [[ "$OPTIONS" == *"pandas"* ]]; then
    pip3 install --user pandas
fi

echo "Python installation complete"
