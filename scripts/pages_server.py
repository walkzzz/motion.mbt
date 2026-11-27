#!/usr/bin/env python3
"""motion GitCode WebHook receiver + Pages server.

Flow:
  GitCode push event -> POST /webhook (secret-verified)
    -> git pull (atomgit main) -> rebuild site (scripts/build_site.py)
    -> served at / (from site/)
Endpoints:
  POST /webhook   GitCode WebHook target (push events)
  GET  /          documentation portal (site/index.html and static files)
  GET  /healthz   liveness probe + last sync status
"""
import hmac
import hashlib
import json
import os
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REPO = "/workspace/motion"
PORT = int(os.environ.get("MOTION_PAGES_PORT", "8080"))
SECRET = os.environ.get("MOTION_WEBHOOK_SECRET", "motion-pages-hook")

state = {
    "last_event": "none",
    "last_sync": "never",
    "last_status": "idle",
    "last_commit": "unknown",
    "sync_count": 0,
}
lock = threading.Lock()


def git_pull_and_build() -> tuple[bool, str]:
    """Pull latest main from the primary remote and rebuild the site."""
    def run(cmd: list[str], cwd: str = REPO) -> subprocess.CompletedProcess:
        return subprocess.run(
            cmd, cwd=cwd, capture_output=True, text=True, timeout=120)

    for step in (["git", "fetch", "atomgit", "main"],
                 ["git", "reset", "--hard", "FETCH_HEAD"]):
        r = run(step)
        if r.returncode != 0:
            return False, f"git failed: {step[1]}\n{r.stderr.strip()[:400]}"

    r = run(["git", "rev-parse", "--short", "HEAD"])
    commit = r.stdout.strip()

    r = run(["python3", "scripts/build_site.py"])
    if r.returncode != 0:
        return False, f"build failed\n{r.stderr.strip()[:400]}"
    return True, commit


def handle_push(payload: dict) -> None:
    with lock:
        state["last_event"] = "push"
        state["last_sync"] = time.strftime("%Y-%m-%d %H:%M:%S")
        state["last_status"] = "syncing"
    ok, info = git_pull_and_build()
    with lock:
        state["last_status"] = "ok" if ok else "error"
        state["last_commit"] = info if ok else state["last_commit"]
        state["sync_count"] += 1
        if not ok:
            state["last_error"] = info


CONTENT_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "application/javascript",
    ".json": "application/json",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
}


class Handler(BaseHTTPRequestHandler):
    server_version = "MotionPages/1.0"

    def _send(self, code: int, body: bytes, ctype: str = "text/plain; charset=utf-8") -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def _secret_ok(self) -> bool:
        token = (self.headers.get("X-Gitcode-Token")
                 or self.headers.get("X-Git-Token")
                 or self.headers.get("X-Hub-Signature-256"))
        if token is None:
            return True  # no token header: allow (secret may be empty)
        if token.startswith("sha256="):
            digest = hmac.new(SECRET.encode(), digestmod=hashlib.sha256)
            return hmac.compare_digest("sha256=" + digest.hexdigest(), token)
        return hmac.compare_digest(token, SECRET)

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/webhook":
            self._send(404, b"not found")
            return
        if not self._secret_ok():
            self._send(403, b"invalid webhook secret")
            return
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length else b"{}"
        try:
            payload = json.loads(raw or b"{}")
        except json.JSONDecodeError:
            self._send(400, b"invalid json")
            return
        event = (payload.get("header", {}).get("event_type")
                 or payload.get("event_name")
                 or "push")
        if event in ("ping",):
            self._send(200, b"pong")
            return
        threading.Thread(target=handle_push, args=(payload,), daemon=True).start()
        self._send(200, b"sync started")

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/healthz":
            with lock:
                body = json.dumps(state, ensure_ascii=False, indent=2).encode()
            self._send(200, body, "application/json")
            return
        if self.path == "/":
            path = "index.html"
        else:
            path = self.path.lstrip("/")[:256]
            if ".." in path or path.startswith("/"):
                self._send(400, b"bad path")
                return
        full = os.path.normpath(os.path.join(REPO, "site", path))
        if not full.startswith(os.path.join(REPO, "site")):
            self._send(400, b"bad path")
            return
        if os.path.isdir(full):
            full = os.path.join(full, "index.html")
        if not os.path.isfile(full):
            self._send(404, b"not found")
            return
        ext = os.path.splitext(full)[1].lower()
        ctype = CONTENT_TYPES.get(ext, "application/octet-stream")
        with open(full, "rb") as f:
            self._send(200, f.read(), ctype)

    def log_message(self, fmt: str, *args) -> None:
        print(f"[{time.strftime('%H:%M:%S')}] {self.address_string()} {fmt % args}", flush=True)


def main() -> None:
    ok, commit = git_pull_and_build()
    with lock:
        state["last_status"] = "ok" if ok else "error"
        state["last_commit"] = commit if ok else "startup build failed"
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"motion pages serving on :{PORT} (webhook POST /webhook, site /, health /healthz)", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
