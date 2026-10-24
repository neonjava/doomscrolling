#!/usr/bin/env python3
"""Preview the built Flutter website with the same routes and headers as Vercel."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import json
import sys
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
WEB_DIR = ROOT / "flutter_ui/build/web"
CONFIG = json.loads((ROOT / "vercel.json").read_text())
REDIRECTS = {row["source"]: row["destination"] for row in CONFIG["redirects"]}
REWRITES = {row["source"]: row["destination"] for row in CONFIG["rewrites"]}

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)

    def end_headers(self):
        for header in CONFIG["headers"][0]["headers"]:
            self.send_header(header["key"], header["value"])
        super().end_headers()

    def do_GET(self):
        path = urlsplit(self.path).path.rstrip("/") or "/"
        if path in REDIRECTS:
            self.send_response(307)
            self.send_header("Location", REDIRECTS[path])
            self.end_headers()
            return
        if path in REWRITES:
            self.path = REWRITES[path]
        super().do_GET()

if __name__ == "__main__":
    if not (WEB_DIR / "main.dart.js").exists():
        sys.exit("Build first: bash scripts/build_web.sh")
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"Serving Flutter website at http://localhost:{port}", flush=True)
    try: server.serve_forever()
    except KeyboardInterrupt: pass
    finally: server.server_close()
