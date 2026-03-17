
import time

MAX_LOG_ENTRIES = 50


class PerfLog:

    def __init__(self, max_entries: int = MAX_LOG_ENTRIES):
        self.entries: list[dict] = []
        self.max_entries = max_entries

    def log(self, context: str, label: str, duration_ms: float = 0):
        entry = {
            "time": time.strftime("%H:%M:%S"),
            "context": context,
            "label": label,
            "duration_ms": round(duration_ms, 1),
        }
        self.entries.append(entry)
        if len(self.entries) > self.max_entries:
            self.entries.pop(0)

    def start_timer(self) -> float:
        return time.perf_counter()

    def end_timer(self, start: float, context: str, label: str):
        elapsed = (time.perf_counter() - start) * 1000
        self.log(context, label, elapsed)

    def clear(self):
        self.entries.clear()

    def format(self) -> str:
        lines = []
        for e in self.entries:
            if e["duration_ms"] > 0:
                lines.append(
                    f"[{e['time']}] {e['context']}: {e['label']} "
                    f"({e['duration_ms']:.0f}ms)"
                )
            else:
                lines.append(f"[{e['time']}] {e['context']}: {e['label']}")
        return "\n".join(lines)


perf_log = PerfLog()
