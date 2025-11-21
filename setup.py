#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Setup automatico per WhereWindsMeet-Lua-Frida-Injector
Verifica dipendenze, configura il progetto e prepara l'ambiente
"""

import os
import sys
import json
import subprocess
import shutil
from pathlib import Path

# Colori per output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text.center(60)}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}\n")

def print_success(text):
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

def print_error(text):
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

def print_warning(text):
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")

def print_info(text):
    print(f"{Colors.OKCYAN}ℹ {text}{Colors.ENDC}")

def check_python_version():
    """Verifica versione Python"""
    print_info("Controllo versione Python...")
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 7):
        print_error(f"Python 3.7+ richiesto, trovato {version.major}.{version.minor}")
        return False
    print_success(f"Python {version.major}.{version.minor}.{version.micro}")
    return True

def check_pip():
    """Verifica che pip sia installato"""
    print_info("Controllo pip...")
    try:
        import pip
        print_success("pip installato")
        return True
    except ImportError:
        print_error("pip non trovato")
        return False

def install_frida():
    """Installa Frida"""
    print_info("Installazione Frida...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "frida", "frida-tools"])
        print_success("Frida installato con successo")
        return True
    except subprocess.CalledProcessError:
        print_error("Errore durante l'installazione di Frida")
        return False

def check_frida():
    """Verifica che Frida sia installato"""
    print_info("Controllo Frida...")
    try:
        import frida
        version = frida.__version__
        print_success(f"Frida {version} installato")
        return True
    except ImportError:
        print_warning("Frida non trovato")
        response = input("Vuoi installare Frida ora? (s/n): ").lower()
        if response == 's':
            return install_frida()
        return False

def create_directories():
    """Crea le directory necessarie"""
    print_info("Creazione directory...")
    
    dirs = [
        "Scripts",
        "Logs",
        "Backups",
        "Config"
    ]
    
    for dir_name in dirs:
        path = Path(dir_name)
        if not path.exists():
            path.mkdir(parents=True, exist_ok=True)
            print_success(f"Directory creata: {dir_name}")
        else:
            print_info(f"Directory già esistente: {dir_name}")
    
    return True

def load_config():
    """Carica la configurazione"""
    config_path = Path("config.json")
    if config_path.exists():
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return None

def save_config(config):
    """Salva la configurazione"""
    config_path = Path("config.json")
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

def configure_project():
    """Configura il progetto interattivamente"""
    print_info("Configurazione progetto...")
    
    config = load_config()
    if not config:
        print_error("File config.json non trovato")
        return False
    
    print("\nConfigurazione corrente:")
    print(f"  Project Root: {config['paths']['project_root']}")
    print(f"  Game EXE: {config['paths']['game_exe']}")
    print(f"  Frida Host: {config['frida']['host']}:{config['frida']['port']}")
    
    response = input("\nVuoi modificare la configurazione? (s/n): ").lower()
    if response == 's':
        # Project root
        new_root = input(f"Project Root [{config['paths']['project_root']}]: ").strip()
        if new_root:
            config['paths']['project_root'] = new_root
        
        # Game exe
        new_exe = input(f"Game EXE [{config['paths']['game_exe']}]: ").strip()
        if new_exe:
            config['paths']['game_exe'] = new_exe
        
        # Frida port
        new_port = input(f"Frida Port [{config['frida']['port']}]: ").strip()
        if new_port:
            try:
                config['frida']['port'] = int(new_port)
            except ValueError:
                print_warning("Porta non valida, mantengo quella corrente")
        
        save_config(config)
        print_success("Configurazione salvata")
    
    return True

def check_files():
    """Verifica che i file necessari esistano"""
    print_info("Controllo file necessari...")
    
    required_files = [
        "hook.js",
        "Loader_gadget.py",
        "frida-gadget.config",
        "config.json"
    ]
    
    all_ok = True
    for file_name in required_files:
        path = Path(file_name)
        if path.exists():
            print_success(f"File trovato: {file_name}")
        else:
            print_error(f"File mancante: {file_name}")
            all_ok = False
    
    return all_ok

def check_scripts():
    """Verifica gli script Lua"""
    print_info("Controllo script Lua...")
    
    scripts_dir = Path("Scripts")
    if not scripts_dir.exists():
        print_error("Directory Scripts non trovata")
        return False
    
    lua_files = list(scripts_dir.glob("*.lua"))
    if not lua_files:
        print_warning("Nessuno script Lua trovato")
        return False
    
    print_success(f"Trovati {len(lua_files)} script Lua:")
    for lua_file in lua_files:
        print(f"  - {lua_file.name}")
    
    return True

def create_launcher():
    """Crea uno script launcher per Windows"""
    print_info("Creazione launcher...")
    
    launcher_content = """@echo off
