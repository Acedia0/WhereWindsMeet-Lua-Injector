-- DumpIDs.lua
-- Script to investigate and dump Item IDs

local log_file_path = "C:\\temp\\Where Winds Meet\\Logs\\item_ids.log"

-- Backup previous log if it exists
local f_check = io.open(log_file_path, "r")
if f_check then
    f_check:close()
    local date_str = os.date("%Y%m%d_%H%M%S")
    local backup_path = "C:\\temp\\Where Winds Meet\\Logs\\item_ids_backup_" .. date_str .. ".log"
    os.rename(log_file_path, backup_path)
end

local function log(msg)
    -- print("[DumpIDs] " .. tostring(msg))
    local f = io.open(log_file_path, "a")
    if f then
        f:write("[DumpIDs] " .. tostring(msg) .. "\n")
        f:close()
    end
end

local function dump_table(tbl, name, max_depth)
    if not tbl then return end
    max_depth = max_depth or 1
    if max_depth <= 0 then return end

    log("Dumping table: " .. name)
    for k, v in pairs(tbl) do
        log(string.format("  [%s] = %s", tostring(k), tostring(v)))
        if type(v) == "table" and max_depth > 1 then
            -- Recursive dump (be careful with large tables)
            -- dump_table(v, name .. "." .. tostring(k), max_depth - 1)
        end
    end
end

-- Add a separator for each run to distinguish multiple presses
log("\n========================================")
log("DumpIDs Run Started")
log("========================================")

-- Helper to call GM functions from their modules
local function call_gm(module_name, func_name, ...)
    local mod = package.loaded[module_name]
    if not mod then
        local status, res = pcall(require, module_name)
        if status then mod = res or package.loaded[module_name] end
    end

    if mod and mod[func_name] then
        local status, result = pcall(mod[func_name], ...)
        if status then
            log("SUCCESS: Called " .. func_name)
            return result
        else
            log("ERROR calling " .. func_name .. ": " .. tostring(result))
            return nil
        end
    else
        log("FAIL: Module or function not found: " .. module_name .. "." .. func_name)
        return nil
    end
end

log("Starting Item ID Investigation...")

-- 1. Check for obvious global tables
local potential_names = {
    "ItemConfig", "StuffConfig", "EquipConfig", "ItemTable", "StuffTable", 
    "G_Item", "G_Stuff", "Config"
}

for _, name in ipairs(potential_names) do
    if _G[name] then
        log("FOUND GLOBAL TABLE: " .. name)
        dump_table(_G[name], name, 1)
    end
end

-- 2. Hook print, dump, warn, error
local original_print = print
local original_dump = dump
local original_warn = warn
local original_error = error

local function capture_output(prefix, ...)
    local args = {...}
    local str = ""
    for i, v in ipairs(args) do
        str = str .. tostring(v) .. "\\t"
    end
    log(prefix .. str)
end

print = function(...) capture_output("[CAPTURED PRINT] ", ...) end
dump = function(...) capture_output("[CAPTURED DUMP] ", ...) end
warn = function(...) capture_output("[CAPTURED WARN] ", ...) end
error = function(...) capture_output("[CAPTURED ERROR] ", ...) end

log("Output functions hooked. Attempting GM commands...")

-- 3. Inspect gm_stuff.add_stuff_count upvalues (might have item table)
log("Inspecting gm_stuff.add_stuff_count upvalues...")
local stuff_mod = package.loaded["hexm.client.debug.gm.gm_commands.gm_stuff"]
if stuff_mod and stuff_mod.add_stuff_count then
    local i = 1
    while true do
        local name, val = debug.getupvalue(stuff_mod.add_stuff_count, i)
        if not name then break end
        log("UPVALUE (add_stuff_count): " .. tostring(name) .. " = " .. tostring(val))
        if type(val) == "table" then
             local count = 0
             for _ in pairs(val) do count = count + 1 end
             log("  -> Table size: " .. count)
             if count > 100 then
                 log("  -> Potential Item Table! Dumping first 10...")
                 local dumped = 0
                 for k, v in pairs(val) do
                     log("    [" .. tostring(k) .. "] = " .. tostring(v))
                     dumped = dumped + 1
                     if dumped >= 10 then break end
                 end
             end
        end
        i = i + 1
    end
else
    log("gm_stuff.add_stuff_count not found")
end

