-- dump_bools_54.lua
-- Parcourt DUMP_ROOT (par défaut package.loaded) et écrit
-- dans un seul fichier toutes les variables booléennes (true/false)
-- sous forme de chemins texte.

-- ======= Config =======
local _G     = _G
local rawget = rawget

local DUMP_PATH = rawget(_G, "DUMP_PATH_BOOLS")
                or rawget(_G, "DUMP_PATH")
                or "C:\\temp\\Where Winds Meet\\env_bools.lua"

-- profondeur max (pour éviter de descendre trop profond)
local MAX_DEPTH = tonumber(rawget(_G, "DUMP_BOOL_DEPTH")) or 8

-- Racine : par défaut package.loaded (comme ton autre script)
local ROOT      = rawget(_G, "DUMP_ROOT") or package.loaded or (_ENV or _G)
local ROOT_NAME = rawget(_G, "DUMP_ROOT_NAME") or "ROOT"

if type(ROOT) ~= "table" then
  error("[dump_bools] Racine à parcourir invalide (pas une table).")
end

-- ======= Locaux =======
local type     = type
local tostring = tostring
local string   = string
local table    = table
local math     = math
local io       = io
local os       = os
local next     = next
local ipairs   = ipairs
local pcall    = pcall

local format = string.format
local q      = function(s) return format("%q", s) end

-- ======= Helpers =======

local RESERVED = {
  ["and"]=1,["break"]=1,["do"]=1,["else"]=1,["elseif"]=1,["end"]=1,
  ["false"]=1,["for"]=1,["function"]=1,["goto"]=1,["if"]=1,["in"]=1,
  ["local"]=1,["nil"]=1,["not"]=1,["or"]=1,["repeat"]=1,["return"]=1,
  ["then"]=1,["true"]=1,["until"]=1,["while"]=1
}

local function is_ident(s)
  return type(s) == "string"
     and s:match("^[A-Za-z_][A-Za-z0-9_]*$")
     and not RESERVED[s]
end

local function key_suffix(k)
  local kt = type(k)
  if kt == "string" and is_ident(k) then
    return "." .. k
  elseif kt == "string" then
    return "[" .. q(k) .. "]"
  elseif kt == "number" then
    if k ~= k or k == math.huge or k == -math.huge then
      return "[" .. q("<number>") .. "]"
    else
      return "[" .. tostring(k) .. "]"
    end
  elseif kt == "boolean" then
    return "[" .. (k and "true" or "false") .. "]"
  else
    -- clé exotique -> on stringify pour au moins la voir
    return "[" .. q(tostring(k)) .. "]"
  end
end

-- ======= Parcours =======

local visited   = setmetatable({}, { __mode = "k" }) -- éviter de re-parcourir les mêmes tables
local bool_vars = {}

local function visit(value, path, depth)
  if depth > MAX_DEPTH then
    return
  end

  local t = type(value)

  if t == "boolean" then
    local line = path .. " = " .. (value and "true" or "false")
    bool_vars[#bool_vars+1] = line
    return
  end

  if t ~= "table" then
    return
  end

  if visited[value] then
    return
  end
  visited[value] = true

  -- on utilise next/rawget pour éviter les __pairs / __index chelous
  for k,_ in next, value do
    local ok, v = pcall(rawget, value, k)
    if ok then
      local child_path = path .. key_suffix(k)
      visit(v, child_path, depth + 1)
    end
  end
end

-- ======= Écriture fichier unique =======

local function write_bools(path, list)
  local f, err = io.open(path, "wb")
  if not f then
    error("[dump_bools] Échec ouverture " .. path .. " : " .. tostring(err))
  end

  f:write(format(
    "-- Auto-generated boolean dump\n-- %s\n\nreturn {\n",
    os.date("%Y-%m-%d %H:%M:%S")
  ))

  for _, line in ipairs(list) do
    f:write("  ", q(line), ",\n")
  end

  f:write("}\n")
  f:close()
end

-- ======= Lancement =======

local function dump_bools()
  visit(ROOT, ROOT_NAME, 0)

  write_bools(DUMP_PATH, bool_vars)

  print(("[dump_bools] booleans trouvés = %d"):format(#bool_vars))
  print("[dump_bools] écrit -> " .. DUMP_PATH)
end

dump_bools()
