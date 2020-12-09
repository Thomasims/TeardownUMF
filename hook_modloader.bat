@echo off
:: Inject the mod loader in various realms so mods can use whichever they need

:: Menu-related realms
echo Installing in Menu-related realms...
find /c "mods/umf/injector.lua" data\ui\menu.lua  || ( echo|set /p=";loadfile "mods/umf/injector.lua" "menu"" >> data\ui\menu.lua )
find /c "mods/umf/injector.lua" data\ui\loading.lua  || ( echo|set /p=";loadfile "mods/umf/injector.lua" "loading"" >> data\ui\loading.lua )
find /c "mods/umf/injector.lua" data\ui\splash.lua  || ( echo|set /p=";loadfile "mods/umf/injector.lua" "splash"" >> data\ui\splash.lua )

:: HUD-related realms
echo Installing in HUD-related realms...
find /c "mods/umf/injector.lua" data\ui\hud.lua  || ( echo|set /p=";loadfile "mods/umf/injector.lua" "hud"" >> data\ui\hud.lua )
find /c "mods/umf/injector.lua" data\ui\terminal.lua  || ( echo|set /p=";loadfile "mods/umf/injector.lua" "terminal"" >> data\ui\terminal.lua )
find /c "mods/umf/injector.lua" data\ui\tv.lua  || ( echo|set /p=";loadfile "mods/umf/injector.lua" "tv"" >> data\ui\tv.lua )

:: Level-related realms
echo Installing in Level-related realms...
find /c "mods/umf/injector.lua" data\script\main.lua  || ( echo|set /p=";loadfile "mods/umf/injector.lua" "world"" >> data\script\main.lua )
find /c "mods/umf/injector.lua" data\script\heist.lua  || ( echo|set /p=";loadfile "mods/umf/injector.lua" "heist"" >> data\script\heist.lua )
find /c "mods/umf/injector.lua" data\script\sandbox.lua  || ( echo|set /p=";loadfile "mods/umf/injector.lua" "sandbox"" >> data\script\sandbox.lua )

echo Complete
pause
