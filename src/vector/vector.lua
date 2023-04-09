---@diagnostic disable: param-type-mismatch
----------------
-- Vector class and related functions
-- @script vector.vector
UMF_REQUIRE "/"

local quat_meta = global_metatable( "quaternion" )

---@class Vector
local vector_meta
vector_meta = global_metatable( "vector" )

--- Tests if the parameter is a vector.
---
---@param v any
---@return boolean
function IsVector( v )
	return type( v ) == "table" and type( v[1] ) == "number" and type( v[2] ) == "number" and type( v[3] ) == "number" and
		       not v[4]
end

--- Makes the parameter vec into a vector.
---
---@param v number[]
---@return Vector v
function MakeVector( v )
	return instantiate_global_metatable( "vector", v )
end

--- Creates a new vector.
---
---@param x? number
---@param y? number
---@param z? number
---@return Vector
---@overload fun(v: Vector): Vector
function Vector( x, y, z )
	if IsVector( x ) then
---@diagnostic disable-next-line: need-check-nil
		x, y, z = x[1], x[2], x[3]
	end
	return MakeVector { x or 0, y or 0, z or 0 }
end

---@type Vector

--- Unserialize a vector from its serialized form.
---
---@param data string
---@return Vector self
function vector_meta:__unserialize( data )
	local x, y, z = data:match( "([-0-9.]*);([-0-9.]*);([-0-9.]*)" )
	self[1] = tonumber( x )
	self[2] = tonumber( y )
	self[3] = tonumber( z )
	return self
end

--- Serialize the vector to a string.
---
---@return string data
function vector_meta:__serialize()
	return string.format("%f;%f;%f", self[1], self[2], self[3])
end

VEC_ZERO = Vector()
VEC_FORWARD = Vector( 0, 0, 1 )
VEC_UP = Vector( 0, 1, 0 )
VEC_LEFT = Vector( 1, 0, 0 )

--- Clones the vector.
---
---@return Vector clone
function vector_meta:Clone()
	return MakeVector { self[1], self[2], self[3] }
end

local VecStr = VecStr
--- Turn the vector into a string for printing.
---
---@return string
function vector_meta:__tostring()
	return VecStr( self )
end

--- Unary operator `-v`
---
---@return Vector
function vector_meta:__unm()
	return MakeVector { -self[1], -self[2], -self[3] }
end

--- Adds to the vector.
---
---@param o Vector | number
---@return Vector self
function vector_meta:Add( o )
	if IsVector( o ) then
		self[1] = self[1] + o[1]
		self[2] = self[2] + o[2]
		self[3] = self[3] + o[3]
	else
		self[1] = self[1] + o
		self[2] = self[2] + o
		self[3] = self[3] + o
	end
	return self
end

--- Addition operator `v + o`
---
---@param a Vector | number
---@param b Vector | number
---@return Vector
---@overload fun(a: Transformation, b: Vector): Transformation
---@overload fun(a: Vector, b: Transformation): Transformation
function vector_meta.__add( a, b )
	if not IsVector( a ) then
		a, b = b, a
	end
	if IsTransformation( b ) then
		return Transformation( vector_meta.Add( vector_meta.Clone( a ), b.pos ), quat_meta.Clone( b.rot ) )
	end
	return vector_meta.Add( vector_meta.Clone( a ), b )
end

--- Subtracts from the vector.
---
---@param o Vector | number
---@return Vector self
function vector_meta:Sub( o )
	if IsVector( o ) then
		self[1] = self[1] - o[1]
		self[2] = self[2] - o[2]
		self[3] = self[3] - o[3]
	else
		self[1] = self[1] - o
		self[2] = self[2] - o
		self[3] = self[3] - o
	end
	return self
end

--- Subtraction operator `v - o`
---
---@param a Vector | number
---@param b Vector | number
---@return Vector
function vector_meta.__sub( a, b )
	if not IsVector( a ) then
		a, b = b, a
	end
	return vector_meta.Sub( vector_meta.Clone( a ), b )
end

