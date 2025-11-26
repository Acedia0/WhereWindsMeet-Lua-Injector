-- It will search for all loaded GM modules and WRITE their functions to a file.
local output_file = "C:\\temp\\Where Winds Meet\\Logs\\cheats_output.txt"
local file = io.open(output_file, "w")
if not file then
    print("Error: Could not open file for writing: " .. output_file)
    return
end
file:write("========== CHEAT FINDER STARTED ==========\n")
-- 1. Search in package.loaded for GM modules
for module_name, module_data in pairs(package.loaded) do
    -- Look for modules that contain "gm" or "debug"
    if type(module_name) == "string" and (module_name:find("gm") or module_name:find("debug")) then
        file:write("\n[+] Module Found: " .. module_name .. "\n")
        
        if type(module_data) == "table" then
            for key, value in pairs(module_data) do
                if type(value) == "function" then
                    file:write("    -> Function: " .. key .. "\n")
                end
            end
        end
    end
end
file:write("\n========== CHEAT FINDER FINISHED ==========\n")
file:close()
print("Cheat Finder finished. Check the file: " .. output_file)