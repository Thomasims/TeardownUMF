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
find /c "mods/core/init.lua" data\script\heist.lua  || ( echo|set /p=" loadfile "mods/core/init.lua" "heist"" >> data\script\heist.lua )

:: mods.lua creation
echo Generating mods filesystem...
(
echo --------------------------------------------------------------------------------------
echo -- THIS FILE IS AUTOMATICALLY GENERATED BY hook_modloader.bat, DO NOT EDIT MANUALLY --
echo --                RE-RUN hook_modloader.bat IF CHANGES HAVE OCCURRED                --
echo --------------------------------------------------------------------------------------
echo return [[%cd%\mods
dir /S /B mods
echo ]]
) > mods/mods.lua

echo Complete
pause