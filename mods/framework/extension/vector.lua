
local vector_meta = {}
vector_meta.__index = vector_meta -- I hate doing this but it's useful sometimes

function IsVector(v)
    return type(v) == "table" and type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number"
end

function MakeVector(v)
    return setmetatable(v, vector_meta)
end

function Vector(x, y, z)
    if IsVector(x) then x, y, z = x[1], x[2], x[3]end
    return MakeVector {x, y, z}
end

function vector_meta:Clone()
    return MakeVector {self[1], self[2], self[3]}
end

local VecStr = VecStr
function vector_meta:__tostring()
    return VecStr(self)
end

function vector_meta:__unm()
    return {-self[1], -self[2], -self[3]}
end

function vector_meta:Add(o)
    if IsVector(o) then
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

function vector_meta.__add(a, b)
    if not IsVector(a) then a, b = b, a end
    return vector_meta.Add(vector_meta.Clone(a), b)
end

function vector_meta:Sub(o)
    if IsVector(o) then
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

function vector_meta.__sub(a, b)
    if not IsVector(a) then a, b = b, a end
    return vector_meta.Sub(vector_meta.Clone(a), b)
end

function vector_meta:Mul(o)
    if IsVector(o) then
        self[1] = self[1] * o[1]
        self[2] = self[2] * o[2]
        self[3] = self[3] * o[3]
    else
        self[1] = self[1] * o
        self[2] = self[2] * o
        self[3] = self[3] * o
    end
    return self
end

function vector_meta.__mul(a, b)
    if not IsVector(a) then a, b = b, a end
    return vector_meta.Mul(vector_meta.Clone(a), b)
end

function vector_meta:Div(o)
    self[1] = self[1] / o
    self[2] = self[2] / o
    self[3] = self[3] / o
    return self
end

function vector_meta.__div(a, b)
    return vector_meta.Div(vector_meta.Clone(a), b)
end

function vector_meta:Mod(o)
    self[1] = self[1] % o
    self[2] = self[2] % o
    self[3] = self[3] % o
    return self
end

function vector_meta.__mod(a, b)
    return vector_meta.Mod(vector_meta.Clone(a), b)
end

function vector_meta:Pow(o)
    self[1] = self[1] ^ o
    self[2] = self[2] ^ o
    self[3] = self[3] ^ o
    return self
end

function vector_meta.__pow(a, b)
    return vector_meta.Pow(vector_meta.Clone(a), b)
end

function vector_meta.__eq(a, b)
    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

function vector_meta.__lt(a, b)
    return a[1] < b[1] or (a[1] == b[1] and (
           a[2] < b[2] or (a[2] == b[2] and (
           a[3] < b[3] ))))
end

function vector_meta.__le(a, b)
    return a[1] < b[1] or (a[1] == b[1] and (
           a[2] < b[2] or (a[2] == b[2] and (
           a[3] <= b[3] ))))
end

local VecDot = VecDot
function vector_meta:Dot(b)
    return MakeVector(VecDot(self, b))
end

local VecCross = VecCross
function vector_meta:Cross(b)
    return MakeVector(VecCross(self, b))
end

local VecLength = VecLength
function vector_meta:Length()
    return VecLength(self)
end

local VecLerp = VecLerp
function vector_meta:Lerp(o, n)
    return MakeVector(VecLerp(self, o, n))
end

local VecNormalize = VecNormalize
function vector_meta:Normalized()
    return MakeVector(VecNormalize(self))
end

function vector_meta:Normalize()
    return vector_meta.Div(self, vector_meta.Length(self))
end

function vector_meta:DistSquare(o)
    return (self[1] - o[1]) ^ 2
         + (self[2] - o[2]) ^ 2
         + (self[3] - o[3]) ^ 2
end

function vector_meta:Distance(o)
    return math.sqrt(vector_meta.DistSquare(self, o))
end

function vector_meta:LookAt(o)
    return QuatLookAt(self, o)
end