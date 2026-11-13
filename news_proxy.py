#!/usr/bin/env python3
"""Pomoćnik za vijesti na laptop.html: preuzima RSS feedove koji ne dozvoljavaju čitanje
direktno iz stranice (BBC, ...) i daje ih stranici. Uz to na klik otvara vijest u Firefoxu
(/open?url=...), jer stranica u Edge prozoru sama ne može pokrenuti drugi preglednik, i čita
cijeli naslov sa stranice vijesti (/title?url=...) kad ga izvor u RSS-u skrati (vijesti.me).

Sluša samo na ovom računaru (127.0.0.1) i preuzima samo feedove iz FEEDS, pa ne može
poslužiti kao otvoreni proxy. Feedove čuva CACHE_S sekundi da ne opterećuje izvore.

Pokretanje:  pythonw news_proxy.py   (Windows, bez prozora)
             python3 news_proxy.py   (Linux Mint)
Provjera:    http://127.0.0.1:8765/feed/bbc-sr

/open i /title primaju samo zahtjeve sa dashboarda (zaglavlje Origin iz OPEN_ORIGINS) i samo adrese
sa sajtova iz OPEN_HOSTS, da neka druga stranica u pregledniku ne može preko pomoćnika otvarati
kartice ili slati zahtjeve po volji.
"""
import html
import re
import sys
import threading
import time
import urllib.parse
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8765
CACHE_S = 600
RETRY_S = 90  # posle neuspjeha izvor se ne pita ponovo ovoliko sekundi (Reddit na česte zahtjeve vraća 429)
FEEDS = {
    "bbc-sr": "https://feeds.bbci.co.uk/serbian/lat/rss.xml",
    "bbc-world": "https://feeds.bbci.co.uk/news/world/rss.xml",
    "bokanews": "https://www.bokanews.me/feed/",
    "rtcg": "https://www.rtcg.me/rss.html",
    # Reddit bez prijave dozvoljava otprilike jedan zahtjev u minuti (inače 429); CACHE_S to pokriva.
    "reddit-worldnews": "https://www.reddit.com/r/worldnews/.rss",
    "slashdot": "https://rss.slashdot.org/Slashdot/slashdotMain",
}
# Odakle smije stići /open: "null" je stranica otvorena kao fajl (file://), ostalo je pregled iz CLAUDE.md.
OPEN_ORIGINS = {"null", "http://127.0.0.1:8090", "http://localhost:8090"}
# Sajtovi čije se vijesti smiju otvoriti (i njihovi poddomeni). Novi izvor: dodaj i ovdje.
OPEN_HOSTS = ("vijesti.me", "bbc.com", "bbc.co.uk", "reddit.com", "slashdot.org", "bokanews.me", "rtcg.me")

XML_ENC = re.compile(rb"""^(\s*<\?xml[^>]*?encoding=)["']([\w.-]+)["']""")
_cache = {}  # ime -> (vrijeme, tijelo)
_failed = {}  # ime -> vrijeme zadnjeg neuspjeha
_locks = {name: threading.Lock() for name in FEEDS}


def to_utf8(body):
    # Stranica čita odgovor kao UTF-8, a neki feedovi (Slashdot: ISO-8859-1) nisu u njemu.
    m = XML_ENC.match(body)
    if not m or m.group(2).lower() in (b"utf-8", b"utf8"):
        return body
    try:
        text = body.decode(m.group(2).decode("ascii"))
    except (LookupError, UnicodeDecodeError):
        return body
    return XML_ENC.sub(rb'\1"UTF-8"', text.encode("utf-8"), count=1)


def get_feed(name):
    # Jedan zahtjev ka izvoru odjednom: drugi sačeka i uzme iz keša (Reddit bi mu inače vratio 429).
    with _locks[name]:
        hit = _cache.get(name)
        if hit and time.time() - hit[0] < CACHE_S:
            return hit[1]
        err = OSError("izvor je maloprije odbio zahtjev")
        if time.time() - _failed.get(name, 0) >= RETRY_S:
            req = urllib.request.Request(FEEDS[name], headers={"User-Agent": "Mozilla/5.0 (laptop dashboard)"})
            try:
                with urllib.request.urlopen(req, timeout=15) as r:
                    body = to_utf8(r.read())
                _failed.pop(name, None)
                _cache[name] = (time.time(), body)
                return body
            except OSError as e:
                _failed[name] = time.time()
                err = e
        if hit:  # izvor trenutno ne radi: vrati zadnje što imamo
            return hit[1]
        raise err


