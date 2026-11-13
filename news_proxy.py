#!/usr/bin/env python3
"""Pomoćnik za vijesti na laptop.html: preuzima RSS feedove koji ne dozvoljavaju čitanje
direktno iz stranice (BBC, ...) i daje ih stranici.

Sluša samo na ovom računaru (127.0.0.1) i preuzima samo feedove iz FEEDS, pa ne može
poslužiti kao otvoreni proxy. Feedove čuva CACHE_S sekundi da ne opterećuje izvore.

Pokretanje:  pythonw news_proxy.py   (Windows, bez prozora)
             python3 news_proxy.py   (Linux Mint)
Provjera:    http://127.0.0.1:8765/feed/bbc-sr
"""
import sys
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8765
CACHE_S = 600
FEEDS = {
    "bbc-sr": "https://feeds.bbci.co.uk/serbian/lat/rss.xml",
    "bbc-world": "https://feeds.bbci.co.uk/news/world/rss.xml",
    "bokanews": "https://www.bokanews.me/feed/",
    "rtcg": "https://www.rtcg.me/rss.html",
}

_cache = {}  # ime -> (vrijeme, tijelo)
_lock = threading.Lock()


def get_feed(name):
    with _lock:
        hit = _cache.get(name)
    if hit and time.time() - hit[0] < CACHE_S:
        return hit[1]
    req = urllib.request.Request(FEEDS[name], headers={"User-Agent": "Mozilla/5.0 (laptop dashboard)"})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            body = r.read()
    except OSError:
        if hit:  # izvor trenutno ne radi: vrati zadnje što imamo
            return hit[1]
        raise
    with _lock:
        _cache[name] = (time.time(), body)
    return body


class Handler(BaseHTTPRequestHandler):
    def cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        # Chromium traži ovo kad stranica (npr. file://) pita server na 127.0.0.1
        self.send_header("Access-Control-Allow-Private-Network", "true")

    def do_OPTIONS(self):
        self.send_response(204)
        self.cors()
        self.send_header("Access-Control-Allow-Methods", "GET")
        self.end_headers()

    def do_GET(self):
        parts = self.path.split("?")[0].strip("/").split("/")
        if len(parts) != 2 or parts[0] != "feed" or parts[1] not in FEEDS:
            self.send_error(404, "nepoznat feed")
            return
        try:
            body = get_feed(parts[1])
        except OSError as e:
            self.send_error(502, f"izvor ne odgovara: {e}")
            return
        self.send_response(200)
        self.cors()
        self.send_header("Content-Type", "text/xml; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):  # tiho: pod pythonw nema konzole
        pass


if __name__ == "__main__":
    # Bez SO_REUSEADDR, da drugo pokretanje odmah javi grešku umjesto da tiho dijeli port.
    ThreadingHTTPServer.allow_reuse_address = False
    try:
        server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    except OSError:
        sys.exit(0)  # već radi
    server.serve_forever()
