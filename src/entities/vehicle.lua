----------------
-- Vehicle class and related functions
-- @script entities.vehicle
UMF_REQUIRE "/"

---@class Vehicle: Entity
---@field transform Transformation (dynamic property -- readonly)
---@field body Body (dynamic property -- readonly)
---@field health number (dynamic property -- readonly)
local vehicle_meta
vehicle_meta = global_metatable( "vehicle", "entity", true )

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
		return setmetatable( { handle = handle, type = "vehicle" }, vehicle_meta )
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

---@return string
function vehicle_meta:__tostring()
	return string.format( "Vehicle[%d]", self.handle )
end

--- Drives the vehicle by setting its controls.
---
---@param drive number
---@param steering number
---@param handbrake number
function vehicle_meta:Drive( drive, steering, handbrake )
	assert( self:IsValid() )
	return DriveVehicle( self.handle, drive, steering, handbrake )
end

--- Gets the transform of the vehicle.
---
---@return Transformation
function vehicle_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetVehicleTransform( self.handle ) )
end

--- Gets the body of the vehicle.
---
---@return Body
function vehicle_meta:GetBody()
	assert( self:IsValid() )
	return Body( GetVehicleBody( self.handle ) )
end

--- Gets the health of the vehicle.
---
---@return number
function vehicle_meta:GetHealth()
	assert( self:IsValid() )
	-- TODO: calculate ourselves if we need to
	return GetVehicleHealth( self.handle )
end

--- Gets the position of the driver camera in object-space.
---
---@return Vector
function vehicle_meta:GetDriverPos()
	assert( self:IsValid() )
	return MakeVector( GetVehicleDriverPos( self.handle ) )
end

--- Gets the position of the driver camera in world-space.
---
---@return Vector
function vehicle_meta:GetGlobalDriverPos()
	return self:GetTransform():ToGlobal( self:GetDriverPos() )
end

----------------
-- Properties implementation

function vehicle_meta._C:transform( setter, val )
	if setter then
		self:SetTransform( val )
	else
		return self:GetTransform()
	end
end

function vehicle_meta._C:body( setter )
	assert(not setter, "cannot set body")
	return self:GetBody()
end

function vehicle_meta._C:health( setter )
	assert(not setter, "cannot set health")
	return self:GetHealth()
end
