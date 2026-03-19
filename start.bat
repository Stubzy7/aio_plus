@echo off

cd /d "%~dp0"


if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
)
set PYTHONPATH=%~dp0..;%PYTHONPATH%

python -m aio_plus
pause