local armature_meta = global_metatable( "armature" )

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

function Armature( definition )
	local ids = {}
	for i, name in ipairs( definition.shapes ) do
		ids[name] = #definition.shapes - i + 1
	end
	local armature = {
		root = definition.bones,
		refs = {},
		scale = definition.scale,
		__noquickload = function()
		end,
		dirty = true,
	}
	local function dobone( b )
		if b.name then
			armature.refs[b.name] = b
		end
		b.transform = b.transform or Transform()
		b.shape_offsets = {}
		b.dirty = true
		if b.shapes then
			for name, transform in pairs( b.shapes ) do
				table.insert( b.shape_offsets,
				              { id = ids[name], tr = Transform( VecScale( transform.pos, definition.scale or 1 ), transform.rot ) } )
			end
		end
		b.children = {}
		for i = 1, #b do
			b.children[i] = dobone( b[i] )
		end
		return b
	end
	dobone( armature.root )
	return setmetatable( armature, armature_meta )
end

local function computebone( bone, transform, scale, dirty )
	dirty = dirty or bone.dirty or bone.jiggle_transform
	if dirty or not bone.gr_transform then
		bone.gr_transform = TransformToParentTransform( transform, bone.transform )
		if bone.jiggle_transform then
			bone.gr_transform = TransformToParentTransform( bone.gr_transform, bone.jiggle_transform )
		end
		bone.g_transform = Transform( VecScale( bone.gr_transform.pos, scale ), bone.gr_transform.rot )
		bone.dirty = false
	end
	for i = 1, #bone.children do
		computebone( bone.children[i], bone.gr_transform, scale, dirty )
	end
end

function armature_meta:ComputeBones()
	computebone( self.root, Transform(), self.scale or 1 )
	self.dirty = false
end

local function applybone( shapes, bone )
	for i = 1, #bone.shape_offsets do
		local offset = bone.shape_offsets[i]
		SetShapeLocalTransform( GetEntityHandle( shapes[offset.id] ),
		                        TransformToParentTransform( bone.g_transform, offset.tr ) )
	end
	for i = 1, #bone.children do
		applybone( shapes, bone.children[i] )
	end
end

function armature_meta:Apply( shapes )
	if self.dirty or self.jiggle then
		self:ComputeBones()
	end
	applybone( shapes, self.root )
end

function armature_meta:SetBoneTransform( bone, transform )
	local b = self.refs[bone]
	if not b then
		return
	end
	self.dirty = true
	b.dirty = true
	b.transform = transform
end

function armature_meta:GetBoneTransform( bone )
	local b = self.refs[bone]
	if not b then
		return Transform()
	end
	return b.transform
end

function armature_meta:GetBoneGlobalTransform( bone )
	local b = self.refs[bone]
	if not b then
		return Transform()
	end
	if self.dirty then
		self:ComputeBones()
	end
	return b.g_transform
end

function armature_meta:SetBoneJiggle( bone, jiggle, constraint )
	local b = self.refs[bone]
	if not b then
		return
	end
	self.dirty = true
	if jiggle > 0 then
		self.jiggle = true
	end
	b.jiggle = math.atan( jiggle ) / math.pi * 2
	b.jiggle_constraint = constraint
end

function armature_meta:GetBoneJiggle( bone )
	local b = self.refs[bone]
	if not b then
		return 0
	end
	return b.jiggle, b.jiggle_constraint
end

function armature_meta:ResetJiggle()
	for _, b in pairs( self.refs ) do
		b.jiggle_transform = nil
	end
	self.dirty = true
end

local function updatebone( bone, current_transform, prev_transform, dt, gravity )
	local current_transform_local = TransformToParentTransform( current_transform, bone.transform )
	local prev_transform_local = TransformToParentTransform( prev_transform, bone.old_transform or bone.transform )
	bone.old_transform = bone.transform
	if bone.jiggle then
		prev_transform_local = TransformToParentTransform( prev_transform_local, bone.jiggle_transform or Transform() )

		local local_diff = TransformToLocalTransform( current_transform_local, prev_transform_local )
		local target = TransformToParentPoint( local_diff, Vec( 0, 0, -2 / dt ) )

		if bone.jiggle_constraint and bone.jiggle_constraint.gravity then
			target = VecAdd( target,
			                 TransformToLocalVec( current_transform_local, VecScale( gravity, bone.jiggle_constraint.gravity ) ) )
		end

		local lookat = QuatLookAt( Vec(), target )

		bone.jiggle_transform = Transform( Vec(), QuatSlerp( lookat, QuatEuler( 0, 0, 0 ), 1 - bone.jiggle ) )
		current_transform_local = TransformToParentTransform( current_transform_local, bone.jiggle_transform )
	end
	for i = 1, #bone.children do
		updatebone( bone.children[i], current_transform_local, prev_transform_local, dt, gravity )
	end
end

function armature_meta:UpdatePhysics( diff, dt, gravity )
	dt = dt or 0.01666
	diff.pos = VecScale( diff.pos, 1 / dt )
	updatebone( self.root, Transform(), diff, dt, gravity or Vec( 0, -10, 0 ) )
