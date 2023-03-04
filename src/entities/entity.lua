----------------
-- Entity class and related functions
-- @script entities.entity
UMF_REQUIRE "/"

---@class Entity
---@field handle number
---@field type string
---@field description string (dynamic property)
---@field tags table (dynamic property -- readonly)
local entity_meta
entity_meta = global_metatable( "entity" )

local properties = {}

-- using these tables as keys to avoid quicksaving them
local DATA_KEY = {}
local TAGS_KEY = {}

function entity_meta:__index( k )
	if properties[k] then return properties[k]( self, false ) end
	if entity_meta[k] then return entity_meta[k] end
	local entdata = rawget( self, DATA_KEY )
	if not entdata then
		entdata = util.shared_table( "game.umf.entdata." .. self.handle )
		rawset( self, DATA_KEY, entdata )
	end
	return entdata[k]
end

function entity_meta:__newindex( k, v )
	if properties[k] then return properties[k]( self, true, v ) end
	local entdata = rawget( self, DATA_KEY )
	if not entdata then
		entdata = util.shared_table( "game.umf.entdata." .. self.handle )
		rawset( self, DATA_KEY, entdata )
	end
	entdata[k] = v
end

function properties:description( set, val )
	if set then
		SetDescription( self.handle, val )
	else
		return GetDescription( self.handle )
	end
end

local tags_meta = {
	__index = function( self, k )
		if HasTag( self.__handle, k ) then
			return GetTagValue( self.__handle, k )
		end
	end,
	__newindex = function( self, k, v )
		if v == nil then
			RemoveTag( self.__handle, k )
		else
			SetTag( self.__handle, k, tostring( v ) )
		end
	end
}

function properties:tags( set )
	if set then error( "cannot set tags key" ) end
	local enttags = rawget( self, TAGS_KEY )
	if not enttags then
		enttags = setmetatable( { __handle = self.handle }, tags_meta )
		rawset( self, TAGS_KEY, enttags )
	end
	return enttags
end

--- Gets the handle of an entity.
---
---@param e Entity | number
---@return number
function GetEntityHandle( e )
	if IsEntity( e ) then
		return e.handle
	end
	return e
end

--- Gets the validity of a table by calling :IsValid() if it supports it.
---
---@param e any
---@return boolean
function IsValid( e )
	if type( e ) == "table" and e.IsValid then
		return e:IsValid()
	end
	return false
end

--- Tests if the parameter is an entity.
---
---@param e any
---@return boolean
function IsEntity( e )
	return type( e ) == "table" and type( e.handle ) == "number"
end

--- Wraps the given handle with the entity class.
---
---@param handle number
---@return Entity
function Entity( handle )
	if type( handle ) == "number" and handle > 0 then
		local type = GetEntityType and GetEntityType( handle )
		return instantiate_global_metatable( type or "entity", { handle = handle, type = type or "unknown" } )
	end
	return handle
end

---@type Entity

---@param data string
---@return Entity self
function entity_meta:__unserialize( data )
	self.handle = tonumber( data )
	return self
end

---@return string data
function entity_meta:__serialize()
	return tostring( self.handle )
end

---@return string
function entity_meta:__tostring()
	return string.format( "Entity[%d]", self.handle )
end

--- Gets the type of the entity.
---
---@return string type
function entity_meta:GetType()
	return rawget( self, "type" ) or "unknown"
end

local IsHandleValid = IsHandleValid
--- Gets the validity of the entity.
---
---@return boolean
function entity_meta:IsValid()
	return IsHandleValid( self.handle )
end

local SetTag = SetTag
--- Sets a tag value on the entity.
---
---@param tag string
---@param value string
function entity_meta:SetTag( tag, value )
	assert( self:IsValid() )
	return SetTag( self.handle, tag, value )
end

local SetDescription = SetDescription
--- Sets the description of the entity.
---
---@param description string
function entity_meta:SetDescription( description )
	assert( self:IsValid() )
	return SetDescription( self.handle, description )
end

local RemoveTag = RemoveTag
--- Removes a tag from the entity.
---
---@param tag string
function entity_meta:RemoveTag( tag )
	assert( self:IsValid() )
	return RemoveTag( self.handle, tag )
end

local HasTag = HasTag
--- Gets if the entity has a tag.
---
---@param tag string
---@return boolean
function entity_meta:HasTag( tag )
	assert( self:IsValid() )
	return HasTag( self.handle, tag )
end

local GetTagValue = GetTagValue
--- Gets the value of a tag.
---
---@param tag string
---@return string
function entity_meta:GetTagValue( tag )
	assert( self:IsValid() )
	return GetTagValue( self.handle, tag )
end

local GetDescription = GetDescription
--- Gets the description of the entity.
---
---@return string
function entity_meta:GetDescription()
	assert( self:IsValid() )
	return GetDescription( self.handle )
end

local Delete = Delete
--- Deletes the entity.
function entity_meta:Delete()
	return Delete( self.handle )
end