--- Multiplies the vector.
---
---@param o Vector | Quaternion | number
---@return Vector self
function vector_meta:Mul( o )
	if IsVector( o ) then
		self[1] = self[1] * o[1]
		self[2] = self[2] * o[2]
		self[3] = self[3] * o[3]
	elseif IsQuaternion( o ) then
		-- v2 = v + 2 * r X (s * v + r X v) / quat_meta.LengthSquare(self)
		-- local s, r = o[4], Vector(o[1], o[2], o[3])
		-- self:Add(2 * s * r:Cross(self) + 2 * r:Cross(r:Cross(self)))

		local x1, y1, z1 = self[1], self[2], self[3]
		local x2, y2, z2, s = o[1], o[2], o[3], o[4]

		local x3 = y2 * z1 - z2 * y1
		local y3 = z2 * x1 - x2 * z1
		local z3 = x2 * y1 - y2 * x1

		self[1] = x1 + (x3 * s + y2 * z3 - z2 * y3) * 2
		self[2] = y1 + (y3 * s + z2 * x3 - x2 * z3) * 2
		self[3] = z1 + (z3 * s + x2 * y3 - y2 * x3) * 2
	else
		self[1] = self[1] * o
		self[2] = self[2] * o
		self[3] = self[3] * o
	end
	return self
end

--- Multiplication operator `v * o`
---
---@param a Vector | Quaternion | number
---@param b Vector | Quaternion | number
---@return Vector
function vector_meta.__mul( a, b )
	if not IsVector( a ) then
		a, b = b, a
	end
	return vector_meta.Mul( vector_meta.Clone( a ), b )
end

--- Divides the vector components.
---
---@param o number
---@return Vector self
function vector_meta:Div( o )
	self[1] = self[1] / o
	self[2] = self[2] / o
	self[3] = self[3] / o
	return self
end

--- Division operator `v / o`
---
---@param a Vector | number
---@param b Vector | number
---@return Vector
function vector_meta.__div( a, b )
	return vector_meta.Div( vector_meta.Clone( a ), b )
end

--- Applies the modulo operator on the vector components.
---
---@param o number
---@return Vector self
function vector_meta:Mod( o )
	self[1] = self[1] % o
	self[2] = self[2] % o
	self[3] = self[3] % o
	return self
end

--- Modulo operator `v % o`
---
---@param a Vector | number
---@param b Vector | number
---@return Vector
function vector_meta.__mod( a, b )
	return vector_meta.Mod( vector_meta.Clone( a ), b )
end

--- Applies the exponent operator on the vector components.
---
---@param o number
---@return Vector self
function vector_meta:Pow( o )
	self[1] = self[1] ^ o
	self[2] = self[2] ^ o
	self[3] = self[3] ^ o
	return self
end

--- Power operator `v ^ o`
---
---@param a Vector
---@param b number
---@return Vector
function vector_meta.__pow( a, b )
	return vector_meta.Pow( vector_meta.Clone( a ), b )
end

--- Equality comparison operator `v == o`
---
---@param a Vector
---@param b Vector
---@return boolean
function vector_meta.__eq( a, b )
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

--- Strict inequality comparison operator `v < o`
---
---@param a Vector
---@param b Vector
---@return boolean
function vector_meta.__lt( a, b )
	return a[1] < b[1] or (a[1] == b[1] and (a[2] < b[2] or (a[2] == b[2] and (a[3] < b[3]))))
end

--- Inequality comparison operator `v <= o`
---
---@param a Vector
---@param b Vector
---@return boolean
function vector_meta.__le( a, b )
	return a[1] < b[1] or (a[1] == b[1] and (a[2] < b[2] or (a[2] == b[2] and (a[3] <= b[3]))))
end

local VecDot = VecDot
--- Computes the dot product with another vector.
---
---@param b Vector
---@return number
function vector_meta:Dot( b )
	return VecDot( self, b )
end

local VecCross = VecCross
--- Computes the cross product with another vector.
---
---@param b Vector
---@return Vector
function vector_meta:Cross( b )
	return MakeVector( VecCross( self, b ) )
end

local VecLength = VecLength
--- Gets the length of the vector.
---
---@return number
function vector_meta:Length()
	return VecLength( self )
end

--- Gets the volume of the vector (product of all its components).
---
---@return number
function vector_meta:Volume()
	return math.abs( self[1] * self[2] * self[3] )
end

local VecLerp = VecLerp
--- Lerps from the vector to another one.
---
---@param o Vector
---@param n number
---@return Vector
function vector_meta:Lerp( o, n )
	return MakeVector( VecLerp( self, o, n ) )
end

local VecNormalize = VecNormalize
--- Gets the normalized form of the vector.
---
---@return Vector
function vector_meta:Normalized()
	return MakeVector( VecNormalize( self ) )
end

--- Normalize the vector.
---
---@return Vector self
function vector_meta:Normalize()
	return vector_meta.Div( self, vector_meta.Length( self ) )