end

local function DebugAxis( tr, s )
	s = s or 1
	DebugLine( tr.pos, TransformToParentPoint( tr, Vec( 1 * s, 0, 0 ) ), 1, 0, 0 )
	DebugLine( tr.pos, TransformToParentPoint( tr, Vec( 0, 1 * s, 0 ) ), 0, 1, 0 )
	DebugLine( tr.pos, TransformToParentPoint( tr, Vec( 0, 0, 1 * s ) ), 0, 0, 1 )
end

function armature_meta:DrawDebug( transform )
	transform = transform or Transform()
	DebugAxis( transform, 0.05 )
	for k, v in pairs( self.refs ) do
		local r = TransformToParentTransform( transform, v.g_transform )
		local g = v.name:find( "^__FIXED_" ) and 1 or 0
		for i = 1, #v.children do
			DebugLine( r.pos, TransformToParentTransform( transform, v.children[i].g_transform ).pos, 1, 1 - g, g, .4 )
		end
		for i = 1, #v.shape_offsets do
			local offset = v.shape_offsets[i]
			local p = TransformToParentTransform( transform, TransformToParentTransform( v.g_transform, offset.tr ) )
			DebugAxis( p, 0.03 )
			DebugLine( r.pos, p.pos, 0, 1, 1, .4 )
		end
	end
end

