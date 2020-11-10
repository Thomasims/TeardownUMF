# Teardown Unofficial Modding Framework

The purpose of this framework is to create an environment where multiple mods can co-exist easily.
It also aims at providing mods more utilities and helper functions through the "framework" mod.

## Installing

- Place all the files of this repository next to teardown.exe (C:\Program Files (x86)\Steam\steamapps\common\Teardown)
- Run `hook_modloader.bat` to patch the default scripts

To install a mod, place its folder in the `mods` folder and add the name in `mods/mods.lua`

## Creating mods

A basic mod is simply a folder in `mods` with 2 files: `manifest.lua` and `init.lua`.
The manifest is the mod descriptor, it contains the printname, the list of dependencies and the list of realms it can be used in.
The init script is the lua entrypoint for the various realms used by the mod.

### Realms

-

## Console

The framework includes a very basic console, this means you can use print() in your mod and view the values passed easily.
It also keeps the last 128 lines in the savegame file to easily copy/paste content out of it.
