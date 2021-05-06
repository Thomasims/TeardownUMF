local body_meta = global_metatable( "body", "entity" )

function IsBody( e )
	return IsEntity( e ) and e.type == "body"
end

function Body( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "body" }, body_meta )
	end
end

function FindBodyByTag( tag, global )
	return Body( FindBody( tag, global ) )
end

function FindBodiesByTag( tag, global )
	local t = FindBodies( tag, global )
	for i = 1, #t do
		t[i] = Body( t[i] )
	end
	return t
end

function body_meta:__tostring()
	return string.format( "Body[%d]", self.handle )
end

function body_meta:ApplyImpulse( pos, vel )
	assert( self:IsValid() )
	return ApplyBodyImpulse( self.handle, pos, vel )
end

function body_meta:ApplyLocalImpulse( pos, vel )
	local transform = self:GetTransform()
	return self:ApplyImpulse( transform:ToGlobal( pos ), transform:ToGlobalDir( vel ) )
end

function body_meta:DrawOutline( r, ... )
	assert( self:IsValid() )
	return DrawBodyOutline( self.handle, r, ... )
end

function body_meta:DrawHighlight( amount )
	assert( self:IsValid() )
	return DrawBodyHighlight( self.handle, amount )
end

function body_meta:SetTransform( tr )
	assert( self:IsValid() )
	return SetBodyTransform( self.handle, tr )
end

function body_meta:SetDynamic( bool )
	assert( self:IsValid() )
	return SetBodyDynamic( self.handle, bool )
end

function body_meta:SetVelocity( vel )
	assert( self:IsValid() )
	return SetBodyVelocity( self.handle, vel )
end

function body_meta:SetAngularVelocity( avel )
	assert( self:IsValid() )
	return SetBodyAngularVelocity( self.handle, avel )
end

function body_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetBodyTransform( self.handle ) )
end

function body_meta:GetMass()
	assert( self:IsValid() )
	return GetBodyMass( self.handle )
end

function body_meta:GetVelocity()
	assert( self:IsValid() )
	return MakeVector( GetBodyVelocity( self.handle ) )
end

function body_meta:GetAngularVelocity()
	assert( self:IsValid() )
	return MakeVector( GetBodyAngularVelocity( self.handle ) )
end

function body_meta:GetShapes()
	assert( self:IsValid() )
	local shapes = GetBodyShapes( self.handle )
	for i = 1, #shapes do
		shapes[i] = Shape( shapes[i] )
	end
	return shapes
end

function body_meta:GetVehicle()
	assert( self:IsValid() )
	return Vehicle( GetBodyVehicle( self.handle ) )
end

function body_meta:GetWorldBounds()
	assert( self:IsValid() )
	local min, max = GetBodyBounds( self.handle )
	return MakeVector( min ), MakeVector( max )
end

function body_meta:IsDynamic()
	assert( self:IsValid() )
	return IsBodyDynamic( self.handle )
end

function body_meta:IsVisible( maxdist )
	assert( self:IsValid() )
	return IsBodyVisible( self.handle, maxdist )
end

function body_meta:IsBroken()
	return not self:IsValid() or IsBodyBroken( self.handle )
end

function body_meta:IsJointedToStatic()
	assert( self:IsValid() )
	return IsBodyJointedToStatic( self.handle )
end