TITLE_RE = (  # prvo og:title (čist naslov), pa <title>; naslov može sadržati drugu vrstu navodnika
    re.compile(r"""<meta[^>]+property=["']og:title["'][^>]*?content=(?:"([^"]+)"|'([^']+)')""", re.I),
    re.compile(r"""<meta[^>]+content=(?:"([^"]+)"|'([^']+)')[^>]*?property=["']og:title["']""", re.I),
    re.compile(r"<title[^>]*>([^<]+)()</title>", re.I),
)
_titles = {}  # adresa vijesti -> cijeli naslov (naslov se ne mijenja, pa se čuva dok pomoćnik radi)
_title_slots = threading.Semaphore(2)  # najviše dvije stranice odjednom sa istog sajta


def get_title(url):
    if url in _titles:
        return _titles[url]
    with _title_slots:
        if url in _titles:
            return _titles[url]
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (laptop dashboard)"})
        with urllib.request.urlopen(req, timeout=15) as r:
            page = r.read(200_000).decode(r.headers.get_content_charset() or "utf-8", "replace")
    for rx in TITLE_RE:
        m = rx.search(page)
        title = html.unescape(m.group(1) or m.group(2)).strip() if m else ""
        if title:
            if len(_titles) > 500:
                _titles.clear()
            _titles[url] = title
            return title
    raise LookupError("stranica nema naslov")


def open_in_browser(url):
    try:
        webbrowser.get("firefox").open_new_tab(url)
    except webbrowser.Error:  # nema Firefoxa: podrazumijevani preglednik
        webbrowser.open_new_tab(url)


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

    def allowed_url(self, query):
        """Adresa iz ?url=..., ili None (uz poslat odgovor) ako zahtjev nije sa dashboarda ili sajt nije dozvoljen."""
        if self.headers.get("Origin") not in OPEN_ORIGINS:
            self.send_error(403, "zahtjev nije sa dashboarda")
            return None
        url = urllib.parse.parse_qs(query).get("url", [""])[0]
        u = urllib.parse.urlsplit(url)
        host = (u.hostname or "").lower()
        if u.scheme not in ("http", "https") or not any(host == h or host.endswith("." + h) for h in OPEN_HOSTS):
            self.send_error(400, "adresa nije sa dozvoljenog sajta")
            return None
        return url

    def do_open(self, query):
        url = self.allowed_url(query)
        if not url:
            return
        threading.Thread(target=open_in_browser, args=(url,), daemon=True).start()
        self.send_response(204)
        self.cors()
        self.end_headers()

    def do_title(self, query):
        url = self.allowed_url(query)
        if not url:
            return
        try:
            body = get_title(url).encode("utf-8")
        except (OSError, LookupError) as e:
            self.send_error(502, f"naslov nije dostupan: {e}")
            return
        self.send_response(200)
        self.cors()
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path, _, query = self.path.partition("?")
        if path == "/open":
            self.do_open(query)
            return
        if path == "/title":
            self.do_title(query)
            return
        parts = path.strip("/").split("/")
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
    # Na Windowsu bi SO_REUSEADDR dao da dva pomoćnika tiho dijele port, pa ga tamo nema. Na Linuxu
    # ne dozvoljava dijeljenje, a treba da bi se pomoćnik mogao ponovo pokrenuti odmah posle gašenja
    # (stare veze su još minut u TIME_WAIT i bez ovoga bind javlja "Address already in use").
    ThreadingHTTPServer.allow_reuse_address = sys.platform != "win32"
    try:
        server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    except OSError:
        sys.exit(0)  # već radi
    server.serve_forever()
