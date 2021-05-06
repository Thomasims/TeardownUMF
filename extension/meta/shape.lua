local shape_meta = global_metatable( "shape", "entity" )

function IsShape( e )
	return IsEntity( e ) and e.type == "shape"
end

function Shape( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "shape" }, shape_meta )
	end
end

function FindShapeByTag( tag, global )
	return Shape( FindShape( tag, global ) )
end

function FindShapesByTag( tag, global )
	local t = FindShapes( tag, global )
	for i = 1, #t do
		t[i] = Shape( t[i] )
	end
	return t
end

function shape_meta:__tostring()
	return string.format( "Shape[%d]", self.handle )
end

function shape_meta:DrawOutline( r, ... )
	assert( self:IsValid() )
	return DrawShapeOutline( self.handle, r, ... )
end

function shape_meta:DrawHighlight( amount )
	assert( self:IsValid() )
	return DrawShapeHighlight( self.handle, amount )
end

function shape_meta:SetLocalTransform( transform )
	assert( self:IsValid() )
	return SetShapeLocalTransform( self.handle, transform )
end

function shape_meta:SetEmissiveScale( scale )
	assert( self:IsValid() )
	return SetShapeEmissiveScale( self.handle, scale )
end

function shape_meta:GetLocalTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetShapeLocalTransform( self.handle ) )
end

function shape_meta:GetWorldTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetShapeWorldTransform( self.handle ) )
end

function shape_meta:GetBody()
	assert( self:IsValid() )
	return Body( GetShapeBody( self.handle ) )
end

function shape_meta:GetJoints()
	assert( self:IsValid() )
	local joints = GetShapeJoints( self.handle )
	for i = 1, #joints do
		joints[i] = Joint( joints[i] )
	end
	return joints
end

function shape_meta:GetLights()
	assert( self:IsValid() )
	local lights = GetShapeLights( self.handle )
	for i = 1, #lights do
		lights[i] = Light( lights[i] )
	end
	return lights
end

function shape_meta:GetWorldBounds()
	assert( self:IsValid() )
	local min, max = GetShapeBounds( self.handle )
	return MakeVector( min ), MakeVector( max )
end

function shape_meta:IsVisible( maxDist )
	assert( self:IsValid() )
	return IsShapeVisible( self.handle )
end

function shape_meta:IsBroken()
	return not self:IsValid() or IsShapeBroken( self.handle )
end
