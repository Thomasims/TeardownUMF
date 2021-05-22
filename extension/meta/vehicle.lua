local vehicle_meta = global_metatable( "vehicle", "entity" )

function IsVehicle( e )
	return IsEntity( e ) and e.type == "vehicle"
end

function Vehicle( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "vehicle" }, vehicle_meta )
	end
end

function FindVehicleByTag( tag, global )
	return Vehicle( FindVehicle( tag, global ) )
end

function FindVehiclesByTag( tag, global )
	local t = FindVehicles( tag, global )
	for i = 1, #t do
		t[i] = Vehicle( t[i] )
	end
	return t
end

function vehicle_meta:__tostring()
	return string.format( "Vehicle[%d]", self.handle )
end

function vehicle_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetVehicleTransform( self.handle ) )
end

function vehicle_meta:GetBody()
	assert( self:IsValid() )
	return Body( GetVehicleBody( self.handle ) )
end

function vehicle_meta:GetDriverPos()
	assert( self:IsValid() )
	return MakeVector( GetVehicleDriverPos( self.handle ) )
end

function vehicle_meta:GetGlobalDriverPos()
	return self:GetTransform():ToGlobal( self:GetDriverPos() )
end
