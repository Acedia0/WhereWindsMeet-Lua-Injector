-- ESP_Objects.lua
-- ESP (Extra Sensory Perception) per visualizzare oggetti rilevanti nel gioco
-- Mostra NPC, items, risorse, nemici con distanza e informazioni

-- ========= CONFIGURAZIONE ESP =========
local ESP_CONFIG = {
  -- Abilita/disabilita categorie
  show_npcs = true,
  show_items = true,
  show_enemies = true,
  show_resources = true,
  show_chests = true,
  show_quest_objects = true,
  
  -- Distanza massima di visualizzazione (in metri)
  max_distance = 100,
  
  -- Filtri per nome (case-insensitive)
  npc_filter = {},  -- vuoto = mostra tutti
  item_filter = {},
  
  -- Colori per categorie (RGB 0-255)
  colors = {
    npc = {r=255, g=255, b=0},      -- Giallo
    enemy = {r=255, g=0, b=0},      -- Rosso
    item = {r=0, g=255, b=0},       -- Verde
    resource = {r=0, g=255, b=255}, -- Ciano
    chest = {r=255, g=165, b=0},    -- Arancione
    quest = {r=255, g=0, b=255},    -- Magenta
  },
  
  -- Opzioni visualizzazione
  show_distance = true,
  show_health = true,
  show_level = true,
  update_interval = 0.5, -- secondi tra aggiornamenti
}

-- ========= VARIABILI GLOBALI =========
local esp_active = false
local esp_data = {}
local last_update = 0

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
  -- Cerca il player avatar nell'ambiente di gioco
  local network = safe_get(package.loaded, "hexm.client.net.network")
  if network and type(network.get_avatar) == "function" then
    local ok, avatar = pcall(network.get_avatar, network)
    if ok then
      return avatar
    end
  end
  return nil
end

local function get_player_position()
  local player = get_player()
  if not player then
    return nil
  end
  
  -- Prova a ottenere la posizione
  if type(player.get_position) == "function" then
    local ok, pos = pcall(player.get_position, player)
    if ok and pos then
      return pos
    end
  end
  
  -- Fallback: cerca nei campi comuni
  local pos = rawget(player, "position") or rawget(player, "pos")
  return pos
end

local function calculate_distance(pos1, pos2)
  if not pos1 or not pos2 then
    return nil
  end
  
  local x1, y1, z1 = pos1.x or pos1[1] or 0, pos1.y or pos1[2] or 0, pos1.z or pos1[3] or 0
  local x2, y2, z2 = pos2.x or pos2[1] or 0, pos2.y or pos2[2] or 0, pos2.z or pos2[3] or 0
  
  local dx = x2 - x1
  local dy = y2 - y1
  local dz = z2 - z1
  
  return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function get_entity_info(entity)
  if not entity or type(entity) ~= "table" then
    return nil
  end
  
  local info = {
    name = "Unknown",
    type = "unknown",
    position = nil,
    health = nil,
    max_health = nil,
    level = nil,
    is_enemy = false,
    is_dead = false,
  }
  
  -- Nome
  if type(entity.get_name) == "function" then
    local ok, name = pcall(entity.get_name, entity)
    if ok and name then
      info.name = tostring(name)
    end
  end
  info.name = info.name or rawget(entity, "name") or rawget(entity, "entity_name") or "Unknown"
  
  -- Posizione
  if type(entity.get_position) == "function" then
    local ok, pos = pcall(entity.get_position, entity)
    if ok then
      info.position = pos
    end
  end
  info.position = info.position or rawget(entity, "position") or rawget(entity, "pos")
  
  -- Salute
  if type(entity.get_hp) == "function" then
    local ok, hp = pcall(entity.get_hp, entity)
    if ok then
      info.health = hp
    end
  end
  info.health = info.health or rawget(entity, "hp") or rawget(entity, "health")
  
  if type(entity.get_max_hp) == "function" then
    local ok, max_hp = pcall(entity.get_max_hp, entity)
    if ok then
      info.max_health = max_hp
    end
  end
  info.max_health = info.max_health or rawget(entity, "max_hp") or rawget(entity, "max_health")
  
  -- Livello
  if type(entity.get_level) == "function" then
    local ok, level = pcall(entity.get_level, entity)
    if ok then
      info.level = level
    end
  end
  info.level = info.level or rawget(entity, "level") or rawget(entity, "lv")
  
  -- Tipo e stato
  local entity_type = rawget(entity, "entity_type") or rawget(entity, "type")
  if entity_type then
    info.type = tostring(entity_type)
  end
  
  -- Controlla se è nemico
  if type(entity.is_enemy) == "function" then
    local ok, is_enemy = pcall(entity.is_enemy, entity)
    if ok then
      info.is_enemy = is_enemy
    end
  end
  
  -- Controlla se è morto
  if type(entity.is_dead) == "function" then
    local ok, is_dead = pcall(entity.is_dead, entity)
    if ok then
      info.is_dead = is_dead
    end
  end
  
  return info
