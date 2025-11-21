# WhereWindsMeet-Lua-Frida-Injector v2.0

**Injector Lua avanzato per _Where Winds Meet_ (PC)** con supporto per ESP, feature avanzate e debug completo.

## 🎯 Caratteristiche

### ✨ Nuove Feature v2.0
- **ESP (Extra Sensory Perception)**: Visualizza oggetti rilevanti nel gioco
  - NPC, nemici, items, risorse, chest, oggetti quest
  - Filtri configurabili per categoria
  - Visualizzazione distanza, livello, HP
  - Aggiornamento in tempo reale

- **Feature Avanzate**:
  - Speed Hack (moltiplicatore velocità)
  - Jump Hack (moltiplicatore salto)
  - Infinite Stamina
  - No Fall Damage
  - God Mode (invincibilità)
  - Teleport System (salva/carica posizioni)

- **Sistema di Configurazione**:
  - File config.json centralizzato
  - Setup automatico con script Python
  - Launcher Windows integrato

### 🔧 Feature Originali
- Proxy DLL (`dinput8.dll`) per injection automatica
- Hook di `lua_load` e `lua_pcall` tramite Frida
- Script Lua personalizzabili
- Debug console e GM menu
- Dump completo dell'ambiente Lua
- Trace delle chiamate di funzione
- Traduzione automatica menu GM

---

## 📋 Requisiti

