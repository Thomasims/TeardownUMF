----------------
-- Quaternion class and related functions
-- @script vector.quat
UMF_REQUIRE "/"

local vector_meta = global_metatable( "vector" )
---@class Quaternion
local quat_meta
quat_meta = global_metatable( "quaternion" )

--- Tests if the parameter is a quaternion.
---
---@param q any
---@return boolean
function IsQuaternion( q )
	return type( q ) == "table" and type( q[1] ) == "number" and type( q[2] ) == "number" and type( q[3] ) == "number" and
		       type( q[4] ) == "number"
end

--- Makes the parameter quat into a quaternion.
---
---@param q number[]
---@return Quaternion q
function MakeQuaternion( q )
	return setmetatable( q, quat_meta )
end

--- Creates a new quaternion.
---
---@param i? number
---@param j? number
---@param k? number
---@param r? number
---@return Quaternion
---@overload fun(q: Quaternion): Quaternion
function Quaternion( i, j, k, r )
	if IsQuaternion( i ) then
		i, j, k, r = i[1], i[2], i[3], i[4]
	end
	return MakeQuaternion { i or 0, j or 0, k or 0, r or 1 }
end

---@type Quaternion

---@param data string
---@return Quaternion self
function quat_meta:__unserialize( data )
	local i, j, k, r = data:match( "([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*)" )
	self[1] = tonumber( i )
	self[2] = tonumber( j )
	self[3] = tonumber( k )
	self[4] = tonumber( r )
	return self
end

---@return string data
function quat_meta:__serialize()
	return table.concat( self, ";" )
end

QUAT_ZERO = Quaternion()

--- Clones the quaternion.
---
---@return Quaternion clone
function quat_meta:Clone()
	return MakeQuaternion { self[1], self[2], self[3], self[4] }
end

local QuatStr = QuatStr
---@return string
function quat_meta:__tostring()
	return QuatStr( self )
end

---@return Quaternion
function quat_meta:__unm()
	return MakeQuaternion { -self[1], -self[2], -self[3], -self[4] }
end

--- Conjugates the quaternion.
---
---@return Quaternion
function quat_meta:Conjugate()
	return MakeQuaternion { -self[1], -self[2], -self[3], self[4] }
end

--- Inverts the quaternion.
---
---@return Quaternion
function quat_meta:Invert()
	local l = quat_meta.LengthSquare( self )
	return MakeQuaternion { -self[1] / l, -self[2] / l, -self[3] / l, self[4] / l }
end

--- Adds to the quaternion.
---
---@param o Quaternion | number
---@return Quaternion self
function quat_meta:Add( o )
	if IsQuaternion( o ) then
		self[1] = self[1] + o[1]
		self[2] = self[2] + o[2]
		self[3] = self[3] + o[3]
		self[4] = self[4] + o[4]
	else
		self[1] = self[1] + o
		self[2] = self[2] + o
		self[3] = self[3] + o
		self[4] = self[4] + o
	end
	return self
end

---@param a Quaternion | number
---@param b Quaternion | number
---@return Quaternion
function quat_meta.__add( a, b )
	if not IsQuaternion( a ) then
		a, b = b, a
	end
	return quat_meta.Add( quat_meta.Clone( a ), b )
end

--- Subtracts from the quaternion.
---
---@param o Quaternion | number
---@return Quaternion self
function quat_meta:Sub( o )
	if IsQuaternion( o ) then
		self[1] = self[1] - o[1]
		self[2] = self[2] - o[2]
		self[3] = self[3] - o[3]
		self[4] = self[4] - o[4]
	else
		self[1] = self[1] - o
		self[2] = self[2] - o
		self[3] = self[3] - o
		self[4] = self[4] - o
	end
	return self
end

---@param a Quaternion | number
---@param b Quaternion | number
---@return Quaternion
function quat_meta.__sub( a, b )
	if not IsQuaternion( a ) then
		a, b = b, a
	end
	return quat_meta.Sub( quat_meta.Clone( a ), b )
end

--- Multiplies (~rotate) the quaternion.
---
---@param o Quaternion
---@return Quaternion self
function quat_meta:Mul( o )
	local i1, j1, k1, r1 = self[1], self[2], self[3], self[4]
	local i2, j2, k2, r2 = o[1], o[2], o[3], o[4]
	self[1] = j1 * k2 - k1 * j2 + r1 * i2 + i1 * r2
	self[2] = k1 * i2 - i1 * k2 + r1 * j2 + j1 * r2
	self[3] = i1 * j2 - j1 * i2 + r1 * k2 + k1 * r2
	self[4] = r1 * r2 - i1 * i2 - j1 * j2 - k1 * k2
	return self
end

