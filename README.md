# This Branch is ***NOT READY FOR NORMAL USAGE***.
UMF is moving away from the special position afforded by hook_modloader.bat in preparation for the Steam Workshop integration. There will be major changes due to this and mods using it will have to update their structure as well.

# Teardown Unofficial Modding Framework

The UMF is an unofficial extension of the modding system present in the game.
It aims to fill in some gaps that the current API doesn't currently cover and provide its users with useful utilities.

# Installing

**_You can find a step-by-step guide [here](https://github.com/Thomasims/TeardownUMF-Examples/wiki/Installation-Guide)._**

- Place `mods` and `hook_modloader.bat` next to teardown.exe (C:\Program Files (x86)\Steam\steamapps\common\Teardown)
- Run `hook_modloader.bat` to patch the default scripts

To install a mod, place its folder in the `Documents/Teardown/mods` folder.

# Creating mods

The UMF is just an addon for the regular modding API, please refer to https://teardowngame.com/modding/ for creating mods.

In order for the UMF to recognize a mod, it must have 2 extra files: `manifest.lua` and `init.lua`.
The manifest is the mod descriptor, it contains the list of dependencies and the list of realms it can be used in.
The init script is the lua entrypoint for the various realms used by the mod.

You can see an example mod [here](https://github.com/Thomasims/TeardownUMF-Examples).

## include()

Because of how the framework loads files, `#include` will not work in Lua files under `init.lua`.

`include()` attempts to find the file 3 times:

1. In the same folder as the current file
2. In the folder of the current mod
3. From the root of the game

## Hooks

Hooks are a simple way to avoid overriding the behavior of other mods. To attach a handler to an event, you just need to use `hook.add` with the desired event and an ID unique to your mod:

```lua
hook.add("base.command.quickload", "mymod_identifier", function(cmd, arg0, ...)
	-- The code here will run when handleCommand() receives a quickload command
end)
```

The default hooks can be found in `mods/umf/core/default_hooks.lua`.

## Realms

What I refer to as Realms is the different Lua states (contexts) the game uses from the menu, hud, game logic, etc.
Depending on where you need your mod to run, you'll need to use one of the Realm "guards" to stop code from executing in other places.

For example, if you wanted your code to run exclusively in the menu, you would need to use `REALM_MENU`:

```lua
if REALM_MENU then
	hook.add("base.draw", "some identifier", function()
		-- UI Code
	end)
end
```

These Realm guards are available: `REALM_MENU`, `REALM_LOADING`, `REALM_SPLASH`, `REALM_HUD`, `REALM_TERMINAL`, `REALM_TV`, `REALM_WORLD`, `REALM_SANDBOX`. Each corresponds to one of the default files in the game's data folder.

## Console

The framework includes a very basic console, this means you can use print() in your mod and view the values passed easily.
It also keeps the last 128 lines in the savegame file to easily copy/paste content out of it.
