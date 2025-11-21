-- Advanced_Features.lua
-- Feature avanzate per Where Winds Meet
-- Include: teleport, speed hack, no clip, infinite stamina, ecc.

-- ========= CONFIGURAZIONE =========
local FEATURES = {
  speed_multiplier = 1.0,
  jump_multiplier = 1.0,
  infinite_stamina = false,
  no_fall_damage = false,
  infinite_health = false,
  auto_loot = false,
  teleport_enabled = false,
}

-- ========= UTILITY FUNCTIONS =========
local function safe_get(tbl, ...)
  local current = tbl
  for _, key in ipairs({...}) do
    if type(current) ~= "table" then
      return nil
    end
    current = rawget(current, key)
    if current == nil then
      return nil
    end
  end
  return current
end

local function get_player()
  local network = safe_get(package.loaded, "hexm.client.net.network")
  if network and type(network.get_avatar) == "function" then
    local ok, avatar = pcall(network.get_avatar, network)
    if ok then
      return avatar
    end
  end
  return nil
end

-- ========= SPEED HACK =========
local original_speed = nil

local function set_speed_multiplier(multiplier)
  if type(multiplier) ~= "number" or multiplier <= 0 then
    print("[SPEED] Errore: moltiplicatore deve essere un numero positivo")
    return false
  end
  
  local player = get_player()
  if not player then
    print("[SPEED] Errore: impossibile trovare il player")
    return false
  end
  
  -- Salva velocità originale se non già salvata
  if not original_speed and type(player.get_move_speed) == "function" then
    local ok, speed = pcall(player.get_move_speed, player)
    if ok then
      original_speed = speed
    end
  end
  
  -- Imposta nuova velocità
  if type(player.set_move_speed) == "function" then
    local base_speed = original_speed or 5.0
    local new_speed = base_speed * multiplier
    local ok = pcall(player.set_move_speed, player, new_speed)
    if ok then
      FEATURES.speed_multiplier = multiplier
      print(string.format("[SPEED] Velocità impostata a %.1fx (%.2f)", multiplier, new_speed))
      return true
    end
  end
  
  print("[SPEED] Errore: impossibile modificare la velocità")
  return false
end

local function reset_speed()
  return set_speed_multiplier(1.0)
end

-- ========= JUMP HACK =========
local original_jump = nil

local function set_jump_multiplier(multiplier)
  if type(multiplier) ~= "number" or multiplier <= 0 then
    print("[JUMP] Errore: moltiplicatore deve essere un numero positivo")
    return false
  end
  
  local player = get_player()
  if not player then
    print("[JUMP] Errore: impossibile trovare il player")
    return false
  end
  
  -- Salva jump originale
  if not original_jump and type(player.get_jump_height) == "function" then
    local ok, jump = pcall(player.get_jump_height, player)
    if ok then
      original_jump = jump
    end
  end
  
  -- Imposta nuovo jump
  if type(player.set_jump_height) == "function" then
    local base_jump = original_jump or 2.0
    local new_jump = base_jump * multiplier
    local ok = pcall(player.set_jump_height, player, new_jump)
    if ok then
      FEATURES.jump_multiplier = multiplier
      print(string.format("[JUMP] Salto impostato a %.1fx (%.2f)", multiplier, new_jump))
      return true
    end
  end
  
  print("[JUMP] Errore: impossibile modificare il salto")
  return false
end

local function reset_jump()
  return set_jump_multiplier(1.0)
end

-- ========= INFINITE STAMINA =========
local stamina_hook_active = false

local function enable_infinite_stamina()
  local player = get_player()
  if not player then
    print("[STAMINA] Errore: impossibile trovare il player")
    return false
  end
  
  -- Prova a impostare stamina al massimo
  if type(player.set_stamina) == "function" and type(player.get_max_stamina) == "function" then
    local ok, max_stamina = pcall(player.get_max_stamina, player)
    if ok then
      pcall(player.set_stamina, player, max_stamina)
      FEATURES.infinite_stamina = true
      stamina_hook_active = true
      print("[STAMINA] Stamina infinita attivata!")
      return true
    end
  end
  
  print("[STAMINA] Errore: impossibile attivare stamina infinita")
  return false
end

local function disable_infinite_stamina()
  stamina_hook_active = false
  FEATURES.infinite_stamina = false
  print("[STAMINA] Stamina infinita disattivata!")
  return true
end

