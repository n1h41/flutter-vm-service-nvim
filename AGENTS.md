# AGENTS.md - n1h41-nvim Plugin Development Guide

## Project Type
Lua-based Neovim plugin for Flutter development utilities

## Build/Lint/Test Commands
- No formal build process - plugin loads directly via Lua require
- Test manually in Neovim by loading the plugin and testing keybinds
- Validate Lua syntax: `lua -c lua/n1h41/init.lua` and `lua -c lua/n1h41/flutter.lua`

## Code Style Guidelines

### File Structure
- Main entry point: `lua/n1h41/init.lua`  
- Feature modules: `lua/n1h41/<feature>.lua`

### Lua Conventions
- Use `snake_case` for function names and variables
- Use `PascalCase` for module names in require statements
- Prefer `local` variables and functions
- Return module table `M` from files
- Use tabs for indentation (consistent with existing code)

### Error Handling
- Use `pcall` for potentially failing operations (line 1, 131, 155)
- Provide user feedback via `vim.notify()` with appropriate log levels
- Handle nil values before use (lines 53, 73, 93, 244)

### Neovim Integration
- Use `vim.keymap.set()` for keybinds with descriptive options
- Create user commands with `vim.api.nvim_create_user_command()`
- Use `vim.system()` for external commands with proper error checking
- Leverage existing plugins (flutter-tools.nvim, telescope) when available