echo ========================================
echo WhereWindsMeet Lua Frida Injector
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

REM Avvia il loader
echo [*] Avvio Frida Gadget Loader...
echo [*] Assicurati che il gioco sia già avviato!
echo.
python Loader_gadget.py

pause
"""
    
    launcher_path = Path("start_injector.bat")
    with open(launcher_path, 'w', encoding='utf-8') as f:
        f.write(launcher_content)
    
    print_success("Launcher creato: start_injector.bat")
    return True

def print_summary():
    """Stampa un riepilogo finale"""
    print_header("SETUP COMPLETATO")
    
    print("Il progetto è stato configurato con successo!\n")
    
    print(f"{Colors.BOLD}Prossimi passi:{Colors.ENDC}")
    print("1. Copia dinput8.dll nella cartella del gioco (accanto a wwm.exe)")
    print("2. Avvia il gioco (Where Winds Meet)")
    print("3. Esegui start_injector.bat (o python Loader_gadget.py)")
    print("4. Premi il tasto '1' per iniettare gli script Lua\n")
    
    print(f"{Colors.BOLD}Script disponibili:{Colors.ENDC}")
    print("  - Test.lua: Script di test base (debug flags)")
    print("  - ESP_Objects.lua: ESP per oggetti rilevanti")
    print("  - Advanced_Features.lua: Feature avanzate (speed, teleport, god mode)")
    print("  - Debug_console.lua: Abilita console debug")
    print("  - Dump_env.lua: Dump completo dell'ambiente Lua")
    print("  - Trace_call.lua: Trace delle chiamate di funzione\n")
    
    print(f"{Colors.BOLD}Comandi utili (in-game dopo injection):{Colors.ENDC}")
    print("  - print_esp_help(): Aiuto per ESP")
    print("  - start_esp(): Attiva ESP")
    print("  - print_features_help(): Aiuto per feature avanzate")
    print("  - get_player_info(): Info sul player\n")
    
    print(f"{Colors.WARNING}ATTENZIONE:{Colors.ENDC}")
    print("  - Questo tool è solo per scopi educativi")
    print("  - L'uso in multiplayer può risultare in ban")
    print("  - Usa a tuo rischio e pericolo\n")

def main():
    """Funzione principale"""
    print_header("WhereWindsMeet Lua Frida Injector - Setup")
    
    # Verifica Python
    if not check_python_version():
        return 1
    
    # Verifica pip
    if not check_pip():
        print_error("pip è richiesto per continuare")
        return 1
    
    # Verifica/Installa Frida
    if not check_frida():
        print_error("Frida è richiesto per continuare")
        return 1
    
    # Crea directory
    if not create_directories():
        print_error("Errore durante la creazione delle directory")
        return 1
    
    # Verifica file
    if not check_files():
        print_warning("Alcuni file necessari sono mancanti")
        response = input("Vuoi continuare comunque? (s/n): ").lower()
        if response != 's':
            return 1
    
    # Verifica script
    check_scripts()
    
    # Configura progetto
    if not configure_project():
        print_error("Errore durante la configurazione")
        return 1
    
    # Crea launcher
    create_launcher()
    
    # Riepilogo
    print_summary()
    
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print(f"\n{Colors.WARNING}Setup interrotto dall'utente{Colors.ENDC}")
        sys.exit(1)
    except Exception as e:
        print_error(f"Errore inaspettato: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
