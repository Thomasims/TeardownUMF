UMF_REQUIRE "/"

---@class Shape: Entity
local shape_meta = global_metatable( "shape", "entity" )

--- Tests if the parameter is a shape entity.
---
---@param e any
---@return boolean
function IsShape( e )
	return IsEntity( e ) and e.type == "shape"
end

--- Wraps the given handle with the shape class.
---
---@param handle number
---@return Shape?
function Shape( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "shape" }, shape_meta )
	end
end

--- Finds a shape with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Shape?
function FindShapeByTag( tag, global )
	return Shape( FindShape( tag, global ) )
end

--- Finds all shapes with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Shape[]
function FindShapesByTag( tag, global )
	local t = FindShapes( tag, global )
	for i = 1, #t do
		t[i] = Shape( t[i] )
	end
	return t
end

---@return string
function shape_meta:__tostring()
	return string.format( "Shape[%d]", self.handle )
end

--- Draws the outline of the shape.
---
---@param r number
---@overload fun(r: number, g: number, b: number, a: number)
function shape_meta:DrawOutline( r, ... )
	assert( self:IsValid() )
	return DrawShapeOutline( self.handle, r, ... )
end

--- Draws a highlight of the shape.
---
---@param amount number
function shape_meta:DrawHighlight( amount )
	assert( self:IsValid() )
	return DrawShapeHighlight( self.handle, amount )
end

--- Sets the transform of the shape relative to its body.
---
---@param transform Transformation
function shape_meta:SetLocalTransform( transform )
	assert( self:IsValid() )
	return SetShapeLocalTransform( self.handle, transform )
end

--- Sets the emmissivity scale of the shape.
---
---@param scale number
function shape_meta:SetEmissiveScale( scale )
	assert( self:IsValid() )
	return SetShapeEmissiveScale( self.handle, scale )
end

--- Gets the transform of the shape relative to its body.
---
---@return Transformation
function shape_meta:GetLocalTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetShapeLocalTransform( self.handle ) )
end

--- Gets the transform of the shape.
---
---@return Transformation
function shape_meta:GetWorldTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetShapeWorldTransform( self.handle ) )
end

--- Gets the body of this shape.
---
---@return Body
function shape_meta:GetBody()
	assert( self:IsValid() )
	return Body( GetShapeBody( self.handle ) )
end

--- Gets the joints attached to this shape.
---
---@return Joint[]
function shape_meta:GetJoints()
	assert( self:IsValid() )
	local joints = GetShapeJoints( self.handle )
	for i = 1, #joints do
		joints[i] = Joint( joints[i] )
	end
	return joints
end

--- Gets the lights attached to this shape.
---
---@return Light[]
function shape_meta:GetLights()
	assert( self:IsValid() )
	local lights = GetShapeLights( self.handle )
	for i = 1, #lights do
		lights[i] = Light( lights[i] )
	end
	return lights
end

--- Gets the bounds of the shape.
---
---@return Vector min
---@return Vector max
function shape_meta:GetWorldBounds()
	assert( self:IsValid() )
	local min, max = GetShapeBounds( self.handle )
	return MakeVector( min ), MakeVector( max )
end

--- Gets the material and color of the shape at the specified position.
---
---@param pos Vector
---@return string type
---@return number r
---@return number g
---@return number b
---@return number a
function shape_meta:GetMaterialAtPos( pos )
	assert( self:IsValid() )
	return GetShapeMaterialAtPosition( self.handle, pos )
end

--- Gets the size of the shape in voxels.
---
---@return number x
---@return number y
---@return number z
function shape_meta:GetSize()
	assert( self:IsValid() )
	return GetShapeSize( self.handle )
end

--- Gets the count of voxels in the shape.
---
---@return number
function shape_meta:GetVoxelCount()
	assert( self:IsValid() )
	return GetShapeVoxelCount( self.handle )
end

--- Gets if the shape is currently visible.
---
---@param maxDist number
---@param rejectTransparent? boolean
---@return boolean
function shape_meta:IsVisible( maxDist, rejectTransparent )
	assert( self:IsValid() )
	return IsShapeVisible( self.handle, maxDist, rejectTransparent )
end

--- Gets if the shape has been broken.
---
---@return boolean
function shape_meta:IsBroken()
	return not self:IsValid() or IsShapeBroken( self.handle )
end
