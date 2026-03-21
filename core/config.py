
import configparser
import io
import os
import shutil


def _ini_path() -> str:
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "AIO_config.ini")
    if not os.path.exists(path):
        default = os.path.join(os.path.dirname(path), "AIO_config.default.ini")
        if os.path.exists(default):
            shutil.copy2(default, path)
    return path


def _read_parser(path: str | None = None) -> configparser.ConfigParser:
    path = path or _ini_path()
    cp = configparser.ConfigParser(interpolation=None)
    if not os.path.exists(path):
        return cp
    try:
        with open(path, "rb") as f:
            raw = f.read()
        if raw[:2] == b"\xff\xfe":
            text = raw.decode("utf-16-le")
        elif raw[:3] == b"\xef\xbb\xbf":
            text = raw[3:].decode("utf-8")
        else:
            text = raw.decode("utf-8", errors="replace")
        cp.read_string(text)
    except Exception:
        cp.read(path, encoding="utf-8")
    return cp


def _write_parser(cp: configparser.ConfigParser, path: str | None = None):
    path = path or _ini_path()
    with open(path, "w", encoding="utf-8") as f:
        cp.write(f)


def read_ini(section: str, key: str, default: str = "Default") -> str:
    cp = _read_parser()
    try:
        return cp.get(section, key)
    except (configparser.NoSectionError, configparser.NoOptionError):
        return default


def write_ini(section: str, key: str, value: str):
    path = _ini_path()
    cp = _read_parser(path)
    if not cp.has_section(section):
        cp.add_section(section)
    cp.set(section, key, str(value))
    _write_parser(cp, path)


def read_ini_int(section: str, key: str, default: int = 0) -> int:
    val = read_ini(section, key, str(default))
    try:
        return int(val)
    except (ValueError, TypeError):
        return default


def read_ini_bool(section: str, key: str, default: bool = False) -> bool:
    val = read_ini(section, key, str(int(default)))
    return val.lower() in ("1", "true", "yes")


def ensure_defaults():
    path = _ini_path()
    cp = _read_parser(path)
    changed = False
    defaults = {
        ("Timings", "SearchBarClickMs"): "30",
        ("Timings", "FilterSettleMs"): "100",
        ("Timings", "TransferSettleMs"): "100",
    }
    for (section, key), val in defaults.items():
        if not cp.has_section(section):
            cp.add_section(section)
            changed = True
        if not cp.has_option(section, key):
            cp.set(section, key, val)
            changed = True
    if changed:
        _write_parser(cp, path)


def ini_detect_command_key(entry_widget, root=None):
    import tkinter as tk

    _EXCLUDED = {
        "Shift_L", "Shift_R", "Control_L", "Control_R",
        "Alt_L", "Alt_R", "Super_L", "Super_R",
        "Caps_Lock", "Num_Lock",
    }

    entry_widget.delete(0, tk.END)
    entry_widget.focus_set()

    def _on_key(event):
        if event.keysym in _EXCLUDED:
            return
        key = event.keysym
        entry_widget.delete(0, tk.END)
        entry_widget.insert(0, "{" + key + "}")
        entry_widget.unbind("<Key>")

    entry_widget.bind("<Key>", _on_key)


def list_load(section: str) -> list[str]:
    cp = _read_parser()
    if not cp.has_section(section):
        return []
    try:
        count = int(cp.get(section, "Count", fallback="0"))
    except ValueError:
        return []
    items = []
    for i in range(1, count + 1):
        val = cp.get(section, f"Item_{i}", fallback=None)
        if val is not None:
            items.append(val)
    return items


def list_save(section: str, items: list[str]):
    path = _ini_path()
    cp = _read_parser(path)
    if cp.has_section(section):
        cp.remove_section(section)
    cp.add_section(section)
    cp.set(section, "Count", str(len(items)))
    for i, item in enumerate(items, 1):
        cp.set(section, f"Item_{i}", item)
    _write_parser(cp, path)