function LoadArmatureFromXML( xml, parts, scale ) -- Example below
	scale = scale or 1
	local dt = ParseXML( xml )
	assert( dt.type == "prefab" and dt.children[1] and dt.children[1].type == "group" )
	local shapes = {}
	local offsets = {}
	for i = 1, #parts do
		shapes[i] = parts[i][1]
		local v = parts[i][2]
		-- Compensate for the editor placing vox parts relative to the center of the base
		offsets[parts[i][1]] = Vec( math.floor( v[1] / 2 ) / 10, 0, -math.floor( v[2] / 2 ) / 10 )
	end

	local function parseVec( str )
		if not str then
			return Vec( 0, 0, 0 )
		end
		local x, y, z = str:match( "([%d.-]+) ([%d.-]+) ([%d.-]+)" )
		return Vec( tonumber( x ), tonumber( y ), tonumber( z ) )
	end

	local function parseTransform( attr )
		local pos, angv = parseVec( attr.pos ), parseVec( attr.rot )
		return Transform( Vec( pos[1], pos[2], pos[3] ), QuatEuler( angv[1], angv[2], angv[3] ) )
	end

	local function translatebone( node, isLocation )
		local t = { name = node.attributes.name, transform = parseTransform( node.attributes ) }
		local sub = t
		if not isLocation then
			t.name = "__FIXED_" .. node.attributes.name
			t[1] = { name = node.attributes.name }
			sub = t[1]
		end
		sub.shapes = {}
		for i = 1, #node.children do
			local child = node.children[i]
			if child.type == "vox" then
				local name = child.attributes.object
				local tr = parseTransform( child.attributes )
				local s = child.attributes.scale and tonumber( child.attributes.scale ) or 1
				tr.pos = VecSub( tr.pos, VecScale( offsets[name], s ) )
				tr.rot = QuatRotateQuat( tr.rot, QuatEuler( -90, 0, 0 ) )
				sub.shapes[name] = tr
			elseif child.type == "group" then
				sub[#sub + 1] = translatebone( child )
			elseif child.type == "location" then
				sub[#sub + 1] = translatebone( child, true )
			end
		end
		return t
	end
	local bones = translatebone( dt.children[1] )[1]
	bones.transform = Transform( Vec(), QuatEuler( 0, 0, 0 ) )
	bones.name = "root"

	local arm = Armature { shapes = shapes, scale = scale, bones = bones }
	arm:ComputeBones()
	return arm, dt
end
--[=[
--[[---------------------------------------------------
    LoadArmatureFromXML is capable of taking the XML of a prefab and turning it into a useable armature object for tools and such.
    Two things are required: the XML of the prefab itself, and a list of all the objects inside the vox for position correction.
    The list of objects should be as it appears in MagicaVoxel, with every slot corresponding to an object in the vox file.
    One notable limitation is that there can only be one vox file used and that all the objects inside it can only be used once.
--]]---------------------------------------------------

-- Loading the armature from the prefab and the objects list
local armature = LoadArmatureFromXML([[
<prefab version="0.7.0">
    <group id_="1196432640" open_="true" name="instance=MOD/physgun.xml" pos="-3.4 0.7 0.0" rot="0.0 0.0 0.0">
        <vox id_="1866644736" pos="-0.125 -0.125 0.125" file="MOD/physgun.vox" object="body" scale="0.5"/>
        <group id_="279659168" open_="true" name="core0" pos="0.0 0.0 -0.075" rot="0.0 0.0 0.0">
            <vox id_="496006720" pos="-0.025 -0.125 0.0" rot="0.0 0.0 0.0" file="MOD/physgun.vox" object="core_0" scale="0.5"/>
        </group>
        <group id_="961930560" open_="true" name="core1" pos="0.0 0.0 -0.175" rot="0.0 0.0 0.0">
            <vox id_="1109395584" pos="-0.025 -0.125 0.0" rot="0.0 0.0 0.0" file="MOD/physgun.vox" object="core_1" scale="0.5"/>
        </group>
        <group id_="806535232" open_="true" name="core2" pos="0.0 0.0 -0.275" rot="0.0 0.0 0.0">
            <vox id_="378362432" pos="-0.025 -0.125 0.0" rot="0.0 0.0 0.0" file="MOD/physgun.vox" object="core_2" scale="0.5"/>
        </group>
        <group id_="1255943040" open_="true" name="arms_rot" pos="0.0 0.0 -0.375" rot="0.0 0.0 0.0">
            <group id_="439970016" open_="true" name="arm0_base" pos="0.0 0.1 0.0" rot="0.0 0.0 0.0">
                <vox id_="1925106432" pos="-0.025 0.0 0.025" file="MOD/physgun.vox" object="arm_00" scale="0.5"/>
                <group id_="2122316288" open_="true" name="arm0_tip" pos="0.0 0.2 -0.0" rot="0.0 0.0 0.0">
                    <vox id_="572557440" pos="-0.025 0.0 0.025" file="MOD/physgun.vox" object="arm_01" scale="0.5"/>
                </group>
            </group>
            <group id_="516324128" open_="true" name="arm1_base" pos="0.087 -0.05 0.0" rot="180.0 180.0 -60.0">
                <vox id_="28575440" pos="-0.025 0.0 0.025" file="MOD/physgun.vox" object="arm_10" scale="0.5"/>
                <group id_="962454912" open_="true" name="arm1_tip" pos="0.0 0.2 0.0" rot="0.0 0.0 0.0">
                    <vox id_="1966724352" pos="-0.025 0.0 0.025" file="MOD/physgun.vox" object="arm_11" scale="0.5"/>
                </group>
            </group>
            <group id_="634361664" open_="true" name="arm2_base" pos="-0.087 -0.05 0.0" rot="180.0 180.0 60.0">
                <vox id_="1049360960" pos="-0.025 0.0 0.025" file="MOD/physgun.vox" object="arm_20" scale="0.5"/>
                <group id_="1428116608" open_="true" name="arm2_tip" pos="0.0 0.2 0.0" rot="0.0 0.0 0.0">
                    <vox id_="1388661504" pos="-0.025 0.0 0.025" file="MOD/physgun.vox" object="arm_21" scale="0.5"/>
                </group>
            </group>
        </group>
        <group id_="1569551872" open_="true" name="nozzle" pos="0.0 0.0 -0.475">
            <vox id_="506099872" pos="-0.025 -0.125 0.1" file="MOD/physgun.vox" object="cannon" scale="0.5"/>
        </group>
    </group>
</prefab>
]], {
    -- The list of objects as it appears in MagicaVoxel. Each entry has the name of the object followed by the size as seen in MagicaVoxel.
    -- Please note that the order MUST be the same as in MagicaVoxel and that there can be no gaps.
    {"cannon", Vec(5, 3, 5)},
    {"core_2", Vec(5, 2, 5)},
    {"core_1", Vec(5, 2, 5)},
    {"core_0", Vec(5, 2, 5)},
    {"arm_21", Vec(1, 1, 2)},
    {"arm_11", Vec(1, 1, 2)},
    {"arm_01", Vec(1, 1, 2)},
    {"arm_20", Vec(1, 1, 4)},
    {"arm_10", Vec(1, 1, 4)},
    {"arm_00", Vec(1, 1, 4)},
    {"body", Vec(9, 6, 5)}
})
-----------------------------------------------------

-- Every frame you can animate the armature by setting the local transform of bones and then applying the changes to the shapes of the object.
armature:SetBoneTransform("core0", Transform(Vec(), QuatEuler(0, 0, GetTime()*73)))
armature:SetBoneTransform("core1", Transform(Vec(), QuatEuler(0, 0, -GetTime()*45)))
armature:SetBoneTransform("core2", Transform(Vec(), QuatEuler(0, 0, GetTime()*83)))
armature:SetBoneTransform("arms_rot", Transform(Vec(), QuatEuler(0, 0, GetTime()*20)))
local tr = Transform(Vec(0,0,0), QuatEuler(-40 + 5 * math.sin(GetTime()), 0, 0))
armature:SetBoneTransform("arm0_base", tr)
armature:SetBoneTransform("arm0_tip", tr)
armature:SetBoneTransform("arm1_base", tr)
armature:SetBoneTransform("arm1_tip", tr)
armature:SetBoneTransform("arm2_base", tr)
armature:SetBoneTransform("arm2_tip", tr)
-- shapes is the list of all the shapes of the vox, it can be obtained with GetBodyShapes()
armature:Apply(shapes)

--]=]
