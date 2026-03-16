
import logging
import threading
try:
    import requests
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False

log = logging.getLogger(__name__)

# Map priority names to ntfy.sh values
_PRIORITY_MAP = {
    "min": "min", "low": "low", "default": "default",
    "high": "high", "max": "max", "urgent": "urgent",
}


def ntfy_push(priority: str, message: str, key: str = ""):
    """Send a push notification via ntfy.sh.

    Args:
        priority: Notification priority ("low", "default", "high", "max", "urgent").
        message: The notification body text.
        key: The ntfy topic key. If empty, does nothing.
    """
    if not key:
        log.debug("ntfy_push: no key set, skipping")
        return
    if not REQUESTS_AVAILABLE:
        log.warning("ntfy_push: requests module not available")
        return

    prio = _PRIORITY_MAP.get(priority.lower(), "default")
    log.info("ntfy_push: sending to topic '%s' prio=%s msg='%s'", key, prio, message)

    def _send():
        try:
            resp = requests.post(
                f"https://ntfy.sh/{key}",
                data=message.encode("utf-8"),
                headers={
                    "Title": "GG AIO",
                    "Priority": prio,
                },
                timeout=10,
            )
            log.info("ntfy_push: response %d", resp.status_code)
        except Exception as e:
            log.error("ntfy_push: failed — %s", e)

    threading.Thread(target=_send, daemon=True).start()
