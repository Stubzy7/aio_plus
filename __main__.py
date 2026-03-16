
import logging
import sys
import os

logging.basicConfig(
    level=logging.WARNING,
    format="%(asctime)s %(name)s %(levelname)s: %(message)s",
    stream=sys.stderr,
)
# Enable sheep debug logging
logging.getLogger("modules.sheep").setLevel(logging.INFO)

# Ensure project root is on path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import AIOApp


def main():
    app = AIOApp()
    app.run()


if __name__ == "__main__":
    main()
