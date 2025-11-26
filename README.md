# WhereWindsMeet-Lua-Frida-Injector

**Proof-of-concept Lua injector for _Where Winds Meet_ (PC)** using:

- a **proxy `dinput8.dll`** placed in the same folder as `wwm.exe` (the game executable)
- **Frida Gadget** (`frida-gadget.dll`)
- a small **Python loader** (`Loader_gadget.py`)
- a **Frida JS script** (`hook.js`) that hooks the game’s internal `lua_load` and `lua_pcall`

This mini project was built as an experiment to confirm that:
- the game uses a **custom Lua 5.4 VM** internally, and  
- it is possible to **inject and run custom Lua scripts**, open the debug / GM console and tweak various flags.

It is **not** a polished tool or trainer, just a working testbed.

> ⚠️ **Disclaimer**
> - This project is for **educational / reverse-engineering purposes only**.  


---

## Project layout

Everything lives under:

```text
C:\temp\Where Winds Meet\
```

Example layout:

```text
C:\temp\Where Winds Meet\
│
├─ Config\
│   └─ cheat_config.lua        # Configurable cheat settings
│
├─ Scripts\
│   └─ Test.lua                # Example Lua test script (entry point)
│   └─ CheatController.lua     # This fork's cheat logic
│
├─ dinput8.dll                 # Proxy DLL, placed next to wwm.exe (game folder)
├─ frida-gadget.config         # Frida Gadget configuration
├─ frida-gadget.dll            # Frida Gadget binary
├─ hook.js                     # Frida JS script (hooks lua_load / lua_pcall)
└─ Loader_gadget.py            # Python loader for Frida Gadget
```

The **proxy `dinput8.dll`** is dropped in the **game folder** (next to `wwm.exe`).  
At runtime, it will:

1. Load the real system `dinput8.dll` from:

   ```text
   C:\Windows\System32\dinput8.dll
   ```

2. Also load **`frida-gadget.dll`** from:

   ```text
   C:\temp\Where Winds Meet\
   ```

From there, Frida Gadget injects `hook.js` into the `wwm.exe` process.


---

## How it works (high level)

1. **Game start & dinput proxy**
   - When `wwm.exe` starts, Windows loads `dinput8.dll` from the **game directory first**.
   - Our **proxy `dinput8.dll`** forwards calls to the **real** `dinput8.dll` in `System32`, so the game still works normally.
   - It also loads `frida-gadget.dll` (Frida Gadget) from `C:\temp\Where Winds Meet\`.

2. **Frida Gadget + Python loader**
   - `frida-gadget.dll` exposes a Frida Gadget endpoint (default: `127.0.0.1:27042`).
   - `Loader_gadget.py` connects to this Gadget and injects the JS script `hook.js` into `wwm.exe`.

3. **Hooking `lua_load` and `lua_pcall`**
   - `hook.js` scans `wwm.exe` for the internal Lua functions using the following x64 signatures:

     ```c
     const SIG_LUA_LOAD =
       "48 89 5C 24 10 56 48 83 EC 50 49 8B D9 48 8B F1 4D 8B C8 4C 8B C2 48 8D 54 24 20";

     const SIG_LUA_PCALL =
       "48 89 74 24 18 57 48 83 EC 40 33 F6 48 89 6C 24 58 49 63 C1 41 8B E8 48 8B F9 45 85 C9";
     ```

   - Once the addresses are found, it creates `NativeFunction` wrappers and hooks `lua_pcall`.
   - When you press **key `1`**, the script arms an injection: on the **next `lua_pcall`**, a minimal Lua loader chunk is executed.

4. **Lua loader + `Test.lua`**
   - The injected Lua chunk does essentially:

     ```lua
     local path = [[C:\temp\Where Winds Meet\Scripts\Test.lua]]
     local f, err = loadfile(path)
     if not f then
       print("[inject] loadfile failed:", err)
     else
       local ok, err2 = pcall(f)
       if not ok then
         print("[inject] error in Test.lua:", err2)
       end
     end
     ```

   - This means **all your actual logic lives in `Scripts\Test.lua`** (or whatever you point it to):
     - Enable debug / GM menu
     - Toggle debug flags
     - Patch game tables, etc.

## 🔧 Configuration (`cheat_config.lua`)

All cheat settings are controlled through:
```bash
C:\temp\Where Winds Meet\Config\cheat_config.lua
```
- Open this file in any text editor and modify the values as needed. Example:
```lua
return {
    GodMode = true,
    InfiniteStamina = true,
    DamageBonus = 10,
    RecoverStatus = true,
}
```
- Save the file after making your changes.
- Press "1" to reload changes when playing game.
---

## Requirements

- **OS**: Windows x64
- **Game**: PC version of *Where Winds Meet*
- **Python**: 3.x (e.g. 3.10+)
- **Python modules**:
  - [`frida`](https://pypi.org/project/frida/)
  - `argparse` & `json` (standard library; no extra install needed)

Install Frida for Python:

```bash
pip install frida
# (frida-tools optional but useful)
pip install frida-tools
```


---

## Setup

### 1. Clone / copy the project

Place the project under:

```text
C:\temp\Where Winds Meet\
```

You should end up with:

```text
C:\temp\Where Winds Meet\
│   dinput8.dll
│   frida-gadget.dll
│   frida-gadget.config
│   hook.js
│   Loader_gadget.py
├─ Config\
│   └─ cheat_config.lua
└── Scripts\
    └── Test.lua
    └─ CheatController.lua
