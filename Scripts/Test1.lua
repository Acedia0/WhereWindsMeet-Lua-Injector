-- ============================================================
--  FULL TEST LUA / AUTO-GM CHEATS FOR WHERE WINDS MEET
-- ============================================================

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

-- ========= GM MODULES =========
local ok_combat, gm_combat = pcall(require, "hexm.client.debug.gm.gm_commands.gm_combat")
local ok_player, gm_player = pcall(require, "hexm.client.debug.gm.gm_commands.gm_player")
local ok_move, gm_move     = pcall(require, "hexm.client.debug.gm.gm_commands.gm_move")

-- ========= ALWAYS-ON CHEATS =========
local player_id = 1
local default_damage = 99999999
local default_xp = 200000

-- GODMODE
if ok_combat and gm_combat and gm_combat.gm_set_invincible then
    gm_combat.gm_set_invincible(1)
    print("[✔] Godmode ON")
end

-- NOCLIP
if ok_move and gm_move and gm_move.gm_set_noclip then
    gm_move.gm_set_noclip(1)
    print("[✔] Noclip ON")
end

-- ONE HIT KILL
if ok_combat and gm_combat and gm_combat.gm_add_damage then
    gm_combat.gm_add_damage(player_id, default_damage)
    print("[✔] One-hit kill mode armed")
end

-- SPEED x2
if ok_move and gm_move and gm_move.gm_set_speed then
    gm_move.gm_set_speed(2)
    print("[✔] Speed x2")
end

-- NO COOLDOWN
if ok_combat and gm_combat and gm_combat.gm_no_cd then
    gm_combat.gm_no_cd()
    print("[✔] No skill cooldowns")
end

-- ========= AUTO LOOP =========
createThread(function()
    while true do
        -- Auto stamina
        if ok_player and gm_player then
            if gm_player.gm_set_stamina then gm_player.gm_set_stamina(999999) end
            if gm_player.gm_add_stamina then gm_player.gm_add_stamina(999999) end
            if gm_player.gm_full_stamina then gm_player.gm_full_stamina() end
        end

        -- Auto energy
        if ok_player and gm_player then
            if gm_player.gm_set_energy then gm_player.gm_set_energy(999999) end
            if gm_player.gm_add_energy then gm_player.gm_add_energy(999999) end
            if gm_player.gm_full_energy then gm_player.gm_full_energy() end
        end

        -- Auto XP
        if ok_player and gm_player and gm_player.gm_add_xp then
            gm_player.gm_add_xp(default_xp)
        end

        -- Auto buff (example, can adjust buff id)
        if ok_combat and gm_combat and gm_combat.gm_add_buff then
            gm_combat.gm_add_buff(player_id, 1)
        end

        sleep(50)
    end
end)

print("[✔] ALL cheats active. Enjoy.")
