local trigger_meta = global_metatable( "trigger", "entity" )

function IsTrigger( e )
	return IsEntity( e ) and e.type == "trigger"
end

function Trigger( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "trigger" }, trigger_meta )
	end
end

function FindTriggerByTag( tag, global )
	return Trigger( FindTrigger( tag, global ) )
end

function FindTriggersByTag( tag, global )
	local t = FindTriggers( tag, global )
	for i = 1, #t do
		t[i] = Trigger( t[i] )
	end
	return t
end

function trigger_meta:__tostring()
	return string.format( "Trigger[%d]", self.handle )
end

function trigger_meta:SetTransform( transform )
	assert( self:IsValid() )
	return SetTriggerTransform( self.handle, transform )
end

function trigger_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetTriggerTransform( self.handle ) )
end

function trigger_meta:IsBodyInTrigger( handle )
	assert( self:IsValid() )
	return IsBodyInTrigger( self.handle, GetEntityHandle( handle ) )
end

function trigger_meta:IsVehicleInTrigger( handle )
	assert( self:IsValid() )
	return IsVehicleInTrigger( self.handle, GetEntityHandle( handle ) )
end

function trigger_meta:IsShapeInTrigger( handle )
	assert( self:IsValid() )
	return IsShapeInTrigger( self.handle, GetEntityHandle( handle ) )
end

function trigger_meta:IsPointInTrigger( point )
	assert( self:IsValid() )
	return IsPointInTrigger( self.handle, point )
end

function trigger_meta:IsEmpty( demolision )
	assert( self:IsValid() )
	return IsTriggerEmpty( self.handle, demolision )
end
