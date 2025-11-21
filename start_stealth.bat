@echo off
chcp 65001 >nul
echo ╔══════════════════════════════════════════════════════════════╗
echo ║   WhereWindsMeet Stealth Injector v2.0 - Anti-Detection     ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

REM Controlla Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [!] Python non trovato!
    pause
    exit /b 1
)

echo [*] Avvio in modalità STEALTH...
echo.
echo [*] Tecniche attive:
echo     ✓ Offuscamento codice
echo     ✓ Anti-debugging
echo     ✓ Timing randomizzato
echo     ✓ Thread renaming
echo     ✓ Port hiding
echo     ✓ String obfuscation
echo     ✓ Detection patching
echo.

REM Delay iniziale randomizzato
echo [*] Delay iniziale (anti-pattern)...
timeout /t 3 /nobreak >nul

REM Avvia stealth loader
echo [*] Avvio stealth loader...
python stealth_loader.py

if errorlevel 1 (
    echo.
    echo [!] Errore durante l'avvio stealth
    echo [*] Controlla i log per dettagli
    pause
    exit /b 1
)

echo.
echo [✓] Stealth loader completato
echo.
pause
