----------------
-- Tool Framework
-- @script tool.tool
UMF_REQUIRE "core"
UMF_REQUIRE "vector"
UMF_REQUIRE "entities"
UMF_REQUIRE "animation/armature.lua"

---@class Tool
---@field _TRANSFORM Transformation
---@field _TRANSFORM_FIX Transformation
---@field _TRANSFORM_DIFF Transformation
---@field _ARMATURE Armature
---@field _TOOLAMMOSTRING string
---@field armature Armature
---@field _SHAPES Shape[]
---@field _OBJECTS table[]
---@field _C table
---@field model string
---@field printname string
---@field id string
local tool_meta
tool_meta = global_metatable( "tool", nil, true )

local extra_tools = {}
local alreadyInit = false

--- Registers a tool using UMF.
---
---@param id string
---@param data table
---@return Tool
function RegisterToolUMF( id, data, force )
	if LoadArmatureFromXML and type( data.model ) == "table" then
		local arm, xml = LoadArmatureFromXML( data.model.prefab, data.model.objects, data.model.scale )
		data.armature = arm
		data._ARMATURE = arm
		data._OBJECTS = data.model.objects
		local function findvox( xml )
			if xml.type == "vox" then
				return xml.attributes["file"]
			end
			for i, c in ipairs( xml.children ) do
				local t = findvox( c )
				if t then
					return t
				end
			end
		end
		data.model = data.model.path or findvox( xml )
	end
	instantiate_global_metatable( "tool", data )
	data.id = id
	extra_tools[id] = data
	if not data.group and HasKey( "game.tool." .. id .. ".skin.group" ) then
		data.group = GetInt( "game.tool." .. id .. ".skin.group" )
	end
	if alreadyInit or force then
		if not data.noregister and not GetBool( "game.tool." .. id .. ".enabled" ) then
			RegisterTool( id, data.printname or id, data.model or "", data.group or 6 )
			SetBool( "game.tool." .. id .. ".enabled", true )
		end
	end
	for k, f in pairs( tool_meta._C ) do
		local v = rawget( data, k )
		if v ~= nil then
			rawset( data, k, nil )
			f( data, v )
		end
	end
	return data
end

hook.add( "base.init", "api.tool_loader", function()
	for id, tool in pairs( extra_tools ) do
		if not tool.noregister and not GetBool( "game.tool." .. id .. ".enabled" ) then
			RegisterTool( id, tool.printname or id, tool.model or "", tool.group or 6 )
			SetBool( "game.tool." .. id .. ".enabled", true )
		end
	end
	alreadyInit = true
end )

---@type Tool

function tool_meta._C:ammo( setter, val )
	local key = "game.tool." .. self.id .. ".ammo"
	local keystr = key .. ".display"
	if setter then
		if type( val ) == "number" then
			SetFloat( key, val )
			ClearKey( keystr )
			rawset( self, "_TOOLAMMOSTRING", false )
		else
			SetFloat( key, 0 )
			SetString( key .. ".display", tostring( val or "" ) )
			rawset( self, "_TOOLAMMOSTRING", tostring( val or "" ) )
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
---@param transform Transformation
function tool_meta:DrawInWorld( transform )
	SetToolTransform( TransformToLocalTransform( GetCameraTransform(), transform ) )
end

--- Gets the transform of the tool.
---
---@return Transformation
function tool_meta:GetTransform()
	return self._TRANSFORM or MakeTransformation( GetBodyTransform( GetToolBody() ) )
end

--- Gets the predicted transform of the tool.
---
---@return Transformation
function tool_meta:GetPredictedTransform()
	return self._TRANSFORM_FIX or MakeTransformation( GetBodyTransform( GetToolBody() ) )
end

--- Gets the transform delta of the tool.
---
---@return Transformation
function tool_meta:GetTransformDelta()
	return self._TRANSFORM_DIFF or Transformation( Vec(), Quat() )
end

