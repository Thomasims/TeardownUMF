local joint_meta = global_metatable( "joint", "entity" )

function IsJoint( e )
	return IsEntity( e ) and e.type == "joint"
end

function Joint( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "joint" }, joint_meta )
	end
end

function FindJointByTag( tag, global )
	return Joint( FindJoint( tag, global ) )
end

function FindJointsByTag( tag, global )
	local t = FindJoints( tag, global )
	for i = 1, #t do
		t[i] = Joint( t[i] )
	end
	return t
end

function joint_meta:__tostring()
	return string.format( "Joint[%d]", self.handle )
end

function joint_meta:SetMotor( velocity, strength )
	assert( self:IsValid() )
	return SetJointMotor( self.handle, velocity, strength )
end

function joint_meta:GetJointType()
	assert( self:IsValid() )
	return GetJointType( self.handle )
end

function joint_meta:GetOtherShape( shape )
	assert( self:IsValid() )
	return GetJointOtherShape( self.handle, shape )
end

function joint_meta:GetLimits()
	assert( self:IsValid() )
	return GetJointLimits( self.handle )
end

function joint_meta:GetMovement()
	assert( self:IsValid() )
	return GetJointMovement( self.handle )
end

function joint_meta:IsBroken()
	return not self:IsValid() or IsJointBroken( self.handle )
end

