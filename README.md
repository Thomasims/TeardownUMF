# This Branch is ***NOT READY FOR NORMAL USAGE***.
UMF is moving away from the special position afforded by hook_modloader.bat in preparation for the Steam Workshop integration. There will be major changes due to this and mods using it will have to update their structure as well.

# Teardown Unofficial Modding Framework

The UMF is an unofficial extension of the modding system present in the game.
This branch of UMF is intended as a library that mod makers can copy into their mod to extend the game's API.

# Installing

- Place the contents of this repo in a folder called `umf` inside your mod
- include the parts you need with #include (For example `#include "umf/umf_meta.lua"`)