end

local function get_all_entities()
  local entities = {}
  
  -- Cerca lo space/world manager
  local space_module = safe_get(package.loaded, "hexm.client.entities.local.space")
  if not space_module then
    return entities
  end
  
  -- Prova a ottenere lo space corrente
  local space = nil
  if type(space_module.get_current_space) == "function" then
    local ok, s = pcall(space_module.get_current_space, space_module)
    if ok then
      space = s
    end
  end
  
  if not space then
    return entities
  end
  
  -- Ottieni tutte le entità
  if type(space.get_entities) == "function" then
    local ok, ents = pcall(space.get_entities, space)
    if ok and ents then
      for _, entity in pairs(ents) do
        table.insert(entities, entity)
      end
    end
  elseif type(space.entities) == "table" then
    for _, entity in pairs(space.entities) do
      table.insert(entities, entity)
    end
  end
  
  return entities
end

-- ========= ESP CORE =========
local function update_esp_data()
  esp_data = {}
  
  local player_pos = get_player_position()
  if not player_pos then
    return
  end
  
  local entities = get_all_entities()
  
  for _, entity in ipairs(entities) do
    local info = get_entity_info(entity)
    
    if info and info.position then
      local distance = calculate_distance(player_pos, info.position)
      
      if distance and distance <= ESP_CONFIG.max_distance then
        info.distance = distance
        
        -- Categorizza l'entità
        local category = "unknown"
        if info.is_enemy or string.find(string.lower(info.type), "enemy") then
          category = "enemy"
        elseif string.find(string.lower(info.type), "npc") then
          category = "npc"
        elseif string.find(string.lower(info.type), "item") then
          category = "item"
        elseif string.find(string.lower(info.type), "resource") or string.find(string.lower(info.name), "resource") then
          category = "resource"
        elseif string.find(string.lower(info.type), "chest") or string.find(string.lower(info.name), "chest") then
          category = "chest"
        elseif string.find(string.lower(info.type), "quest") then
          category = "quest"
        end
        
        info.category = category
        
        -- Applica filtri
        local should_show = false
        if category == "npc" and ESP_CONFIG.show_npcs then
          should_show = true
        elseif category == "enemy" and ESP_CONFIG.show_enemies then
          should_show = true
        elseif category == "item" and ESP_CONFIG.show_items then
          should_show = true
        elseif category == "resource" and ESP_CONFIG.show_resources then
          should_show = true
        elseif category == "chest" and ESP_CONFIG.show_chests then
          should_show = true
        elseif category == "quest" and ESP_CONFIG.show_quest_objects then
          should_show = true
        end
        
        if should_show and not info.is_dead then
          table.insert(esp_data, info)
        end
      end
    end
  end
  
  -- Ordina per distanza
  table.sort(esp_data, function(a, b)
    return a.distance < b.distance
  end)
end

