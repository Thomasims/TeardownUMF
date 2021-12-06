----------------
-- Body class and related functions
-- @script entities.body
UMF_REQUIRE "/"

---@class Body: Entity
local body_meta
body_meta = global_metatable( "body", "entity" )

--- Tests if the parameter is a body entity.
---
---@param e any
---@return boolean
function IsBody( e )
	return IsEntity( e ) and e.type == "body"
end

--- Wraps the given handle with the body class.
---
---@param handle number
---@return Body?
function Body( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "body" }, body_meta )
	end
end

--- Finds a body with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Body?
function FindBodyByTag( tag, global )
	return Body( FindBody( tag, global ) )
end

--- Finds all bodies with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Body[]
function FindBodiesByTag( tag, global )
	local t = FindBodies( tag, global )
	for i = 1, #t do
		t[i] = Body( t[i] )
	end
	return t
end

---@type Body

---@return string
function body_meta:__tostring()
	return string.format( "Body[%d]", self.handle )
end

--- Applies a force to the body at the specified world-space point.
---
---@param pos Vector World-space position
---@param vel Vector World-space force and direction
function body_meta:ApplyImpulse( pos, vel )
	assert( self:IsValid() )
	return ApplyBodyImpulse( self.handle, pos, vel )
end

--- Applies a force to the body at the specified object-space point.
---
---@param pos Vector Object-space position
---@param vel Vector Object-space force and direction
function body_meta:ApplyLocalImpulse( pos, vel )
	local transform = self:GetTransform()
	return self:ApplyImpulse( transform:ToGlobal( pos ), transform:ToGlobalDir( vel ) )
end

--- Draws the outline of the body.
---
---@param r number
---@overload fun(r: number, g: number, b: number, a: number)
function body_meta:DrawOutline( r, ... )
	assert( self:IsValid() )
	return DrawBodyOutline( self.handle, r, ... )
end

--- Draws a highlight of the body.
---
---@param amount number
function body_meta:DrawHighlight( amount )
	assert( self:IsValid() )
	return DrawBodyHighlight( self.handle, amount )
end

--- Sets the transform of the body.
---
---@param tr Transformation
function body_meta:SetTransform( tr )
	assert( self:IsValid() )
	return SetBodyTransform( self.handle, tr )
end

--- Sets if the body should be simulated.
---
---@param bool boolean
function body_meta:SetActive( bool )
	assert( self:IsValid() )
	return SetBodyActive( self.handle, bool )
end

--- Sets if the body should move.
---
---@param bool boolean
function body_meta:SetDynamic( bool )
	assert( self:IsValid() )
	return SetBodyDynamic( self.handle, bool )
end

--- Sets the velocity of the body.
---
---@param vel Vector
function body_meta:SetVelocity( vel )
	assert( self:IsValid() )
	return SetBodyVelocity( self.handle, vel )
end

--- Sets the angular velocity of the body.
---
---@param avel Vector
function body_meta:SetAngularVelocity( avel )
	assert( self:IsValid() )
	return SetBodyAngularVelocity( self.handle, avel )
end

--- Gets the transform of the body.
---
---@return Transformation
function body_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetBodyTransform( self.handle ) )
end

--- Gets the mass of the body.
---
---@return number
function body_meta:GetMass()
	assert( self:IsValid() )
	return GetBodyMass( self.handle )
end

--- Gets the velocity of the body.
---
---@return Vector
function body_meta:GetVelocity()
	assert( self:IsValid() )
	return MakeVector( GetBodyVelocity( self.handle ) )
end

--- Gets the velocity at the position on the body.
---
---@param pos Vector
---@return Vector
function body_meta:GetVelocityAtPos( pos )
	assert( self:IsValid() )
	return MakeVector( GetBodyVelocityAtPos( self.handle, pos ) )
end

--- Gets the angular velocity of the body.
---
---@return Vector
function body_meta:GetAngularVelocity()
	assert( self:IsValid() )
	return MakeVector( GetBodyAngularVelocity( self.handle ) )
end

--- Gets the shape of the body.
---
---@return Shape[]
function body_meta:GetShapes()
	assert( self:IsValid() )
	local shapes = GetBodyShapes( self.handle )
	for i = 1, #shapes do
		shapes[i] = Shape( shapes[i] )
	end
	return shapes
end

--- Gets the vehicle of the body.
---
---@return Vehicle?
function body_meta:GetVehicle()
	assert( self:IsValid() )
	return Vehicle( GetBodyVehicle( self.handle ) )
end

--- Gets the bounds of the body.
---
---@return Vector min
---@return Vector max
function body_meta:GetWorldBounds()
	assert( self:IsValid() )
	local min, max = GetBodyBounds( self.handle )
	return MakeVector( min ), MakeVector( max )
end

--- Gets the center of mas in object-space.
---
---@return Vector
function body_meta:GetLocalCenterOfMass()
	assert( self:IsValid() )
	return MakeVector( GetBodyCenterOfMass( self.handle ) )
end

--- Gets the center of mass in world-space.
---
---@return Vector
function body_meta:GetWorldCenterOfMass()
	return self:GetTransform():ToGlobal( self:GetLocalCenterOfMass() )
end

--- Gets the closest point to the body from a given origin.
---
---@param origin Vector
---@return boolean hit
---@return Vector point
---@return Vector normal
---@return Shape shape
function body_meta:GetClosestPoint( origin )
	local hit, point, normal, shape = GetBodyClosestPoint( self.handle, origin )
	if not hit then
		return false
	end
	return hit, MakeVector( point ), MakeVector( normal ), Shape( shape )
end

--- Gets all the dynamic bodies in the jointed structure.
--- The result will include the current body.
---
---@return Body[] jointed
function body_meta:GetJointedBodies()
	local list = GetJointedBodies( self.handle )
	for i = 1, #list do
		list[i] = Body( list[i] )
	end
	return list
end

--- Gets if the body is currently being simulated.
---
---@return boolean
function body_meta:IsActive()
	assert( self:IsValid() )
	return IsBodyActive( self.handle )
end

--- Gets if the body is dynamic.
---
---@return boolean
function body_meta:IsDynamic()
	assert( self:IsValid() )
	return IsBodyDynamic( self.handle )
end

--- Gets if the body is visble on screen.
---
---@param maxdist number
---@return boolean
function body_meta:IsVisible( maxdist )
	assert( self:IsValid() )
	return IsBodyVisible( self.handle, maxdist )
end

--- Gets if the body has been broken.
---
---@return boolean
function body_meta:IsBroken()
	return not self:IsValid() or IsBodyBroken( self.handle )
end

--- Gets if the body somehow attached to something static.
---
---@return boolean
function body_meta:IsJointedToStatic()
	assert( self:IsValid() )
	return IsBodyJointedToStatic( self.handle )
end
