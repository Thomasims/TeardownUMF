
function AssetType(search, match, root, default)
	local known, knownMod = default or {}, {}

	for i, file in ipairs(file.find(search)) do
		local mod, name = file:match(match)
		local path = root .. file
		knownMod[mod] = knownMod[mod] or {}
		knownMod[mod][name] = path
		known[name] = path
	end

	return function(name)
		if current_mod then
			local modLocal = knownMod[current_mod(1)]
			if modLocal and modLocal[name] then return modLocal[name] end
		end
		return known[name] or name
	end
end

Asset = AssetType("mods/*/assets/**", "^mods/([^/]-)/assets/(.-)$", "../../")