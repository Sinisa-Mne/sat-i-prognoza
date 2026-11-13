#!/bin/sh
# Instalira "Sat i prognoza" (laptop.html) na Linux Mint:
#   - kopira laptop.html, news_proxy.py i icons/meteocons u ~/.local/share/sat-i-prognoza
#   - dodaje pokretanje pri prijavi (~/.config/autostart) i stavku u meniju
#   - odmah ga pokreće
# Pokretanje:  sh install-mint.sh [EKRAN]   (ponovno pokretanje samo osvježi fajlove)
#   EKRAN je ime ekrana iz `xrandr --listmonitors` (npr. LVDS) na kojem se prozor otvara;
#   bez njega se uzima prvi ekran koji nije glavni. Za premještanje treba wmctrl; bez njega
#   prozor jednom prevuci na željeni ekran.
# Uklanjanje:  rm -r ~/.local/share/sat-i-prognoza ~/.config/sat-i-prognoza-edge \
#                    ~/.config/autostart/sat-i-prognoza.desktop ~/.local/share/applications/sat-i-prognoza.desktop
set -e
SRC=$(cd "$(dirname "$0")" && pwd)
DEST="$HOME/.local/share/sat-i-prognoza"
EKRAN="${1:-}"

EDGE=$(command -v microsoft-edge-stable || command -v microsoft-edge || true)
[ -n "$EDGE" ] || { echo "Greška: Edge nije instaliran (microsoft-edge-stable)."; exit 1; }
command -v python3 >/dev/null || { echo "Greška: nema python3."; exit 1; }

mkdir -p "$DEST/icons" "$HOME/.config/autostart" "$HOME/.local/share/applications"
cp "$SRC/laptop.html" "$SRC/news_proxy.py" "$DEST/"
rm -rf "$DEST/icons/meteocons"
cp -r "$SRC/icons/meteocons" "$DEST/icons/meteocons"

cat > "$DEST/start.sh" <<EOF
#!/bin/sh
# Pomoćnik za BBC vijesti (sam izađe ako već radi), pa dashboard u posebnom Edge prozoru
# preko cijelog ekrana, bez naslovne trake (F11 vraća u običan prozor).
python3 "$DEST/news_proxy.py" >/dev/null 2>&1 &
sleep 1
# Ekran za dashboard: EKRAN (ime iz xrandr-a) ili, ako je prazno, prvi koji nije glavni.
EKRAN="$EKRAN"
GEO=\$(xrandr --listmonitors 2>/dev/null | awk -v e="\$EKRAN" '
  NR > 1 && (e != "" ? \$NF == e : index(\$2, "*") == 0) {
    split(\$3, a, "[/x+]"); printf "%d,%d,%d,%d", a[5], a[6], a[1], a[3]; exit }')
# Prozor na taj ekran premješta wmctrl kad se pojavi. Namjerno bez --window-position: to Edge
# primjenjuje na svaki novi prozor tog profila, pa bi se i on otvarao preko dashboarda
# (vijest ide u Edge prozor samo kad pomoćnik ne radi; inače je otvara Firefox).
FS=--start-fullscreen
if command -v wmctrl >/dev/null; then
  FS=
  ( W=laptop.html.Microsoft-edge
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
      sleep 1
      wmctrl -x -r \$W -b remove,fullscreen 2>/dev/null || continue
      if [ -n "\$GEO" ]; then
        wmctrl -x -r \$W -b remove,maximized_vert,maximized_horz
        wmctrl -x -r \$W -e "0,\$GEO"
      fi
      wmctrl -x -r \$W -b add,fullscreen
      break
    done ) &
fi
# --password-store=basic: uz automatsku prijavu keyring je zaključan i Edge bi tražio lozinku.
exec "$EDGE" --user-data-dir="$HOME/.config/sat-i-prognoza-edge" --no-first-run \\
  --password-store=basic --app="file://$DEST/laptop.html" \$FS >/dev/null 2>&1
EOF
chmod +x "$DEST/start.sh"

DESKTOP="[Desktop Entry]
Type=Application
Name=Sat i prognoza
Comment=Sat, kalendar, prognoza i vijesti
Exec=$DEST/start.sh
Icon=weather-few-clouds
Terminal=false
Categories=Utility;
X-GNOME-Autostart-Delay=10"
printf '%s\n' "$DESKTOP" > "$HOME/.config/autostart/sat-i-prognoza.desktop"
printf '%s\n' "$DESKTOP" > "$HOME/.local/share/applications/sat-i-prognoza.desktop"

pkill -f -- "--user-data-dir=$HOME/.config/sat-i-prognoza-edge" 2>/dev/null || true
pkill -f -- "$DEST/news_proxy.py" 2>/dev/null || true   # da se pokrene nova verzija pomoćnika
nohup "$DEST/start.sh" >/dev/null 2>&1 &
echo "Instalirano u $DEST i pokrenuto. Pokreće se samo pri svakoj prijavi."
command -v wmctrl >/dev/null || echo "Napomena: nema wmctrl (sudo apt install wmctrl), pa prozor sam prevuci na željeni ekran."
echo "Otvara se preko cijelog pomoćnog ekrana (ili onog zadatog kao: sh install-mint.sh IME); F11 = običan prozor."
