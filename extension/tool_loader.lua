local tool_meta = {
	__index = {
		DrawInWorld = function( self, transform )
			SetToolTransform( TransformToLocalTransform( GetCameraTransform(), transform ) )
		end,
		GetTransform = function( self )
			return self._TRANSFORM or MakeTransformation( GetBodyTransform( GetToolBody() ) )
		end,
		GetPredictedTransform = function( self )
			return self._TRANSFORM_FIX or MakeTransformation( GetBodyTransform( GetToolBody() ) )
		end,
		GetTransformDelta = function( self )
			return self._TRANSFORM_DIFF or Transformation( Vec(), Quat() )
		end,
		GetBoneGlobalTransform = function( self, bone, nopredicted )
			if not self._ARMATURE then
				return Transformation( Vec(), Quat() )
			end
			return (nopredicted and self:GetTransform() or self:GetPredictedTransform()):ToGlobal(
			       self._ARMATURE:GetBoneGlobalTransform( bone ) )
		end,
		DrawDebug = function( self, nobones, nobounds, nopredicted )
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
					                VecScale( s[#s + 1 - i][2], .05 ), 1, 1, 1, .2, false )
				end
			end
		end,
	},
}

local extra_tools = {}
function RegisterToolUMF( id, data )
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
	setmetatable( data, tool_meta )
	data.id = id
	extra_tools[id] = data
	RegisterTool( id, data.printname or id, data.model or "" )
	SetBool( "game.tool." .. id .. ".enabled", true )
end

local function istoolactive()
	return GetBool( "game.player.canusetool" )
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
		end
		local body = GetToolBody()
		if not tool._BODY or tool._BODY.handle ~= body then
			tool._BODY = Body( body )
			tool._SHAPES = tool._BODY and tool._BODY:GetShapes()
		end
		if tool._BODY then
			tool._TRANSFORM = tool._BODY:GetTransform()
			tool._TRANSFORM_DIFF = tool._TRANSFORM_OLD and tool._TRANSFORM:ToLocal( tool._TRANSFORM_OLD ) or
			                       Transformation( Vec(), Quat() )
			local reverse_diff = tool._TRANSFORM_OLD and tool._TRANSFORM_OLD:ToLocal( tool._TRANSFORM ) or
			                     Transformation( Vec(), Quat() )
			-- reverse_diff.pos = VecScale(reverse_diff.pos, 60 * dt)
			tool._TRANSFORM_FIX = tool._TRANSFORM:ToGlobal( reverse_diff )
			if tool.Animate then
				softassert( pcall( tool.Animate, tool, tool._BODY, tool._SHAPES ) )
			end
			if tool._ARMATURE then
				tool._ARMATURE:UpdatePhysics( tool:GetTransformDelta(), GetTimeStep(),
				                              TransformToLocalVec( tool:GetTransform(), Vec( 0, -10, 0 ) ) )
				tool._ARMATURE:Apply( tool._SHAPES )
			end
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

hook.add( "base.draw", "api.tool_loader", function()
	local tool = extra_tools[GetString( "game.player.tool" )]
	if tool and tool.Draw then
		softassert( pcall( tool.Draw, tool ) )
	end
end )

hook.add( "api.mouse.pressed", "api.tool_loader", function( button )
	local tool = extra_tools[GetString( "game.player.tool" )]
	local event = button == "lmb" and "LeftClick" or "RightClick"
	if tool and tool[event] and istoolactive() then
		softassert( pcall( tool[event], tool ) )
	end
end )

hook.add( "api.mouse.released", "api.tool_loader", function( button )
	local tool = extra_tools[GetString( "game.player.tool" )]
	local event = button == "lmb" and "LeftClickReleased" or "RightClickReleased"
	if tool and tool[event] and istoolactive() then
		softassert( pcall( tool[event], tool ) )
	end
end )
