
from core.config import list_load, list_save


class ListManager:

    def __init__(self, section: str, items: list[str] | None = None):
        self.section = section
        self.items: list[str] = items if items is not None else []

    def load(self) -> list[str]:
        self.items = list_load(self.section)
        return self.items

    def save(self):
        list_save(self.section, self.items)

    def add(self, item: str) -> bool:
        item = item.strip()
        if not item or item in self.items:
            return False
        self.items.append(item)
        self.save()
        return True

    def remove(self, item: str) -> bool:
        item = item.strip()
        if item in self.items:
            self.items.remove(item)
            self.save()
            return True
        return False

    def clear(self):
        self.items.clear()
        self.save()

    def refresh_combobox(self, combo):
        combo["values"] = self.items
        if self.items:
            combo.set(self.items[0])
        else:
            combo.set("")
