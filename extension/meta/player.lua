local player_meta = global_metatable( "player" )

PLAYER = setmetatable( {}, player_meta )

function player_meta:__unserialize( data )
	return self
end

function player_meta:__serialize()
	return ""
end

function player_meta:__tostring()
	return string.format( "Player" )
end

function player_meta:GetType()
	return "player"
end

function player_meta:Respawn()
	return RespawnPlayer()
end

function player_meta:SetTransform( transform )
	return SetPlayerTransform( transform )
end

function player_meta:SetCamera( transform )
	return SetCameraTransform( transform )
end

function player_meta:SetSpawnTransform( transform )
	return SetPlayerSpawnTransform( transform )
end

function player_meta:SetVehicle( handle )
	return SetPlayerVehicle( GetEntityHandle( handle ) )
end

function player_meta:SetVelocity( velocity )
	return SetPlayerVelocity( velocity )
end

function player_meta:SetScreen( handle )
	return SetPlayerScreen( GetEntityHandle( handle ) )
end

function player_meta:SetHealth( health )
	return SetPlayerHealth( health )
end

function player_meta:GetTransform()
	return MakeTransformation( GetPlayerTransform() )
end

function player_meta:GetCamera()
	return MakeTransformation( GetCameraTransform() )
end

function player_meta:GetVelocity()
	return MakeVector( GetPlayerVelocity() )
end

function player_meta:GetVehicle()
	return Vehicle( GetPlayerVehicle() )
end

function player_meta:GetGrabShape()
	return Shape( GetPlayerGrabShape() )
end

function player_meta:GetGrabBody()
	return Body( GetPlayerGrabBody() )
end

function player_meta:GetPickShape()
	return Shape( GetPlayerPickShape() )
end

function player_meta:GetPickBody()
	return Body( GetPlayerPickBody() )
end

function player_meta:GetInteractShape()
	return Shape( GetPlayerInteractShape() )
end

function player_meta:GetInteractBody()
	return Body( GetPlayerInteractBody() )
end

function player_meta:GetScreen()
	return Screen( GetPlayerScreen() )
end

function player_meta:GetHealth()
	return GetPlayerHealth()
end