---@param a Quaternion | number
---@param b Quaternion | number
---@return Quaternion
---@overload fun(a: Quaternion, b: Vector): Vector
---@overload fun(a: Quaternion, b: Transformation): Transformation
function quat_meta.__mul( a, b )
	if not IsQuaternion( a ) then
		a, b = b, a
	end
	if type( b ) == "number" then
		return Quaternion( a[1] * b, a[2] * b, a[3] * b, a[4] * b )
	end
	if IsVector( b ) then
		return vector_meta.__mul( b, a )
	end
	if IsTransformation( b ) then
		---@diagnostic disable-next-line: undefined-field
		return Transformation( vector_meta.Mul( vector_meta.Clone( b.pos ), a ), QuatRotateQuat( b.rot, a ) )
	end
	return MakeQuaternion( QuatRotateQuat( a, b ) )
end

--- Divides the quaternion components.
---
---@param o number
---@return Quaternion self
function quat_meta:Div( o )
	if IsQuaternion( o ) then
		quat_meta.Mul( self, { -o[1], -o[2], -o[3], o[4] } )
	else
		self[1] = self[1] / o
		self[2] = self[2] / o
		self[3] = self[3] / o
		self[4] = self[4] / o
	end
	return self
end

---@param a Quaternion | number
---@param b Quaternion | number
---@return Quaternion
function quat_meta.__div( a, b )
	return quat_meta.Div( quat_meta.Clone( a ), b )
end

---@param a Quaternion
---@param b Quaternion
---@return boolean
function quat_meta.__eq( a, b )
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
end

--- Gets the squared length of the quaternion.
---
---@return number
function quat_meta:LengthSquare()
	return self[1] ^ 2 + self[2] ^ 2 + self[3] ^ 2 + self[4] ^ 2
end

--- Gets the length of the quaternion
---
---@return number
function quat_meta:Length()
	return math.sqrt( quat_meta.LengthSquare( self ) )
end

local QuatSlerp = QuatSlerp
--- S-lerps from the quaternion to another one.
---
---@param o Quaternion
---@param n number
---@return Quaternion
function quat_meta:Slerp( o, n )
	return MakeQuaternion( QuatSlerp( self, o, n ) )
end

--- Gets the left-direction of the quaternion.
---
---@return Vector
function quat_meta:Left()
	local x, y, z, s = self[1], self[2], self[3], self[4]

	return Vector( 1 - (y ^ 2 + z ^ 2) * 2, (z * s + x * y) * 2, (x * z - y * s) * 2 )
end

--- Gets the up-direction of the quaternion.
---
---@return Vector
function quat_meta:Up()
	local x, y, z, s = self[1], self[2], self[3], self[4]

	return Vector( (y * x - z * s) * 2, 1 - (z ^ 2 + x ^ 2) * 2, (x * s + y * z) * 2 )
end

--- Gets the forward-direction of the quaternion.
---
---@return Vector
function quat_meta:Forward()
	local x, y, z, s = self[1], self[2], self[3], self[4]

	return Vector( (y * s + z * x) * 2, (z * y - x * s) * 2, 1 - (x ^ 2 + y ^ 2) * 2 )
end

--- Gets the euler angle representation of the quaternion.
--- Note: This uses the same order as QuatEuler().
---
---@return number
---@return number
---@return number
function quat_meta:ToEuler()
	if GetQuatEuler then
		return GetQuatEuler( self )
	end
	local x, y, z, w = self[1], self[2], self[3], self[4]
	-- Credit to https://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToEuler/index.htm

	local bank, heading, attitude

	local s = 2 * x * y + 2 * z * w
	if s >= 1 then
		heading = 2 * math.atan2( x, w )
		bank = 0
		attitude = math.pi / 2
	elseif s <= -1 then
		heading = -2 * math.atan2( x, w )
		bank = 0
		attitude = math.pi / -2
	else
		bank = math.atan2( 2 * x * w - 2 * y * z, 1 - 2 * x ^ 2 - 2 * z ^ 2 )
		heading = math.atan2( 2 * y * w - 2 * x * z, 1 - 2 * y ^ 2 - 2 * z ^ 2 )
		attitude = math.asin( s )
	end

	return math.deg( bank ), math.deg( heading ), math.deg( attitude )
end

--- Approachs another quaternion by the specified angle.
---
---@param dest Quaternion
---@param rate number
---@return Quaternion
function quat_meta:Approach( dest, rate )
	local dot = self[1] * dest[1] + self[2] * dest[2] + self[3] * dest[3] + self[4] * dest[4]
	if dot >= 1 then
		return self
	end
	local corr_rate = rate / math.acos( 2 * dot ^ 2 - 1 )
	if corr_rate >= 1 then
		return MakeQuaternion( dest )
	end
	return MakeQuaternion( QuatSlerp( self, dest, corr_rate ) )
end
