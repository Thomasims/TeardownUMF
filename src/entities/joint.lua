UMF_REQUIRE "/"

---@class Joint: Entity
local joint_meta = global_metatable( "joint", "entity" )

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
		return setmetatable( { handle = handle, type = "joint" }, joint_meta )
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

---@return string
function joint_meta:__tostring()
	return string.format( "Joint[%d]", self.handle )
end

--- Makes the joint behave as a motor.
---
---@param velocity number
---@param strength number
function joint_meta:SetMotor( velocity, strength )
	assert( self:IsValid() )
	return SetJointMotor( self.handle, velocity, strength )
end

--- Makes the joint behave as a motor moving to the specified target.
---
---@param target number
---@param maxVel number
---@param strength number
function joint_meta:SetMotorTarget( target, maxVel, strength )
	assert( self:IsValid() )
	return SetJointMotorTarget( self.handle, target, maxVel, strength )
end

--- Gets the type of the joint.
---
---@return string
function joint_meta:GetJointType()
	assert( self:IsValid() )
	return GetJointType( self.handle )
end

--- Finds the other shape the joint is attached to.
---
---@param shape Shape | number
---@return Shape
function joint_meta:GetOtherShape( shape )
	assert( self:IsValid() )
	return Shape( GetJointOtherShape( self.handle, GetEntityHandle( shape ) ) )
end

--- Gets the limits of the joint.
---
---@return number min
---@return number max
function joint_meta:GetLimits()
	assert( self:IsValid() )
	return GetJointLimits( self.handle )
end

--- Gets the current position or angle of the joint.
---
---@return number
function joint_meta:GetMovement()
	assert( self:IsValid() )
	return GetJointMovement( self.handle )
end

--- Gets if the joint is broken.
---
---@return boolean
function joint_meta:IsBroken()
	return not self:IsValid() or IsJointBroken( self.handle )
end

