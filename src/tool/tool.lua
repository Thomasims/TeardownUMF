----------------
-- Tool Framework
-- @script tool.tool
UMF_REQUIRE "core"
UMF_REQUIRE "vector"
UMF_REQUIRE "entities"
UMF_REQUIRE "animation/armature.lua"

---@type table<string, Tool2>
local UMF_tools = {}
local post_init = false
local previous
local current_hook
local current_hook_updated
local transform_info = {}

-- #region Armature

local function offset_shape( editor_transform, scale, x, y )
	local vec = VecScale( Vec( -math.floor( x / 2 ), 0, math.floor( y / 2 ) ), scale / 10 )
	return TransformToParentTransform( editor_transform, Transform( vec, QuatEuler( -90, 0, 0 ) ) )
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

local id_counter = 0
local function translatebone( node, isLocation, modelinfo )
	modelinfo = modelinfo or { vox = {} }
	local t = { name = node.attributes.name, transform = parseTransform( node.attributes ) }
	local sub = t
	if not isLocation then
		t.name = "__FIXED_" .. (node.attributes.name or "UNKNOWN")
		t[1] = { name = node.attributes.name }
		sub = t[1]
	end
	sub.shapes = {}
	for i = 1, #node.children do
		local child = node.children[i]
		if child.type == "vox" then
			id_counter = id_counter + 1
			child.attributes.tags = (child.attributes.tags or "") .. " __UMF_TOOL_SHAPE_ID=" .. id_counter
			child.id = id_counter
			table.insert( sub.shapes, {
				id = id_counter,
				attributes = child.attributes,
				transform = Transform(),
				editor_transform = parseTransform( child.attributes ),
				scale = child.attributes.scale and tonumber( child.attributes.scale ) or 1,
			} )
			table.insert( modelinfo.vox, child )
		elseif child.type == "voxbox" then
			id_counter = id_counter + 1
			child.attributes.tags = (child.attributes.tags or "") .. " __UMF_TOOL_SHAPE_ID=" .. id_counter
			table.insert( sub.shapes, {
				id = id_counter,
				attributes = child.attributes,
				transform = parseTransform( child.attributes ),
				scale = child.attributes.scale and tonumber( child.attributes.scale ) or 1,
			} )
			child.id = id_counter
		elseif child.type == "group" then
			sub[#sub + 1] = translatebone( child, false, modelinfo )
		elseif child.type == "location" then
			sub[#sub + 1] = translatebone( child, true, modelinfo )
		end
	end
	return t, modelinfo
end

local function load_xml( xml )
	local dt = ParseXML( xml )
	local root = dt.type == "prefab" and dt.children[1] or dt
	assert( root and root.type == "group", "Invalid Tool XML" )
	local root_bone, modelinfo = translatebone( root )
	root_bone.name = "root"

	local missingvox = {}
	for i = 1, #modelinfo.vox do
		missingvox[modelinfo.vox[i].id] = modelinfo.vox[i]
	end
	local spawned = Spawn( root:Render(), Transform( Vec( 10000, 10000, 10000 ) ), true, false )
	local shapes = {}
	for i = 1, #spawned do
		if GetEntityType( spawned[i] ) == "shape" then
			local id = tonumber( GetTagValue( spawned[i], "__UMF_TOOL_SHAPE_ID" ) )
			shapes[id] = spawned[i]
			missingvox[id] = nil
		end
	end
	if next( missingvox ) then
		local missingfiles = {}
		for _, vox in pairs( missingvox ) do
			missingfiles[vox.file or ""] = true
		end
		for name in pairs( missingfiles ) do
			DebugPrint( string.format( "[UMF] Unknown tool model \"%s\", are you sure the XML is valid?", name ) )
		end
	end

	local armature = Armature { shapes = {}, bones = root_bone }
	armature:ComputeBones()
	armature.body = spawned[1]
	armature.shapes = shapes

	local shapes_data = armature:GetShapeTransforms()
	for i = 1, #shapes_data do
		local data = shapes_data[i]
		---@diagnostic disable-next-line: undefined-field
		if data.editor_transform then
			local shape = armature.shapes[data.id]
			data.transform = offset_shape( data.editor_transform, data.scale, GetShapeSize( shape ) )
		end
	end

	return armature, root
end

local function attach_armature( armature, tool_body )
	if not armature then
		return
	end
	local tool_shapes = GetBodyShapes( tool_body )
	for i = 1, #tool_shapes do
		Delete( tool_shapes[i] )
	end
	armature.active_shapes = {}
	local last
	for key, shape in pairs( armature.shapes ) do
		local _, _, _, s = GetShapeSize( shape )
		local xml = string.format( "<vox file=\"tool/wire.vox\" scale=\"%f\" collide=\"false\"/>", s * 10 )
		local dst = Spawn( xml, Transform(), true, false )[1]
		if HasTag(shape, "collider") then
			last = dst
		else
			SetShapeBody( dst, tool_body )
		end
		CopyShapeContent( shape, dst )
		CopyShapePalette( shape, dst )
		for _, tag in ipairs( ListTags( shape ) ) do
			SetTag( dst, tag, GetTagValue( shape, tag ) )
		end
		armature.active_shapes[key] = dst
	end
	if last then
		SetShapeBody( last, tool_body )
	end
end

local function apply_armature( armature )
	if not armature then
		return
	end
	local shapes_data = armature:GetShapeTransforms()
	for i = 1, #shapes_data do
		SetShapeLocalTransform( armature.active_shapes[shapes_data[i].id], shapes_data[i].global_transform )
	end
end

-- #endregion Armature

-- #region Metatable

---@class Tool2
---@field armature Armature|nil
---@field _C table
---@field model string
---@field printname string
---@field id string
---@field noregister boolean|nil
---@field group number|nil
local tool_meta
tool_meta = global_metatable( "tool", nil, true )

function tool_meta._C:ammo( setter, val )
	local key = "game.tool." .. self.id .. ".ammo"
	local keystr = key .. ".display"
	if setter then
		if type( val ) == "number" then
			SetFloat( key, val )
			ClearKey( keystr )
		else
			SetFloat( key, 0 )
			SetString( key .. ".display", tostring( val or "" ) )
		end
	elseif HasKey( keystr ) then
		return GetString( keystr )
	else
		return GetFloat( key )
	end
end

function tool_meta._C:enabled( setter, val )
	local key = "game.tool." .. self.id .. ".enabled"
	if setter then
		SetBool( key, val )
	else
		return GetBool( key )
	end
end

--- Draws the tool in the world instead of the player view.
---
---@param self Tool2
---@param transform transform
function tool_meta:DrawInWorld( transform )
	SetToolTransform( TransformToLocalTransform( GetPlayerCameraTransform(), transform ) )
end

local function scale_transform( tr, s )
	return Transform( VecLerp( Vec(), tr.pos, s ), QuatSlerp( Quat( 0, 0, 0, 1 ), tr.rot, s ) )
end

local function get_transform_info( key )
	local t = transform_info[current_hook]
	if not t then
		t = {}
		transform_info[current_hook] = t
	end
	if not current_hook_updated then
		local current = GetBodyTransform( GetToolBody() )
		t.old = t.current or current
		t.olddt = t.currentdt or 1
		t.current = current
		t.currentdt = GetTimeStep()
		t.diff = TransformToLocalTransform( t.current, t.old )
		local rdiff = scale_transform( TransformToLocalTransform( t.old, t.current ), t.currentdt / t.olddt )
		t.fix = TransformToParentTransform( t.current, rdiff )
		current_hook_updated = true
	end
	return key and t[key] or t
end

--- Gets the transform of the tool.
---
---@param self Tool2
---@return Transformation
function tool_meta:GetTransform( predicted )
	return MakeTransformation( get_transform_info( predicted and "fix" or "current" ) )
end

--- Gets the transform delta of the tool.
---
---@return Transformation
function tool_meta:GetTransformDelta()
	return MakeTransformation( get_transform_info( "diff" ) )
end

--- Gets the transform of a bone on the tool in world-space.
---
---@param self Tool2
---@param bone string
---@return Transformation
function tool_meta:GetBoneGlobalTransform( bone, nopredicted )
	if not self.armature then
		return Transformation( Vec(), Quat() )
	end
	return self:GetTransform( not nopredicted ):ToGlobal( self.armature:GetBoneGlobalTransform( bone ) )
end

--- Draws the debug armature of the tool.
---
---@param self Tool2
---@param nobones? boolean Don't draw bones.
---@param nobounds? boolean Don't draw bounds.
function tool_meta:DrawDebug( nobones, nobounds, nopredicted )
	if not self.armature then
		return
	end
	local ptr = self:GetTransform( not nopredicted )
	if not nobones then
		self.armature:DrawDebug( ptr )
	end
	if not nobounds then
		local shapes_data = self.armature:GetShapeTransforms()
		for i = 1, #shapes_data do
			local data = shapes_data[i]
			local shape = self.armature.shapes[data.id]
			visual.drawbox( ptr:ToGlobal( data.global_transform ), Vec( 0, 0, 0 ),
			                VecScale( Vec( GetShapeSize( shape ) ), data.scale / 10 ),
			                { r = 1, g = 1, b = 1, a = .2, writeZ = false } )
		end
	end
end

--- Registers the tool.
---
---@param self Tool2
function tool_meta:Register()
	local enabledKey = "game.tool." .. self.id .. ".enabled"
	if not self.noregister and not GetBool( enabledKey ) then -- TODO: find a better way to determine if a tool is already registered
		RegisterTool( self.id, self.printname or self.id, self.model or "", self.group or 6 )
		if not HasKey( enabledKey ) then
			SetBool( enabledKey, true )
		end
	end
end

--- Emit an event to the tool
---
---@param self Tool2
---@param event string
---@param ... any
function tool_meta:Emit( event, ... )
	if event then
		local handler = rawget( self, event )
		if handler then
			return softassert( pcall( handler, self, ... ) )
		end
	end
	return true
end

-- #endregion Metatable

-- #region Hooks

local function previous_tool( force )
	return previous and (force or GetBool( "game.player.canusetool" )) and UMF_tools[previous]
end

local function active_tool( force )
	return (force or GetBool( "game.player.canusetool" )) and UMF_tools[GetString( "game.player.tool" )]
end

hook.add( "base.init", "api.tool_loader", function()
	for _, tool in pairs( UMF_tools ) do
		tool:Register()
	end
	post_init = true
end )

hook.add( "api.mouse.wheel", "api.tool_loader", function( ds )
	local tool = previous_tool()
	if tool then
		tool:Emit( "MouseWheel", ds )
	end
end )

hook.add( "base.update", "api.tool_loader", function( dt )
	current_hook = "update"
	current_hook_updated = false
	local tool = active_tool()
	if tool then
		if tool.armature then
			tool.armature:UpdatePhysics( tool:GetTransformDelta(), GetTimeStep(),
			                             TransformToLocalVec( tool:GetTransform(), Vec( 0, -10, 0 ) ) )
		end
		tool:Emit( "Update", dt )
	end
end )

hook.add( "base.tick", "api.tool_loader", function( dt )
	current_hook = "tick"
	current_hook_updated = false
	local cur = GetString( "game.player.tool" )

	local prevtool = previous_tool( true )
	if prevtool then
		local _, dolock = prevtool:Emit( "ShouldLockMouseWheel" )
		if dolock ~= nil then
			SetBool( "game.input.locktool", dolock )
			if previous ~= cur and dolock then
				SetString( "game.player.tool", previous )
				cur = previous
			end
		end
		if previous ~= cur then
			prevtool:Emit( "Holster" )
			prevtool._BODY = nil
			prevtool._SHAPES = nil
		end
	end

	local tool = UMF_tools[cur]
	if tool then
		local body = GetToolBody()
		if (GetPlayerVehicle() ~= 0 or GetBool( "game.map.enabled" )) and tool._BODY then
			tool:Emit( "Holster" )
			tool._BODY = nil
			tool._SHAPES = nil
			return
		end
		if body == 0 then
			return
		end
		if previous == cur and (not tool._BODY or tool._BODY.handle ~= body) then
			tool._BODY = Body( body )
			attach_armature( tool.armature, body )
			tool._SHAPES = tool._BODY:GetShapes()
			tool:Emit( "Deploy" )
			if tool.armature then
				tool.armature:ResetJiggle()
			end
		end
		if IsValid( tool._BODY ) then
			if previous == cur then
				tool:Emit( "Animate", tool._BODY, tool._SHAPES )
			end
			if tool.armature then
				apply_armature( tool.armature )
			end
		end
		if HasKey( "game.tool." .. tool.id .. ".ammo.display" ) then
			-- Fix sandbox ammo string
			SetInt( "game.tool." .. tool.id .. ".ammo", 0 )
		end
		tool:Emit( "Tick", dt )
	end
	previous = cur
end )

hook.add( "api.firsttick", "api.tool_loader", function()
	for _, tool in pairs( UMF_tools ) do
		tool:Emit( "Initialize" )
	end
end )

hook.add( "base.draw", "api.tool_loader", function( dt )
	current_hook = "draw"
	current_hook_updated = false
	local tool = active_tool()
	if tool then
		tool:Emit( "Draw", dt )
	end
end )

hook.add( "api.mouse.pressed", "api.tool_loader", function( button )
	local tool = active_tool()
	if tool then
		---@diagnostic disable-next-line: param-type-mismatch
		tool:Emit( button == "lmb" and "LeftClick" or button == "rmb" and "RightClick" )
		tool:Emit( "MousePressed", button )
	end
end )

hook.add( "api.mouse.released", "api.tool_loader", function( button )
	local tool = active_tool()
	if tool then
		---@diagnostic disable-next-line: param-type-mismatch
		tool:Emit( button == "lmb" and "LeftClickReleased" or button == "rmb" and "RightClickReleased" )
		tool:Emit( "MouseReleased", button )
	end
end )

-- #endregion Hooks

function RegisterToolUMF( id, tool, immediateRegister )
	tool.id = id
	UMF_tools[id] = tool

	local xml
	if type( tool.model ) == "string" then
		if tool.model:match( "^[\r\n\t ]*<" ) then
			xml = tool.model
			tool.model = "vox/tool/wire.vox"
		end
	elseif type( tool.model ) == "table" and tool.model.prefab then
		xml = tool.model.prefab
		tool.model = "vox/tool/wire.vox"
	end
	if xml then
		tool.armature = load_xml( xml )
	end

	if not tool.group and HasKey( "game.tool." .. id .. ".skin.group" ) then
		tool.group = GetInt( "game.tool." .. id .. ".skin.group" )
	end

	instantiate_global_metatable( "tool", tool )

	if post_init or immediateRegister then
		tool:Register()
	end

	if tool.armature then
		tool:Emit( "SetupModel", tool.armature.body, tool.armature.shapes )
	end

	return tool
end
