----------------
-- Trigger class and related functions
-- @script entities.trigger
UMF_REQUIRE "/"

---@class trigger_handle: integer

---@class Trigger: Entity
---@field handle trigger_handle
---@field private _C table property contrainer (internal)
---@field transform Transformation (dynamic property)
local trigger_meta
trigger_meta = global_metatable( "trigger", "entity", true )

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
		return instantiate_global_metatable( "trigger", { handle = handle, type = "trigger" } )
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

---@param self Trigger
---@return string
function trigger_meta:__tostring()
	return string.format( "Trigger[%d]", self.handle )
end

--- Sets the transform of the trigger.
---
---@param self Trigger
---@param transform transform
function trigger_meta:SetTransform( transform )
	assert( self:IsValid() )
	return SetTriggerTransform( self.handle, transform )
end

--- Gets the transform of the trigger.
---
---@param self Trigger
---@return Transformation
function trigger_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetTriggerTransform( self.handle ) )
end

--- Gets the distance to the trigger from a given origin.
--- Negative values indicate the origin is inside the trigger.
---
---@param self Trigger
---@param origin vector
function trigger_meta:GetDistance( origin )
	return GetTriggerDistance( self.handle, origin )
end

--- Gets the closest point to the trigger from a given origin.
---
---@param self Trigger
---@param origin vector
function trigger_meta:GetClosestPoint( origin )
	return MakeVector( GetTriggerClosestPoint( self.handle, origin ) )
end

--- Gets the bounds of the trigger.
---
---@param self Trigger
---@return Vector min
---@return Vector max
function trigger_meta:GetWorldBounds()
	assert( self:IsValid() )
	local min, max = GetTriggerBounds( self.handle )
	return MakeVector( min ), MakeVector( max )
end

--- Gets if the specified body is in the trigger.
---
---@param self Trigger
---@param handle Body | number
---@return boolean
function trigger_meta:IsBodyInTrigger( handle )
	assert( self:IsValid() )
	local bodyHandle = GetEntityHandle( handle )
	---@cast bodyHandle body_handle
	return IsBodyInTrigger( self.handle, bodyHandle )
end

--- Gets if the specified vehicle is in the trigger.
---
---@param self Trigger
---@param handle Vehicle | number
---@return boolean
function trigger_meta:IsVehicleInTrigger( handle )
	assert( self:IsValid() )
	local vehicleHandle = GetEntityHandle( handle )
	---@cast vehicleHandle vehicle_handle
	return IsVehicleInTrigger( self.handle, vehicleHandle )
end

--- Gets if the specified shape is in the trigger.
---
---@param self Trigger
---@param handle Shape | number
---@return boolean
function trigger_meta:IsShapeInTrigger( handle )
	assert( self:IsValid() )
	local shapeHandle = GetEntityHandle( handle )
	---@cast shapeHandle shape_handle
	return IsShapeInTrigger( self.handle, shapeHandle )
end

--- Gets if the specified point is in the trigger.
---
---@param self Trigger
---@param point vector
---@return boolean
function trigger_meta:IsPointInTrigger( point )
	assert( self:IsValid() )
	return IsPointInTrigger( self.handle, point )
end

--- Gets if the trigger is empty.
---
---@param self Trigger
---@param demolision boolean
---@return boolean empty
---@return Vector? highpoint
function trigger_meta:IsEmpty( demolision )
	assert( self:IsValid() )
	local empty, highpoint = IsTriggerEmpty( self.handle, demolision )
	return empty, highpoint and MakeVector( highpoint )
end

----------------
-- Properties implementation

---@param self Trigger
---@param setter boolean
---@param val transform
---@return Transformation?
function trigger_meta._C:transform( setter, val )
	if setter then
		self:SetTransform( val )
	else
		return self:GetTransform()
	end
end