-- ========= NO FALL DAMAGE =========
local function enable_no_fall_damage()
  local player = get_player()
  if not player then
    print("[FALL] Errore: impossibile trovare il player")
    return false
  end
  
  -- Cerca il sistema di danno da caduta
  local combat_module = safe_get(package.loaded, "hexm.client.entities.local.component.combat")
  if combat_module then
    -- Prova a disabilitare fall damage
    if type(player.set_fall_damage_enabled) == "function" then
      local ok = pcall(player.set_fall_damage_enabled, player, false)
      if ok then
        FEATURES.no_fall_damage = true
        print("[FALL] Danno da caduta disabilitato!")
        return true
      end
    end
  end
  
  print("[FALL] Errore: impossibile disabilitare danno da caduta")
  return false
end

local function disable_no_fall_damage()
  local player = get_player()
  if player and type(player.set_fall_damage_enabled) == "function" then
    pcall(player.set_fall_damage_enabled, player, true)
  end
  FEATURES.no_fall_damage = false
  print("[FALL] Danno da caduta riabilitato!")
  return true
end

-- ========= TELEPORT =========
local saved_positions = {}

local function save_position(name)
  name = name or "default"
  
  local player = get_player()
  if not player then
    print("[TP] Errore: impossibile trovare il player")
    return false
  end
  
  local pos = nil
  if type(player.get_position) == "function" then
    local ok, p = pcall(player.get_position, player)
    if ok then
      pos = p
    end
  end
  
  if not pos then
    print("[TP] Errore: impossibile ottenere la posizione")
    return false
  end
  
  saved_positions[name] = {
    x = pos.x or pos[1] or 0,
    y = pos.y or pos[2] or 0,
    z = pos.z or pos[3] or 0,
  }
  
  print(string.format("[TP] Posizione '%s' salvata: (%.2f, %.2f, %.2f)", 
    name, saved_positions[name].x, saved_positions[name].y, saved_positions[name].z))
  return true
end

local function teleport_to_saved(name)
  name = name or "default"
  
  local pos = saved_positions[name]
  if not pos then
    print(string.format("[TP] Errore: posizione '%s' non trovata", name))
    return false
  end
  
  return teleport_to(pos.x, pos.y, pos.z)
end

local function teleport_to(x, y, z)
  local player = get_player()
  if not player then
    print("[TP] Errore: impossibile trovare il player")
    return false
  end
  
  if type(player.set_position) == "function" then
    local ok = pcall(player.set_position, player, {x=x, y=y, z=z})
    if ok then
      print(string.format("[TP] Teletrasportato a: (%.2f, %.2f, %.2f)", x, y, z))
      return true
    end
  end
  
  print("[TP] Errore: impossibile teletrasportare")
  return false
end

local function list_saved_positions()
  print("\n========== POSIZIONI SALVATE ==========")
  local count = 0
  for name, pos in pairs(saved_positions) do
    print(string.format("  %s: (%.2f, %.2f, %.2f)", name, pos.x, pos.y, pos.z))
    count = count + 1
  end
  if count == 0 then
    print("  Nessuna posizione salvata")
  end
  print("=======================================\n")
end

-- ========= GOD MODE =========
local god_mode_active = false

local function enable_god_mode()
  -- Usa il comando GM interno se disponibile
  local gm_combat = safe_get(package.loaded, "hexm.client.debug.gm.gm_commands.gm_combat")
  if gm_combat and type(gm_combat.gm_set_invincible) == "function" then
    local ok = pcall(gm_combat.gm_set_invincible, 1)
    if ok then
      god_mode_active = true
      FEATURES.infinite_health = true
      print("[GOD] God Mode attivato! (invincibilità)")
      return true
    end
  end
  
  print("[GOD] Errore: impossibile attivare God Mode")
  return false
end

local function disable_god_mode()
  local gm_combat = safe_get(package.loaded, "hexm.client.debug.gm.gm_commands.gm_combat")
  if gm_combat and type(gm_combat.gm_set_invincible) == "function" then
    pcall(gm_combat.gm_set_invincible)
  end
  god_mode_active = false
  FEATURES.infinite_health = false
  print("[GOD] God Mode disattivato!")
  return true
end

