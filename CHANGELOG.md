# AIO+ Changelog

---

### Popcorn OCR + macro tab improvements
- OCR detects tame vs storage inventories, uses weight for tames
- Tame popcorn stops at saddle weight via weight OCR
- Crafting inventory OCR strips weight data from slot count
- Popcorn count=0 drops everything w OCR instead of keybinds
- Guided macros save as grid params instead of per-slot events in config
- Repeat popcorn F key arms/disarms properly w F1
- Default config updated w all sections for fresh installs

---

### Added GG art animation
- GG art animated on join sim tab. Optional, delete `gui/art_anim.py` for static.

### Fixed join sim clicking when ARK unfocused

### Fixed autoclicker + mammoth drums stealing focus

### Fixed join sim MainMenu navigation

### Fixed taskbar auto-hide not restoring

### Fixed join sim loading-in detection stopping early

### Added Auto Level saddle-only mode
- Auto Saddle works with zero stat points.

---

### Added Delta art animation
- Delta art animated on join sim tab. Optional, remove `gui/art_anim.py` for static.

### Added BG left click for key repeat macros

### Fixed failed join skipping server instead of retrying

### Removed server gating from F6 cycle

---

### Fixed F key triggering wrong macros

### Fixed key repeat not resuming after pause

### Added mouse button support for Detect Key + macro hotkeys

### Fixed `[E] Feed` imprint detection

### Fixed upload char join detection

### Fixed "Items Not Allowed" popup not handled

### Added upload char 3-stage timer

### Fixed transmitter pixel coordinates

### Fixed server number not typing into search
