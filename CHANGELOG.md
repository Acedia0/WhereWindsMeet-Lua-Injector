# Changelog

All notable changes to WhereWindsMeet-Lua-Frida-Injector will be documented in this file.

## [2.0.0] - 2024-11-21

### Added
- **ESP System** (`Scripts/ESP_Objects.lua`)
  - Real-time object visualization
  - Configurable filters for NPCs, enemies, items, resources, chests, quest objects
  - Distance, level, and health display
  - Color-coded categories
  - Adjustable update interval and max distance

- **Advanced Features** (`Scripts/Advanced_Features.lua`)
  - Speed hack with multiplier
  - Jump hack with multiplier
  - Infinite stamina toggle
  - No fall damage toggle
  - God mode (invincibility)
  - Teleport system with save/load positions
  - Player info display

- **Automated Setup** (`setup.py`)
  - Python version check
  - Automatic Frida installation
  - Directory structure creation
  - Interactive configuration
  - File verification
  - Windows launcher generation

- **Centralized Configuration** (`config.json`)
  - Project paths configuration
  - Frida connection settings
  - Injection behavior settings
  - Feature toggles (ESP, debug, advanced)
  - Logging configuration

- **Script Loader** (`Scripts/Loader_All.lua`)
  - Organized script loading system
  - Auto-load and auto-start options
  - Script management commands
  - Comprehensive help system

- **Windows Launcher** (`start_injector.bat`)
  - One-click injector start
  - Python and Frida verification
  - Game process detection
  - User-friendly interface

- **Documentation**
  - Complete Italian documentation (`README_IT.md`)
  - Quick start guide (`QUICK_START_IT.md`)
  - Changelog (`CHANGELOG.md`)
  - `.gitignore` for clean repository

### Changed
- Improved error handling throughout all scripts
- Enhanced logging with structured output
- Better code organization and comments
- Updated README with v2.0 features

### Fixed
- Various stability improvements
- Better handling of missing game functions
- Improved compatibility with different game versions

## [1.0.0] - Original Release

### Features
- Basic Lua injection via Frida Gadget
- Hook `lua_load` and `lua_pcall`
- Debug console enabler
- GM menu access
- Environment dump utility
- Function call tracer
- GM menu translator
- Boolean values dump

---

## Roadmap

### Future Enhancements
- [ ] GUI interface for easier configuration
- [ ] Real-time ESP overlay (DirectX/OpenGL hook)
- [ ] More advanced teleport features (waypoint system)
- [ ] Item spawner
- [ ] Quest manager
- [ ] NPC interaction automation
- [ ] Custom Lua REPL console
- [ ] Profile system for different configurations
- [ ] Auto-update system
- [ ] Multi-language support for ESP labels

### Known Issues
- ESP may not work correctly with all entity types
- Some GM functions may be patched in newer game versions
- Teleport may cause issues in certain game areas
- Performance impact with many objects in ESP range

---

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## License

This project is for educational and research purposes only.
Use at your own risk.
