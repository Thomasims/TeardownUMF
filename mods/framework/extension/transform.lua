
local transform_meta = {}
transform_meta.__index = transform_meta -- I hate doing this but it's useful sometimes

function TransformationMeta()
    return transform_meta
end

function IsTransformation(v)
    return type(v) == "table" and v.pos and v.rot
end

function MakeTransformation(t)
    setmetatable(t.pos, VectorMeta())
    setmetatable(t.rot, QuaternionMeta())
    return setmetatable(t, transform_meta)
end

function Transformation(pos, rot)
    return MakeTransformation { pos = pos, rot = rot }
end

transform_meta.__type = "transformation"

util.register_unserializer(transform_meta.__type, function(data)
    local x, y, z, i, j, k, r = data:match("([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*);([-0-9.]*)")
    return Transformation({tonumber(x), tonumber(y), tonumber(z)}, {tonumber(i), tonumber(j), tonumber(k), tonumber(r)})
end)

function transform_meta:__serialize()
    return table.concat(self.pos, ";") .. ";" .. table.concat(self.rot, ";")
end

function transform_meta:Clone()
    return MakeTransformation {pos = VectorMeta().Clone(self.pos), rot = QuaternionMeta().Clone(self.rot)}
end

local TransformStr = TransformStr
function transform_meta:__tostring()
    return TransformStr(self)
end

local TransformToLocalPoint = TransformToLocalPoint
local TransformToLocalTransform = TransformToLocalTransform
local TransformToLocalVec = TransformToLocalVec
local TransformToParentPoint = TransformToParentPoint
local TransformToParentTransform = TransformToParentTransform
local TransformToParentVec = TransformToParentVec

function transform_meta.__add(a, b)
    if not IsTransformation(b) then
        if IsVector(b) then
            b = Transformation(b, QUAT_ZERO)
        elseif IsQuaternion(b) then
            b = Transformation(VEC_ZERO, b)
        end
    end
    return MakeTransformation(TransformToParentTransform(a, b))
end

function transform_meta:ToLocal(o)
    if IsTransformation(o) then
        return MakeTransformation(TransformToLocalTransform(self, o))
    else
        return MakeVector(TransformToLocalPoint(self, o))
    end
end

function transform_meta:ToLocalDir(o)
    return MakeVector(TransformToLocalVec(self, o))
end

function transform_meta:ToGlobal(o)
    if IsTransformation(o) then
        return MakeTransformation(TransformToParentTransform(self, o))
    else
        return MakeVector(TransformToParentPoint(self, o))
    end
end

function transform_meta:ToGlobalDir(o)
    return MakeVector(TransformToParentVec(self, o))
end

function transform_meta:Raycast(dist)
    local dir = TransformToParentVec(self, VEC_FORWARD)
    local hit, dist = Raycast(self.pos, dir, dist)
    local vector_meta = VectorMeta()
    return {
        hit = hit,
        dist = dist,
        hitpos = hit and vector_meta.__add(self.pos, vector_meta.Mul(dir, dist))
    }
end