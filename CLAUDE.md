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
  Novi izvor bez CORS-a: dodaj ga u `FEEDS` i u `NEWS.sources` kao `http://127.0.0.1:8765/feed/<ime>`.
- Praznici: državni CG su 2 dana (3 ako prvi pada vikendom); Uskrs po gregorijanskom, Vaskrs po julijanskom
  računu; bajrami i jevrejski praznici preko `Intl` kalendara (`islamic-umalqura`, `hebrew`).
- Ikonice: Meteocons (MIT) u `icons/meteocons/{anim,static}`; animirana je samo velika ikonica.

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
- Windows: `install-windows.ps1` pravi prečice u Startup folderu koje pokazuju na ovaj folder.
