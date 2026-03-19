#!/bin/bash

cd "$(dirname "$0")"

if [ -d "venv" ]; then
    source venv/bin/activate
fi

export PYTHONPATH=$PYTHONPATH:$(pwd)/..

python3 -m aio_plus