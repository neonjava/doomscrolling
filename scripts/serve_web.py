#!/usr/bin/env python3
"""Local development server for the Doomscrolling website."""
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import sys

WEB_DIR = Path(__file__).resolve().parents[1] / "web"

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)

    def do_GET(self):
        # Support clean URLs locally (e.g. /open-source -> /open-source.html)
        path = self.path.split("?")[0].rstrip("/")
        if path == "/download":
            self.send_response(302)
            self.send_header("Location", "/Doomscrolling-v0.1.0.apk")
            self.end_headers()
            return
        if path and not Path(WEB_DIR / path.lstrip("/")).exists():
            html_candidate = WEB_DIR / f"{path.lstrip('/')}.html"
            if html_candidate.exists():
                self.path = f"{path}.html"
        super().do_GET()

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
    server = HTTPServer(("0.0.0.0", port), Handler)
    print(f"Serving Doomscrolling website at http://localhost:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")

if __name__ == "__main__":
    main()
