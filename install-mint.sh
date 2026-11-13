#!/bin/sh
# Instalira "Sat i prognoza" (laptop.html) na Linux Mint:
#   - kopira laptop.html, news_proxy.py i icons/meteocons u ~/.local/share/sat-i-prognoza
#   - dodaje pokretanje pri prijavi (~/.config/autostart) i stavku u meniju
#   - odmah ga pokreće
# Pokretanje:  sh install-mint.sh [EKRAN]   (ponovno pokretanje samo osvježi fajlove)
#   EKRAN je ime ekrana iz `xrandr --listmonitors` (npr. LVDS) na kojem se prozor otvara;
#   bez njega se uzima prvi ekran koji nije glavni.
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
# Pomoćnik za BBC vijesti (sam izađe ako već radi), pa dashboard u posebnom Edge prozoru.
python3 "$DEST/news_proxy.py" >/dev/null 2>&1 &
sleep 1
# Ekran za prozor: EKRAN (ime iz xrandr-a) ili, ako je prazno, prvi koji nije glavni.
# Edge ne pamti pouzdano na kojem je ekranu bio, pa položaj zadajemo pri svakom pokretanju.
EKRAN="$EKRAN"
POS=\$(xrandr --listmonitors 2>/dev/null | awk -v e="\$EKRAN" '
  NR > 1 && (e != "" ? \$NF == e : index(\$2, "*") == 0) {
    split(\$3, a, "[/x+]")
    printf "--window-position=%d,%d --window-size=%d,%d", a[5], a[6], a[1], a[3]; exit }')
# Uz zadat položaj Edge ne poštuje --start-maximized, pa prozor maksimizuje wmctrl (ako ga ima).
[ -n "\$POS" ] && command -v wmctrl >/dev/null && (
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    sleep 2
    wmctrl -x -r laptop.html.Microsoft-edge -b add,maximized_vert,maximized_horz 2>/dev/null && break
  done ) &
# --password-store=basic: uz automatsku prijavu keyring je zaključan i Edge bi tražio lozinku.
exec "$EDGE" --user-data-dir="$HOME/.config/sat-i-prognoza-edge" --no-first-run \\
  --password-store=basic \$POS \\
  --app="file://$DEST/laptop.html" --start-maximized >/dev/null 2>&1
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
nohup "$DEST/start.sh" >/dev/null 2>&1 &
echo "Instalirano u $DEST i pokrenuto. Pokreće se samo pri svakoj prijavi."
echo "Otvara se na pomoćnom ekranu (ili na onom zadatom kao: sh install-mint.sh IME); dvoklik = preko cijelog ekrana."