-- 4. Call gm_stuff.gen_gm_equip_suite_list() and inspect CList
if stuff_mod and stuff_mod.gen_gm_equip_suite_list then
    log("Calling gen_gm_equip_suite_list()...")
    local status, res = pcall(stuff_mod.gen_gm_equip_suite_list)
    if status then
        local res_type = type(res)
        log("SUCCESS: gen_gm_equip_suite_list returned type: " .. res_type)
        
        -- Handle "list" type (custom game type) or table or userdata
        if res_type == "list" or res_type == "table" or res_type == "userdata" then
             log("Inspecting result as list...")
             
             -- Try to get count using # operator
             local count = nil
             local status_len, len = pcall(function() return #res end)
             if status_len then 
                 count = len 
                 log("  -> Count (#res): " .. tostring(count))
             else
                 log("  -> Could not get count via # operator")
             end
             
             -- Iterate MORE items to get the "long list" back
             log("  -> Dumping items (max 2000)...")
             for i = 0, 2000 do
                 local status_get, val = pcall(function() return res[i] end)
                 if status_get and val then
                     local val_type = type(val)
                     local val_str = tostring(val)
                     log("  [" .. i .. "] = " .. val_str .. " (Type: " .. val_type .. ")")
                     
                     -- If it's a CList (userdata), try to inspect it deeply
                     if val_type == "userdata" or val_type == "list" or val_type == "table" or string.find(val_str, "List") then
                         
                         -- 1. Dump Metatable to find methods
                         local mt = getmetatable(val)
                         if mt then
                             log("    -> Metatable found! Dumping keys...")
                             for k, v in pairs(mt) do
                                 log("      MT[" .. tostring(k) .. "] = " .. tostring(v))
                             end
                             -- Check __index if it's a table
                             if type(mt.__index) == "table" then
                                 log("      -> __index is table. Dumping keys...")
                                 for k, v in pairs(mt.__index) do
                                     log("        __index[" .. tostring(k) .. "] = " .. tostring(v))
                                 end
                             end
                         else
                             log("    -> No metatable found.")
                         end

                         -- 2. Try various access methods
                         local inner_count = "unknown"
                         pcall(function() inner_count = #val end)
                         pcall(function() if val.Count then inner_count = val.Count end end)
                         pcall(function() if val.Count then inner_count = val:Count() end end)
                         log("    -> Count attempt: " .. tostring(inner_count))

                         -- Try GetItem / At / toTable
                         pcall(function() 
                            if val.GetItem then 
                                log("    -> Found GetItem method. Trying val:GetItem(0)...")
                                log("      Result: " .. tostring(val:GetItem(0)))
                            end
                         end)
                         pcall(function() 
                            if val.ToTable then 
                                log("    -> Found ToTable method. Converting...")
                                local t = val:ToTable()
                                log("      Result type: " .. type(t))
                            end
                         end)

                         -- Blindly iterate some items using numeric index again, just in case
                         for j = 0, 5 do
                             local s4, v4 = pcall(function() return val[j] end)
                             if s4 and v4 then
                                 log("      SubItem[" .. j .. "] = " .. tostring(v4))
                             end
                         end
                         
                         -- Only do deep inspection for the first few lists to avoid log spam
                         if i > 2 then 
                            log("    -> Skipping deep inspection for remaining lists.")
                         end
                     end
                 else
                     if count and i >= count then break end
                     if i > 100 and not val then break end
                 end
             end
        end
    else
        log("ERROR calling gen_gm_equip_suite_list: " .. tostring(res))
    end
end

-- 5. Inspect hexm.client.config.entity_config
log("Inspecting hexm.client.config.entity_config...")
local entity_config = package.loaded["hexm.client.config.entity_config"]
if entity_config then
    -- Inspect the singleton instance 'config'
    if entity_config.config then
        log("Inspecting entity_config.config instance...")
        local cfg = entity_config.config
        
        -- Try to dump fields if it's a table/userdata
        local status_pairs, iter, state, idx = pcall(pairs, cfg)
        if status_pairs then
            log("  Dumping fields of entity_config.config:")
            local count = 0
            -- Wrap the loop iteration in pcall if possible, but pairs iterator is hard to wrap safely in a for loop
            -- Instead, we'll try manual iteration if pairs worked
            local s_loop, err = pcall(function()
                if type(iter) == "function" then
                    for k, v in iter, state, idx do
                        log("    ." .. tostring(k) .. " = " .. tostring(v))
                        count = count + 1
                        if count > 20 then break end
                    end
                else
                    log("    -> Iterator is not a function: " .. tostring(iter))
                end
            end)
            if not s_loop then log("  Error iterating entity_config.config: " .. tostring(err)) end
        else
            log("  Could not iterate entity_config.config with pairs()")
        end
        
        -- Try to find a 'get' method or similar
        if cfg.get_item then log("  Found method: get_item") end
        if cfg.GetItem then log("  Found method: GetItem") end
        if cfg.items then log("  Found field: items") end
        if cfg.data then log("  Found field: data") end
    end

    -- Inspect the class 'EntityConfig' to see methods
    if entity_config.EntityConfig then
        log("Inspecting EntityConfig class...")
        local cls = entity_config.EntityConfig
        local s_cls, err_cls = pcall(function()
            for k, v in pairs(cls) do
                 log("  Class Field: " .. tostring(k) .. " = " .. tostring(v))
            end
        end)
        if not s_cls then log("  Error iterating EntityConfig class: " .. tostring(err_cls)) end
    end
else
    log("hexm.client.config.entity_config not loaded")
end

log("Investigation Complete.")

-- Restore functions
print = original_print
dump = original_dump
warn = original_warn
error = original_error
log("Investigation Complete.")

-- Restore print
print = original_print
log("Investigation Complete.")
