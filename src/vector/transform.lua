---@diagnostic disable: duplicate-doc-field
----------------
-- Transform class and related functions
-- @script vector.transform
UMF_REQUIRE "/"

local vector_meta = global_metatable( "vector" )
local quat_meta = global_metatable( "quaternion" )

---@class transform
---@field pos vector
---@field rot quaternion

---@class Transformation: transform
---@field pos Vector
---@field rot Quaternion
local transform_meta
transform_meta = global_metatable( "transformation" )

--- Tests if the parameter is a transformation.
---
---@param t any
---@return boolean
function IsTransformation( t )
	return type( t ) == "table" and t.pos and t.rot
end

--- Makes the parameter transform into a transformation.
---
---@param t transform
---@return Transformation t
function MakeTransformation( t )
	instantiate_global_metatable( "vector", t.pos )
	instantiate_global_metatable( "quaternion", t.rot )
	return instantiate_global_metatable( "transformation", t )
end

--- Creates a new transformation.
---
---@param pos? vector
---@param rot? quaternion
---@return Transformation
function Transformation( pos, rot )
	return MakeTransformation { pos = pos or { 0, 0, 0 }, rot = rot or { 0, 0, 0, 1 } }
end

---@type Transformation

---@param data string
---@return Transformation self
function transform_meta:__unserialize( data )
	local x, y, z, i, j, k, r =
		data:match( "([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*)" )
	self.pos = Vector( tonumber( x ), tonumber( y ), tonumber( z ) )
	self.rot = Quaternion( tonumber( i ), tonumber( j ), tonumber( k ), tonumber( r ) )
	return self
end

---@return string data
function transform_meta:__serialize()
	return string.format("%f;%f;%f;%f;%f;%f;%f", self.pos[1], self.pos[2], self.pos[3], self.rot[1], self.rot[2], self.rot[3], self.rot[4])
end

--- Clones the transformation.
---
---@return Transformation clone
function transform_meta:Clone()
	return MakeTransformation { pos = vector_meta.Clone( self.pos ), rot = quat_meta.Clone( self.rot ) }
end

local TransformStr = TransformStr
---@return string
function transform_meta:__tostring()
	return TransformStr( self )
end

local TransformToLocalPoint = TransformToLocalPoint
local TransformToLocalTransform = TransformToLocalTransform
local TransformToLocalVec = TransformToLocalVec
local TransformToParentPoint = TransformToParentPoint
local TransformToParentTransform = TransformToParentTransform
local TransformToParentVec = TransformToParentVec

---@param a transform
---@param b transform | vector | quaternion
---@return Transformation
function transform_meta.__add( a, b )
	if not IsTransformation( b ) then
		if IsVector( b ) then
			---@cast b vector
			b = Transformation( b, QUAT_ZERO )
		elseif IsQuaternion( b ) then
			---@cast b quaternion
			b = Transformation( VEC_ZERO, b )
		end
	end
	---@cast b transform
	return MakeTransformation( TransformToParentTransform( a, b ) )
end

--- Gets the local representation of a world-space transform, point or rotation
---
---@generic T : transform | vector | quaternion
---@param o T
---@return T
function transform_meta:ToLocal( o )
	if IsTransformation( o ) then
		return MakeTransformation( TransformToLocalTransform( self, o ) )
	elseif IsQuaternion( o ) then
		return MakeQuaternion( TransformToLocalTransform( self, Transform( {}, o ) ).rot )
	else
		return MakeVector( TransformToLocalPoint( self, o ) )
	end
end

--- Gets the local representation of a world-space direction
---
---@param o vector
---@return Vector
function transform_meta:ToLocalDir( o )
	return MakeVector( TransformToLocalVec( self, o ) )
end

--- Gets the global representation of a local-space transform, point or rotation
---
---@generic T : transform | vector | quaternion
---@param o T
---@return T
function transform_meta:ToGlobal( o )
	if IsTransformation( o ) then
		return MakeTransformation( TransformToParentTransform( self, o ) )
	elseif IsQuaternion( o ) then
		return MakeQuaternion( TransformToParentTransform( self, Transform( {}, o ) ).rot )
	else
		return MakeVector( TransformToParentPoint( self, o ) )
	end
end

--- Gets the global representation of a local-space direction
---
---@param o vector
---@return Vector
function transform_meta:ToGlobalDir( o )
	return MakeVector( TransformToParentVec( self, o ) )
end

--- Raycasts from the transformation
---
---@deprecated
---@param dist number
---@param mul? number
---@param radius? number
---@param rejectTransparent? boolean
---@return { hit: boolean, dist: number, normal: Vector, shape: Shape | number, hitpos: Vector }
function transform_meta:Raycast( dist, mul, radius, rejectTransparent )
	local dir = TransformToParentVec( self, VEC_FORWARD )
	if mul then
		vector_meta.Mul( dir, mul )
	end
	local hit, dist2, normal, shape = QueryRaycast( self.pos, dir, dist, radius, rejectTransparent )
	return {
		hit = hit,
		dist = dist2,
		normal = hit and MakeVector( normal ),
		shape = hit and Shape and Shape( shape ) or shape,
		hitpos = vector_meta.__add( self.pos, vector_meta.Mul( dir, hit and dist2 or dist ) ),
	}
end
