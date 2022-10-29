----------------
-- Config Library
-- @script util.config
local registryloaded = UMF_SOFTREQUIRE "registry.lua"

if registryloaded then
	--- Creates a structured table for the mod config
	---
	---@param def table
	function OptionsKeys( def )
		return util.structured_table( "savegame.mod", def )
	end
end

OptionsMenu = setmetatable( {}, {
	__call = function( self, def )
		def.title_size = def.title_size or 50
		local pos = def.center or 0.5
		local f = OptionsMenu.Group( def )
		draw = function()
			UiPush()
			UiTranslate( UiWidth() * pos, 60 )
			UiPush()
			local fw, fh = f()
			UiPop()
			UiTranslate( 0, fh + 20 )
			UiFont( "regular.ttf", 30 )
			UiAlign( "center top" )
			UiButtonImageBox( "ui/common/box-outline-6.png", 6, 6 )
			if UiTextButton( "Close" ) then
				Menu()
			end
			UiPop()
		end
		return f
	end,
} )

----------------
-- Organizers --
----------------

--- Groups multiple options together
---
---@param def table
function OptionsMenu.Group( def )
	local elements = {}
	if def.title then
		elements[#elements + 1] = OptionsMenu.Text( def.title, {
			size = def.title_size or 40,
			pad_bottom = def.title_pad or 15,
			align = def.title_align or "center top",
		} )
	end
	for i = 1, #def do
		elements[#elements + 1] = def[i]
	end
	local condition = def.condition
	return function()
		if condition and not condition() then
			return 0, 0
		end
		local mw, mh = 0, 0
		for i = 1, #elements do
			UiPush()
			local w, h = elements[i]()
			UiPop()
			UiTranslate( 0, h )
			mh = mh + h
			mw = math.max( mw, w )
		end
		return mw, mh
	end
end

function OptionsMenu.Columns( def )
	local elements = {}
	for i = 1, #def do
		elements[#elements + 1] = def[i]
	end

	return function()
		local mw, mh = UiWidth(), 0
		UiPush()
			UiTranslate(UiWidth() * ( - 0.5 + 0.5 / #elements ), 0)
			for i = 1, #elements do
				UiPush()
					local _, gh = elements[i]()
				UiPop()
				UiTranslate(UiWidth() * ( 1 / #elements ), 0)
				mh = math.max( mh, gh )
			end
		UiPop()
		return mw, mh
	end
end

--- Text section
---
---@param text string
---@param options? table
function OptionsMenu.Text( text, options )
	options = options or {}
	local size = options.size or 30
	local align = options.align or "left top"
	local offset = options.offset or (align:find( "left" ) and -400) or 0
	local font = options.font or "regular.ttf"
	local padt = options.pad_top or 0
	local padb = options.pad_bottom or 5
	local condition = options.condition
	return function()
		if condition and not condition() then
			return 0, 0
		end
		UiTranslate( offset, padt )
		UiFont( font, size )
		UiAlign( align )
		UiWordWrap( 800 )
		local tw, th = UiText( text )
		return tw, th + padt + padb
	end
end

--- Spacer
---
---@param space number Vertical space
---@param spacew? number Horizontal space
---@param condition? function Condition function to enable this spacer
function OptionsMenu.Spacer( space, spacew, condition )
	return function()
		if condition and not condition() then
			return 0, 0
		end
		return spacew or 0, space
	end
end

----------------
---- Values ----
----------------

local function getvalue( id, def, func )
	local key = "savegame.mod." .. id
	if HasKey( key ) then
		return (func or GetString)( key )
	else
		return def
	end
end

local function setvalue( id, val, func )
	local key = "savegame.mod." .. id
	if val ~= nil then
		(func or SetString)( key, val )
	else
		ClearKey( key )
	end
end

--- Keybind value
---
---@param def table
function OptionsMenu.Keybind( def )
	local text = def.name or def.id
	local size = def.size or 30
	local padt = def.pad_top or 0
	local padb = def.pad_bottom or 5
	local allowmouse = def.allowmouse or false
	local value = string.upper( getvalue( def.id, def.default ) or "" )
	if value == "" then
		value = "<none>"
	end
	local pressed = false
	local condition = def.condition
	return function()
		if condition and not condition() then
			return 0, 0
		end
		UiTranslate( -4, padt )
		UiFont( "regular.ttf", size )
		local fheight = UiFontHeight()
		UiAlign( "right top" )
		local lw, lh = UiText( text )
		UiTranslate( 8, 0 )
		UiAlign( "left top" )
		UiColor( 1, 1, 0 )
		local tempv = value
		if pressed then
			tempv = "<press a key>"
			local k = InputLastPressedKey()
			if k == "esc" then
				pressed = false
			elseif k ~= "" then
				value = string.upper( k )
				tempv = value
				setvalue( def.id, k )
				pressed = false
			end
		end
		local rw, rh = UiGetTextSize( tempv )
		if allowmouse then
			local inrect = UiIsMouseInRect( rw, rh )
			local mouse = InputPressed( "lmb" ) and "lmb" or InputPressed( "rmb" ) and "rmb" or InputPressed( "mmb" ) and "mmb"
			if inrect and mouse == "lmb" then
				pressed = not pressed
			elseif pressed and mouse then
				value = string.upper( mouse )
				tempv = value
				rw, rh = UiGetTextSize( tempv )
				setvalue( def.id, mouse )
				pressed = false
			end
			UiTextButton( tempv )
		elseif UiTextButton( tempv ) then
			pressed = not pressed
		end
		UiTranslate( rw, 0 )
		if value ~= "<none>" then
			UiColor( 1, 0, 0 )
			if UiTextButton( "x" ) then
				value = "<none>"
				setvalue( def.id, "" )
			end
			UiTranslate( size * 0.8, 0 )
		end
		if getvalue( def.id ) then
			UiColor( 0.5, 0.8, 1 )
			if UiTextButton( "Reset" ) then
				value = def.default and string.upper( def.default ) or "<none>"
				setvalue( def.id )
			end
		end
		return lw + 8 + rw, fheight + padt + padb
	end
end

--- Slider value
---
---@param def table
function OptionsMenu.Slider( def )
	local text = def.name or def.id
	local size = def.size or 30
	local padt = def.pad_top or 0
	local padb = def.pad_bottom or 5
	local min = def.min or 0
	local max = def.max or 100
	local range = max - min
	local getter = def.getter or GetFloat
	local setter = def.setter or SetFloat
	local value = getvalue( def.id, def.default, getter )
	local formatter = def.formatter
	local format = string.format( "%%.%df", math.max( 0, math.floor( math.log10( 1000 / range ) ) ) )
	local step = def.step
	local condition = def.condition
	return function()
		if condition and not condition() then
			return 0, 0
		end
		UiTranslate( -4, padt )
		UiFont( "regular.ttf", size )
		local fheight = UiFontHeight()
		UiAlign( "right top" )
		local lw, lh = UiText( text )
		UiTranslate( 16, lh / 2 )
		UiAlign( "left middle" )
		UiColor( 1, 1, 0.5 )
		UiRect( 200, 2 )
		UiTranslate( -8, 0 )
		local prev = value
		value = UiSlider( "ui/common/dot.png", "x", (value - min) * 200 / range, 0, 200 ) * range / 200 + min
		if step then
			value = math.floor( value / step + 0.5 ) * step
		end
		UiTranslate( 216, 0 )
		UiText( formatter and formatter( value ) or string.format( format, value ) )
		if value ~= prev then
			setvalue( def.id, value, setter )
		end
		return lw + 224, fheight + padt + padb
	end
end

--- Toggle value
---
---@param def table
function OptionsMenu.Toggle( def )
	local text = def.name or def.id
	local size = def.size or 30
	local padt = def.pad_top or 0
	local padb = def.pad_bottom or 5
	local value = getvalue( def.id, def.default, GetBool )
	local condition = def.condition
	return function()
		if condition and not condition() then
			return 0, 0
		end
		UiTranslate( -4, padt )
		UiFont( "regular.ttf", size )
		local fheight = UiFontHeight()
		UiAlign( "right top" )
		local lw, lh = UiText( text )
		UiTranslate( 8, 0 )
		UiAlign( "left top" )
		UiColor( 1, 1, 0 )
		if UiTextButton( value and "Enabled" or "Disabled" ) then
			value = not value
			setvalue( def.id, value, SetBool )
		end
		return lw + 100, fheight + padt + padb
	end
end
