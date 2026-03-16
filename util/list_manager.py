
from core.config import list_load, list_save


class ListManager:
    """Manages a list of strings with INI persistence and optional ComboBox sync."""

    def __init__(self, section: str, items: list[str] | None = None):
        self.section = section
        self.items: list[str] = items if items is not None else []

    def load(self) -> list[str]:
        """Load items from INI file."""
        self.items = list_load(self.section)
        return self.items

    def save(self):
        """Save items to INI file."""
        list_save(self.section, self.items)

    def add(self, item: str) -> bool:
        """Add an item if not empty and not duplicate. Returns True if added."""
        item = item.strip()
        if not item or item in self.items:
            return False
        self.items.append(item)
        self.save()
        return True

    def remove(self, item: str) -> bool:
        """Remove an item. Returns True if removed."""
        item = item.strip()
        if item in self.items:
            self.items.remove(item)
            self.save()
            return True
        return False

    def clear(self):
        """Remove all items."""
        self.items.clear()
        self.save()

    def refresh_combobox(self, combo):
        """Update a tkinter Combobox with current items."""
        combo["values"] = self.items
        if self.items:
            combo.set(self.items[0])
        else:
            combo.set("")
