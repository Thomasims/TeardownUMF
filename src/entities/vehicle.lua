----------------
-- Vehicle class and related functions
-- @script entities.vehicle
UMF_REQUIRE "/"

---@class vehicle_handle: integer

---@class Vehicle: Entity
---@field handle vehicle_handle
---@field private _C table property contrainer (internal)
---@field transform Transformation (dynamic property -- readonly)
---@field body Body (dynamic property -- readonly)
---@field health number (dynamic property -- readonly)
local vehicle_meta = global_metatable( "vehicle", "entity", true )

--- Tests if the parameter is a vehicle entity.
---
---@param e any
---@return boolean
function IsVehicle( e )
	return IsEntity( e ) and e.type == "vehicle"
end

--- Wraps the given handle with the vehicle class.
---
---@param handle number
---@return Vehicle?
function Vehicle( handle )
	if handle > 0 then
		return instantiate_global_metatable( "vehicle", { handle = handle, type = "vehicle" } )
	end
end

--- Finds a vehicle with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Vehicle?
function FindVehicleByTag( tag, global )
	return Vehicle( FindVehicle( tag, global ) )
end

--- Finds all vehicles with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Vehicle[]
function FindVehiclesByTag( tag, global )
	local t = FindVehicles( tag, global )
	for i = 1, #t do
		t[i] = Vehicle( t[i] )
	end
	return t
end

---@type Vehicle

---@param self Vehicle
---@return string
function vehicle_meta:__tostring()
	return string.format( "Vehicle[%d]", self.handle )
end

--- Drives the vehicle by setting its controls.
---
---@param self Vehicle
---@param drive number
---@param steering number
---@param handbrake boolean
function vehicle_meta:Drive( drive, steering, handbrake )
	assert( self:IsValid() )
	return DriveVehicle( self.handle, drive, steering, handbrake )
end

--- Gets the transform of the vehicle.
---
---@param self Vehicle
---@return Transformation
function vehicle_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetVehicleTransform( self.handle ) )
end

--- Gets the body of the vehicle.
---
---@param self Vehicle
---@return Body
function vehicle_meta:GetBody()
	assert( self:IsValid() )
	local body = Body( GetVehicleBody( self.handle ) )
	---@cast body Body
	return body
end

--- Gets the health of the vehicle.
---
---@param self Vehicle
---@return number
function vehicle_meta:GetHealth()
	assert( self:IsValid() )
	-- TODO: calculate ourselves if we need to
	return GetVehicleHealth( self.handle )
end

--- Gets the position of the driver camera in object-space.
---
---@param self Vehicle
---@return Vector
function vehicle_meta:GetDriverPos()
	assert( self:IsValid() )
	return MakeVector( GetVehicleDriverPos( self.handle ) )
end

--- Gets the position of the driver camera in world-space.
---
---@param self Vehicle
---@return Vector
function vehicle_meta:GetGlobalDriverPos()
	return self:GetTransform():ToGlobal( self:GetDriverPos() )
end

----------------
-- Properties implementation

---@param self Vehicle
---@param setter boolean
---@return Transformation
function vehicle_meta._C:transform( setter )
	assert(not setter, "cannot set transform")
	return self:GetTransform()
end

---@param self Vehicle
---@param setter boolean
---@return Body
function vehicle_meta._C:body( setter )
	assert(not setter, "cannot set body")
	return self:GetBody()
end

---@param self Vehicle
---@param setter boolean
---@return number
function vehicle_meta._C:health( setter )
	assert(not setter, "cannot set health")
	return self:GetHealth()
end
