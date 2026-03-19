@echo off

IF NOT EXIST venv (
    echo Creating virtual environment...
    python -m venv venv
) ELSE (
    echo Virtual environment already exists. Skipping creation...
)

echo Activating environment and installing requirements...
call venv\Scripts\activate && pip install -r requirements.txt

echo Setup complete.
pause