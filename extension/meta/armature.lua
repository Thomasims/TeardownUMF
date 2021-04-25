
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
    local armature = {root = definition.bones, refs = {}, scale = definition.scale, __noquickload = function() end, dirty = true}
    local function dobone(b)
        if b.name then armature.refs[b.name] = b end
        b.transform = b.transform or Transform()
        b.shape_offsets = {}
        if b.shapes then
            for name, transform in pairs(b.shapes) do
                table.insert(b.shape_offsets, {
                    id = ids[name],
                    tr = Transform(VecScale(transform.pos, definition.scale or 1), transform.rot)
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

local function computebone(bone, transform, scale)
    local newtr = TransformToParentTransform(transform, bone.transform)
    bone.g_transform = Transform(VecScale(newtr.pos, scale), newtr.rot)
    for i = 1, #bone.children do
        computebone(bone.children[i], newtr, scale)
    end
end

function armature_meta:ComputeBones()
    computebone(self.root, Transform(), self.scale or 1)
    self.dirty = false
end

local function applybone(shapes, bone)
    for i = 1, #bone.shape_offsets do
        local offset = bone.shape_offsets[i]
        SetShapeLocalTransform(
            GetEntityHandle(shapes[offset.id]),
            TransformToParentTransform(bone.g_transform, offset.tr)
        )
    end
    for i = 1, #bone.children do
        applybone(shapes, bone.children[i])
    end
end

function armature_meta:Apply(shapes)
    if self.dirty then
        self:ComputeBones()
    end
    applybone(shapes, self.root)
end

function armature_meta:SetBoneTransform(bone, transform)
    local b = self.refs[bone]
    if not b then return end
    self.dirty = true
    b.transform = transform
end

function armature_meta:GetBoneTransform(bone)
    local b = self.refs[bone]
    if not b then return Transform() end
    return b.transform
end

function armature_meta:GetBoneGlobalTransform(bone)
    local b = self.refs[bone]
    if not b then return Transform() end
    if self.dirty then self:ComputeBones() end
    return b.g_transform
end

local function DebugAxis(tr, s)
    s = s or 1
    DebugLine(tr.pos, TransformToParentPoint(tr, Vec(1*s,0,0)), 1, 0, 0)
    DebugLine(tr.pos, TransformToParentPoint(tr, Vec(0,1*s,0)), 0, 1, 0)
    DebugLine(tr.pos, TransformToParentPoint(tr, Vec(0,0,1*s)), 0, 0, 1)
end

function armature_meta:DrawDebug(transform)
    transform = transform or Transform()
    DebugAxis(transform, 0.05)
    for k, v in pairs(self.refs) do
        local r = TransformToParentTransform(transform, v.g_transform)
        local g = v.name:find("^__FIXED_") and 1 or 0
        for i = 1, #v.children do
            DebugLine(r.pos, TransformToParentTransform(transform, v.children[i].g_transform).pos, 1, 1 - g, g, .4)
        end
        for i = 1, #v.shape_offsets do
            local offset = v.shape_offsets[i]
            local p = TransformToParentTransform(transform, TransformToParentTransform(v.g_transform, offset.tr))
            DebugAxis(p, 0.03)
            DebugLine(r.pos, p.pos, 0, 1, 1, .4)
        end
    end
end

function LoadArmatureFromXML(xml, parts, scale)
	scale = scale or 1
	local dt = ParseXML(xml)
	assert(dt.type == "prefab" and dt.children[1] and dt.children[1].type == "group")
	local shapes = {}
	local offsets = {}
	for i = 1, #parts do
		shapes[i] = parts[i][1]
		local v = parts[i][2]
		-- Compensate for the editor placing vox parts relative to the center of the base
		offsets[parts[i][1]] = Vec(math.floor(v[1]/2)/10, 0, -math.floor(v[2]/2)/10)
	end

	local function parseVec(str)
		if not str then return Vec(0,0,0) end
		local x, y, z = str:match("([%d.-]+) ([%d.-]+) ([%d.-]+)")
		return Vec(tonumber(x), tonumber(y), tonumber(z))
	end

	local function parseTransform(attr)
		local pos, angv = parseVec(attr.pos), parseVec(attr.rot)
		return Transform(Vec(pos[1], pos[2], pos[3]), QuatEuler(angv[1], angv[2], angv[3]))
	end

	local function translatebone(node, isLocation)
		local t = {
			name = node.attributes.name,
			transform = parseTransform(node.attributes),
		}
		local sub = t
		if not isLocation then
			t.name = "__FIXED_" .. node.attributes.name
			t[1] = {
				name = node.attributes.name
			}
			sub = t[1]
		end
		sub.shapes = {}
		for i = 1, #node.children do
			local child = node.children[i]
			if child.type == "vox" then
				local name = child.attributes.object
				local tr = parseTransform(child.attributes)
				local s = child.attributes.scale and tonumber(child.attributes.scale) or 1
				tr.pos = VecSub(tr.pos, VecScale(offsets[name], s))
				tr.rot = QuatRotateQuat(tr.rot, QuatEuler(-90,0,0))
				sub.shapes[name] = tr
			elseif child.type == "group" then
				sub[#sub + 1] = translatebone(child)
			elseif child.type == "location" then
				sub[#sub + 1] = translatebone(child, true)
			end
		end
		return t
	end
	local bones = translatebone(dt.children[1])[1]
	bones.transform = Transform(Vec(), QuatEuler(0, 0, 0))
	bones.name = "root"

	local arm = Armature {
		shapes = shapes,
		scale = scale,
		bones = bones,
	}
	arm:ComputeBones()
	return arm
end