-- ESP_Stealth.lua
-- ESP offuscato e stealth per evitare detection
-- Usa tecniche avanzate di evasione

-- ========= OFFUSCAMENTO =========

-- Genera nomi variabili casuali
local function _G(l)
    local c = 'abcdefghijklmnopqrstuvwxyz'
    local r = ''
    for i = 1, l or 8 do
        r = r .. c:sub(math.random(1, #c), math.random(1, #c))
    end
    return r
end

-- XOR encryption per stringhe
local function _X(s, k)
    k = k or 42
    local r = {}
    for i = 1, #s do
        table.insert(r, string.char(bit32.bxor(string.byte(s, i), k)))
    end
    return table.concat(r)
end

-- Decryption
local function _D(s, k)
    return _X(s, k) -- XOR è simmetrico
end

-- ========= CONFIGURAZIONE OFFUSCATA =========

local _cfg = {
    [_X('enabled', 17)] = true,
    [_X('max_dist', 17)] = 100,
    [_X('update_int', 17)] = 2.0,
    [_X('show_npc', 17)] = true,
    [_X('show_enemy', 17)] = true,
    [_X('show_item', 17)] = true,
    [_X('random_delay', 17)] = true
}

-- ========= ANTI-DETECTION =========

local _ad = {}

-- Timing check per rilevare debugging
function _ad:_tc()
    local t1 = os.clock()
    local _ = 0
    for i = 1, 1000 do _ = _ + i end
    local t2 = os.clock()
    return (t2 - t1) > 0.01 -- Troppo lento = debugger
end

-- Random delay per evitare pattern
function _ad:_rd(min, max)
    if not _cfg[_X('random_delay', 17)] then return end
    min = min or 0.1
    max = max or 0.5
    local delay = min + math.random() * (max - min)
    local start = os.clock()
    while os.clock() - start < delay do
        -- Busy wait con jitter
        if math.random() > 0.5 then
            local _ = math.sqrt(math.random(1000))
        end
    end
end

-- Check ambiente sicuro
function _ad:_cs()
    -- Timing check
    if self:_tc() then
        return false, _X('Debugger detected', 17)
    end
    
    -- Check funzioni sospette
    local suspicious = {
        'debug', 'getinfo', 'traceback', 'getlocal'
    }
    
    for _, name in ipairs(suspicious) do
        if debug and debug[name] then
            -- Funzioni debug attive = sospetto
            if math.random() > 0.7 then -- Random per evitare pattern
                return false, _X('Debug functions active', 17)
            end
        end
    end
    
    return true, 'OK'
end

-- ========= ESP CORE (OFFUSCATO) =========

local _esp = {
    [_X('active', 23)] = false,
    [_X('objects', 23)] = {},
    [_X('last_update', 23)] = 0
}

-- Safe table access
local function _st(t, ...)
    local keys = {...}
    local current = t
    for _, key in ipairs(keys) do
        if type(current) ~= 'table' then return nil end
        current = current[key]
        if current == nil then return nil end
    end
    return current
end

-- Trova oggetti (offuscato)
function _esp:_fo()
    local objs = {}
    
    -- Delay randomizzato
    _ad:_rd(0.05, 0.15)
    
    -- Cerca in environment globale (offuscato)
    local env_keys = {
        _X('GameWorld', 31),
        _X('EntityManager', 31),
        _X('ObjectList', 31),
        _X('NPCManager', 31)
    }
    
    for _, key_enc in ipairs(env_keys) do
        local key = _D(key_enc, 31)
        
        -- Prova ad accedere
        local success, result = pcall(function()
            return _G[key]
        end)
        
        if success and result then
            -- Delay anti-pattern
            _ad:_rd(0.02, 0.08)
            
            -- Estrai oggetti
            if type(result) == 'table' then
                for k, v in pairs(result) do
                    if type(v) == 'table' then
                        -- Verifica se è un oggetto valido
                        local pos = _st(v, 'position') or _st(v, 'pos') or _st(v, 'transform', 'position')
                        local name = _st(v, 'name') or _st(v, 'displayName') or tostring(k)
                        
                        if pos then
                            table.insert(objs, {
                                [_X('name', 19)] = name,
                                [_X('pos', 19)] = pos,
                                [_X('type', 19)] = _X('unknown', 19),
                                [_X('ref', 19)] = v
                            })
                        end
                    end
                end
            end
        end
    end
    
    return objs
end

-- Calcola distanza (offuscato)
function _esp:_cd(p1, p2)
    if not p1 or not p2 then return 9999 end
    
    local x1 = _st(p1, 'x') or _st(p1, 1) or 0
    local y1 = _st(p1, 'y') or _st(p1, 2) or 0
    local z1 = _st(p1, 'z') or _st(p1, 3) or 0
    
    local x2 = _st(p2, 'x') or _st(p2, 1) or 0
    local y2 = _st(p2, 'y') or _st(p2, 2) or 0
    local z2 = _st(p2, 'z') or _st(p2, 3) or 0
    
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- Get player position (offuscato)
function _esp:_gp()
    local player_keys = {
        _X('LocalPlayer', 27),
        _X('Player', 27),
        _X('MyPlayer', 27),
        _X('PlayerController', 27)
    }
    
    for _, key_enc in ipairs(player_keys) do
        local key = _D(key_enc, 27)
        
        local success, player = pcall(function()
            return _G[key]
        end)
        
        if success and player then
            local pos = _st(player, 'position') or _st(player, 'pos') or _st(player, 'transform', 'position')
            if pos then return pos end
        end
    end
    
    return nil
end

-- Update ESP (offuscato)
function _esp:_u()
    local now = os.clock()
    local interval = _cfg[_X('update_int', 17)] or 2.0
    
    if now - self[_X('last_update', 23)] < interval then
        return
    end
    
    -- Check sicurezza
    local safe, msg = _ad:_cs()
    if not safe then
        self[_X('active', 23)] = false
        return
    end
    
    -- Delay randomizzato
    _ad:_rd(0.1, 0.3)
    
    -- Get player pos
    local player_pos = self:_gp()
    if not player_pos then return end
    
    -- Find objects
    local objects = self:_fo()
    
    -- Filtra per distanza
    local max_dist = _cfg[_X('max_dist', 17)] or 100
    local filtered = {}
    
    for _, obj in ipairs(objects) do
        local dist = self:_cd(player_pos, obj[_X('pos', 19)])
        if dist <= max_dist then
            obj[_X('distance', 19)] = dist
            table.insert(filtered, obj)
        end
    end
    
    -- Sort per distanza
    table.sort(filtered, function(a, b)
        return (a[_X('distance', 19)] or 9999) < (b[_X('distance', 19)] or 9999)
    end)
    
    self[_X('objects', 23)] = filtered
    self[_X('last_update', 23)] = now
end

-- Display ESP (offuscato)
function _esp:_ds()
    if not self[_X('active', 23)] then return end
    
    -- Update
    self:_u()
    
    -- Display
    local objs = self[_X('objects', 23)] or {}
    
    if #objs == 0 then
        return
    end
    
    -- Delay anti-pattern
    _ad:_rd(0.01, 0.05)
    
    -- Print top 10
    local count = math.min(10, #objs)
    for i = 1, count do
        local obj = objs[i]
        local name = _D(obj[_X('name', 19)] or 'Unknown', 19)
        local dist = obj[_X('distance', 19)] or 0
        
        -- Output offuscato
        if math.random() > 0.3 then -- Random per evitare pattern
            -- Print solo se random check passa
            local output = string.format('[%d] %s - %.1fm', i, name, dist)
            -- Usa print sicuro
            pcall(print, output)
        end
    end
end

-- ========= API PUBBLICA (OFFUSCATA) =========

-- Start ESP
local function _se()
    -- Check sicurezza
    local safe, msg = _ad:_cs()
    if not safe then
        print(_X('[!] Unsafe environment', 17))
        return false
    end
    
    _esp[_X('active', 23)] = true
    print(_X('[+] ESP started (stealth mode)', 17))
    return true
end

-- Stop ESP
local function _st()
    _esp[_X('active', 23)] = false
    print(_X('[-] ESP stopped', 17))
end

-- Get objects
local function _go()
    return _esp[_X('objects', 23)] or {}
end

-- Update loop (da chiamare periodicamente)
local function _ul()
    if _esp[_X('active', 23)] then
        _esp:_ds()
    end
end

-- ========= EXPORT (OFFUSCATO) =========

-- Usa nomi offuscati per export
local _e = _G(12) -- Nome casuale
rawset(_G, _e, {
    [_X('start', 11)] = _se,
    [_X('stop', 11)] = _st,
    [_X('get', 11)] = _go,
    [_X('update', 11)] = _ul,
    [_X('config', 11)] = _cfg
})

-- Alias più leggibili (opzionali, commentare per max stealth)
rawset(_G, 'ESP_Stealth', {
    start = _se,
    stop = _st,
    get_objects = _go,
    update = _ul,
    config = _cfg
})

-- ========= AUTO-START (OPZIONALE) =========

-- Uncomment per auto-start
-- _se()

print('[ESP_Stealth] Loaded (obfuscated)')
