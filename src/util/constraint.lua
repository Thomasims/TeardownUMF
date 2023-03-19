----------------
-- Constraint Utilities
-- @script util.constraint
UMF_REQUIRE "meta.lua"

if not GetEntityHandle then
	GetEntityHandle = function( handle )
		return handle
	end
end

constraint = {}
_UMFConstraints = {}
local solvers = {}

function constraint.RunUpdate( dt )
	local offset = 0
	for i = 1, #_UMFConstraints do
		local v = _UMFConstraints[i + offset]
		if v.joint and IsJointBroken( v.joint ) then
			table.remove( _UMFConstraints, i + offset )
			offset = offset - 1
		else
			local result = { c = v }
			for j = 1, #v.solvers do
				local s = v.solvers[j]
				solvers[s.type]( s, result )
			end
			if result.angvel then
				local l = VecLength( result.angvel )
				ConstrainAngularVelocity( v.parent, v.child, VecScale( result.angvel, 1 / l ), l * 10, 0, v.max_aimp )
			end
		end
	end
end

local coreloaded = UMF_SOFTREQUIRE "core"
if coreloaded then
	hook.add( "base.update", "umf.constraint", constraint.RunUpdate )
end

local function find_index( t, v )
	for i = 1, #t do
		if t[i] == v then
			return i
		end
	end
end

function constraint.Relative( val, body )
	if type( val ) == "table" and val.handle or type( val ) == "number" then
		body = val
		val = nil
	end
	if type( val ) == "table" and val.body then
		body = val.body
		val = val.val
	end
	return { body = GetEntityHandle( body or 0 ), val = val }
end

local function resolve_point( relative_val )
	return TransformToParentPoint( GetBodyTransform( relative_val.body ), relative_val.val )
end

local function resolve_axis( relative_val )
	return TransformToParentVec( GetBodyTransform( relative_val.body ), relative_val.val )
end

local function resolve_orientation( relative_val )
	return TransformToParentTransform( GetBodyTransform( relative_val.body ),
	                                   Transform( Vec(), relative_val.val or Quat() ) )
end

local function resolve_transform( relative_val )
	return TransformToParentTransform( GetBodyTransform( relative_val.body ), relative_val.val )
end

local constraint_meta = global_metatable( "constraint" )

function constraint.New( parent, child, joint )
	return instantiate_global_metatable( "constraint", {
		parent = GetEntityHandle( parent ),
		child = GetEntityHandle( child ),
		joint = GetEntityHandle( joint ),
		solvers = {},
		tmp = {},
		active = false,
	} )
end

