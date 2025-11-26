-- CheatController.lua
-- Reads cheat_config.lua and applies settings to the game.
-- Run this script (Press '1') to reload the configuration.

local config_path = "C:\\temp\\Where Winds Meet\\Config\\cheat_config.lua"
local log_file_path = "C:\\temp\\Where Winds Meet\\Logs\\cheat_controller.log"

local function log(msg)
    local f = io.open(log_file_path, "a")
    if f then
        f:write("[CheatController] " .. tostring(msg) .. "\n")
        f:close()
    end
end

log("\n========================================")
log("CheatController Run Started (CLEANED)")
log("========================================")

local function safe_require(module_name)
    local mod = package.loaded[module_name]
    if not mod then
        local status, res = pcall(require, module_name)
        if status then mod = res or package.loaded[module_name] end
    end
    return mod
end

local function safe_call(module_name, func_name, ...)
    local mod = safe_require(module_name)
    if mod and mod[func_name] then
        local status, result = pcall(mod[func_name], ...)
        if status then
            log("SUCCESS: " .. func_name .. " applied.")
            return true
        else
            log("ERROR: Failed to call " .. func_name .. ": " .. tostring(result))
        end
    else
        -- log("WARNING: Module or function not found: " .. module_name .. "." .. func_name)
    end
    return false
end

local function apply_config()
    log("Loading configuration...")
    local status, config = pcall(dofile, config_path)
    
    if not status or type(config) ~= "table" then
        log("CRITICAL ERROR: Could not load config file! " .. tostring(config))
        return
    end
    
    log("Applying Cheats...")

    -- ========================================================================
    -- 1. GOD MODE (Confirmed Working)
    -- ========================================================================
    if config.GodMode then
        safe_call("hexm.client.debug.gm.gm_commands.gm_combat", "gm_set_invincible", true)
        log("-> God Mode Applied")
    else
        safe_call("hexm.client.debug.gm.gm_commands.gm_combat", "gm_set_invincible", false)
    end

    -- ========================================================================
    -- 2. INFINITE STAMINA (Confirmed Working)
    -- ========================================================================
    if config.InfiniteStamina then
        safe_call("hexm.client.debug.gm.gm_commands.gm_combat", "gm_lock_res_consume", true)
        safe_call("hexm.client.debug.gm.gm_commands.gm_combat", "gm_unlimited_dive_resource", true)
        log("-> Infinite Stamina Applied (Lock Res + Unlimited Dive)")
    else
        safe_call("hexm.client.debug.gm.gm_commands.gm_combat", "gm_lock_res_consume", false)
        safe_call("hexm.client.debug.gm.gm_commands.gm_combat", "gm_unlimited_dive_resource", false)
        log("-> Infinite Stamina Removed")
    end

    -- ========================================================================
    -- 3. DAMAGE BONUS (Confirmed Working)
    -- ========================================================================
    -- Adds extra damage to the player (Target ID 1)
    if config.DamageBonus and config.DamageBonus > 0 then
        safe_call("hexm.client.debug.gm.gm_commands.gm_combat", "gm_add_damage", 1, config.DamageBonus)
        log("-> Damage Bonus Applied: " .. tostring(config.DamageBonus))
    else
        safe_call("hexm.client.debug.gm.gm_commands.gm_combat", "gm_add_damage", 1, 0)
        log("-> Damage Bonus Removed")
    end

    -- ========================================================================
    -- 4. RECOVER STATUS (Confirmed Working)
    -- ========================================================================
    if config.RecoverStatus then
        safe_call("hexm.client.debug.gm.gm_commands.gm_combat", "gm_recover", 1)
        log("-> Status Recovered (Health/Stamina Refilled)")
    end

    log("Configuration Reloaded Successfully!")
end

-- Wrap main execution in pcall
local status, err = pcall(apply_config)
if not status then
    log("FATAL ERROR in CheatController: " .. tostring(err))
end
