@echo off
chcp 65001 >nul
echo ========================================
echo WhereWindsMeet Lua Frida Injector v2.0
echo ========================================
echo.

REM Controlla se Python è installato
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRORE] Python non trovato!
    echo Installa Python 3.7+ da https://www.python.org/
    pause
    exit /b 1
)

REM Controlla se Frida è installato
python -c "import frida" >nul 2>&1
if errorlevel 1 (
    echo [AVVISO] Frida non trovato!
    echo Installazione Frida in corso...
    python -m pip install frida frida-tools
    if errorlevel 1 (
        echo [ERRORE] Installazione Frida fallita!
        pause
        exit /b 1
    )
    echo [OK] Frida installato con successo!
    echo.
)

REM Verifica che il gioco sia avviato
echo [*] Verifica processo wwm.exe...
tasklist /FI "IMAGENAME eq wwm.exe" 2>NUL | find /I /N "wwm.exe">NUL
if errorlevel 1 (
    echo [AVVISO] Il gioco (wwm.exe) non sembra essere avviato!
    echo [AVVISO] Assicurati di avviare il gioco prima di continuare.
    echo.
    set /p continue="Vuoi continuare comunque? (s/n): "
    if /i not "%continue%"=="s" (
        exit /b 0
    )
) else (
    echo [OK] Processo wwm.exe trovato!
)
echo.

REM Avvia il loader
echo [*] Avvio Frida Gadget Loader...
echo [*] Premi CTRL+C per interrompere
echo.
echo ========================================
echo.

python Loader_gadget.py

echo.
echo ========================================
echo [*] Injector terminato
echo ========================================
pause
