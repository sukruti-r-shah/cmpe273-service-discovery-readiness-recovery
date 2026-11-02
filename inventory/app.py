"""Inventory Service.

Endpoints:
  GET /items   -> inventory data + which Pod served the request
  GET /ready   -> readiness: 200 normally, 503 if /tmp/unready exists
  GET /health  -> liveness: always 200 while the process is up
"""
import json
import os
import signal
import socket
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

POD_NAME = os.environ.get("POD_NAME", socket.gethostname())
POD_IP = os.environ.get("POD_IP", "unknown")
PORT = int(os.environ.get("PORT", "8080"))
UNREADY_FLAG = "/tmp/unready"

INVENTORY = {
    "laptop": 12,
    "keyboard": 40,
    "monitor": 7,
}


def log(msg):
    ts = datetime.now(timezone.utc).strftime("%H:%M:%S")
    print(f"[{ts}] [{POD_NAME}] {msg}", flush=True)


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/items":
            log("GET /items -> 200")
            self._send(200, {"served_by": POD_NAME, "pod_ip": POD_IP, "items": INVENTORY})
        elif self.path == "/ready":
            if os.path.exists(UNREADY_FLAG):
                log("readiness check -> 503 (not ready)")
                self._send(503, {"ready": False, "pod": POD_NAME})
            else:
                self._send(200, {"ready": True, "pod": POD_NAME})
        elif self.path == "/health":
            self._send(200, {"alive": True, "pod": POD_NAME})
        else:
            self._send(404, {"error": "not found"})

    def log_message(self, *args):
        pass  # silence default access log; we log what matters ourselves


def handle_sigterm(signum, frame):
    # As PID 1 in a container, Python ignores SIGTERM by default, which would make
    # Kubernetes wait the full 30s grace period before killing the Pod.
    log("SIGTERM received, shutting down")
    sys.exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, handle_sigterm)
    log(f"Inventory Service starting on port {PORT}")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