- **OS**: Windows x64
- **Gioco**: Where Winds Meet (PC)
- **Python**: 3.7+ ([Download](https://www.python.org/))
- **Moduli Python**:
  - `frida` (installato automaticamente dal setup)
  - `frida-tools` (opzionale ma consigliato)

---

## 🚀 Installazione Rapida

### 1. Setup Automatico

```bash
# Clona o scarica il progetto
cd WhereWindsMeet-Lua-Frida-Injector

# Esegui il setup automatico
python setup.py
```

Il setup verificherà:
- ✓ Versione Python
- ✓ Installazione pip
- ✓ Installazione Frida (con installazione automatica se mancante)
- ✓ Creazione directory necessarie
- ✓ Verifica file del progetto
- ✓ Configurazione interattiva

### 2. Copia DLL nel Gioco

Copia `dinput8.dll` nella cartella del gioco (accanto a `wwm.exe`):

```
<Cartella Gioco>\wwm.exe
<Cartella Gioco>\dinput8.dll  <-- Copia qui
```

### 3. Avvia il Gioco

Avvia normalmente Where Winds Meet e attendi che il processo `wwm.exe` sia attivo.

### 4. Avvia l'Injector

**Metodo 1 - Launcher (Consigliato)**:
```bash
# Doppio click su:
start_injector.bat
```

**Metodo 2 - Manuale**:
```bash
python Loader_gadget.py
```

### 5. Inietta Script

Quando l'injector è connesso:
- Premi il tasto **`1`** (riga numerica superiore)
- Gli script verranno iniettati al prossimo `lua_pcall`
- Controlla la console per conferma

---

## 📁 Struttura Progetto

```
WhereWindsMeet-Lua-Frida-Injector/
│
├── Scripts/                          # Script Lua
│   ├── Test.lua                      # Entry point (debug flags)
│   ├── ESP_Objects.lua               # ⭐ ESP per oggetti
│   ├── Advanced_Features.lua         # ⭐ Feature avanzate
│   ├── Debug_console.lua             # Console debug
│   ├── Dump_env.lua                  # Dump ambiente completo
│   ├── Dump_TF_values.lua            # Dump valori booleani
│   ├── Trace_call.lua                # Trace chiamate funzioni
│   ├── gm_dict_translation.lua       # Dizionario traduzioni
│   └── gm_menu_translator.lua        # Traduttore menu GM
│
├── Logs/                             # Log generati
├── Backups/                          # Backup configurazioni
├── Config/                           # Configurazioni extra
│
├── dinput8.dll                       # Proxy DLL (da copiare nel gioco)
├── frida-gadget.dll                  # Frida Gadget binary
├── frida-gadget.config               # Configurazione Gadget
├── hook.js                           # Script Frida JS
├── Loader_gadget.py                  # Loader Python
├── setup.py                          # ⭐ Setup automatico
├── config.json                       # ⭐ Configurazione centralizzata
├── start_injector.bat                # ⭐ Launcher Windows
│
├── README.md                         # Documentazione inglese
└── README_IT.md                      # ⭐ Documentazione italiana
```

---

## 🎮 Utilizzo

### ESP (Extra Sensory Perception)

Dopo l'injection, usa questi comandi nella console Lua:

```lua
-- Mostra aiuto ESP
print_esp_help()

-- Attiva ESP
start_esp()

-- Disattiva ESP
stop_esp()

-- Toggle ESP
toggle_esp()

-- Aggiorna manualmente
render_esp()

-- Configura ESP
configure_esp({
  show_npcs = true,
  show_enemies = true,
  show_items = true,
  max_distance = 150,
  update_interval = 1.0
})
```

**Categorie ESP**:
- 🟡 **NPC** (Giallo): Personaggi non giocanti
- 🔴 **Nemici** (Rosso): Creature ostili
- 🟢 **Items** (Verde): Oggetti raccoglibili
- 🔵 **Risorse** (Ciano): Materiali e risorse
- 🟠 **Chest** (Arancione): Forzieri e contenitori
- 🟣 **Quest** (Magenta): Oggetti di quest

### Feature Avanzate

```lua
-- Mostra aiuto
print_features_help()

-- Info player
get_player_info()

-- VELOCITÀ
set_speed_multiplier(2.0)  -- 2x velocità
reset_speed()              -- Ripristina normale

-- SALTO
set_jump_multiplier(3.0)   -- 3x altezza salto
reset_jump()               -- Ripristina normale

-- STAMINA
enable_infinite_stamina()  -- Stamina infinita
disable_infinite_stamina() -- Disattiva

-- DANNO DA CADUTA
enable_no_fall_damage()    -- Nessun danno da caduta
disable_no_fall_damage()   -- Riattiva danno

-- TELEPORT
save_position("casa")      -- Salva posizione corrente
teleport_to_saved("casa")  -- Teletrasporta a "casa"
teleport_to(100, 50, 200)  -- Teletrasporta a coordinate
list_saved_positions()     -- Lista posizioni salvate

-- GOD MODE
enable_god_mode()          -- Invincibilità
disable_god_mode()         -- Disattiva
```

### Debug e GM

```lua
-- Abilita flag debug (già in Test.lua)
-- DEBUG, ENABLE_DEBUG_PRINT, FORCE_OPEN_DEBUG_SHORTCUT, ecc.

-- God Mode tramite GM interno
package.loaded["hexm.client.debug.gm.gm_commands.gm_combat"].gm_set_invincible(1)  -- ON
package.loaded["hexm.client.debug.gm.gm_commands.gm_combat"].gm_set_invincible()   -- OFF
```

---

## ⚙️ Configurazione

### config.json

Modifica `config.json` per personalizzare il comportamento:

```json
{
  "paths": {
    "project_root": "C:\\temp\\Where Winds Meet",
    "game_exe": "wwm.exe"
  },
  
  "frida": {
    "host": "127.0.0.1",
    "port": 27042,
    "timeout": 30
  },
  
  "injection": {
    "hotkey": "1",
    "entry_script": "Test.lua",
    "auto_inject": false
  },
  
  "features": {
    "esp": {
      "enabled": false,
      "auto_start": false,
      "max_distance": 100
    },
    "advanced": {
      "speed_hack": false,
      "god_mode": false
    }
  }
}
```

### Script Entry Point

Modifica `Scripts/Test.lua` per cambiare cosa viene eseguito all'injection:

```lua
-- Esempio: Carica ESP e feature avanzate
dofile([[C:\temp\Where Winds Meet\Scripts\ESP_Objects.lua]])
dofile([[C:\temp\Where Winds Meet\Scripts\Advanced_Features.lua]])

-- Auto-start ESP
start_esp()

-- Auto-enable God Mode
enable_god_mode()

print("[INIT] Setup completato!")
```

---

## 🔍 Troubleshooting

### Frida non si connette

```bash
# Verifica che il gioco sia avviato
tasklist | findstr wwm.exe

# Verifica che Frida Gadget sia caricato
# Controlla i log in frida_hook_log.json

# Prova a cambiare porta in config.json
"port": 27043
```

### Injection non funziona

- ⚠️ Assicurati di premere `1` **dopo** che il gioco ha caricato il Lua
- ⚠️ Alcuni script devono essere iniettati **prima** della fine del caricamento
- ⚠️ Riavvia il gioco e prova a iniettare prima

### Script Lua danno errori

```lua
-- Controlla i log
-- C:\temp\Where Winds Meet\frida_hook_log.json

-- Verifica che i percorsi siano corretti
-- Modifica i path negli script se necessario
```

### DLL non viene caricata

- Verifica che `dinput8.dll` sia nella **stessa cartella** di `wwm.exe`
- Verifica che `frida-gadget.dll` sia in `C:\temp\Where Winds Meet\`
- Controlla i permessi dei file

---

## 🛠️ Sviluppo

### Creare Nuovi Script

1. Crea un nuovo file `.lua` in `Scripts/`
2. Usa le utility functions:

```lua
-- Safe get da tabelle
local function safe_get(tbl, ...)
  local current = tbl
  for _, key in ipairs({...}) do
    if type(current) ~= "table" then return nil end
    current = rawget(current, key)
    if current == nil then return nil end
  end
  return current
end

-- Ottieni player
local function get_player()
  local network = safe_get(package.loaded, "hexm.client.net.network")
  if network and type(network.get_avatar) == "function" then
    local ok, avatar = pcall(network.get_avatar, network)
    if ok then return avatar end
  end
  return nil
end

-- Esporta funzioni globali
rawset(_G, "my_function", my_function)
```

3. Carica lo script da `Test.lua`:

```lua
dofile([[C:\temp\Where Winds Meet\Scripts\MioScript.lua]])
```

### Modificare hook.js

Per cambiare il comportamento dell'injection, modifica `hook.js`:

```javascript
// Cambia hotkey
const HOTKEY_VK = 0x32; // key '2'

// Cambia script entry point
const TEST_PATH = "C:\\temp\\Where Winds Meet\\Scripts\\MioScript.lua";

// Aggiungi nuove signature
const SIG_MY_FUNCTION = "48 89 5C 24 10 ...";
```

---

## ⚠️ Disclaimer

- **Solo scopi educativi e di ricerca**
- L'uso di questo tool può violare i Terms of Service del gioco
- L'uso in multiplayer può risultare in **ban permanente**
- Gli autori non sono responsabili per l'uso improprio
- **Usa a tuo rischio e pericolo**

---

## 📝 Changelog

### v2.0.0 (Corrente)
- ✨ Aggiunto ESP completo per oggetti rilevanti
- ✨ Aggiunte feature avanzate (speed, jump, teleport, god mode)
- ✨ Sistema di configurazione centralizzato (config.json)
- ✨ Setup automatico con script Python
- ✨ Launcher Windows integrato
- ✨ Documentazione italiana completa
- 🔧 Migliorata gestione errori
- 🔧 Ottimizzato sistema di logging
- 📚 Aggiunti esempi e guide

### v1.0.0 (Originale)
- Injection base tramite Frida Gadget
- Hook lua_load e lua_pcall
- Script debug console
- Dump ambiente Lua
- Trace chiamate funzioni
- Traduttore menu GM

---

## 🤝 Contributi

Contributi, bug report e feature request sono benvenuti!

1. Fork del progetto
2. Crea un branch per la tua feature (`git checkout -b feature/AmazingFeature`)
3. Commit delle modifiche (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Apri una Pull Request

---

## 📄 Licenza

Questo progetto è distribuito per **scopi educativi e di ricerca**.

---

## 🙏 Ringraziamenti

- Frida Project per l'eccellente framework
- Community di Where Winds Meet per il supporto
- Tutti i contributor del progetto

---

## 📞 Supporto

Per domande, problemi o suggerimenti:
- Apri una Issue su GitHub
- Consulta la documentazione
- Controlla la sezione Troubleshooting

---

**Buon divertimento e ricorda: usa responsabilmente! 🎮**