end

--- Gets the squared distance to another vector.
---
---@param o Vector
---@return number
function vector_meta:DistSquare( o )
	return (self[1] - o[1]) ^ 2 + (self[2] - o[2]) ^ 2 + (self[3] - o[3]) ^ 2
end

--- Gets the distance to another vector.
---
---@param o Vector
---@return number
function vector_meta:Distance( o )
	return math.sqrt( vector_meta.DistSquare( self, o ) )
end

--- Gets the rotation to another vector.
---
---@param o Vector
---@return Quaternion
function vector_meta:LookAt( o )
	return MakeQuaternion( QuatLookAt( self, o ) )
end

--- Convert the direction vector into a Quaternion using an optional up vector.
--- This function behaves similarly to QuatLookAt, so "forward" is -z
---
---@param target_up? Vector
---@return Quaternion
function vector_meta:ToQuaternion( target_up )
	local forward = VecScale( self, -1 / VecLength( self ) )
	local right = VecNormalize( VecCross( target_up or Vec( 0, 1, 0 ), forward ) )
	local up = VecCross( forward, right )

	local m00, m01, m02 = right[1], right[2], right[3]
	local m10, m11, m12 = up[1], up[2], up[3]
	local m20, m21, m22 = forward[1], forward[2], forward[3]

	if m22 < 0 then
		if m00 > m11 then
			local t = 1 + m00 - m11 - m22
			local t2 = 0.5 / math.sqrt( t )
			return Quaternion( t2 * t, t2 * (m01 + m10), t2 * (m20 + m02), t2 * (m12 - m21) )
		else
			local t = 1 - m00 + m11 - m22
			local t2 = 0.5 / math.sqrt( t )
			return Quaternion( t2 * (m01 + m10), t2 * t, t2 * (m12 + m21), t2 * (m20 - m02) )
		end
	else
		if m00 < -m11 then
			local t = 1 - m00 - m11 + m22
			local t2 = 0.5 / math.sqrt( t )
			return Quaternion( t2 * (m20 + m02), t2 * (m12 + m21), t2 * t, t2 * (m01 - m10) )
		else
			local t = 1 + m00 + m11 + m22
			local t2 = 0.5 / math.sqrt( t )
			return Quaternion( t2 * (m12 - m21), t2 * (m20 - m02), t2 * (m01 - m10), t2 * t )
		end
	end
end

--- Approachs another vector by the specified distance.
---
---@param dest Vector
---@param rate number
---@return Vector
function vector_meta:Approach( dest, rate )
	local dist = vector_meta.Distance( self, dest )
	if dist < rate then
		return dest
	end
	return vector_meta.Lerp( self, dest, rate / dist )
end

--- Get the minimum value for each vector component.
---
---@vararg Vector|number
---@return Vector
function vector_meta:Min( ... )
	local n = vector_meta.Clone( self )
	for i = 1, select( "#", ... ) do
		local o = select( i, ... )
		if type( o ) == "number" then
			n[1] = math.min( n[1], o )
			n[2] = math.min( n[2], o )
			n[3] = math.min( n[3], o )
		else
			n[1] = math.min( n[1], o[1] )
			n[2] = math.min( n[2], o[2] )
			n[3] = math.min( n[3], o[3] )
		end
	end
	return n
end

--- Get the maximum value for each vector component.
---
---@vararg Vector
---@return Vector
---@overload fun(o: number, ...): Vector
function vector_meta:Max( ... )
	local n = vector_meta.Clone( self )
	for i = 1, select( "#", ... ) do
		local o = select( i, ... )
		if type( o ) == "number" then
			n[1] = math.max( n[1], o )
			n[2] = math.max( n[2], o )
			n[3] = math.max( n[3], o )
		else
			n[1] = math.max( n[1], o[1] )
			n[2] = math.max( n[2], o[2] )
			n[3] = math.max( n[3], o[3] )
		end
	end
	return n
end

--- Clamp the vector components.
---
---@param min Vector | number
---@param max Vector | number
---@return Vector
function vector_meta:Clamp( min, max )
	if type( min ) == "number" then
		return Vector( math.max( math.min( self[1], max ), min ), math.max( math.min( self[2], max ), min ),
		               math.max( math.min( self[3], max ), min ) )
	else
		return Vector( math.max( math.min( self[1], max[1] ), min[1] ), math.max( math.min( self[2], max[2] ), min[2] ),
		               math.max( math.min( self[3], max[3] ), min[3] ) )
	end
end