```

### 2. Drop the proxy DLL into the game folder

Find your game install folder and place **`dinput8.dll`** next to `wwm.exe`, for example:

```text
<Your Game Folder>\...\wwm.exe
<Your Game Folder>\...\dinput8.dll   # <-- proxy DLL from this project
```

The system `dinput8.dll` in `C:\Windows\System32\` remains untouched.

### 3. Make sure Python + Frida are installed

- Install [Python 3](https://www.python.org/) if not already installed.
- Install the Frida Python package:

  ```bash
  pip install frida
  ```

### 4. Check / adjust `frida-gadget.config` (optional)

By default, the config is expected to:
- listen on `127.0.0.1:27042`
- use `hook.js` as the injected script (via `Loader_gadget.py`)

You can adjust behavior if needed, but the provided config is meant for the described workflow.


---

## Launch & usage

### 1. Start the game

1. Launch *Where Winds Meet* normally.
2. Wait until the actual **`wwm.exe`** game process is running (not just the launcher).

### 2. Run the Python loader

Open **PowerShell** in the project directory:

```powershell
PS C:\temp\Where Winds Meet> python Loader_gadget.py
# or, depending on your setup:
PS C:\temp\Where Winds Meet> py Loader_gadget.py
```

The script will:

- Connect to Frida Gadget at `127.0.0.1:27042`
- Attach to the `wwm.exe` process
- Load `hook.js`
- Start logging Frida messages to `frida_hook_log.json`

You should see logs like:

```text
[*] Connecting to Gadget at 127.0.0.1:27042 ...
[OK] Selected process: pid=... name=wwm.exe
[*] Attach ...
[OK] Script loaded: hook.js
[📄] Logs -> C:\temp\Where Winds Meet\frida_hook_log.json
[⏳] Ctrl+C to quit.
```

### 3. Trigger Lua injection

- Once the injector is running and the game is in Lua code:
  - Press the **`1` key** (top row numeric key) in the console window that runs `hook.js` / Frida.
  - The script arms an injection: at the **next call to `lua_pcall`** inside the game, the loader chunk is executed.
  - That loader then performs `loadfile + pcall` on:

    ```text
    C:\temp\Where Winds Meet\Scripts\Test.lua
    ```

> ⚠️ Some Lua scripts (for example those enabling the debug / GM menu) must be injected **before the end of the loading sequence** to take effect properly.  
> If injection is “too late”, you may need to restart the game and trigger the hotkey earlier.

### 4. Stopping the injector

- Press **Ctrl+C** in the console where `Loader_gadget.py` is running.
- The script will try to unload the Frida script and detach cleanly:

```text
[*] Done.
```


---

## Writing your own Lua scripts

The entry point used by the loader is:

```text
C:\temp\Where Winds Meet\Scripts\Test.lua
```

Inside `Test.lua`, you can:

- Open or configure the **debug / GM menu**
- Modify global tables or flags
- Use helper scripts (like `Debug_console.lua`) to recursively force flags such as:

  ```lua
  DEBUG                     = true
  DISABLE_ACSDK             = true
  ENABLE_DEBUG_PRINT        = true
  ENABLE_FORCE_SHOW_GM      = true
  FORCE_OPEN_DEBUG_SHORTCUT = true
  GM_IS_OPEN_GUIDE          = true
  GM_USE_PUBLISH            = true
  acsdk_info_has_inited     = false
  ```

Anything reachable from the game’s Lua environment can potentially be inspected or patched.


---

## Turning this into a “real” project

This repository is currently just a **research / PoC setup**.  
To turn it into a more serious / robust project, you would probably want to:

1. **Remove the Frida dependency**
   - Implement a custom native DLL that:
     - Loads into `wwm.exe` (still via `dinput8.dll` proxy or another injection method).
     - Scans for `lua_load` / `lua_pcall` signatures internally.
     - Hooks them using a library like **MinHook** or your own trampoline code or others hooking methods.
   - Expose your own API to execute Lua chunks from disk or memory.

2. **Handle game updates / versions**
   - The current signatures are intentionally chosen to be resilient to address changes caused by recompilation.
   - However, major code changes or layout differences between builds can still break them, so it’s worth adding version checks / sanity checks (e.g. game build, module size, extra validation around scan results).
   - Optionally provide a small diagnostic mode that only scans, reports the found addresses, and verifies they look like valid `lua_load` / `lua_pcall` before enabling any hooks.

3. **Better configuration & UX**
   - Config file to:
     - Change the Lua script path (not only `Scripts\Test.lua`).
     - Enable/disable auto-flag modifications (debug flags, GM, etc.).
   - In-game UI overlays or an external controller instead of a plain console + key `1`.

4. **Safety & stability**
   - Better error handling around injection timing.
   - Logging of Lua errors, stack traces, etc. into a dedicated log view.
   - Optionally provide a “dry run” / inspection mode that only dumps tables and does not patch anything.

5. **Abstraction for Lua utilities**
   - Helpers to:
     - Inspect global tables
     - Patch flags in a controlled way
     - Register new commands / console actions
   - Possibly wrap the internal Lua state with a small C API for power users.


---

## Status (edited after recent game patches)

- ✅ Verified that:
  - The game uses a **custom Lua 5.4 VM**.
  - It is still possible to **inject and run custom Lua scripts**.
  - Debug / GM-related behavior can be toggled via Lua.

- 🛠️ GM / debug behavior (post-patch):
  - Recent game updates **patched the opening of the in-game GM / debug menu UI**.
  - However, the underlying **GM functions are still callable directly from Lua**.
    For example, to control invincibility:

    ```lua
    -- Enable invincibility
    package.loaded["hexm.client.debug.gm.gm_commands.gm_combat"].gm_set_invincible(1)

    -- Disable / toggle invincibility
    package.loaded["hexm.client.debug.gm.gm_commands.gm_combat"].gm_set_invincible()
    ```

  - `Dump_env.lua` is useful to find **all GM-related functions** that correspond to the (now patched) GM menu features.
  - I also recommend using `Trace_call.lua` to **analyze which internal functions (and with which arguments)** are actually called by these GM helpers before their removal.
    Example of a trace for what is really called inside `gm_set_invincible`:

    ```text
    Enable invincibility :
    
    CALL gm_set_invincible (hexm/client/debug/gm/gm_commands/gm_oversea.lua:53)  args: (...1=1)
    CALL <anonymous> (hexm/client/debug/gm/gm_commands/gm_combat.lua:35)  args: (value=1)
      CALL add_buff (hexm/client/debug/gm/gm_commands/gm_oversea.lua:53)  args: (...1=70063, ...2="aRyXXXXXXXXXXX")
      CALL <anonymous> (hexm/client/debug/gm/gm_commands/gm_combat.lua:434)  args: (buff_no=70063, eid="aRyXXXXXXXXXXX", duration=nil, buff_level=nil, fromid=nil)
        CALL get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)  args: (self=<instance of Network at 1772025FA00>)
        RET  get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)
        CALL fake_server (hexm/client/entities/local/space.lua:298)  args: (self=<instance of Space at 1771C91C9C0>)
          CALL spaceno (hexm/client/entities/local/space.lua:156)  args: (self=<instance of Space at 1771C91C9C0>)
          RET  spaceno (hexm/client/entities/local/space.lua:156)
          CALL spaceid (hexm/client/entities/local/space.lua:168)  args: (self=<instance of Space at 1771C91C9C0>)
          RET  spaceid (hexm/client/entities/local/space.lua:168)
        CALL <anonymous> (hexm/client/fake_server/entities/space.lua:153)  args: (cls=<class FakeSpaceFactory at 000001774600D3B0>, spaceno=501, spaceid="aRyzyXXXXXXXXX")
          CALL is_destroyed (hexm/client/fake_server/entities/fake_base.lua:104)  args: (self=<instance of Space at 1775BA8FF40>)
          RET  is_destroyed (hexm/client/fake_server/entities/fake_base.lua:104)
        RET  <anonymous> (hexm/client/fake_server/entities/space.lua:153)
        CALL get_entity (hexm/client/fake_server/entities/space.lua:35)  args: (self=<instance of Space at 1775BA8FF40>, eid="aRyXXXXXXXXXXX")
        CALL <anonymous> (hexm/client/fake_server/entities/components/entity_manager_proxy.lua:18)  args: (self=<instance EntitiesProxy at 000001775BA8F770>, k="aRyXXXXXXXXXXX", default=nil)
        RET  <anonymous> (hexm/client/fake_server/entities/components/entity_manager_proxy.lua:18)
        CALL is_client_space (hexm/client/entities/local/space.lua:249)  args: (self=<instance of Space at 1771C91C9C0>)
        CALL <anonymous> (hexm/common/misc/mode_misc.lua:16)  args: (space=<instance of Space at 1771C91C9C0>)
          CALL get_space_mode (hexm/common/misc/mode_misc.lua:98)  args: (space=<instance of Space at 1771C91C9C0>)
            CALL get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)  args: (self=<instance of Network at 1772025FA00>)
            RET  get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)
          RET  get_space_mode (hexm/common/misc/mode_misc.lua:98)
        RET  <anonymous> (hexm/common/misc/mode_misc.lua:16)
        CALL add_buff (hexm/client/fake_server/entities/common_members/buff_base.lua:167)  args: (self=<instance of FakePlayerAvatar at 1774B679D00>, buff_no=70063, fromid="aRyXXXXXXXXXXX", kwargs={level: 1})
          CALL get_buff_sys_d (hexm/common/misc/buff_misc.lua:13)  args: (buff_no=70063, level=nil)
          RET  get_buff_sys_d (hexm/common/misc/buff_misc.lua:13)
          CALL is_client_buff (hexm/common/consts/buff_consts.lua:189)  args: (sys_d={ignore_behit_type: 3, buff_destroy_fromer: [1, 1, 1, 1], buff_estimate: 1, buff_control_type: 0, buff_destroy_cond: 0, immune_damage: [1, 2], immnue_damage_times: [-1, 0], is_client_display: 0, buff_id: 70063, buff_show_flag: 1, immune_all_controlbuff: 1, has_fake_need: 1, buff_destroy_owner: [1, 1, 1, 1], buff_specialshow_priority: 1, buff_name: -3307847279787213631, has_anti_need: 1, buff_maxtime: -1.0, buff_show_priority: 1, buff_type: 1})
          RET  is_client_buff (hexm/common/consts/buff_consts.lua:189)
          CALL call_server_with_token (hexm/client/net/network_comp/net_call_rpc.lua:96)  args: (self=<instance of Network at 1772025FA00>, tag="buff", rpc_method="rpc_clientify_call_buff", ...1="add_buff", ...2="aRyXXXXXXXXXXX")
            CALL get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)  args: (self=<instance of Network at 1772025FA00>)
            RET  get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)
            CALL gen (hexm/common/util/hotp.lua:73)  args: (self=<instance Hotp at 00000177202600E0>, ts=1763665291)
            CALL <anonymous> (hexm/common/util/hotp.lua:88)  args: (self=<instance Hotp at 00000177202600E0>, tt=36786, seq=7)
            CALL <anonymous> (hexm/common/util/crc32.lua:56)  args: (h=301203463, crc=nil)
            RET  <anonymous> (hexm/common/util/crc32.lua:56)
            CALL ? (engine/client/AsioServerProxy.lua:37)  args: (self=<instance AsioServerProxy at 000001772DA8E000>, ...1=1186793276, ...2="add_buff", ...3="aRyXXXXXXXXXXX", ...4=[70063, aRyXXXXXXXXXXX, {level: 1}])
              CALL callserver (engine/client/AsioServerProxy.lua:24)  args: (...1="", ...2=199962398, ...3=[1186793276, add_buff, aRyXXXXXXXXXXX, [70063, aRyXXXXXXXXXXX, {level: 1}]])
              RET  callserver (engine/client/AsioServerProxy.lua:24)
            RET  ? (engine/client/AsioServerProxy.lua:37)
          RET  call_server_with_token (hexm/client/net/network_comp/net_call_rpc.lua:96)
        RET  add_buff (hexm/client/fake_server/entities/common_members/buff_base.lua:167)
      RET  <anonymous> (hexm/client/debug/gm/gm_commands/gm_combat.lua:434)
    RET  <anonymous> (hexm/client/debug/gm/gm_commands/gm_combat.lua:35)

    Disable invincibility :
    
    CALL gm_set_invincible (hexm/client/debug/gm/gm_commands/gm_oversea.lua:53)  args: ()
    CALL <anonymous> (hexm/client/debug/gm/gm_commands/gm_combat.lua:35)  args: (value=nil)
      CALL rm_buff (hexm/client/debug/gm/gm_commands/gm_oversea.lua:53)  args: (...1=70063, ...2="aRyXXXXXXXXXXX")
      CALL <anonymous> (hexm/client/debug/gm/gm_commands/gm_combat.lua:476)  args: (buff_no=70063, eid="aRyXXXXXXXXXXX", fromid=nil)
        CALL fake_server (hexm/client/entities/local/space.lua:298)  args: (self=<instance of Space at 1771C91C9C0>)
          CALL spaceno (hexm/client/entities/local/space.lua:156)  args: (self=<instance of Space at 1771C91C9C0>)
          RET  spaceno (hexm/client/entities/local/space.lua:156)
          CALL spaceid (hexm/client/entities/local/space.lua:168)  args: (self=<instance of Space at 1771C91C9C0>)
          RET  spaceid (hexm/client/entities/local/space.lua:168)
        CALL <anonymous> (hexm/client/fake_server/entities/space.lua:153)  args: (cls=<class FakeSpaceFactory at 000001774600D3B0>, spaceno=501, spaceid="aRyzyXXXXXXXXX")
          CALL is_destroyed (hexm/client/fake_server/entities/fake_base.lua:104)  args: (self=<instance of Space at 1775BA8FF40>)
          RET  is_destroyed (hexm/client/fake_server/entities/fake_base.lua:104)
        RET  <anonymous> (hexm/client/fake_server/entities/space.lua:153)
        CALL get_entity (hexm/client/fake_server/entities/space.lua:35)  args: (self=<instance of Space at 1775BA8FF40>, eid="aRyXXXXXXXXXXX")
        CALL <anonymous> (hexm/client/fake_server/entities/components/entity_manager_proxy.lua:18)  args: (self=<instance EntitiesProxy at 000001775BA8F770>, k="aRyXXXXXXXXXXX", default=nil)
        RET  <anonymous> (hexm/client/fake_server/entities/components/entity_manager_proxy.lua:18)
        CALL is_client_space (hexm/client/entities/local/space.lua:249)  args: (self=<instance of Space at 1771C91C9C0>)
        CALL <anonymous> (hexm/common/misc/mode_misc.lua:16)  args: (space=<instance of Space at 1771C91C9C0>)
          CALL get_space_mode (hexm/common/misc/mode_misc.lua:98)  args: (space=<instance of Space at 1771C91C9C0>)
            CALL get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)  args: (self=<instance of Network at 1772025FA00>)
            RET  get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)
          RET  get_space_mode (hexm/common/misc/mode_misc.lua:98)
        RET  <anonymous> (hexm/common/misc/mode_misc.lua:16)
        CALL remove_buffs_by_No (hexm/client/fake_server/entities/common_members/buff_base.lua:239)  args: (self=<instance of FakePlayerAvatar at 1774B679D00>, buffs_no=70063, fromid=0)
          CALL get_buff_by_No (hexm/client/entities/server/common_members/buff_base.lua:73)  args: (self=<instance of PlayerAvatar at 1774A821620>, buff_no=70063, fromid=0)
          RET  get_buff_by_No (hexm/client/entities/server/common_members/buff_base.lua:73)
          CALL _check_call_buffs (hexm/client/fake_server/entities/common_members/buff_base.lua:207)  args: (self=<instance of FakePlayerAvatar at 1774B679D00>, fname="remove_buffs_by_No", buffs_no=[70063], ...1=0)
            CALL call_server_with_token (hexm/client/net/network_comp/net_call_rpc.lua:96)  args: (self=<instance of Network at 1772025FA00>, tag="buff", rpc_method="rpc_clientify_call_buff", ...1="remove_buffs_by_No", ...2="aRyXXXXXXXXXXX")
              CALL get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)  args: (self=<instance of Network at 1772025FA00>)
              RET  get_avatar (hexm/client/net/network_comp/net_login_logic.lua:133)
              CALL gen (hexm/common/util/hotp.lua:73)  args: (self=<instance Hotp at 00000177202600E0>, ts=1763665291)
              CALL <anonymous> (hexm/common/util/hotp.lua:88)  args: (self=<instance Hotp at 00000177202600E0>, tt=36786, seq=8)
              CALL <anonymous> (hexm/common/util/crc32.lua:56)  args: (h=301203464, crc=nil)
              RET  <anonymous> (hexm/common/util/crc32.lua:56)
              CALL ? (engine/client/AsioServerProxy.lua:37)  args: (self=<instance AsioServerProxy at 000001772DA8E000>, ...1=2851724304, ...2="remove_buffs_by_No", ...3="aRyXXXXXXXXXXX", ...4=[[70063], 0])
                CALL callserver (engine/client/AsioServerProxy.lua:24)  args: (...1="", ...2=199962398, ...3=[2851724304, remove_buffs_by_No, aRyXXXXXXXXXXX, [[70063], 0]])
                RET  callserver (engine/client/AsioServerProxy.lua:24)
              RET  ? (engine/client/AsioServerProxy.lua:37)
            RET  call_server_with_token (hexm/client/net/network_comp/net_call_rpc.lua:96)
          RET  _check_call_buffs (hexm/client/fake_server/entities/common_members/buff_base.lua:207)
          CALL index (hexm/client/fake_server/entities/base_entity.lua:212)  args: (self=<instance of FakePlayerAvatar at 1774B679D00>, k="buffs_data")
          RET  index (hexm/client/fake_server/entities/base_entity.lua:212)
          CALL remove_buffs_by_No (hexm/common/combat/buff/buff_comp.lua:253)  args: (self=<instance of CombatBuffComp at 176BDB8E520>, buffs_no=[70063], fromid=0, reason=nil, rtype=nil)
            CALL get_bids_by_No (hexm/common/combat/buff/buff_comp.lua:177)  args: (self=<instance of CombatBuffComp at 176BDB8E520>, buffs_no=[70063], fromid=0)
            RET  get_bids_by_No (hexm/common/combat/buff/buff_comp.lua:177)
          RET  remove_buffs_by_No (hexm/common/combat/buff/buff_comp.lua:253)
        RET  remove_buffs_by_No (hexm/client/fake_server/entities/common_members/buff_base.lua:239)
      RET  <anonymous> (hexm/client/debug/gm/gm_commands/gm_combat.lua:476)
    RET  <anonymous> (hexm/client/debug/gm/gm_commands/gm_combat.lua:35)
    ```

- ⚠️ PoC quality only:
  - Uses Frida + Gadget.
  - No guarantees on compatibility or stability.

Use at your own risk, and have fun exploring the game’s Lua internals 🙂
