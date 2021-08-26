UMF_REQUIRE "/"

---@class Entity
---@field handle number
---@field type string
local entity_meta = global_metatable( "entity" )

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
	if handle > 0 then
		return setmetatable( { handle = handle, type = "unknown" }, entity_meta )
	end
end

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
	return self.type or "unknown"
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
