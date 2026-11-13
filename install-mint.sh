#!/bin/sh
# Instalira "Sat i prognoza" (laptop.html) na Linux Mint:
#   - kopira laptop.html, news_proxy.py i icons/meteocons u ~/.local/share/sat-i-prognoza
#   - dodaje pokretanje pri prijavi (~/.config/autostart) i stavku u meniju
#   - odmah ga pokreće
# Pokretanje:  sh install-mint.sh      (ponovno pokretanje samo osvježi fajlove)
# Uklanjanje:  rm -r ~/.local/share/sat-i-prognoza ~/.config/sat-i-prognoza-edge \
#                    ~/.config/autostart/sat-i-prognoza.desktop ~/.local/share/applications/sat-i-prognoza.desktop
set -e
SRC=$(cd "$(dirname "$0")" && pwd)
DEST="$HOME/.local/share/sat-i-prognoza"

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
exec "$EDGE" --user-data-dir="$HOME/.config/sat-i-prognoza-edge" --no-first-run \\
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
echo "Prozor prevuci na željeni ekran; dvoklik = preko cijelog ekrana."
