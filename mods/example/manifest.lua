return {
	-- Name used in UI (NYI)
	printname = "Example Mod",

	-- Other mods this mod depends on, this uses the folder name in mods/
	dependencies = {"framework"},

	-- Realms supported by this mod (menu, loading, splash, hud, terminal, tv, world, ...)
	-- If you don't know which realms you need, you can simply use {"*"}
	realms = {"hud", "world"},

	-- Mods marked as disabled will not be loaded
	disabled = true,
}