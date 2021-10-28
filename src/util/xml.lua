----------------
-- XML Utilities
-- @script util.xml

---@class XMLNode
---@field __call fun(children: XMLNode[]): XMLNode
---@field attributes table<string, string> | nil
---@field children XMLNode[] | nil
---@field type string
local xml_meta
xml_meta = global_metatable( "xmlnode" )

--- Defines an XML node.
---
---@param type string
---@return fun(attributes: table<string, string>): XMLNode
XMLTag = function( type )
	return function( attributes )
		return setmetatable( { type = type, attributes = attributes }, xml_meta )
	end
end

--- Parses XML from a string.
---
---@param xml string
---@return XMLNode
ParseXML = function( xml )
	local pos = 1
	local function skipw()
		local next = xml:find( "[^ \t\n]", pos )
		if not next then
			return false
		end
		pos = next
		return true
	end
	local function expect( pattern, noskip )
		if not noskip then
			if not skipw() then
				return false
			end
		end
		local s, e = xml:find( pattern, pos )
		if not s then
			return false
		end
		local pre = pos
		pos = e + 1
		return xml:match( pattern, pre )
	end

	local readtag, readattribute, readstring

	local rt = { n = "\n", t = "\t", r = "\r", ["0"] = "\0", ["\\"] = "\\", ["\""] = "\"" }
	readstring = function()
		if not expect( "^\"" ) then
			return false
		end
		local start = pos
		while true do
			local s = assert( xml:find( "[\\\"]", pos ), "Invalid string" )
			if xml:sub( s, s ) == "\\" then
				pos = s + 2
			else
				pos = s + 1
				break
			end
		end
		return xml:sub( start, pos - 2 ):gsub( "\\(.)", rt )
	end

	readattribute = function()
		local name = expect( "^([%d%w_]+)" )
		if not name then
			return false
		end
		if expect( "^=" ) then
			return name, assert( readstring() )
		else
			return name, "1"
		end
	end

	readtag = function()
		local save = pos
		if not expect( "^<" ) then
			return false
		end

		local type = expect( "^([%d%w_]+)" )
		if not type then
			pos = save
			return false
		end
		skipw()

		local attributes = {}
		repeat
			local attr, val = readattribute()
			if attr then
				attributes[attr] = val
			end
		until not attr

		local children = {}
		if not expect( "^/>" ) then
			assert( expect( "^>" ) )
			repeat
				local child = readtag()
				if child then
					children[#children + 1] = child
				end
			until not child
			assert( expect( "^</" ) and expect( "^" .. type ) and expect( "^>" ) )
		end

		return XMLTag( type )( attributes )( children )
	end

	return readtag()
end

---@type XMLNode

---@return XMLNode self
function xml_meta:__call( children )
	self.children = children
	return self
end

--- Renders this node into an XML string.
---
---@return string
function xml_meta:Render()
	local attr = ""
	if self.attributes then
		for name, val in pairs( self.attributes ) do
			attr = string.format( "%s %s=%q", attr, name, val )
		end
	end
	local children = {}
	if self.children then
		for i = 1, #self.children do
			children[i] = self.children[i]:Render()
		end
	end
	return string.format( "<%s%s>%s</%s>", self.type, attr, table.concat( children, "" ), self.type )
end
