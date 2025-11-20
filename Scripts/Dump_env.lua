-- dump_env_all_54_userdata.lua  (Lua 5.4)
-- Version avec :
--   - dump des userdata sous forme :
--       { __userdata = "userdata: 0x...", __metatable = { ... } }
--   - dump des types "dict" et "list" via dictlib/listlib
--   - aucune utilisation de pairs()/next sur autre chose qu'une vraie table

local ok, err = pcall(function()

  -- ======= Config =======
  local _G     = _G
  local rawget = rawget

  local DUMP_PATH   = rawget(_G, "DUMP_PATH")
                    or "C:\\temp\\Where Winds Meet\\env_full_dump.lua"

  local DUMP_DEPTH  = tonumber(rawget(_G, "DUMP_DEPTH")) or 12   -- profondeur max
  local PRETTY      = (rawget(_G, "DUMP_PRETTY") ~= false)      -- pretty-print

  -- Racine par défaut : package.loaded (modules chargés)
  local ROOT        = rawget(_G, "DUMP_ROOT") or package.loaded or (_ENV or _G)

  if type(ROOT) ~= "table" then
    error("[dump_env_all] Racine à dumper invalide (pas une table).")
  end

  -- ======= Locaux pour perf =======
  local dbg      = rawget(_G, "debug")
  local getmt    = (dbg and dbg.getmetatable) or getmetatable
  local type     = type
  local tostring = tostring
  local pcall    = pcall
  local string   = string
  local table    = table
  local math     = math
  local os       = os
  local io       = io
  local next     = next
  local ipairs   = ipairs

  -- libs python-like
  local listlib  = rawget(_G, "listlib")
  local dictlib  = rawget(_G, "dictlib")
  local len_fn   = rawget(_G, "len")

  local format = string.format
  local rep    = string.rep
  local sort   = table.sort
  local concat = table.concat
  local q      = function(s) return format("%q", s) end

  -- IDs stables pour objets non primitifs
  local OBJ_ID   = setmetatable({}, { __mode = "k" })
  local OBJ_SEQ  = { table = 0, ["function"] = 0, userdata = 0, thread = 0 }
  local function uid(x)
    local id = OBJ_ID[x]
    if id then return id end
    local t = type(x)
    local n = (OBJ_SEQ[t] or 0) + 1
    OBJ_SEQ[t] = n
    id = format("%s%d", t:sub(1,1):upper(), n)
    OBJ_ID[x] = id
    return id
  end

  local function safe_tostring(x)
    local t = type(x)
    if t == "nil" or t == "boolean" or t == "number" then
      return tostring(x)
    elseif t == "string" then
      return x
    end

    local mt = getmt and getmt(x) or nil
    if type(mt) == "table" and rawget(mt, "__tostring") ~= nil then
      return "<" .. t .. ":" .. uid(x) .. ">"
    end

    local ok_t, s = pcall(tostring, x)
    if ok_t and type(s) == "string" then
      return s
    end
    return "<" .. t .. ":" .. uid(x) .. ">"
  end

  -- Adresse brute (table: 0x..., userdata: 0x...) sans __tostring custom
  local function addr_repr(x)
    local t = type(x)
    if t ~= "table" and t ~= "userdata" and t ~= "function" and t ~= "thread" then
      return safe_tostring(x)
    end

    local mt = getmt and getmt(x) or nil
    local s

    if type(mt) == "table" and mt.__tostring ~= nil then
      local old = mt.__tostring
      mt.__tostring = nil
      local ok_t, res = pcall(tostring, x)
      mt.__tostring = old
      if ok_t and type(res) == "string" then
        s = res
      end
    else
      local ok_t, res = pcall(tostring, x)
      if ok_t and type(res) == "string" then
        s = res
      end
    end

    if not s then
      s = safe_tostring(x)
    end
    return s
  end

  -- longueur séquentielle 1..n (sans trous) via rawget
  local function seq_len(t)
    local n, i = 0, 1
    while rawget(t, i) ~= nil do
      n = i
      i = i + 1
    end
    return n
  end

  -- ======= Encodage table -> littéral Lua =======
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

  -- Clés à ignorer complètement dans le dump
  -- Tu peux étendre cette table ou la surcharger via _G.DUMP_IGNORE_KEYS
  local IGNORE_KEYS = rawget(_G, "DUMP_IGNORE_KEYS") or {
    gm_command_short_cuts = true,
    gm_command_ui_components = true,
  }

  local function should_ignore_key(k)
    return type(k) == "string" and IGNORE_KEYS[k] == true
  end

  -- Gestion des cycles + déduplication (pour les tables Lua)
  local VISITING = setmetatable({}, { __mode = "k" })
  local TIDS     = setmetatable({}, { __mode = "k" })
  local ENCODED  = setmetatable({}, { __mode = "k" })  -- bool : déjà dumpé en entier
  local NEXT_TID = 0

  local function tid_for(t)
    local id = TIDS[t]
    if id then return id end
    NEXT_TID = NEXT_TID + 1
    TIDS[t] = NEXT_TID
    return NEXT_TID
  end

  local function cmp_keys(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then
      return ta < tb
    end
    if ta == "string" then return a < b end
    if ta == "number" then return a < b end
    if ta == "boolean" then
      return (a and 1 or 0) < (b and 1 or 0)
    end
    local sa = safe_tostring(a)
    local sb = safe_tostring(b)
    return sa < sb
  end

  -- forward decl
  local encode_value
  local encode_dict
  local encode_list

  -- Encodage minimal de userdata : adresse + metatable (si table)
  local function encode_userdata(u, depth, indent)
    local tag = addr_repr(u)

    if depth >= DUMP_DEPTH then
      return q(tag)
    end

    local mt = getmt and getmt(u) or nil
    if mt == nil or type(mt) ~= "table" then
      return q(tag)
    end

    local sp  = PRETTY and rep("  ", indent) or ""
    local nl  = PRETTY and "\n" or ""
    local parts = {}

    local taglit = q(tag)
    if PRETTY then
      parts[#parts+1] = sp .. "  __userdata = " .. taglit
    else
      parts[#parts+1] = "__userdata = " .. taglit
    end

    local mt_enc = encode_value(mt, depth + 1, indent + 1)
    if PRETTY then
      parts[#parts+1] = sp .. "  __metatable = " .. mt_enc
    else
      parts[#parts+1] = "__metatable = " .. mt_enc
    end

    if PRETTY then
      return "{" .. nl .. concat(parts, "," .. nl) .. nl .. sp .. "}"
    else
      return "{" .. concat(parts, ",") .. "}"
    end
  end

  -- Encodage d'un "dict" Python-like via dictlib + listlib
  local function encode_dict(d, depth, indent)
    depth  = depth or 0
    indent = indent or 0

    if depth >= DUMP_DEPTH then
      return q("<dict>")
    end

    if not (dictlib and type(dictlib.items) == "function") then
      return q(safe_tostring(d))
    end

    local ok_items, items = pcall(dictlib.items, d)
    if not ok_items or items == nil then
      return q(safe_tostring(d))
    end

    local sp  = PRETTY and rep("  ", indent) or ""
    local nl  = PRETTY and "\n" or ""
    local parts = {}

    local function key_repr(k)
      local kt = type(k)
      if kt == "string" and is_ident(k) then
        return k .. " = "
      elseif kt == "string" then
        return "[" .. q(k) .. "] = "
      elseif kt == "number" then
        if k ~= k or k == math.huge or k == -math.huge then
          return "[" .. q("<number>") .. "] = "
        else
          return "[" .. tostring(k) .. "] = "
        end
      elseif kt == "boolean" then
        return "[" .. (k and "true" or "false") .. "] = "
      else
        return "[" .. q("<key:" .. safe_tostring(k) .. ">") .. "] = "
      end
    end

    local function add_pair(k, v)
      if should_ignore_key(k) then
        return
      end
      local kr = key_repr(k)
      local ev = encode_value(v, depth + 1, indent + 1)
      if PRETTY then
        parts[#parts+1] = sp .. "  " .. kr .. ev
      else
        parts[#parts+1] = kr .. ev
      end
    end

    local used_fallback = false

    -- items est typiquement un "list" Python -> iterunpack donne (idx, key, value)
    if listlib and type(listlib.iterunpack) == "function" then
      local ok_iter, it, st, fst = pcall(listlib.iterunpack, items)
      if ok_iter and type(it) == "function" then
        local ok_loop = pcall(function()
          for idx, key, value in it, st, fst do
            add_pair(key, value)
          end
        end)
        if not ok_loop then
          used_fallback = true
        end
      else
        used_fallback = true
      end
    else
      used_fallback = true
    end

    -- fallback si items est une table Lua de paires [k,v]
    if used_fallback then
      if type(items) == "table" then
        for _, pair in ipairs(items) do
          if type(pair) == "table" then
            add_pair(pair[1], pair[2])
          end
        end
      else
        return q(safe_tostring(d))
      end
    end

    if PRETTY then
      return "{" .. nl .. concat(parts, "," .. nl) .. nl .. sp .. "}"
    else
      return "{" .. concat(parts, ",") .. "}"
    end
  end

  -- Encodage d'un "list" Python-like via listlib.iterunpack
  local function encode_list(lst, depth, indent)
    depth  = depth or 0
    indent = indent or 0

    if depth >= DUMP_DEPTH then
      return q("<list>")
    end

    if not listlib then
      return q(safe_tostring(lst))
    end

    local sp  = PRETTY and rep("  ", indent) or ""
    local nl  = PRETTY and "\n" or ""
    local parts = {}

    local function add_value(v)
      local ev = encode_value(v, depth + 1, indent + 1)
      if PRETTY then
        parts[#parts+1] = sp .. "  " .. ev
      else
        parts[#parts+1] = ev
      end
    end

    local function finish_if_any()
      if #parts == 0 then
        return nil
      end
      if PRETTY then
        return "{" .. nl .. concat(parts, "," .. nl) .. nl .. sp .. "}"
      else
        return "{" .. concat(parts, ",") .. "}"
      end
    end

    -- ==========================
    -- 1) Tentative via iterunpack
    -- ==========================
    if type(listlib.iterunpack) == "function" then
      local ok_iter, it, st, fst = pcall(listlib.iterunpack, lst)
      if ok_iter and type(it) == "function" then
        local ok_loop = pcall(function()
          for idx, a, b, c, d, e in it, st, fst do
            local value
            if b == nil and c == nil and d == nil and e == nil then
              -- cas classique: list [val1, val2, ...] -> iterunpack : idx, val
              value = a
            else
              -- cas "tuple" : on emballe (a,b,c,...) dans une petite table
              local tup = {}
              if a ~= nil then tup[#tup+1] = a end
              if b ~= nil then tup[#tup+1] = b end
              if c ~= nil then tup[#tup+1] = c end
              if d ~= nil then tup[#tup+1] = d end
              if e ~= nil then tup[#tup+1] = e end
              value = tup
            end
            add_value(value)
          end
        end)

        if ok_loop then
          local res = finish_if_any()
          if res then
            return res
          end
        end

        -- si la boucle a planté ou n'a rien produit, on nettoie et on tente autre chose
        parts = {}
      end
    end

    -- =========================================
    -- 2) Fallback : len() + indexation numérique
    --    (beaucoup de "list" supportent lst[i])
    -- =========================================
    if len_fn then
      local ok_len, n = pcall(len_fn, lst)
      if ok_len and type(n) == "number" and n > 0 then
        -- heuristique très simple : 0-based ou 1-based ?
        local base = 1
        local ok0, v0 = pcall(function() return lst[0] end)
        local ok1, v1 = pcall(function() return lst[1] end)
        if ok0 and v0 ~= nil and (not ok1 or v1 == nil) then
          base = 0
        end

        local ok_loop = pcall(function()
          for i = 0, n - 1 do
            local idx = base + i
            local ok_v, v = pcall(function() return lst[idx] end)
            if ok_v and v ~= nil then
              add_value(v)
            end
          end
        end)

        if ok_loop then
          local res = finish_if_any()
          if res then
            return res
          end
        end
      end
    end

    -- ===================
    -- 3) Dernier recours
    -- ===================
    return q(safe_tostring(lst))
  end

  -- ================== encode_value ==================
  function encode_value(v, depth, indent)
    depth  = depth or 0
    indent = indent or 0

    local sp  = PRETTY and rep("  ", indent) or ""
    local nl  = PRETTY and "\n" or ""

    local t = type(v)

    if t == "nil" then
      return "nil"
    elseif t == "boolean" then
      return v and "true" or "false"
    elseif t == "number" then
      if v ~= v or v == math.huge or v == -math.huge then
        return q("<number>")
      end
      return tostring(v)
    elseif t == "string" then
      return q(v)
    elseif t == "function" or t == "thread" then
      return q(addr_repr(v))
    elseif t == "dict" then
      -- nouveau : dump complet d'un dict Python-like
      return encode_dict(v, depth, indent)
    elseif t == "list" then
      -- nouveau : dump complet d'une list Python-like
      return encode_list(v, depth, indent)
    elseif t == "userdata" then
      return encode_userdata(v, depth, indent)
    elseif t ~= "table" then
      -- autres types exotiques, on se contente d'une string
      return q(safe_tostring(v))
    end

    -- Table Lua
    local id = tid_for(v)

    if ENCODED[v] then
      return q(addr_repr(v))
    end

    if depth >= DUMP_DEPTH then
      return q("<truncated:T" .. id .. ">")
    end
    if VISITING[v] then
      return q("<cycle:T" .. id .. ">")
    end

    VISITING[v] = true

    local n = seq_len(v)
    local parts = {}

    -- partie séquence
    for i = 1, n do
      local ev = encode_value(rawget(v, i), depth + 1, indent + 1)
      if PRETTY then
        parts[#parts+1] = format("%s  %s", sp, ev)
      else
        parts[#parts+1] = ev
      end
    end

    -- partie hash
    local hkeys = {}
    for k,_ in next, v do
      if not (type(k)=="number" and k%1==0 and k>=1 and k<=n) then
        if not should_ignore_key(k) then
          hkeys[#hkeys+1] = k
        end
      end
    end
    sort(hkeys, cmp_keys)

    local function key_repr(k)
      local kt = type(k)
      if kt == "string" and is_ident(k) then
        return k .. " = "
      elseif kt == "string" then
        return "[" .. q(k) .. "] = "
      elseif kt == "number" then
        if k ~= k or k == math.huge or k == -math.huge then
          return "[" .. q("<number>") .. "] = "
        else
          return "[" .. tostring(k) .. "] = "
        end
      elseif kt == "boolean" then
        return "[" .. (k and "true" or "false") .. "] = "
      else
        return "[" .. q("<key:" .. safe_tostring(k) .. ">") .. "] = "
      end
    end

    for _, k in ipairs(hkeys) do
      local ev = encode_value(rawget(v, k), depth + 1, indent + 1)
      local kr = key_repr(k)
      if PRETTY then
        parts[#parts+1] = format("%s  %s%s", sp, kr, ev)
      else
        parts[#parts+1] = kr .. ev
      end
    end

    VISITING[v] = nil
    ENCODED[v]  = true

    if PRETTY then
      return "{" .. nl .. concat(parts, "," .. nl) .. nl .. sp .. "}"
    else
      return "{" .. concat(parts, ",") .. "}"
    end
  end


  -- ======= Dump principal =======
  local function dump_env_to_lua_file()
    local body   = encode_value(ROOT, 0, 0)
    local header = format(
      "-- Auto-generated dump of package.loaded (ou DUMP_ROOT)\n-- %s\n\nreturn ",
      os.date("%Y-%m-%d %H:%M:%S")
    )

    local content = header .. body .. (PRETTY and "\n" or "")

    local f, ferr = io.open(DUMP_PATH, "wb")
    if not f then
      local fb = "env_full_dump.lua"
      local f2, ferr2 = io.open(fb, "wb")
      if f2 then
        f2:write(content)
        f2:close()
        print(format("[dump_env_all] écrit %s (fallback).", fb))
        return
      end
      error("[dump_env_all] Échec écriture: "..tostring(ferr).." / "..tostring(ferr2))
    end

    f:write(content)
    f:close()
    print("[dump_env_all] écrit: "..DUMP_PATH)
  end

  dump_env_to_lua_file()

end)

-- ======= Gestion d'erreur globale =======
if not ok then
  local ef = io.open("C:\\temp\\Where Winds Meet\\env_full_dump_error.txt", "wb")
  if ef then
    ef:write("Erreur dans dump_env_all_54_userdata.lua:\n")
    ef:write(tostring(err), "\n")
    ef:close()
  end
end

