-- trace_hook.lua
-- Trace des appels de fonctions Lua + arguments dans un log,
-- en ignorant les fonctions "classiques" / bruit.

local ok, err = pcall(function()

  local dbg = debug
  if not dbg or not dbg.sethook then
    return  -- environnement trop bridé
  end

  -- Source de ce fichier (pour ignorer toutes les fonctions déclarées ici)
  local THIS_SRC = nil
  do
    local info = dbg.getinfo(1, "S")
    THIS_SRC = info and info.short_src or nil
  end

  local LOG_PATH = "C:\\temp\\Where Winds Meet\\trace_calls.log"

  local f, ferr = io.open(LOG_PATH, "wb")
  if not f then
    return
  end

  local function write_line(...)
    local n = select("#", ...)
    local parts = {}
    for i = 1, n do
      parts[#parts+1] = tostring(select(i, ...))
    end
    f:write(table.concat(parts), "\n")
  end

  write_line("-- Trace des appels de fonctions Lua")
  write_line("-- ", os.date("%Y-%m-%d %H:%M:%S"))
  write_line("")

  ---------------------------------------------------------------------------
  -- CONFIG FILTRES
  ---------------------------------------------------------------------------

  -- Fichiers / chemins à ignorer (short_src)
  local SKIP_SRC_PREFIXES = {
    "engine/Lib/",                      -- tes helpers engine
    "hexm/client/trace.lua",           -- trace/log du client
    "hexm/client/logger.lua",          -- logger
    "hexm/common/strict.lua",          -- strict newindex/guard
    "hexm/common/datetime_manager.lua",-- date/time helpers
    "hexm/common/data/dir_object.lua", -- DataManager root/index
    "hexm/common/data/bin_data_object.lua",
    "engine/Lib/partial.lua",
    "hexm/client/entities/local/component/anim.lua",
    "hexm/client/manager/task_queue/",
    

  }

  -- Noms de fonctions à ignorer
  local SKIP_FUNC_NAMES = {
    newindexdot   = true,
    excepthook    = true,
    __G__TRACKBACK__ = true,
    repr          = true,
    len           = true,
    error         = true,
    get_trace_msg = true,
    show_trace    = true,
    format_datetime = true,
    now           = true,
    now_raw       = true,
  }

  ---------------------------------------------------------------------------
  -- Helpers
  ---------------------------------------------------------------------------

  local string_format = string.format
  local string_rep    = string.rep

  local function safe_tostring(v)
    local t = type(v)
    if t == "string" then
      local s = v
      local max_len = 200
      local len = #s
      if len > max_len then
        s = s:sub(1, max_len) .. string_format("...<len=%d>", len)
      end
      return string_format("%q", s)
    elseif t == "number" or t == "boolean" or t == "nil" then
      return tostring(v)
    end

    local ok_t, s = pcall(tostring, v)
    if ok_t and type(s) == "string" then
      return s
    end
    return "<" .. t .. ">"
  end

  -- Pour éviter la récursion dans le hook
  local in_hook = false

  -- Indentation en fonction de la profondeur d'appel
  local indent = 0

  -- Teste si on doit ignorer cet appel
  local function should_skip(info)
    local src = info.short_src or ""

    -- Ignorer le fichier du hook lui-même
    if THIS_SRC and src == THIS_SRC then
      return true
    end

    -- Ignorer certaines sources "classiques"
    for _, prefix in ipairs(SKIP_SRC_PREFIXES) do
      if src == prefix or src:sub(1, #prefix) == prefix then
        return true
      end
    end

    -- Ignorer certaines fonctions par nom
    local name = info.name
    if name and SKIP_FUNC_NAMES[name] then
      return true
    end

    return false
  end

  ---------------------------------------------------------------------------
  -- Hook
  ---------------------------------------------------------------------------

  local function hook(event, line)
    if in_hook then
      return
    end

    if event == "return" then
      if indent > 0 then
        indent = indent - 1
      end
      return
    end

    if event ~= "call" and event ~= "tail call" then
      return
    end

    in_hook = true

    local info = dbg.getinfo(2, "nSlu")
    if not info then
      in_hook = false
      return
    end

    if should_skip(info) then
      in_hook = false
      return
    end

    -- On ne trace que les fonctions Lua pour avoir les arguments
    if info.what ~= "Lua" then
      in_hook = false
      return
    end

    local func_name = info.name or "<anonymous>"
    local src       = info.short_src or "?"
    local linedef   = info.linedefined or -1

    -- Récupération des arguments
    local args = {}

    local nparams = info.nparams or 0
    for i = 1, nparams do
      local name, value = dbg.getlocal(2, i)
      if not name then break end
      args[#args+1] = string_format("%s=%s", name, safe_tostring(value))
    end

    if info.isvararg then
      local i = 1
      while true do
        local name, value = dbg.getlocal(2, -i)
        if not name then
          break
        end
        args[#args+1] = string_format("...%d=%s", i, safe_tostring(value))
        i = i + 1
      end
    end

    local prefix = string_rep("  ", indent)

    write_line(string_format(
      "%sCALL %s (%s:%d)  args: (%s)",
      prefix,
      func_name,
      src,
      linedef,
      table.concat(args, ", ")
    ))

    indent = indent + 1
    in_hook = false
  end

  ---------------------------------------------------------------------------
  -- Activation du hook
  ---------------------------------------------------------------------------

  dbg.sethook(hook, "cr")

  -- Création sûre dans un environnement strict :
  rawset(_G, "STOP_TRACE_HOOK", function()
    dbg.sethook(nil)
    write_line("")
    write_line("-- TRACE STOPPED at ", os.date("%Y-%m-%d %H:%M:%S"))
    f:flush()
    f:close()
  end)

end)

if not ok then
  local ef = io.open("C:\\temp\\Where Winds Meet\\trace_hook_error.txt", "wb")
  if ef then
    ef:write("Erreur dans trace_hook.lua:\n")
    ef:write(tostring(err), "\n")
    ef:close()
  end
end
