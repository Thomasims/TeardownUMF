local location_meta = global_metatable( "location", "entity" )

function IsLocation( e )
	return IsEntity( e ) and e.type == "location"
end

function Location( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "location" }, location_meta )
	end
end

function FindLocationByTag( tag, global )
	return Location( FindLocation( tag, global ) )
end

function FindLocationsByTag( tag, global )
	local t = FindLocations( tag, global )
	for i = 1, #t do
		t[i] = Location( t[i] )
	end
	return t
end

function location_meta:__tostring()
	return string.format( "Location[%d]", self.handle )
end

function location_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetLocationTransform( self.handle ) )
end
