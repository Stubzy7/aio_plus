#!/bin/bash

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
else
    echo "Virtual environment already exists. Skipping creation..."
fi

echo "Activating environment and installing requirements..."
source venv/bin/activate
pip install -r requirements.txt

echo "Setup complete."