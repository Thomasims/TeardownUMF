
local armature_meta = global_metatable("armature")

--[[

Armature {
    shapes = {
        "core_2",
        "core_1",
        "core_0",
        "arm_21",
        "arm_11",
        "arm_01",
        "arm_20",
        "arm_10",
        "arm_00",
        "body"
    },

    bones = {
        name = "root",
        shapes = {
            body = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
        },
        {
            name = "core_0",
            shapes = {
                core_0 = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
            },
        },
        {
            name = "core_1",
            shapes = {
                core_1 = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
            },
        },
        {
            name = "core_2",
            shapes = {
                core_2 = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
            },
        },
        {
            name = "arm_00",
            shapes = {
                arm_00 = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
            },
            {
                name = "arm_01",
                shapes = {
                    arm_01 = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
                },
            },
        },
        {
            name = "arm_10",
            shapes = {
                arm_10 = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
            },
            {
                name = "arm_11",
                shapes = {
                    arm_11 = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
                },
            },
        },
        {
            name = "arm_20",
            shapes = {
                arm_20 = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
            },
            {
                name = "arm_21",
                shapes = {
                    arm_21 = Transformation(Vec(0,0,0), QuatEuler(0,0,0)),
                },
            },
        },
    }
}

]]

function Armature(definition)
    local ids = {}
    for i, name in ipairs(definition.shapes) do
        ids[name] = #definition.shapes - i + 1
    end
    local armature = {root = definition.bones, refs = {}, __noquickload = function() end}
    local function dobone(b)
        if b.name then armature.refs[b.name] = b end
        b.transform = Transform()
        b.shape_offsets = {}
        if b.shapes then
            for name, transform in pairs(b.shapes) do
                table.insert(b.shape_offsets, {
                    id = ids[name],
                    tr = transform
                })
            end
        end
        b.children = {}
        for i = 1, #b do
            b.children[i] = dobone(b[i])
        end
        return b
    end
    dobone(armature.root)
    return setmetatable(armature, armature_meta)
end

local function applybone(shapes, bone, transform)
    local newtr = TransformToParentTransform(transform, bone.transform)
    for i = 1, #bone.shape_offsets do
        local b = bone.shape_offsets[i]
        SetShapeLocalTransform(GetEntityHandle(shapes[b.id]), TransformToParentTransform(newtr, b.tr))
    end
    for i = 1, #bone.children do
        applybone(shapes, bone.children[i], newtr)
    end
end

function armature_meta:Apply(shapes)
    applybone(shapes, self.root, Transform())
end

function armature_meta:SetBoneTransform(bone, transform)
    local b = self.refs[bone]
    if not b then return end
    b.transform = transform
end

function armature_meta:GetBoneTransform(bone)
    local b = self.refs[bone]
    if not b then return Transform() end
    return b.transform
end