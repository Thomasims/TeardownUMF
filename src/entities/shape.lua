----------------
-- Shape class and related functions
-- @script entities.shape
UMF_REQUIRE "/"

---@class shape_handle: integer

---@class Shape: Entity
---@field handle shape_handle
---@field private _C table property contrainer (internal)
---@field transform Transformation (dynamic property)
---@field emissive number (dynamic property -- writeonly)
---@field body Body (dynamic property -- readonly)
---@field joints Joint[] (dynamic property -- readonly)
---@field lights Light[] (dynamic property -- readonly)
---@field size Vector (dynamic property -- readonly)
---@field broken boolean (dynamic property -- readonly)
local shape_meta
shape_meta = global_metatable( "shape", "entity", true )

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
		return instantiate_global_metatable( "shape", { handle = handle, type = "shape" } )
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

---@type Shape

---@param self Shape
---@return string
function shape_meta:__tostring()
	return string.format( "Shape[%d]", self.handle )
end

--- Draws the outline of the shape.
---
---@param self Shape
---@param r number
---@overload fun(self: Shape, r: number, g: number, b: number, a: number)
function shape_meta:DrawOutline( r, ... )
	assert( self:IsValid() )
	return DrawShapeOutline( self.handle, r, ... )
end

--- Draws a highlight of the shape.
---
---@param self Shape
---@param amount number
function shape_meta:DrawHighlight( amount )
	assert( self:IsValid() )
	return DrawShapeHighlight( self.handle, amount )
end

--- Sets the transform of the shape relative to its body.
---
---@param self Shape
---@param transform transform
function shape_meta:SetLocalTransform( transform )
	assert( self:IsValid() )
	return SetShapeLocalTransform( self.handle, transform )
end

--- Sets the emmissivity scale of the shape.
---
---@param self Shape
---@param scale number
function shape_meta:SetEmissiveScale( scale )
	assert( self:IsValid() )
	return SetShapeEmissiveScale( self.handle, scale )
end

--- Sets the collision filter of the shape.
--- A shape will only collide with another if the following is true:
--- ```
--- (A.layer & B.mask) && (B.layer & A.mask)
--- ```
---
---@param self Shape
---@param layer? number bit array (8 bits, 0-255)
---@param mask? number bit mask (8 bits, 0-255)
function shape_meta:SetCollisionFilter( layer, mask )
	SetShapeCollisionFilter( self.handle, layer or 1, mask or 255 )
end

--- Gets the transform of the shape relative to its body.
---
---@param self Shape
---@return Transformation
function shape_meta:GetLocalTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetShapeLocalTransform( self.handle ) )
end

--- Gets the transform of the shape.
---
---@param self Shape
---@return Transformation
function shape_meta:GetWorldTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetShapeWorldTransform( self.handle ) )
end

--- Gets the body of this shape.
---
---@param self Shape
---@return Body
function shape_meta:GetBody()
	assert( self:IsValid() )
---@diagnostic disable-next-line: return-type-mismatch
	return Body( GetShapeBody( self.handle ) )
end

--- Gets the joints attached to this shape.
---
---@param self Shape
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
---@param self Shape
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
---@param self Shape
---@return Vector min
---@return Vector max
function shape_meta:GetWorldBounds()
	assert( self:IsValid() )
	local min, max = GetShapeBounds( self.handle )
	return MakeVector( min ), MakeVector( max )
end

--- Gets the material and color of the shape at the specified position.
---
---@param self Shape
---@param pos vector
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
---@param self Shape
---@return number x
---@return number y
---@return number z
---@return number scale
function shape_meta:GetSize()
	assert( self:IsValid() )
	return GetShapeSize( self.handle )
end

--- Gets the count of voxels in the shape.
---
---@param self Shape
---@return number
function shape_meta:GetVoxelCount()
	assert( self:IsValid() )
	return GetShapeVoxelCount( self.handle )
end

--- Gets the closest point to the shape from a given origin.
---
---@param self Shape
---@param origin vector
---@return boolean hit
---@return Vector? point
---@return Vector? normal
function shape_meta:GetClosestPoint( origin )
	local hit, point, normal = GetShapeClosestPoint( self.handle, origin )
	if not hit then
		return false
	end
	return hit, MakeVector( point ), MakeVector( normal )
end

--- Gets all the shapes touching the shape
---
---@param self Shape
---@return Shape[] shapes
function shape_meta:GetTouching()
	local min, max = self:GetWorldBounds()
	local potential = QueryAabbShapes( min - { 0.1, 0.1, 0.1 }, max + { 0.1, 0.1, 0.1 } )
	local found = {}
	for i = 1, #potential do
		if potential[i] ~= self.handle and self:IsTouching( potential[i] ) then
			found[#found+1] = Shape( potential[i] )
		end
	end
	return found
end

--- Gets if the shape is currently visible.
---
---@param self Shape
---@param maxDist number
---@param rejectTransparent? boolean
---@return boolean
function shape_meta:IsVisible( maxDist, rejectTransparent )
	assert( self:IsValid() )
	return IsShapeVisible( self.handle, maxDist, rejectTransparent )
end

--- Gets if the shape has been broken.
---
---@param self Shape
---@return boolean
function shape_meta:IsBroken()
	return not self:IsValid() or IsShapeBroken( self.handle )
end

--- Gets if the shape is touching a given shape.
---
---@param self Shape
---@param shape Shape | integer
---@return boolean
function shape_meta:IsTouching( shape )
	assert( self:IsValid() )
	local shapeHandle = GetEntityHandle( shape )
	---@cast shapeHandle shape_handle
	return IsShapeTouching( self.handle, shapeHandle )
end

----------------
-- Properties implementation

---@param self Shape
---@param setter boolean
---@param val transform
---@return Transformation?
function shape_meta._C:transform( setter, val )
	if setter then
		self:SetLocalTransform( val )
	else
		return self:GetLocalTransform()
	end
end

---@param self Shape
---@param setter boolean
---@param val number
function shape_meta._C:emissive( setter, val )
	assert(setter, "cannot get emissive")
	self:SetEmissiveScale( val )
end

---@param self Shape
---@param setter boolean
---@return Body
function shape_meta._C:body( setter )
	assert(not setter, "cannot set body")
	return self:GetBody()
end

---@param self Shape
---@param setter boolean
---@return Joint[]
function shape_meta._C:joints( setter )
	assert(not setter, "cannot set joints")
	return self:GetJoints()
end

---@param self Shape
---@param setter boolean
---@return Light[]
function shape_meta._C:lights( setter )
	assert(not setter, "cannot set lights")
	return self:GetLights()
end

---@param self Shape
---@param setter boolean
---@return Vector
function shape_meta._C:size( setter )
	assert(not setter, "cannot set size")
	return Vector( self:GetSize() )
end

---@param self Shape
---@param setter boolean
---@return boolean
function shape_meta._C:broken( setter )
	assert(not setter, "cannot set broken")
	return self:IsBroken()
end
