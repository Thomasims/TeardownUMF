local screen_meta = global_metatable( "screen", "entity" )

function IsScreen( e )
	return IsEntity( e ) and e.type == "screen"
end

function Screen( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "screen" }, screen_meta )
	end
end

function FindScreenByTag( tag, global )
	return Screen( FindScreen( tag, global ) )
end

function FindScreensByTag( tag, global )
	local t = FindScreens( tag, global )
	for i = 1, #t do
		t[i] = Screen( t[i] )
	end
	return t
end

function screen_meta:__tostring()
	return string.format( "Screen[%d]", self.handle )
end

function screen_meta:SetEnabled( enabled )
	assert( self:IsValid() )
	return SetScreenEnabled( self.handle, enabled )
end

function screen_meta:GetShape()
	assert( self:IsValid() )
	return Shape( GetScreenShape( self.handle ) )
end

function screen_meta:IsEnabled()
	assert( self:IsValid() )
	return IsScreenEnabled( self.handle )
end
