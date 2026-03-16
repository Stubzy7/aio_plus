
import time

MAX_LOG_ENTRIES = 50


class PerfLog:
    """Circular buffer for performance log entries."""

    def __init__(self, max_entries: int = MAX_LOG_ENTRIES):
        self.entries: list[dict] = []
        self.max_entries = max_entries

    def log(self, context: str, label: str, duration_ms: float = 0):
        """Add a log entry."""
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
        """Return a start timestamp for timing."""
        return time.perf_counter()

    def end_timer(self, start: float, context: str, label: str):
        """Log the elapsed time since start."""
        elapsed = (time.perf_counter() - start) * 1000
        self.log(context, label, elapsed)

    def clear(self):
        """Clear all log entries."""
        self.entries.clear()

    def format(self) -> str:
        """Format all entries as a string."""
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


# Singleton
perf_log = PerfLog()
