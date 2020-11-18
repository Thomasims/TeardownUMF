
file = {_listing = {}}

function file.loadinfo()
	local filesystem, root = {}
	for line in dofile(".mods"):gmatch("([^\r\n]+)") do
		if root then
			filesystem[#filesystem + 1] = line:sub(#root + 2):gsub("\\", "/")
		else
			root = line
		end
	end
	file._listing = filesystem
end

local function findsub(sub, path)
	local results = {}
	for i = 1, #sub do
		local match = sub[i]:match(path)
		if match then results[#results + 1] = match end
	end
	return results
end

function file.find(pattern, raw)
	if not raw then
		pattern = "^" .. pattern:gsub("%*+", function(m)
			if m == "**" then return ".-" end
			if m == "*" then return "[^/]-" end
			return m
		end) .. "$"
	end
	return findsub(file._listing, pattern)
end

function file.exists(pattern, raw)
	return #file.find(pattern, raw) > 0
end