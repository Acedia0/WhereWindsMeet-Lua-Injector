-- Loader_All.lua
-- Carica tutti gli script disponibili in modo organizzato
-- Usa questo come entry point per avere tutte le feature disponibili

print("\n" .. string.rep("=", 60))
print("WhereWindsMeet Lua Injector v2.0 - Loader Completo")
print(string.rep("=", 60) .. "\n")

-- ========= CONFIGURAZIONE =========
local BASE_PATH = [[C:\temp\Where Winds Meet\Scripts\]]

local SCRIPTS = {
  -- Debug e utility (sempre caricati)
  {
    name = "Debug Console",
    file = "Debug_console.lua",
    auto_load = true,
    description = "Abilita flag debug e console GM"
  },
  
  -- Feature principali (opzionali)
  {
    name = "ESP Objects",
    file = "ESP_Objects.lua",
    auto_load = false,
    auto_start = false,
    description = "ESP per visualizzare oggetti rilevanti"
  },
  {
    name = "Advanced Features",
    file = "Advanced_Features.lua",
    auto_load = true,
    auto_start = false,
    description = "Speed hack, teleport, god mode, ecc."
  },
  
  -- Utility avanzate (su richiesta)
  {
    name = "GM Menu Translator",
    file = "gm_menu_translator.lua",
    auto_load = false,
    description = "Traduce il menu GM in inglese"
  },
  {
    name = "Trace Calls",
    file = "Trace_call.lua",
    auto_load = false,
    description = "Trace delle chiamate di funzione (performance intensive)"
  },
  {
    name = "Dump Environment",
    file = "Dump_env.lua",
    auto_load = false,
    description = "Dump completo dell'ambiente Lua"
  },
}

-- ========= UTILITY =========
local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function load_script(script_info)
  local full_path = BASE_PATH .. script_info.file
  
  if not file_exists(full_path) then
    print(string.format("[✗] File non trovato: %s", script_info.file))
    return false
  end
  
  print(string.format("[*] Caricamento: %s", script_info.name))
  
  local ok, err = pcall(function()
    dofile(full_path)
  end)
  
  if ok then
    print(string.format("[✓] %s caricato con successo", script_info.name))
    return true
  else
    print(string.format("[✗] Errore nel caricamento di %s:", script_info.name))
    print(string.format("    %s", tostring(err)))
    return false
  end
end

-- ========= CARICAMENTO AUTOMATICO =========
local loaded_count = 0
local failed_count = 0

print("Caricamento script...\n")

for _, script_info in ipairs(SCRIPTS) do
  if script_info.auto_load then
    if load_script(script_info) then
      loaded_count = loaded_count + 1
      
      -- Auto-start se richiesto
      if script_info.auto_start then
        if script_info.name == "ESP Objects" and _G.start_esp then
          print("[*] Auto-start ESP...")
          start_esp()
        end
      end
    else
      failed_count = failed_count + 1
    end
  else
    print(string.format("[○] %s (non caricato automaticamente)", script_info.name))
  end
end

print(string.format("\n[✓] Caricati: %d | [✗] Falliti: %d\n", loaded_count, failed_count))

-- ========= FUNZIONI DI GESTIONE =========
local function list_available_scripts()
  print("\n" .. string.rep("=", 60))
  print("SCRIPT DISPONIBILI")
  print(string.rep("=", 60) .. "\n")
  
  for i, script_info in ipairs(SCRIPTS) do
    local status = script_info.auto_load and "[CARICATO]" or "[NON CARICATO]"
    print(string.format("%d. %s %s", i, status, script_info.name))
    print(string.format("   %s", script_info.description))
    print(string.format("   File: %s\n", script_info.file))
  end
  
  print(string.rep("=", 60) .. "\n")
end

local function load_script_by_index(index)
  if type(index) ~= "number" or index < 1 or index > #SCRIPTS then
    print("[✗] Indice non valido")
    return false
  end
  
  local script_info = SCRIPTS[index]
  return load_script(script_info)
end

local function load_script_by_name(name)
  for _, script_info in ipairs(SCRIPTS) do
    if string.lower(script_info.name) == string.lower(name) or
       string.lower(script_info.file) == string.lower(name) then
      return load_script(script_info)
    end
  end
  
  print(string.format("[✗] Script '%s' non trovato", name))
  return false
end

local function print_loader_help()
  print([[
========== LOADER HELP ==========
Comandi disponibili:

  list_scripts()           - Lista tutti gli script disponibili
  load_script_by_index(n)  - Carica script per indice (1-N)
  load_script_by_name(s)   - Carica script per nome
  print_loader_help()      - Mostra questo aiuto

Script già caricati:
  - Debug Console: flag debug abilitati
  - Advanced Features: usa print_features_help()
  
Script opzionali (carica manualmente):
  - ESP Objects: load_script_by_name("ESP Objects")
  - GM Translator: load_script_by_name("GM Menu Translator")
  - Trace Calls: load_script_by_name("Trace Calls")
  - Dump Env: load_script_by_name("Dump Environment")

Esempi:
  list_scripts()                    -- Lista script
  load_script_by_index(2)           -- Carica ESP
  load_script_by_name("ESP Objects") -- Carica ESP per nome
  
Dopo aver caricato ESP:
  print_esp_help()                  -- Aiuto ESP
  start_esp()                       -- Attiva ESP

Dopo aver caricato Advanced Features:
  print_features_help()             -- Aiuto features
  get_player_info()                 -- Info player
=================================
]])
end

-- ========= ESPORTA FUNZIONI GLOBALI =========
rawset(_G, "list_scripts", list_available_scripts)
rawset(_G, "load_script_by_index", load_script_by_index)
rawset(_G, "load_script_by_name", load_script_by_name)
rawset(_G, "print_loader_help", print_loader_help)

-- ========= RIEPILOGO FINALE =========
print(string.rep("=", 60))
print("INIZIALIZZAZIONE COMPLETATA")
print(string.rep("=", 60))
print("\nComandi rapidi:")
print("  print_loader_help()    - Aiuto loader")
print("  list_scripts()         - Lista script disponibili")
print("  print_features_help()  - Aiuto feature avanzate")
print("  print_esp_help()       - Aiuto ESP (se caricato)")
print("\nScript caricati automaticamente:")
print("  ✓ Debug Console (flag debug abilitati)")
print("  ✓ Advanced Features (speed, teleport, god mode)")
print("\nPer caricare ESP:")
print("  load_script_by_name(\"ESP Objects\")")
print("  start_esp()")
print(string.rep("=", 60) .. "\n")
