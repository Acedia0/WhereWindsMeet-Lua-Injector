-- RunCheats.lua
-- A clean launcher for CheatController.lua
-- This avoids setting global flags that cause UI artifacts (Chinese text, debug menus).

local cheat_controller_path = "C:\\temp\\Where Winds Meet\\Scripts\\CheatController.lua"

print("[RunCheats] Attempting to run CheatController...")

local status, err = pcall(dofile, cheat_controller_path)

if status then
    print("[RunCheats] CheatController executed successfully.")
else
    print("[RunCheats] ERROR: Failed to execute CheatController.")
    print("[RunCheats] Error details: " .. tostring(err))
end
