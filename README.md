# Sat i prognoza

Dashboard za pomoćni ekran: analogni sat, datum, kalendar sa crnogorskim praznicima,
vremenska prognoza (Open-Meteo, izbor modela i mjesta) i vijesti (Vijesti.me, BBC).
Jedan HTML fajl, otvara se u Edge prozoru bez okvira; radi na Windowsu i Linux Mintu.

Raspored: lijevo sat i kalendar; desno trenutno vrijeme, narednih 12 sati, danas + 3 dana i vijesti.

## Fajlovi

| Fajl | Šta je |
|---|---|
| `laptop.html` | cijeli dashboard (HTML + CSS + JS, bez zavisnosti) |
| `news_proxy.py` | mali lokalni pomoćnik (127.0.0.1:8765) za RSS koji ne dozvoljava čitanje iz stranice (BBC) |
| `icons/meteocons/` | ikonice za vrijeme, [Meteocons](https://github.com/basmilius/meteocons) (MIT, Bas Milius) |
| `install-mint.sh` | instalacija na Linux Mint (autostart + meni) |
| `install-windows.ps1` | instalacija na Windowsu (prečice u Startup folderu) |

## Instalacija

**Linux Mint** (treba `microsoft-edge-stable` i `python3`):

```sh
sh install-mint.sh          # prozor ide na prvi ekran koji nije glavni
sh install-mint.sh LVDS     # ili na ekran sa tim imenom (imena: xrandr --listmonitors)
```

Uz `wmctrl` se prozor na tom ekranu i maksimizuje; bez njega samo zauzme veličinu ekrana.

**Windows** (treba Edge i Python sa python.org):

```powershell
powershell -ExecutionPolicy Bypass -File install-windows.ps1
```

Ili samo otvori `laptop.html` u pregledniku (bez BBC vijesti ako pomoćnik ne radi).

## Korišćenje

- Klik na ime mjesta: lista gradova ili pretraga bilo kog mjesta (pamti se).
- Auto / ECMWF / ICON-EU: model prognoze (pamti se). Auto pušta Open-Meteo da izabere.
- Dvoklik bilo gdje: preko cijelog ekrana i nazad.
- Klik na vijest je otvara.
- Adresa može nositi `?place=Sarajevo&lat=43.856&lon=18.413&model=icon_eu`.

## Izvori podataka

- Prognoza i pretraga mjesta: [Open-Meteo](https://open-meteo.com) (besplatno, bez ključa)
- Vijesti: RSS sa vijesti.me i BBC (srpski + World)
- Praznici: računaju se u stranici (državni praznici CG, pravoslavni, katolički, islamski, jevrejski)
