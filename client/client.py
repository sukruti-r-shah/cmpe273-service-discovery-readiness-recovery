"""Client: calls the Inventory Service by its Kubernetes Service name only.

Every request opens a new TCP connection, so Kubernetes can route each one
to any ready Pod behind the Service.
"""
import json
import os
import signal
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

URL = os.environ.get("INVENTORY_URL", "http://inventory-service/items")
INTERVAL = float(os.environ.get("INTERVAL_SECONDS", "0.5"))


def now():
    return datetime.now(timezone.utc).strftime("%H:%M:%S")


signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))  # exit fast on Pod deletion

print(f"[{now()}] client starting, target = {URL}", flush=True)

while True:
    try:
        with urllib.request.urlopen(URL, timeout=2) as resp:
            body = json.loads(resp.read())
            print(f"[{now()}] {resp.status} served_by={body['served_by']}", flush=True)
    except (urllib.error.URLError, OSError, ValueError) as exc:
        print(f"[{now()}] ERROR {exc}", flush=True)
    time.sleep(INTERVAL)