function constraint_meta:Rebuild()
	if not self.active then
		return
	end
	local index = self.lastbuild and find_index( _UMFConstraints, self.lastbuild ) or (#_UMFConstraints + 1)
	local c = {
		parent = self.parent,
		child = self.child,
		joint = self.joint,
		solvers = {},
		max_aimp = self.max_aimp or math.huge,
		max_vimp = self.max_vimp or math.huge,
	}
	for i = 1, #self.solvers do
		c.solvers[i] = self.solvers[i]:Build() or { type = "none" }
	end
	self.lastbuild = c
	_UMFConstraints[index] = c
end

function constraint_meta:Activate()
	self.active = true
	self:Rebuild()
	return self
end

local colors = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 }, { 0, 1, 1 }, { 1, 0, 1 }, { 1, 1, 0 }, { 1, 1, 1 } }
function constraint_meta:DrawDebug( c )
	c = c or GetBodyTransform( self.child ).pos
	for i = 1, #self.solvers do
		local col = colors[(i - 1) % #colors + 1]
		self.solvers[i]:DrawDebug( c, col[1], col[2], col[3] )
	end
end

function constraint_meta:LimitAngularVelocity( maxangvel )
	if self.tmp.asolver then
		self.tmp.asolver.max_avel = maxangvel
	else
		self.tmp.max_avel = maxangvel
	end
	return self
end

function constraint_meta:LimitAngularImpulse( maxangimpulse )
	self.max_aimp = maxangimpulse
	return self
end

function constraint_meta:LimitVelocity( maxvel )
	if self.tmp.vsolver then
		self.tmp.vsolver.max_vel = maxvel
	else
		self.tmp.max_vel = maxvel
	end
	return self
end

function constraint_meta:LimitImpulse( maximpulse )
	self.max_vimp = maximpulse
	return self
end

--------------------------------
--         Solver Base        --
--------------------------------

local solver_meta = global_metatable( "constraint_solver" )

function solver_meta:Build()
end
function solver_meta:DrawDebug()
end

function solvers:none()
end

--------------------------------
--    Rotation Axis Solvers   --
--------------------------------

function constraint_meta:ConstrainRotationAxis( axis, body )
	self.tmp.vsolver = nil
	self.tmp.asolver = nil
	self.tmp.axis = constraint.Relative( axis, body )
	return self
end

local solver_ra_sphere_meta = global_metatable( "constraint_ra_sphere_solver", "constraint_solver" )

function constraint_meta:OnSphere( quat, body )
	local s = instantiate_global_metatable( "constraint_ra_sphere_solver", {} )
	s.axis = self.tmp.axis
	s.quat = constraint.Relative( quat, body )
	s.max_avel = self.tmp.max_avel
	self.tmp.vsolver = nil
	self.tmp.asolver = s
	self.solvers[#self.solvers + 1] = s
	return self
end

function constraint_meta:AboveLatitude( min )
	self.tmp.asolver.min_lat = min
	return self
end

function constraint_meta:BelowLatitude( max )
	self.tmp.asolver.max_lat = max
	return self
end

function constraint_meta:WithinLatitudes( min, max )
	return self:AboveLatitude( min ):BelowLatitude( max )
end

function constraint_meta:WithinLongitudes( min, max )
	self.tmp.asolver.min_lng = min
	self.tmp.asolver.max_lng = max
	return self
end

function solver_ra_sphere_meta:DrawDebug( c, r, g, b )
	local tr = resolve_orientation( self.quat )
	tr.pos = c
	local axis = VecNormalize( resolve_axis( self.axis ) )

	local start_lng = self.min_lng or 0
	local len_lng = self.max_lng and (start_lng - self.max_lng) % 360
	if self.min_lat then
		visual.drawpolygon( TransformToParentTransform( tr, Transform( Vec( 0, math.sin( math.rad( self.min_lat ) ), 0 ) ) ),
		                    math.cos( math.rad( self.min_lat ) ), -start_lng, 40, { arc = len_lng, r = r, g = g, b = b } )
	end
	if self.max_lat then
		visual.drawpolygon( TransformToParentTransform( tr, Transform( Vec( 0, math.sin( math.rad( self.max_lat ) ), 0 ) ) ),
		                    math.cos( math.rad( self.max_lat ) ), -start_lng, 40, { arc = len_lng, r = r, g = g, b = b } )
	end
	if self.min_lng then
		local start_lat = self.min_lat or 360
		local len_lat = start_lat - (self.max_lat or 0)
		visual.drawpolygon( TransformToParentTransform( tr, Transform( Vec(), QuatEuler( 0, 180 - self.min_lng, 90 ) ) ), 1,
		                    180 - start_lat, 20, { arc = len_lat, r = r, g = g, b = b } )
		visual.drawpolygon( TransformToParentTransform( tr, Transform( Vec(), QuatEuler( 0, 180 - self.max_lng, 90 ) ) ), 1,
		                    180 - start_lat, 20, { arc = len_lat, r = r, g = g, b = b } )
	end

	DrawLine( tr.pos, VecAdd( tr.pos, axis ), r, g, b )
end

function solver_ra_sphere_meta:Build()
	local quat = constraint.Relative( self.quat )
	local lng
	if self.min_lng then
		local mid = (self.max_lng + self.min_lng) / 2
		if self.max_lng < self.min_lng then
			mid = mid + 180
		end
		lng = math.acos( math.cos( math.rad( self.min_lng - mid ) ) )
		quat.val = QuatRotateQuat( QuatAxisAngle( QuatRotateVec( quat.val or Quat(), Vec( 0, 1, 0 ) ), -mid ),
		                           quat.val or Quat() )
	end
	local axis = constraint.Relative( self.axis )
	axis.val = VecNormalize( axis.val )
	return {
		type = "ra_sphere",
		axis = axis,
		quat = quat,
		lng = lng,
		min_lat = self.min_lat and math.rad( self.min_lat ) or nil,
		max_lat = self.max_lat and math.rad( self.max_lat ) or nil,
		max_avel = self.max_avel,
	}
end

function solvers:ra_sphere( result )
	local axis = resolve_axis( self.axis )
	local tr = resolve_orientation( self.quat )
	local local_axis = TransformToLocalVec( tr, axis )
	local resv
	local lat = math.asin( local_axis[2] )
	if self.min_lat and lat < self.min_lat then
		local c = VecNormalize( VecCross( Vec( 0, -1, 0 ), local_axis ) )
		resv = VecScale( c, lat - self.min_lat )
	elseif self.max_lat and lat > self.max_lat then
		local c = VecNormalize( VecCross( Vec( 0, -1, 0 ), local_axis ) )
		resv = VecScale( c, lat - self.max_lat )
	end
	if self.lng then
		local l = math.sqrt( local_axis[1] ^ 2 + local_axis[3] ^ 2 )
		if l > 0.05 then
			local n = math.acos( local_axis[3] / l ) - self.lng
			if n < 0 then
				local c = VecNormalize( VecCross( VecCross( Vec( 0, 1, 0 ), local_axis ), local_axis ) )
				resv = VecAdd( resv, VecScale( c, local_axis[1] > 0 and -n or n ) )
				-- local c = VecNormalize( VecCross( Vec( 0, 0, -1 ), local_axis ) )
				-- resv = VecAdd( resv, VecScale( c, -n ) )
			end
		end
	end
	if resv then
		if self.max_avel then
			local len = VecLength( resv )
			if len > self.max_avel then
				resv = VecScale( resv, self.max_avel / len )
			end
		end
		result.angvel = VecAdd( result.angvel, TransformToParentVec( tr, resv ) )
	end
end

--------------------------------
--     Orientation Solvers    --
--------------------------------

function constraint_meta:ConstrainOrientation( quat, body )
	self.tmp.vsolver = nil
	self.tmp.asolver = nil
	self.tmp.quat = constraint.Relative( quat, body )
	return self
end

local solver_quat_quat_meta = global_metatable( "constraint_quat_quat_solver", "constraint_solver" )

function constraint_meta:ToOrientation( quat, body )
	local s = instantiate_global_metatable( "constraint_quat_quat_solver", {} )
	s.quat1 = self.tmp.quat
	s.quat2 = constraint.Relative( quat, body )
	s.max_avel = self.tmp.max_avel
	self.tmp.vsolver = nil
	self.tmp.asolver = s
	self.solvers[#self.solvers + 1] = s
	return self
end

local cdirections = { Vec( 1, 0, 0 ), Vec( 0, 1, 0 ), Vec( 0, 0, 1 ) }
function solver_quat_quat_meta:DrawDebug( c, r, g, b )
	local tr1 = resolve_orientation( self.quat1 )
	tr1.pos = c
	local tr2 = resolve_orientation( self.quat2 )
	tr2.pos = c
	for i = 1, #cdirections do
		local dir = cdirections[i]
		local p1 = TransformToParentPoint( tr1, dir )
		local p2 = TransformToParentPoint( tr2, dir )
		DrawLine( tr1.pos, p1, r, g, b )
		DrawLine( tr1.pos, p2, r, g, b )
		DrawLine( p1, p2, r, g, b )
	end
end

function solver_quat_quat_meta:Build()
	return { type = "quat_quat", quat1 = self.quat1, quat2 = self.quat2, max_avel = self.max_avel or math.huge }
end

function solvers:quat_quat( result )
	ConstrainOrientation( result.c.child, result.c.parent, resolve_orientation( self.quat1 ).rot,
	                      resolve_orientation( self.quat2 ).rot, self.max_avel, result.c.max_aimp )
end

--------------------------------
--      Position Solvers      --
--------------------------------

function constraint_meta:ConstrainPoint( point, body )
	self.tmp.vsolver = nil
	self.tmp.asolver = nil
	self.tmp.point = constraint.Relative( point, body )
	return self
end

local solver_point_point_meta = global_metatable( "constraint_point_point_solver", "constraint_solver" )

function constraint_meta:ToPoint( point, body )
	local s = instantiate_global_metatable( "constraint_point_point_solver", {} )
	s.point1 = self.tmp.point
	s.point2 = constraint.Relative( point, body )
	s.max_vel = self.tmp.max_vel
	self.tmp.vsolver = s
	self.tmp.asolver = nil
	self.solvers[#self.solvers + 1] = s
	return self
end

function solver_point_point_meta:DrawDebug( c, r, g, b )
	local point1 = resolve_point( self.point1 )
	local point2 = resolve_point( self.point2 )
	DebugCross( point1, r, g, b )
	DebugCross( point2, r, g, b )
	DrawLine( point1, point2, r, g, b )
end

function solver_point_point_meta:Build()
	return { type = "point_point", point1 = self.point1, point2 = self.point2, max_vel = self.max_vel or math.huge }
end

function solvers:point_point( result )
	ConstrainPosition( result.c.child, result.c.parent, resolve_point( self.point1 ), resolve_point( self.point2 ),
	                   self.max_vel, result.c.max_vimp )
end

local solver_point_space_meta = global_metatable( "constraint_point_space_solver", "constraint_solver" )

function constraint_meta:ToSpace( transform, body )
	local s = instantiate_global_metatable( "constraint_point_space_solver", {} )
	s.point = self.tmp.point
	s.transform = constraint.Relative( transform, body )
	s.max_vel = self.tmp.max_vel
	s.constraints = {}
	self.tmp.vsolver = s
	self.tmp.asolver = nil
	self.solvers[#self.solvers + 1] = s
	return self
end

function constraint_meta:WithinBox( center, min, max )
	local rcenter = constraint.Relative( self.tmp.vsolver.transform )
	rcenter.val = TransformToParentTransform( rcenter.val, center )
	table.insert( self.tmp.vsolver.constraints, { type = "box", center = rcenter, min = min, max = max } )
	return self
end

function constraint_meta:WithinSphere( center, radius )
	local rcenter = constraint.Relative( self.tmp.vsolver.transform )
	rcenter.val = TransformToParentPoint( rcenter.val, center )
	table.insert( self.tmp.vsolver.constraints, { type = "sphere", center = rcenter, radius = radius } )
	return self
end

function constraint_meta:AbovePlane( transform )
	local rcenter = constraint.Relative( self.tmp.vsolver.transform )
	rcenter.val = TransformToParentTransform( rcenter.val, transform )
	table.insert( self.tmp.vsolver.constraints, { type = "plane", center = rcenter } )
	return self
end

function constraint_meta:AlongPath( points, radius )
	local rcenter = constraint.Relative( self.tmp.vsolver.transform )
	table.insert( self.tmp.vsolver.constraints, { type = "path", center = rcenter, points = points, radius = radius or 0.01 } )
	return self
end


function solver_point_space_meta:DrawDebug( c, r, g, b )
	local point = resolve_point( self.point )
	for i = 1, #self.constraints do
		local c = self.constraints[i]
		if c.type == "plane" then
			local tr = resolve_transform( c.center )
			local lp = TransformToLocalPoint( tr, point )
			lp[2] = 0
			tr.pos = TransformToParentPoint( tr, lp )
			visual.drawpolygon( tr, 1.414, 45, 4, { r = r, g = g, b = b } )
		elseif c.type == "box" then
			local tr = resolve_transform( c.center )
			visual.drawbox( tr, c.min, c.max, { r = r, g = g, b = b } )
		elseif c.type == "sphere" then
			local tr = Transform( resolve_point( c.center ), Quat() )
			visual.drawwiresphere( tr, c.radius, 32, { r = r, g = g, b = b } )
		elseif c.type == "path" then
			local tr = resolve_transform( c.center )
			for j = 1, #c.points - 1 do
				local p1 = TransformToParentPoint( tr, c.points[j] )
				local p2 = TransformToParentPoint( tr, c.points[j + 1] )
				visual.drawline( nil, p1, p2, { r = r, g = g, b = b } )
			end
		end
	end
end

function solver_point_space_meta:Build()
	local consts = {}
	for i = 1, #self.constraints do
		local c = self.constraints[i]
		if c.type == "box" then
			local rcenter = constraint.Relative( c.center )
			rcenter.val.pos = TransformToParentPoint( rcenter.val, VecScale( VecAdd( c.min, c.max ), 0.5 ) )
			consts[i] = { type = "box", center = rcenter, size = VecScale( VecSub( c.max, c.min ), 0.5 ) }
		else
			consts[i] = c
		end
	end
	return { type = "point_space", point = self.point, constraints = consts, max_vel = self.max_vel or math.huge }
end

local function segment_dist(a, b, p)
	local s = VecSub(b, a)
	local da = VecSub(p, a)
	local dot = VecDot(s, da)
	if dot < 0 then
		return VecLength(da), a
	else
		local ds = s[1]^2 + s[2]^2 + s[3]^2
		if dot > ds then
			return VecLength(VecSub(p, b)), b
		else
			local f = dot/ds
			local lp = VecAdd(a, VecScale(s, f))
			return VecLength(VecSub(lp, p)), lp
		end
	end
end

function solvers:point_space( result )
	local point = resolve_point( self.point )
	local resv
	for i = 1, #self.constraints do
		local c = self.constraints[i]
		if c.type == "plane" then
			local tr = resolve_transform( c.center )
			local lp = TransformToLocalPoint( tr, point )
			if lp[2] < 0 then
				resv = VecAdd( resv, TransformToParentVec( tr, Vec( 0, lp[2], 0 ) ) )
			end
		elseif c.type == "box" then
			local tr = resolve_transform( c.center )
			local lp = TransformToLocalPoint( tr, point )
			local sx, sy, sz = c.size[1], c.size[2], c.size[3]
			local nlp = Vec( lp[1] < -sx and lp[1] + sx or lp[1] > sx and lp[1] - sx or 0,
			                 lp[2] < -sy and lp[2] + sy or lp[2] > sy and lp[2] - sy or 0,
			                 lp[3] < -sz and lp[3] + sz or lp[3] > sz and lp[3] - sz or 0 )
			if nlp[1] ~= 0 or nlp[2] ~= 0 or nlp[3] ~= 0 then
				resv = VecAdd( resv, TransformToParentVec( tr, nlp ) )
			end
		elseif c.type == "sphere" then
			local center = resolve_point( c.center )
			local diff = VecSub( point, center )
			local len = VecLength( diff )
			if len > c.radius then
				resv = VecAdd( resv, VecScale( diff, (len - c.radius) / len ) )
			end
		elseif c.type == "path" then
			local ci, cd, cp = nil, math.huge, nil
			local tr = resolve_transform( c.center )
			local lp = TransformToLocalPoint( tr, point )
			if not c.last_known then
				for j = 1, #c.points - 1 do
					local d, p = segment_dist( c.points[j], c.points[j + 1], lp )
					if d < cd then
						ci, cd, cp = j, d, p
					end
				end
			else
				--TODO: optimize for known previous location
			end
			local center = TransformToParentPoint( tr, cp )
			local diff = VecSub( point, center )
			local len = VecLength( diff )
			if len > c.radius then
				resv = VecAdd( resv, VecScale( diff, (len - c.radius) / len ) )
			end
			--c.last_known = ci
		end
	end
	if resv then
		local len = VecLength( resv )
		resv = VecScale( resv, 1 / len )
		if self.max_vel and len > self.max_vel then
			len = self.max_vel
		end
		ConstrainVelocity( result.c.parent, result.c.child, point, resv, len * 10, 0, result.c.max_vimp )
	end
end