--- Gets the transform of a bone on the tool in world-space.
---
---@param bone string
---@param nopredicted? boolean
---@return Transformation
function tool_meta:GetBoneGlobalTransform( bone, nopredicted )
	if not self._ARMATURE then
		return Transformation( Vec(), Quat() )
	end
	return (nopredicted and self:GetTransform() or self:GetPredictedTransform()):ToGlobal(
		       self._ARMATURE:GetBoneGlobalTransform( bone ) )
end

--- Draws the debug armature of the tool.
---
---@param nobones? boolean Don't draw bones.
---@param nobounds? boolean Don't draw bounds.
---@param nopredicted? boolean Don't use the predicted transform.
function tool_meta:DrawDebug( nobones, nobounds, nopredicted )
	if not self._ARMATURE or not self._SHAPES then
		return
	end
	local ptr = (nopredicted and self:GetTransform() or self:GetPredictedTransform())
	if not nobones and self._ARMATURE then
		self._ARMATURE:DrawDebug( ptr )
	end
	if not nobounds and self._OBJECTS then
		local s = self._OBJECTS
		for i = 1, #self._SHAPES do
			visual.drawbox( ptr:ToGlobal( self._SHAPES[i]:GetLocalTransform() ), Vec( 0, 0, 0 ),
			                VecScale( s[#s + 1 - i][2], .05 ), { r = 1, g = 1, b = 1, a = .2, writeZ = false } )
		end
	end
end

--- Callback called when the level loads.
function tool_meta:Initialize()
end

--- Callback called when tick() is called.
---
---@param dt number
function tool_meta:Tick( dt )
end

--- Callback called when draw() is called.
---
---@param dt number
function tool_meta:Draw( dt )
end

--- Callback called to animate the armature.
---
---@param body Body
---@param shapes Shape[]
function tool_meta:Animate( body, shapes )
end

--- Callback called when the tool is deployed.
function tool_meta:Deploy()
end

--- Callback called when the tool is holstered.
function tool_meta:Holster()
end

local function istoolactive()
	return GetBool( "game.player.canusetool" )
end

local function setupshapes( tool )
	local armature = tool._ARMATURE
	if not armature then return end
	local shapes = armature:GetShapeTransforms()
	if not tool.shapes then
		tool.shapes = {}
		for i = 1, #shapes do
			local shape = shapes[i]
			local s = tool._SHAPES[shape.num]
			tool.shapes[shape.attributes.name or shape.id] = s
			if shape.attributes.tags then
				for key, value in (shape.attributes.tags .. " "):gmatch("([^= ]*)=?([^= ]*) ") do
					s:SetTag(key, value)
				end
			end
			if shape.attributes.desc then
				s:SetDescription(shape.attributes.desc)
			end
			if shape.reoffset_scale then
				local x, y = s:GetSize()
				shape.transform = TransformToParentTransform( shape.transform, Transform( Vec(
					-math.floor( x / 2 ) / 10 * shape.reoffset_scale,
					0,
					math.floor( y / 2 ) / 10 * shape.reoffset_scale
				), QuatEuler( -90, 0, 0 ) ) )
				shape.reoffset_scale = nil
			end
		end
	end
end

local prev
hook.add( "api.mouse.wheel", "api.tool_loader", function( ds )
	if not istoolactive() then
		return
	end
	local tool = prev and extra_tools[prev]
	if tool and tool.MouseWheel then
		tool:MouseWheel( ds )
	end
end )

hook.add( "base.update", "api.tool_loader", function( dt )
	local cur = GetString( "game.player.tool" )
	local tool = extra_tools[cur]
	if tool then
		if tool.Update then
			softassert( pcall( tool.Update, tool, dt ) )
		end
	end
end )

hook.add( "base.tick", "api.tool_loader", function( dt )
	local cur = GetString( "game.player.tool" )

	local prevtool = prev and extra_tools[prev]
	if prevtool then
		if prevtool.ShouldLockMouseWheel then
			local s, b = softassert( pcall( prevtool.ShouldLockMouseWheel, prevtool ) )
			if s then
				SetBool( "game.input.locktool", not not b )
			end
			if b then
				SetString( "game.player.tool", prev )
				cur = prev
			end
		end
		if prev ~= cur and prevtool.Holster then
			softassert( pcall( prevtool.Holster, prevtool ) )
		end
	end

	local tool = extra_tools[cur]
	if tool then
		if prev ~= cur then
			if tool.Deploy then
				softassert( pcall( tool.Deploy, tool ) )
			end
			if tool._ARMATURE then
				tool._ARMATURE:ResetJiggle()
			end
			tool.shapes = nil
		end
		local body = GetToolBody()
		if prev == cur and ( not tool._BODY or tool._BODY.handle ~= body ) then
			tool._BODY = Body( body )
			tool._SHAPES = tool._BODY and tool._BODY:GetShapes()
			if not tool.shapes then
				setupshapes(tool)
			end
		end
		if tool._BODY then
			tool._TRANSFORM = tool._BODY:GetTransform()
			tool._TRANSFORM_DIFF = tool._TRANSFORM_OLD and tool._TRANSFORM:ToLocal( tool._TRANSFORM_OLD ) or
				                       Transformation( Vec(), Quat() )
			local reverse_diff = tool._TRANSFORM_OLD and tool._TRANSFORM_OLD:ToLocal( tool._TRANSFORM ) or
				                     Transformation( Vec(), Quat() )
			-- reverse_diff.pos = VecScale(reverse_diff.pos, 60 * dt)
			tool._TRANSFORM_FIX = tool._TRANSFORM:ToGlobal( reverse_diff )
			if tool.Animate and prev == cur then
				softassert( pcall( tool.Animate, tool, tool._BODY, tool._SHAPES ) )
			end
			if tool._ARMATURE then
				tool._ARMATURE:UpdatePhysics( tool:GetTransformDelta(), GetTimeStep(),
				                              TransformToLocalVec( tool:GetTransform(), Vec( 0, -10, 0 ) ) )
				local shapes = tool._ARMATURE:GetShapeTransforms()
				for i = 1, #shapes do -- TODO: avoid using num
					tool._SHAPES[shapes[i].num]:SetLocalTransform( shapes[i].global_transform )
				end
			end
		end
		if tool._TOOLAMMOSTRING then
			-- Fix sandbox ammo string
			SetInt( "game.tool." .. tool.id .. ".ammo", 0 )
		end
		if tool.Tick then
			softassert( pcall( tool.Tick, tool, dt ) )
		end
		if tool._TRANSFORM then
			tool._TRANSFORM_OLD = tool._TRANSFORM
		end
	end
	prev = cur
end )

hook.add( "api.firsttick", "api.tool_loader", function()
	for id, tool in pairs( extra_tools ) do
		if tool.Initialize then
			softassert( pcall( tool.Initialize, tool ) )
		end
	end
end )

hook.add( "base.draw", "api.tool_loader", function( dt )
	local tool = extra_tools[GetString( "game.player.tool" )]
	if tool and tool.Draw then
		softassert( pcall( tool.Draw, tool, dt ) )
	end
end )

hook.add( "api.mouse.pressed", "api.tool_loader", function( button )
	local tool = extra_tools[GetString( "game.player.tool" )]
	local event = button == "lmb" and "LeftClick" or button == "rmb" and "RightClick"
	if tool and istoolactive() then
		if event and tool[event] then
			softassert( pcall( tool[event], tool ) )
		end
		if tool.MousePressed then
			softassert( pcall( tool.MousePressed, tool, button ) )
		end
	end
end )

hook.add( "api.mouse.released", "api.tool_loader", function( button )
	local tool = extra_tools[GetString( "game.player.tool" )]
	local event = button == "lmb" and "LeftClickReleased" or button == "rmb" and "RightClickReleased"
	if tool and istoolactive() then
		if event and tool[event] then
			softassert( pcall( tool[event], tool ) )
		end
		if tool.MouseReleased then
			softassert( pcall( tool.MouseReleased, tool, button ) )
		end
	end
end )
