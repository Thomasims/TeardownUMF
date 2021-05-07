local vector_meta = global_metatable( "vector" )
local quat_meta = global_metatable( "quaternion" )
local transform_meta = global_metatable( "transformation" )

function IsTransformation( v )
	return type( v ) == "table" and v.pos and v.rot
end

function MakeTransformation( t )
	setmetatable( t.pos, vector_meta )
	setmetatable( t.rot, quat_meta )
	return setmetatable( t, transform_meta )
end

function Transformation( pos, rot )
	return MakeTransformation { pos = pos, rot = rot }
end

function transform_meta:__unserialize( data )
	local x, y, z, i, j, k, r =
		data:match( "([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*)" )
	self.pos = Vector( tonumber( x ), tonumber( y ), tonumber( z ) )
	self.rot = Quaternion( tonumber( i ), tonumber( j ), tonumber( k ), tonumber( r ) )
	return self
end

function transform_meta:__serialize()
	return table.concat( self.pos, ";" ) .. ";" .. table.concat( self.rot, ";" )
end

function transform_meta:Clone()
	return MakeTransformation { pos = vector_meta.Clone( self.pos ), rot = quat_meta.Clone( self.rot ) }
end

local TransformStr = TransformStr
function transform_meta:__tostring()
	return TransformStr( self )
end

local TransformToLocalPoint = TransformToLocalPoint
local TransformToLocalTransform = TransformToLocalTransform
local TransformToLocalVec = TransformToLocalVec
local TransformToParentPoint = TransformToParentPoint
local TransformToParentTransform = TransformToParentTransform
local TransformToParentVec = TransformToParentVec

function transform_meta.__add( a, b )
	if not IsTransformation( b ) then
		if IsVector( b ) then
			b = Transformation( b, QUAT_ZERO )
		elseif IsQuaternion( b ) then
			b = Transformation( VEC_ZERO, b )
		end
	end
	return MakeTransformation( TransformToParentTransform( a, b ) )
end

function transform_meta:ToLocal( o )
	if IsTransformation( o ) then
		return MakeTransformation( TransformToLocalTransform( self, o ) )
	else
		return MakeVector( TransformToLocalPoint( self, o ) )
	end
end

function transform_meta:ToLocalDir( o )
	return MakeVector( TransformToLocalVec( self, o ) )
end

function transform_meta:ToGlobal( o )
	if IsTransformation( o ) then
		return MakeTransformation( TransformToParentTransform( self, o ) )
	else
		return MakeVector( TransformToParentPoint( self, o ) )
	end
end

function transform_meta:ToGlobalDir( o )
	return MakeVector( TransformToParentVec( self, o ) )
end

function transform_meta:Raycast( dist, mul, radius, rejectTransparent )
	local dir = TransformToParentVec( self, VEC_FORWARD )
	if mul then
		vector_meta.Mul( dir, mul )
	end
	local hit, dist2, normal, shape = QueryRaycast( self.pos, dir, dist, radius, rejectTransparent )
	return {
		hit = hit,
		dist = dist2,
		normal = normal,
		shape = shape,
		hitpos = vector_meta.__add( self.pos, vector_meta.Mul( dir, hit and dist2 or dist ) ),
	}
end
