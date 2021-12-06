----------------
-- Trigger class and related functions
-- @script entities.trigger
UMF_REQUIRE "/"

---@class Trigger: Entity
local trigger_meta
trigger_meta = global_metatable( "trigger", "entity" )

--- Tests if the parameter is a trigger entity.
---
---@param e any
---@return boolean
function IsTrigger( e )
	return IsEntity( e ) and e.type == "trigger"
end

--- Wraps the given handle with the trigger class.
---
---@param handle number
---@return Trigger?
function Trigger( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "trigger" }, trigger_meta )
	end
end

--- Finds a trigger with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Trigger?
function FindTriggerByTag( tag, global )
	return Trigger( FindTrigger( tag, global ) )
end

--- Finds all triggers with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Trigger[]
function FindTriggersByTag( tag, global )
	local t = FindTriggers( tag, global )
	for i = 1, #t do
		t[i] = Trigger( t[i] )
	end
	return t
end

---@type Trigger

---@return string
function trigger_meta:__tostring()
	return string.format( "Trigger[%d]", self.handle )
end

--- Sets the transform of the trigger.
---
---@param transform Transformation
function trigger_meta:SetTransform( transform )
	assert( self:IsValid() )
	return SetTriggerTransform( self.handle, transform )
end

--- Gets the transform of the trigger.
---
---@return Transformation
function trigger_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetTriggerTransform( self.handle ) )
end

--- Gets the distance to the trigger from a given origin.
--- Negative values indicate the origin is inside the trigger.
---
---@param origin Vector
function trigger_meta:GetDistance(origin)
	return GetTriggerDistance(self.handle, origin)
end

--- Gets the closest point to the trigger from a given origin.
---
---@param origin Vector
function trigger_meta:GetClosestPoint(origin)
	return MakeVector(GetTriggerDistance(self.handle, origin))
end

--- Gets the bounds of the trigger.
---
---@return Vector min
---@return Vector max
function trigger_meta:GetWorldBounds()
	assert( self:IsValid() )
	local min, max = GetTriggerBounds( self.handle )
	return MakeVector( min ), MakeVector( max )
end

--- Gets if the specified body is in the trigger.
---
---@param handle Body | number
---@return boolean
function trigger_meta:IsBodyInTrigger( handle )
	assert( self:IsValid() )
	return IsBodyInTrigger( self.handle, GetEntityHandle( handle ) )
end

--- Gets if the specified vehicle is in the trigger.
---
---@param handle Vehicle | number
---@return boolean
function trigger_meta:IsVehicleInTrigger( handle )
	assert( self:IsValid() )
	return IsVehicleInTrigger( self.handle, GetEntityHandle( handle ) )
end

--- Gets if the specified shape is in the trigger.
---
---@param handle Shape | number
---@return boolean
function trigger_meta:IsShapeInTrigger( handle )
	assert( self:IsValid() )
	return IsShapeInTrigger( self.handle, GetEntityHandle( handle ) )
end

--- Gets if the specified point is in the trigger.
---
---@param point Vector
---@return boolean
function trigger_meta:IsPointInTrigger( point )
	assert( self:IsValid() )
	return IsPointInTrigger( self.handle, point )
end

--- Gets if the trigger is empty.
---
---@param demolision boolean
---@return boolean empty
---@return Vector? highpoint
function trigger_meta:IsEmpty( demolision )
	assert( self:IsValid() )
	local empty, highpoint = IsTriggerEmpty( self.handle, demolision )
	return empty, highpoint and MakeVector( highpoint )
end
