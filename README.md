# Teardown Unofficial Modding Framework

The purpose of this framework is to create an environment where multiple mods can co-exist easily.
It also aims at providing mods more utilities and helper functions through the "framework" mod.

_Note: Thanks to the installation process, this framework should be compatible with most other mods and loaders as long as you run `hook_modloader.bat` after installing them._

# Installing

- Place `mods` and `hook_modloader.bat` next to teardown.exe (C:\Program Files (x86)\Steam\steamapps\common\Teardown)
- Run `hook_modloader.bat` to patch the default scripts

To install a mod, place its folder in the `mods` folder and run `hook_modloader.bat`

# Creating mods

A basic mod is simply a folder in `mods` with 2 files: `manifest.lua` and `init.lua`.
The manifest is the mod descriptor, it contains the printname, the list of dependencies and the list of realms it can be used in. You can see an example manifest in `mods/framework/manifest.lua`.
The init script is the lua entrypoint for the various realms used by the mod.

## include()

Because of how the framework loads files, `#include` will no longer work. you can fix this by simply removing the `#`.

`include()` attempts to find the file 3 times:

1. In the same folder as the current file
2. In the folder of the current mod
3. From the root of the game

## Hooks

Hooks are a simple way to avoid overriding the behavior of other mods. To attach a handler to an event, you just need to use `hook.add` with the desired event and an ID unique to your mod:

```lua
hook.add("base.handleCommand", "mymod_identifier", function(cmd, arg0, ...)
	-- The code here will run as if it was placed at the start of handleCommand()
end)
```

The default hooks can be found in `mods/core/default_hooks.lua`.

## Realms

What I refer to as Realms is the different lua states the game uses from the menu, hud, game logic, etc.
Depending on where you need your mod to run, you'll need to use one of the Realm "guards" to stop code from executing in other places.

For example, if you wanted your code to run exclusively in the menu, you would need to use `REALM_MENU`:

```lua
if REALM_MENU then
	hook.add("base.draw", function()
		-- UI Code
	end)
end
```

These Realm guards are available: `REALM_MENU`, `REALM_LOADING`, `REALM_SPLASH`, `REALM_HUD`, `REALM_TERMINAL`, `REALM_TV`, `REALM_WORLD`.

## Console

The framework includes a very basic console, this means you can use print() in your mod and view the values passed easily.
It also keeps the last 128 lines in the savegame file to easily copy/paste content out of it.
