-- set_debug_flags.lua
-- Change les flags comme DEBUG, DISABLE_ACSDK, etc. partout dans l'environnement.

-- ========= CONFIG =========
local FLAGS_TO_SET = {
  DEBUG                   = true,
  DISABLE_ACSDK           = true,
  ENABLE_DEBUG_PRINT      = true,
  ENABLE_FORCE_SHOW_GM    = true,
  FORCE_OPEN_DEBUG_SHORTCUT = true,
  GM_IS_OPEN_GUIDE        = true,
  GM_USE_PUBLISH          = true,
  acsdk_info_has_inited   = false,
}

local MAX_DEPTH = 10
local ROOT = rawget(_G, "DUMP_ROOT") or package.loaded
local ROOT_NAME = rawget(_G, "DUMP_ROOT_NAME") or "ROOT"

-- ========= LOGIC =========
local visited = setmetatable({}, { __mode = "k" })
local rawget, rawset, type, tostring = rawget, rawset, type, tostring
local next, pcall = next, pcall

local function modify_flags(tbl, path, depth)
  if depth > MAX_DEPTH then return end
  if visited[tbl] then return end
  visited[tbl] = true

  for k, _ in next, tbl do
    local ok, v = pcall(rawget, tbl, k)
    if not ok then goto continue end

    if type(k) == "string" and FLAGS_TO_SET[k] ~= nil then
      local old_val = tostring(v)
      rawset(tbl, k, FLAGS_TO_SET[k])
      print(string.format("[✔] %s%s = %s → %s", path, k, old_val, tostring(FLAGS_TO_SET[k])))
    end

    if type(v) == "table" then
      local child_path = string.format("%s%s.", path, tostring(k))
      modify_flags(v, child_path, depth + 1)
    end

    ::continue::
  end
end

-- ========= EXECUTION =========
modify_flags(ROOT, ROOT_NAME .. ".", 0)
print("[OK] Modification des flags terminée.")
