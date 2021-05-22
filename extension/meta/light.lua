local light_meta = global_metatable( "light", "entity" )

function IsLight( e )
	return IsEntity( e ) and e.type == "light"
end

function Light( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "light" }, light_meta )
	end
end

function FindLightByTag( tag, global )
	return Light( FindLight( tag, global ) )
end

function FindLightsByTag( tag, global )
	local t = FindLights( tag, global )
	for i = 1, #t do
		t[i] = Light( t[i] )
	end
	return t
end

function light_meta:__tostring()
	return string.format( "Light[%d]", self.handle )
end

function light_meta:SetEnabled( enabled )
	assert( self:IsValid() )
	return SetLightEnabled( self.handle, enabled )
end

function light_meta:SetColor( r, g, b )
	assert( self:IsValid() )
	return SetLightColor( self.handle, r, g, b )
end

function light_meta:SetIntensity( intensity )
	assert( self:IsValid() )
	return SetLightIntensity( self.handle, intensity )
end

function light_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetLightTransform( self.handle ) )
end

function light_meta:GetShape()
	assert( self:IsValid() )
	return Shape( GetLightShape( self.handle ) )
end

function light_meta:IsPointAffectedByLight( point )
	assert( self:IsValid() )
	return IsPointAffectedByLight( self.handle, point )
end