-- ========= HELP =========
local function print_features_help()
  print([[
========== ADVANCED FEATURES HELP ==========
Comandi disponibili:

VELOCITÀ:
  set_speed_multiplier(x)  - Imposta velocità (es: 2.0 = 2x)
  reset_speed()            - Ripristina velocità normale

SALTO:
  set_jump_multiplier(x)   - Imposta altezza salto (es: 3.0 = 3x)
  reset_jump()             - Ripristina salto normale

STAMINA:
  enable_infinite_stamina()  - Attiva stamina infinita
  disable_infinite_stamina() - Disattiva stamina infinita

DANNO DA CADUTA:
  enable_no_fall_damage()    - Disabilita danno da caduta
  disable_no_fall_damage()   - Riabilita danno da caduta

TELEPORT:
  save_position("nome")      - Salva posizione corrente
  teleport_to_saved("nome")  - Teletrasporta a posizione salvata
  teleport_to(x, y, z)       - Teletrasporta a coordinate
  list_saved_positions()     - Lista posizioni salvate

GOD MODE:
  enable_god_mode()          - Attiva invincibilità
  disable_god_mode()         - Disattiva invincibilità

UTILITY:
  print_features_help()      - Mostra questo aiuto
  get_player_info()          - Mostra info sul player

Esempi:
  set_speed_multiplier(2.5)  -- Velocità 2.5x
  save_position("casa")      -- Salva posizione "casa"
  teleport_to_saved("casa")  -- Torna a casa
  enable_god_mode()          -- Attiva invincibilità
============================================
]])
end

local function get_player_info()
  local player = get_player()
  if not player then
    print("[INFO] Impossibile trovare il player")
    return
  end
  
  print("\n========== PLAYER INFO ==========")
  
  -- Nome
  if type(player.get_name) == "function" then
    local ok, name = pcall(player.get_name, player)
    if ok then
      print("Nome: " .. tostring(name))
    end
  end
  
  -- Posizione
  if type(player.get_position) == "function" then
    local ok, pos = pcall(player.get_position, player)
    if ok and pos then
      local x = pos.x or pos[1] or 0
      local y = pos.y or pos[2] or 0
      local z = pos.z or pos[3] or 0
      print(string.format("Posizione: (%.2f, %.2f, %.2f)", x, y, z))
    end
  end
  
  -- HP
  if type(player.get_hp) == "function" and type(player.get_max_hp) == "function" then
    local ok1, hp = pcall(player.get_hp, player)
    local ok2, max_hp = pcall(player.get_max_hp, player)
    if ok1 and ok2 then
      print(string.format("HP: %d / %d (%.1f%%)", hp, max_hp, (hp/max_hp)*100))
    end
  end
  
  -- Stamina
  if type(player.get_stamina) == "function" and type(player.get_max_stamina) == "function" then
    local ok1, stamina = pcall(player.get_stamina, player)
    local ok2, max_stamina = pcall(player.get_max_stamina, player)
    if ok1 and ok2 then
      print(string.format("Stamina: %d / %d (%.1f%%)", stamina, max_stamina, (stamina/max_stamina)*100))
    end
  end
  
  -- Livello
  if type(player.get_level) == "function" then
    local ok, level = pcall(player.get_level, player)
    if ok then
      print("Livello: " .. tostring(level))
    end
  end
  
  -- Features attive
  print("\nFeatures attive:")
  print("  Speed: " .. FEATURES.speed_multiplier .. "x")
  print("  Jump: " .. FEATURES.jump_multiplier .. "x")
  print("  Infinite Stamina: " .. tostring(FEATURES.infinite_stamina))
  print("  No Fall Damage: " .. tostring(FEATURES.no_fall_damage))
  print("  God Mode: " .. tostring(god_mode_active))
  
  print("=================================\n")
end

-- ========= ESPORTA FUNZIONI GLOBALI =========
rawset(_G, "set_speed_multiplier", set_speed_multiplier)
rawset(_G, "reset_speed", reset_speed)
rawset(_G, "set_jump_multiplier", set_jump_multiplier)
rawset(_G, "reset_jump", reset_jump)
rawset(_G, "enable_infinite_stamina", enable_infinite_stamina)
rawset(_G, "disable_infinite_stamina", disable_infinite_stamina)
rawset(_G, "enable_no_fall_damage", enable_no_fall_damage)
rawset(_G, "disable_no_fall_damage", disable_no_fall_damage)
rawset(_G, "save_position", save_position)
rawset(_G, "teleport_to_saved", teleport_to_saved)
rawset(_G, "teleport_to", teleport_to)
rawset(_G, "list_saved_positions", list_saved_positions)
rawset(_G, "enable_god_mode", enable_god_mode)
rawset(_G, "disable_god_mode", disable_god_mode)
rawset(_G, "print_features_help", print_features_help)
rawset(_G, "get_player_info", get_player_info)

-- ========= INIT =========
print("[FEATURES] Advanced Features caricato con successo!")
print("[FEATURES] Usa print_features_help() per vedere i comandi disponibili")
