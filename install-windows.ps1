# Postavlja "Sat i prognoza" na Windowsu: dvije prečice u Startup folderu
#   - "Vijesti pomocnik": news_proxy.py bez prozora (pythonw), za BBC vijesti
#   - "Sat i prognoza": laptop.html u posebnom Edge prozoru, preko cijelog pomoćnog ekrana
# Pokretanje (iz ovog foldera):  powershell -ExecutionPolicy Bypass -File install-windows.ps1
# Uklanjanje: obriši te dvije prečice iz shell:startup

# Gdje se prozor otvara: bilo koja tačka na pomoćnom ekranu (koordinate Windows desktopa).
# Ekran lijevo od glavnog ima negativan X. --start-fullscreen ga zatim raširi preko tog ekrana.
$WindowPosition = "-1700,1000"

$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
$startup = [Environment]::GetFolderPath("Startup")
$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
          "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { throw "Edge nije nađen" }
$pythonw = (Get-Command pythonw.exe -ErrorAction SilentlyContinue).Source
if (-not $pythonw) { throw "pythonw.exe nije nađen (instaliraj Python sa python.org)" }

$sh = New-Object -ComObject WScript.Shell
$url = "file:///" + (Join-Path $dir "laptop.html").Replace("\", "/")

$s = $sh.CreateShortcut((Join-Path $startup "Vijesti pomocnik.lnk"))
$s.TargetPath = $pythonw
$s.Arguments = '"' + (Join-Path $dir "news_proxy.py") + '"'
$s.WorkingDirectory = $dir
$s.Save()

$s = $sh.CreateShortcut((Join-Path $startup "Sat i prognoza.lnk"))
$s.TargetPath = $edge
$s.Arguments = "--user-data-dir=`"$env:LOCALAPPDATA\SatIPrognoza`" --no-first-run --app=$url " +
               "--window-position=$WindowPosition --window-size=1000,700 --start-fullscreen"
$s.WorkingDirectory = $dir
$s.Save()

Write-Host "Prečice su u $startup. Pokreću se pri sljedećoj prijavi (ili ih pokreni dvoklikom)."
