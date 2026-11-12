#!/usr/bin/env python3
"""Local learning API. Standard library only; never deploy this as production auth."""
import argparse
import json
import secrets
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class AuthServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address, token_ttl=3600):
        super().__init__(address, Handler)
        self.token_ttl = token_ttl
        self.sessions = {}
        self.session_lock = threading.Lock()


class Handler(BaseHTTPRequestHandler):
    user = {"id": "001", "fullName": "Nguyễn Thành", "email": "demo@example.com"}

    def log_message(self, fmt, *args):
        # Base logging includes path/status only. Do not log request bodies or tokens.
        super().log_message(fmt, *args)

    def respond(self, status, payload):
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(raw)

    def do_POST(self):
        if self.path != "/auth/login":
            return self.respond(404, {"message": "Not found"})
        if self.headers.get_content_type() != "application/json":
            return self.respond(415, {"message": "Use application/json"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self.respond(400, {"message": "Invalid content length"})
        if length < 1 or length > 16384:
            return self.respond(400, {"message": "Invalid body size"})
        try:
            body = json.loads(self.rfile.read(length))
        except (json.JSONDecodeError, UnicodeDecodeError):
            return self.respond(400, {"message": "Invalid JSON"})
        if not isinstance(body, dict):
            return self.respond(400, {"message": "Expected object"})
        email, password = body.get("email"), body.get("password")
        if not isinstance(email, str) or not isinstance(password, str):
            return self.respond(400, {"message": "Email and password must be strings"})
        if email != self.user["email"] or password != "123456":
            return self.respond(401, {"message": "Invalid credentials"})
        token = secrets.token_urlsafe(32)
        with self.server.session_lock:
            now = time.time()
            self.server.sessions = {t: expiry for t, expiry in self.server.sessions.items() if expiry > now}
            self.server.sessions[token] = now + self.server.token_ttl
        self.respond(200, {"accessToken": token, "user": self.user})

    def do_GET(self):
        if self.path == "/health":
            return self.respond(200, {"status": "ok"})
        if self.path != "/auth/me":
            return self.respond(404, {"message": "Not found"})
        header = self.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            return self.respond(401, {"message": "Missing bearer token"})
        token = header.removeprefix("Bearer ")
        with self.server.session_lock:
            expiry = self.server.sessions.get(token, 0)
            valid = expiry > time.time()
            if not valid:
                self.server.sessions.pop(token, None)
        if not valid:
            return self.respond(401, {"message": "Session expired"})
        self.respond(200, self.user)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--token-ttl", type=int, default=3600)
    args = parser.parse_args()
    if args.token_ttl <= 0:
        parser.error("--token-ttl must be positive")
    server = AuthServer(("127.0.0.1", args.port), token_ttl=args.token_ttl)
    print(f"Learning API: http://localhost:{args.port}", flush=True)
    print("Demo account: demo@example.com / 123456", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
