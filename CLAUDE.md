# CLAUDE.md

Dashboard za pomoćni ekran (sat, kalendar, prognoza, vijesti). Korisnik piše srpski (ijekavica, latinica);
tekst u stranici i komentari su na tom jeziku.

## Šta je gdje

- `laptop.html` je sve: CSS, HTML i JS u jednom fajlu, bez biblioteka i build koraka. Otvara se preko
  `file://` u Edge `--app` prozoru sa posebnim profilom. Veličine su u `rem`, a `html { font-size: calc(100vh / 48) }`,
  pa se sve skalira sa visinom ekrana; ciljna veličina je 1536×864 (laptop 1920×1080 na 125%) i ništa ne smije
  izaći van ekrana (`document.documentElement.scrollHeight` mora biti jednak visini prozora).
- Podešavanja su na vrhu skripte: `CONFIG` (mjesto, osvježavanje, broj sati/dana), `NEWS` (izvori), `PLACES`
  (ponuđeni gradovi), `MODELS` (Open-Meteo modeli).
- Prognoza: Open-Meteo JSON (`timezone=auto`, `&models=` za ECMWF/ICON-EU; ICON-EU nema podatke posle ~5 dana,
  dolaze `null`). Zadnja prognoza se čuva u localStorage po mjestu i modelu.
- Vijesti: vijesti.me RSS dozvoljava CORS i čita se direktno; BBC ne, pa ide preko `news_proxy.py`
  (stdlib, samo 127.0.0.1:8765, samo feedovi iz `FEEDS`, šalje `Access-Control-Allow-Private-Network`).
  Novi izvor bez CORS-a: dodaj ga u `FEEDS` i u `NEWS.sources` kao `http://127.0.0.1:8765/feed/<ime>`;
  dugme za izbor izvora se pravi samo. Čitaju se RSS (i 1.0 sa `dc:date`) i Atom; pomoćnik feed prevodi u UTF-8. Reddit bez prijave daje oko jedan zahtjev u
  minuti (inače 429), pa pri probi ne zvati feed više puta zaredom. Posle izmjene pomoćnika treba ga ponovo
  pokrenuti (`install-mint.sh` to radi sam).
- Klik na vijest: stranica zove `http://127.0.0.1:8765/open?url=...`, a pomoćnik otvara adresu u Firefoxu
  (`webbrowser`, nova kartica). `/open` prima samo `Origin` iz `OPEN_ORIGINS` (`null` = `file://`, i pregled
  na :8090) i samo sajtove iz `OPEN_HOSTS`; novi izvor vijesti treba dodati i tamo. Ako poziv ne uspije,
  stranica otvara vijest sama (`window.open`, Edge prozor).
- Cijeli naslovi: vijesti.me u RSS-u skraćuje naslove na ~65 znakova ("..."). Za takve stranica zove
  `/title?url=...`, pomoćnik pročita `og:title` sa stranice vijesti (ista ograničenja kao `/open`) i pamti ga;
  stranica ih čuva u localStorage (`vijesti-naslovi`). Naslov ima do 4 reda, pa `line-height` vijesti mora
  ostati dovoljno mali da 4 reda stanu u red (`NEWS.perPage` vijesti po visini kartice).
- Otpornost: svi zahtjevi idu kroz `fetchT` (rok `CONFIG.timeoutSec`), a sljedeći otkucaj sata i sljedeće
  osvježavanje prognoze i vijesti zakazuju se prije prikaza, da zaglavljen zahtjev ili greška u prikazu ne
  zaustave sat ni osvježavanje. Mjesta za vijesti (`perPage * pages`) dijele se u krugovima po uključenim
  izvorima (najnovija iz svakog, pa druga, ...), pa nijedan izvor ne potisne ostale.
- Ekran i sleep: stranica ne drži ekran budnim (`CONFIG.keepAwake: false`), pa gašenje ekrana i sleep idu po
  podešavanjima Cinnamona (Power Management, Screensaver). Uz `true` Edge traži "Blink Wake Lock" i ekran se ne gasi.
- Praznici: državni CG su 2 dana (3 ako prvi pada vikendom); Uskrs po gregorijanskom, Vaskrs po julijanskom
  računu; bajrami i jevrejski praznici preko `Intl` kalendara (`islamic-umalqura`, `hebrew`).
- Ikonice: Meteocons (MIT) u `icons/meteocons/{anim,static}`. Animirana može biti samo velika ikonica
  (`CONFIG.animate`), ali je ugašena: na ovom laptopu (i5-2450M, stari Radeon) animacija troši ~22% procesora,
  a bez nje cijeli dashboard ~0,6%.

## Pregled i provjera

```sh
python3 -m http.server 8090 --bind 127.0.0.1   # pa http://127.0.0.1:8090/laptop.html, prozor 1536×864
python3 news_proxy.py                           # za BBC vijesti
sh -n install-mint.sh
```

Na Windowsu je `python` umjesto `python3` (`python3` je tamo prečica ka Microsoft Store-u).

## Instalacija

- Mint: `sh install-mint.sh` kopira u `~/.local/share/sat-i-prognoza` i dodaje `~/.config/autostart`.
  Posle izmjene `laptop.html` ponovo pokreni skriptu da se kopija osvježi.
  Generisani `start.sh` pri svakom pokretanju čita položaj ekrana iz `xrandr --listmonitors` (argument skripte
  je ime ekrana; bez njega prvi koji nije glavni), pa `wmctrl` premjesti prozor tamo i stavi ga preko cijelog
  ekrana (bez `wmctrl`-a ostaje samo `--start-fullscreen`). Ne koristiti `--window-position/--window-size` za to:
  Edge ih primjenjuje na svaki novi prozor tog profila, pa se i vijesti otvaraju preko dashboarda.
  `--password-store=basic` je tu jer je uz automatsku prijavu keyring zaključan i Edge bi tražio lozinku.
- Windows: `install-windows.ps1` pravi prečice u Startup folderu koje pokazuju na ovaj folder.
