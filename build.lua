#!/usr/bin/lua

---@diagnostic disable: undefined-global
--------------------------------------------------------------------------------
-- This script is used to compile multiple lua files down into one package.
--
-- Usage: build.lua [-s] <output> <input files...>
--------------------------------------------------------------------------------
-- TODO: defines
local function SplitPath( filepath )
	return filepath:match( "^(.-/?)([^/]+)$" )
end

local function CheckDirectory( file, path )
	if file then
		local data, err = file:read( 0 )
		if not data and err == "Is a directory" then
			file:close()
			path = path:match( "(.-)/*$" ) .. "/_index.lua"
			file = io.open( path, "r" )
		end
	else
		local newpath = path:match( "(.-)/*$" ) .. "/_index.lua"
		local newfile = io.open( newpath, "r" )
		if newfile then
			file, path = newfile, newpath
		end
	end
	return file, path
end

local function FindFile( filepath, root )
	local realpath
	local f
	while true do
		realpath = root .. filepath
		f, realpath = CheckDirectory( io.open( realpath, "r" ), realpath )
		if f or root == "" then
			break
		end
		root = root:match( "(.-)[^/]*/+$" ) or ""
	end
	return f, realpath
end

local function PreProcess( filepath, root, done, loaded )
	done = done or {}
	loaded = loaded or {}

	local f, realpath = FindFile( filepath, root or "" )

	if not f then
		print( "missing include: " .. filepath )
		return
	end

	if done[realpath] then
		f:close()
		return
	end
	done[realpath] = true

	local text = f:read( "*a" ) .. "\n"
	f:close()

	local subroot = SplitPath( realpath )
	text = text:gsub( "UMF_REQUIRE \"([^\"]+)\"\r?\n", function( inc )
		PreProcess( inc, subroot, done, loaded )
		return ""
	end ):gsub( "UMF_SOFTREQUIRE \"([^\"]+)\"\r?\n", function( inc )
		local found, newfile = FindFile( inc, subroot )
		return "UMF_SOFTREQUIRE \"" .. (found and newfile or inc) .. "\"\n"
	end )
	if text:match( "^[ \n\t]*$" ) then
		return
	end
	loaded[#loaded + 1] = { file = realpath, code = "(function() " .. text .. " end)();" }
end

local function Shrink( code )
	return code:gsub( "%-%-%[(=*)%[.-%]%1%]", "" ):gsub( "%-%-[^\n]*", "" ):gsub( "[\r\n\t ]+", " " )
end

local function ParseArguments( rules, ... )
	local longRules, shortRules = {}, {}
	for i = 1, #rules do
		local rule = rules[i]
		if rule.long then
			longRules[rule.long] = rule
		end
		if rule.short then
			shortRules[rule.short] = rule
		end
	end
	local rulesValues = {}
	local extra = {}
	local activeRule
	local function activateRule( rule, debug )
		if not rule then
			error( "Unknown rule: " .. debug )
		end
		if activeRule then
			error( "Invalid parameters: " .. debug )
		end
		if rule.hasparam then
			activeRule = rule
		else
			rulesValues[rule.id] = true
		end
	end
	local function applyRule( param )
		if activeRule.multi then
			rulesValues[activeRule.id] = rulesValues[activeRule.id] or {}
			rulesValues[activeRule.id][#rulesValues[activeRule.id] + 1] = param
		else
			rulesValues[activeRule.id] = param
		end
		activeRule = nil
	end

	for i = 1, select( "#", ... ) do
		local param = select( i, ... )
		if param:sub( 1, 1 ) == "-" then
			if param:sub( 1, 2 ) == "--" then
				activateRule( longRules[param:sub( 3 )], param )
			else
				for r, pos in param:gmatch( "([^-])()" ) do
					activateRule( shortRules[r], r )
					if activeRule and pos <= #param then
						applyRule( param:sub( pos ) )
						break
					end
				end
			end
		else
			if activeRule then
				applyRule( param )
			else
				extra[#extra + 1] = param
			end
		end
	end

	return extra, rulesValues
end

local function formatargs( ... )
	local res = {}
	for i = 1, select( "#", ... ) do
		local arg = select( i, ... )
		if arg:find( "[ \"']" ) then
			res[i] = "\"" .. arg:gsub("\"", "\\\"") .. "\""
		else
			res[i] = arg
		end
	end
	return table.concat( res, " " )
end

local precode = "local __RUNLATER = {} local UMF_RUNLATER = function(code) __RUNLATER[#__RUNLATER + 1] = code end\n"
local preloadedcode = "local __UMFLOADED = {%s} local UMF_SOFTREQUIRE = function(name) return __UMFLOADED[name] end\n"
local postcode = "\nfor i = 1, #__RUNLATER do local f = loadstring(__RUNLATER[i]) if f then pcall(f) end end\n"

do
	local files, rules = ParseArguments( {
		{ long = "name", short = "n", hasparam = true, id = "name" },
		{ long = "shorten", short = "s", id = "shorten" },
		{ long = "define", short = "D", hasparam = true, multi = true, id = "define" },
	}, ... )
	if #files < 2 then
		error( "build.lua [-s] <output> <input files...>" )
	end

	local done = {}
	local data = {}
	for i = 2, #files do
		print( "Loading dependencies for " .. files[i] )
		PreProcess( files[i], "src/", done, data )
	end
	print( "Generating build.." )
	local loadedfiles = {}
	for i = 1, #data do
		loadedfiles[i] = string.format( "[%q]=true,", data[i].file )
		print( " * Added " .. data[i].file )
		data[i] = rules.shorten and Shrink( data[i].code ) or ("--" .. data[i].file .. "\n" .. data[i].code)
	end
	local code = table.concat( data, "\n" )
	local f = io.open( files[1], "w" )
	f:write( string.format("-- UMF Package%s generated with:\n-- build.lua %s\n--\n", rules.name and (" " .. rules.name) or "", formatargs( ... )) )
	f:write( precode )
	f:write( string.format( preloadedcode, table.concat( loadedfiles ) ) )
	f:write( code )
	f:write( postcode )
	f:close()
	print( "Build written to " .. files[1] )
end
