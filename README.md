# AIO+

AIO for **ARK: Survival Ascended** on Windows and Linux.

## Features

- Macros
- Auto Craft
- Popcorn
- Magic F
- Sheep
- Auto Level
- Quick Hatch
- Quick Feed
- Auto Imprint
- Join Sim
- Name Spay
- OB Upload/Download
- Overcap
- Grab My Kit
- Auto Pin
- NVIDIA Filter
- Autoclicker
- Mammoth Drums

## Requirements

- **Python 3.10+**
- **ARK: Survival Ascended** (16:9 resolution — 1920x1080, 2560x1440, 3840x2160)

### Windows
- Windows 10/11

### Linux
- X11 or XWayland (Wayland-only is not supported)
- `xdotool` and `xclip` installed
- ARK running via Steam Proton

## Setup

1. **Clone the repo**
   ```
   git clone https://github.com/Stubzy7/aio_plus.git
   cd aio_plus
   ```

2. **Set up a virtual environment**
   ```
   python -m venv venv
   venv\Scripts\activate
   pip install -r requirements.txt
   ```
   On Linux:
   ```
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Linux only — install system packages**
   ```
   # Debian/Ubuntu
   sudo apt install xdotool xclip scrot tesseract-ocr

   # Fedora/Bazzite
   sudo dnf install xdotool xclip scrot tesseract
   ```

4. **Run**
   
   Double-click `start.bat` or run from terminal:
   ```
   python -m aio_plus
   ```

> **Windows:** Run as Administrator if hotkeys or input injection aren't working.
>
> **Linux:** Run from an X11 or XWayland session. Make sure ARK is running via Steam Proton.

## Configuration

Settings are stored in `AIO_config.ini` (created on first run). You can edit values through the GUI or directly in the file.

## Notes

- Designed for **16:9** resolutions. Non-16:9 aspect ratios may have misaligned coordinates.
- On Linux, ARK runs through Proton/XWayland. Most features work, but some Windows-specific features (like NVIDIA Filter, taskbar hiding) are disabled.
- Was unable to test on a linux machine, so i'm unsure how well it will run.
