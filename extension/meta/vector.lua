local vector_meta = global_metatable( "vector" )
local quat_meta = global_metatable( "quaternion" )

function IsVector( v )
	return type( v ) == "table" and type( v[1] ) == "number" and type( v[2] ) == "number" and type( v[3] ) == "number" and
	       not v[4]
end

function MakeVector( v )
	return setmetatable( v, vector_meta )
end

function Vector( x, y, z )
	if IsVector( x ) then
		x, y, z = x[1], x[2], x[3]
	end
	return MakeVector { x or 0, y or 0, z or 0 }
end

function vector_meta:__unserialize( data )
	local x, y, z = data:match( "([-0-9.]*);([-0-9.]*);([-0-9.]*)" )
	self[1] = tonumber( x )
	self[2] = tonumber( y )
	self[3] = tonumber( z )
	return self
end

function vector_meta:__serialize()
	return table.concat( self, ";" )
end

VEC_ZERO = Vector()
VEC_FORWARD = Vector( 0, 0, 1 )
VEC_UP = Vector( 0, 1, 0 )
VEC_LEFT = Vector( 1, 0, 0 )

function vector_meta:Clone()
	return MakeVector { self[1], self[2], self[3] }
end

local VecStr = VecStr
function vector_meta:__tostring()
	return VecStr( self )
end

function vector_meta:__unm()
	return MakeVector { -self[1], -self[2], -self[3] }
end

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

function vector_meta.__add( a, b )
	if not IsVector( a ) then
		a, b = b, a
	end
	if IsTransformation( b ) then
		return Transformation( vector_meta.Add( vector_meta.Clone( a ), b.pos ), quat_meta.Clone( b.rot ) )
	end
	return vector_meta.Add( vector_meta.Clone( a ), b )
end

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

function vector_meta.__sub( a, b )
	if not IsVector( a ) then
		a, b = b, a
	end
	return vector_meta.Sub( vector_meta.Clone( a ), b )
end

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

function vector_meta.__mul( a, b )
	if not IsVector( a ) then
		a, b = b, a
	end
	return vector_meta.Mul( vector_meta.Clone( a ), b )
end

function vector_meta:Div( o )
	self[1] = self[1] / o
	self[2] = self[2] / o
	self[3] = self[3] / o
	return self
end

function vector_meta.__div( a, b )
	return vector_meta.Div( vector_meta.Clone( a ), b )
end

function vector_meta:Mod( o )
	self[1] = self[1] % o
	self[2] = self[2] % o
	self[3] = self[3] % o
	return self
end

function vector_meta.__mod( a, b )
	return vector_meta.Mod( vector_meta.Clone( a ), b )
end

function vector_meta:Pow( o )
	self[1] = self[1] ^ o
	self[2] = self[2] ^ o
	self[3] = self[3] ^ o
	return self
end

function vector_meta.__pow( a, b )
	return vector_meta.Pow( vector_meta.Clone( a ), b )
end

function vector_meta.__eq( a, b )
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

function vector_meta.__lt( a, b )
	return a[1] < b[1] or (a[1] == b[1] and (a[2] < b[2] or (a[2] == b[2] and (a[3] < b[3]))))
end

function vector_meta.__le( a, b )
	return a[1] < b[1] or (a[1] == b[1] and (a[2] < b[2] or (a[2] == b[2] and (a[3] <= b[3]))))
end

local VecDot = VecDot
function vector_meta:Dot( b )
	return MakeVector( VecDot( self, b ) )
end

local VecCross = VecCross
function vector_meta:Cross( b )
	return MakeVector( VecCross( self, b ) )
end

local VecLength = VecLength
function vector_meta:Length()
	return VecLength( self )
end

function vector_meta:Volume()
	return math.abs( self[1] * self[2] * self[3] )
end

local VecLerp = VecLerp
function vector_meta:Lerp( o, n )
	return MakeVector( VecLerp( self, o, n ) )
end

local VecNormalize = VecNormalize
function vector_meta:Normalized()
	return MakeVector( VecNormalize( self ) )
end

function vector_meta:Normalize()
	return vector_meta.Div( self, vector_meta.Length( self ) )
end

function vector_meta:DistSquare( o )
	return (self[1] - o[1]) ^ 2 + (self[2] - o[2]) ^ 2 + (self[3] - o[3]) ^ 2
end

function vector_meta:Distance( o )
	return math.sqrt( vector_meta.DistSquare( self, o ) )
end

function vector_meta:LookAt( o )
	return MakeQuaternion( QuatLookAt( self, o ) )
end