local function render_esp()
  if not esp_active then
    return
  end
  
  local current_time = os.clock()
  if current_time - last_update >= ESP_CONFIG.update_interval then
    update_esp_data()
    last_update = current_time
  end
  
  -- Stampa le informazioni ESP nella console
  print("\n========== ESP OBJECTS ==========")
  print(string.format("Oggetti trovati: %d", #esp_data))
  print("=================================")
  
  for i, info in ipairs(esp_data) do
    local color = ESP_CONFIG.colors[info.category] or {r=255, g=255, b=255}
    local line = string.format("[%s] %s", string.upper(info.category), info.name)
    
    if ESP_CONFIG.show_distance then
      line = line .. string.format(" - %.1fm", info.distance)
    end
    
    if ESP_CONFIG.show_level and info.level then
      line = line .. string.format(" [Lv.%d]", info.level)
    end
    
    if ESP_CONFIG.show_health and info.health and info.max_health then
      local hp_percent = (info.health / info.max_health) * 100
      line = line .. string.format(" [HP: %.0f%%]", hp_percent)
    end
    
    print(line)
    
    -- Limita output per non spammare
    if i >= 20 then
      print(string.format("... e altri %d oggetti", #esp_data - 20))
      break
    end
  end
  
  print("=================================\n")
end

-- ========= COMANDI PUBBLICI =========
local function start_esp()
  if esp_active then
    print("[ESP] ESP già attivo!")
    return
  end
  
  esp_active = true
  last_update = 0
  print("[ESP] ESP attivato! Aggiornamento ogni " .. ESP_CONFIG.update_interval .. " secondi")
  print("[ESP] Usa stop_esp() per disattivare")
  
  -- Avvia loop di rendering (se disponibile un sistema di tick)
  -- Altrimenti l'utente dovrà chiamare render_esp() manualmente
end

local function stop_esp()
  if not esp_active then
    print("[ESP] ESP già disattivato!")
    return
  end
  
  esp_active = false
  esp_data = {}
  print("[ESP] ESP disattivato!")
end

local function toggle_esp()
  if esp_active then
    stop_esp()
  else
    start_esp()
  end
end

local function configure_esp(config)
  if type(config) ~= "table" then
    print("[ESP] Errore: configurazione deve essere una tabella")
    return
  end
  
  for k, v in pairs(config) do
    if ESP_CONFIG[k] ~= nil then
      ESP_CONFIG[k] = v
      print(string.format("[ESP] %s = %s", k, tostring(v)))
    end
  end
  
  print("[ESP] Configurazione aggiornata!")
end

local function print_esp_help()
  print([[
========== ESP HELP ==========
Comandi disponibili:
  start_esp()           - Attiva ESP
  stop_esp()            - Disattiva ESP
  toggle_esp()          - Toggle ESP on/off
  render_esp()          - Aggiorna e mostra ESP manualmente
  configure_esp({...})  - Modifica configurazione
  print_esp_help()      - Mostra questo aiuto

Esempio configurazione:
  configure_esp({
    show_npcs = true,
    show_enemies = true,
    max_distance = 150,
    update_interval = 1.0
  })

Categorie disponibili:
  - NPCs (giallo)
  - Nemici (rosso)
  - Items (verde)
  - Risorse (ciano)
  - Chest (arancione)
  - Quest Objects (magenta)
==============================
]])
end

-- ========= ESPORTA FUNZIONI GLOBALI =========
rawset(_G, "start_esp", start_esp)
rawset(_G, "stop_esp", stop_esp)
rawset(_G, "toggle_esp", toggle_esp)
rawset(_G, "render_esp", render_esp)
rawset(_G, "configure_esp", configure_esp)
rawset(_G, "print_esp_help", print_esp_help)
rawset(_G, "ESP_CONFIG", ESP_CONFIG)

-- ========= AUTO-START (opzionale) =========
print("[ESP] Script ESP caricato con successo!")
print("[ESP] Usa print_esp_help() per vedere i comandi disponibili")
print("[ESP] Usa start_esp() per attivare l'ESP")

-- Uncomment per auto-start:
-- start_esp()
