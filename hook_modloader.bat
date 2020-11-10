@echo off
:: Inject the mod loader in various realms so mods can use whichever they need

:: Menu-related realms
echo Installing in Menu-related realms...
find /c "mods/core/init.lua" data\ui\menu.lua  || ( echo|set /p=" loadfile "mods/core/init.lua" "menu"" >> data\ui\menu.lua )
find /c "mods/core/init.lua" data\ui\loading.lua  || ( echo|set /p=" loadfile "mods/core/init.lua" "loading"" >> data\ui\loading.lua )
find /c "mods/core/init.lua" data\ui\splash.lua  || ( echo|set /p=" loadfile "mods/core/init.lua" "splash"" >> data\ui\splash.lua )

:: HUD-related realms
echo Installing in HUD-related realms...
find /c "mods/core/init.lua" data\ui\hud.lua  || ( echo|set /p=" loadfile "mods/core/init.lua" "hud"" >> data\ui\hud.lua )
find /c "mods/core/init.lua" data\ui\terminal.lua  || ( echo|set /p=" loadfile "mods/core/init.lua" "terminal"" >> data\ui\terminal.lua )
find /c "mods/core/init.lua" data\ui\tv.lua  || ( echo|set /p=" loadfile "mods/core/init.lua" "tv"" >> data\ui\tv.lua )

:: Level-related realms
echo Installing in Level-related realms...
find /c "mods/core/init.lua" data\script\main.lua  || ( echo|set /p=" loadfile "mods/core/init.lua" "world"" >> data\script\main.lua )

echo Complete
pause