-- Change flags like DEBUG, DISABLE_ACSDK, etc. everywhere in the environment
-- and keep them enforced for future changes.

-- ========= CONFIG =========
local FLAGS_TO_SET = {
  DEBUG                     = true,
  DISABLE_ACSDK             = true,
  ENABLE_DEBUG_PRINT        = true,
  ENABLE_FORCE_SHOW_GM      = true,
  FORCE_OPEN_DEBUG_SHORTCUT = true,
  GM_IS_OPEN_GUIDE          = true,
  GM_USE_PUBLISH            = true,
  acsdk_info_has_inited     = false,
}

local MAX_DEPTH = 10
local ROOT = rawget(_G, "DUMP_ROOT") or package.loaded
local ROOT_NAME = rawget(_G, "DUMP_ROOT_NAME") or "ROOT"

-- ========= LOGIC =========
local visited = setmetatable({}, { __mode = "k" })  -- tables déjà traitées
local paths   = setmetatable({}, { __mode = "k" })  -- table -> chemin texte pour logs
local depths  = setmetatable({}, { __mode = "k" })  -- table -> profondeur

local rawget, rawset, type, tostring = rawget, rawset, type, tostring
local next, pcall = next, pcall
local getmetatable, setmetatable = getmetatable, setmetatable
local fmt = string.format

local function log_change(path, key, old_val, new_val)
  print(fmt("[✔] %s%s = %s → %s", path, key, tostring(old_val), tostring(new_val)))
end

local instrument_table  -- forward declaration

-- Ajoute un __newindex sur la table pour :
--   - forcer les FLAGS_TO_SET lors de futures écritures
--   - instrumenter automatiquement les nouvelles tables assignées
local function ensure_hook(tbl)
  local mt = getmetatable(tbl)
  if mt and mt.__flags_hooked then
    return
  end

  mt = mt or {}
  local original_newindex = mt.__newindex
  mt.__flags_hooked = true

  mt.__newindex = function(t, k, v)
    local path  = paths[t]  or (ROOT_NAME .. ".")
    local depth = depths[t] or 0

    -- Si on assigne une table, on l'instrumente aussi (scan + hook)
    if type(v) == "table" and depth < MAX_DEPTH then
      local child_path = fmt("%s%s.", path, tostring(k))
      instrument_table(v, child_path, depth + 1)
    end

    -- Si la clé fait partie des flags, on force la valeur
    if type(k) == "string" and FLAGS_TO_SET[k] ~= nil then
      local new_val = FLAGS_TO_SET[k]
      local old_val = rawget(t, k)
      rawset(t, k, new_val)
      log_change(path, k, old_val, new_val)
      return
    end

    -- Comportement normal ensuite
    if type(original_newindex) == "function" then
      original_newindex(t, k, v)
    elseif original_newindex ~= nil then
      -- cas exotiques (table ou autre) : on reste simple
      rawset(t, k, v)
    else
      rawset(t, k, v)
    end
  end

  setmetatable(tbl, mt)
end

-- Scan récursif initial + instrumentation
instrument_table = function(tbl, path, depth)
  if type(tbl) ~= "table" then return end
  if depth > MAX_DEPTH then return end
  if visited[tbl] then return end

  visited[tbl] = true
  paths[tbl]   = path
  depths[tbl]  = depth

  -- On place le hook sur cette table pour les futures modifications
  ensure_hook(tbl)

  -- On applique les flags tout de suite et on descend récursivement
  for k, _ in next, tbl do
    local ok, v = pcall(rawget, tbl, k)
    if not ok then goto continue end

    if type(k) == "string" and FLAGS_TO_SET[k] ~= nil then
      local desired = FLAGS_TO_SET[k]
      if v ~= desired then
        local old_val = v
        rawset(tbl, k, desired)
        log_change(path, k, old_val, desired)
      end
    end

    if type(v) == "table" then
      local child_path = fmt("%s%s.", path, tostring(k))
      instrument_table(v, child_path, depth + 1)
    end

    ::continue::
  end
end

-- ========= EXECUTION =========
instrument_table(ROOT, ROOT_NAME .. ".", 0)
print("[OK] Flag modification completed (auto-update enabled for future changes).")
