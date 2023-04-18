----------------
-- Joint class and related functions
-- @script entities.joint
UMF_REQUIRE "/"

---@class joint_handle: integer

---@class Joint: Entity
---@field handle joint_handle
---@field private _C table property contrainer (internal)
---@field jointType string (dynamic property -- readonly)
---@field broken boolean (dynamic property -- readonly)
local joint_meta = global_metatable( "joint", "entity", true )

--- Tests if the parameter is a joint entity.
---
---@param e any
---@return boolean
function IsJoint( e )
	return IsEntity( e ) and e.type == "joint"
end

--- Wraps the given handle with the joint class.
---
---@param handle number
---@return Joint?
function Joint( handle )
	if handle > 0 then
		return instantiate_global_metatable( "joint", { handle = handle, type = "joint" } )
	end
end

--- Finds a joint with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Joint?
function FindJointByTag( tag, global )
	return Joint( FindJoint( tag, global ) )
end

--- Finds all joints with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Joint[]
function FindJointsByTag( tag, global )
	local t = FindJoints( tag, global )
	for i = 1, #t do
		t[i] = Joint( t[i] )
	end
	return t
end

---@type Joint

---@param self Joint
---@return string
function joint_meta:__tostring()
	return string.format( "Joint[%d]", self.handle )
end

--- Detatches the joint from the given shape.
---
---@param self Joint
---@param shape Shape
function joint_meta:DetachFromShape( shape )
	local shapeHandle = GetEntityHandle( shape )
	---@cast shapeHandle shape_handle
	DetachJointFromShape( self.handle, shapeHandle )
end

--- Makes the joint behave as a motor.
---
---@param self Joint
---@param velocity number
---@param strength number
function joint_meta:SetMotor( velocity, strength )
	assert( self:IsValid() )
	return SetJointMotor( self.handle, velocity, strength )
end

--- Makes the joint behave as a motor moving to the specified target.
---
---@param self Joint
---@param target number
---@param maxVel number
---@param strength number
function joint_meta:SetMotorTarget( target, maxVel, strength )
	assert( self:IsValid() )
	return SetJointMotorTarget( self.handle, target, maxVel, strength )
end

--- Gets the type of the joint.
---
---@param self Joint
---@return string
function joint_meta:GetJointType()
	assert( self:IsValid() )
	return GetJointType( self.handle )
end

--- Finds the other shape the joint is attached to.
---
---@param self Joint
---@param shape Shape | integer
---@return Shape
function joint_meta:GetOtherShape( shape )
	assert( self:IsValid() )
	local shapeHandle = GetEntityHandle( shape )
	---@cast shapeHandle shape_handle
	local otherShape = Shape( GetJointOtherShape( self.handle, shapeHandle ) )
	---@cast otherShape Shape
	return otherShape
end

--- Gets the limits of the joint.
---
---@param self Joint
---@return number min
---@return number max
function joint_meta:GetLimits()
	assert( self:IsValid() )
	return GetJointLimits( self.handle )
end

--- Gets the current position or angle of the joint.
---
---@param self Joint
---@return number
function joint_meta:GetMovement()
	assert( self:IsValid() )
	return GetJointMovement( self.handle )
end

--- Gets if the joint is broken.
---
---@param self Joint
---@return boolean
function joint_meta:IsBroken()
	return not self:IsValid() or IsJointBroken( self.handle )
end

----------------
-- Properties implementation

---@param self Joint
---@param setter boolean
---@return string
function joint_meta._C:jointType( setter )
	assert(not setter, "cannot set jointType")
	return self:GetType()
end

---@param self Joint
---@param setter boolean
---@return boolean
function joint_meta._C:broken( setter )
	assert(not setter, "cannot set broken")
	return self:IsBroken()
end
