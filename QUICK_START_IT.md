# 🚀 Guida Rapida - WhereWindsMeet Lua Injector v2.0

## ⚡ Setup in 5 Minuti

### 1️⃣ Installa Python
- Scarica Python 3.7+ da [python.org](https://www.python.org/)
- Durante l'installazione, **seleziona "Add Python to PATH"**

### 2️⃣ Setup Automatico
```bash
# Apri PowerShell o CMD nella cartella del progetto
python setup.py
```
Il setup installerà automaticamente Frida e configurerà tutto.

### 3️⃣ Copia DLL nel Gioco
Copia `dinput8.dll` nella cartella del gioco (dove si trova `wwm.exe`):
```
<Cartella Gioco>\wwm.exe
<Cartella Gioco>\dinput8.dll  ← Copia qui
```

### 4️⃣ Avvia
1. **Avvia il gioco** (Where Winds Meet)
2. **Doppio click** su `start_injector.bat`
3. **Premi `1`** quando sei in gioco per iniettare

---

## 🎮 Comandi Principali

### Dopo l'Injection

```lua
-- AIUTO
print_loader_help()      -- Aiuto generale
print_features_help()    -- Aiuto feature avanzate
print_esp_help()         -- Aiuto ESP

-- INFO PLAYER
get_player_info()        -- Mostra info sul tuo personaggio

-- ESP (Visualizza Oggetti)
load_script_by_name("ESP Objects")  -- Carica ESP
start_esp()              -- Attiva ESP
stop_esp()               -- Disattiva ESP

-- VELOCITÀ
set_speed_multiplier(2.0)  -- 2x velocità
reset_speed()              -- Normale

-- SALTO
set_jump_multiplier(3.0)   -- 3x salto
reset_jump()               -- Normale

-- GOD MODE
enable_god_mode()          -- Invincibilità ON
disable_god_mode()         -- Invincibilità OFF

-- TELEPORT
save_position("casa")      -- Salva posizione
teleport_to_saved("casa")  -- Torna a casa
list_saved_positions()     -- Lista posizioni

-- STAMINA
enable_infinite_stamina()  -- Stamina infinita
disable_infinite_stamina() -- Normale
```

---

## 📋 Esempi Pratici

### Esempio 1: Esplorazione Veloce
```lua
-- Velocità 3x + salto alto + no danno caduta
set_speed_multiplier(3.0)
set_jump_multiplier(2.5)
enable_no_fall_damage()
```

### Esempio 2: Farming Sicuro
```lua
-- God mode + velocità + ESP
enable_god_mode()
set_speed_multiplier(2.0)
load_script_by_name("ESP Objects")
start_esp()
```

### Esempio 3: Salva Posizioni Importanti
```lua
-- Salva posizioni chiave
save_position("città")
save_position("dungeon")
save_position("boss")

-- Teletrasporta rapidamente
teleport_to_saved("città")
```

---

## 🔧 Personalizzazione

### Cambia Script di Avvio

Modifica `hook.js` (riga 10):
```javascript
const TEST_PATH = "C:\\temp\\Where Winds Meet\\Scripts\\Loader_All.lua";
```

### Configura ESP

In `config.json`:
```json
"esp": {
  "enabled": true,
  "auto_start": true,
  "max_distance": 150,
  "categories": {
    "npcs": true,
    "enemies": true,
    "items": true
  }
}
```

### Auto-Start Features

In `Scripts/Loader_All.lua`, cambia `auto_load` e `auto_start`:
```lua
{
  name = "ESP Objects",
  file = "ESP_Objects.lua",
  auto_load = true,   -- Carica automaticamente
  auto_start = true,  -- Avvia automaticamente
}
```

---

## ❓ Problemi Comuni

### "Python non trovato"
- Reinstalla Python e seleziona "Add to PATH"
- Riavvia il terminale

### "Frida non si connette"
- Assicurati che il gioco sia avviato
- Verifica che `dinput8.dll` sia nella cartella del gioco
- Prova a cambiare porta in `config.json`

### "Injection non funziona"
- Premi `1` **dopo** che il gioco ha caricato
- Alcuni script vanno iniettati **durante** il caricamento
- Riavvia il gioco e riprova

### "Script danno errori"
- Controlla i log in `frida_hook_log.json`
- Verifica i percorsi negli script
- Alcuni comandi potrebbero non funzionare in tutte le versioni del gioco

---

## ⚠️ Importante

- ❌ **NON usare in multiplayer** (rischio ban)
- ✅ Usa solo in single-player o modalità offline
- 💾 Fai backup dei salvataggi prima di usare
- 🔒 Questo tool è solo per scopi educativi

---

## 📚 Documentazione Completa

Per maggiori dettagli, consulta:
- `README_IT.md` - Documentazione completa in italiano
- `README.md` - Documentazione originale in inglese

---

## 🎯 Prossimi Passi

1. ✅ Completa il setup
2. ✅ Prova i comandi base
3. 📖 Leggi `README_IT.md` per feature avanzate
4. 🎮 Divertiti responsabilmente!

---

**Buon divertimento! 🎮✨**
