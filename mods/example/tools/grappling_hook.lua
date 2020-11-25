
local TOOL = {}

TOOL.base = "gun"

TOOL.printname = "Grappling Hook"
TOOL.order = 3

TOOL.suppress_default = true

local STATE_READY = 0
local STATE_THROWN = 1
local STATE_ATTACHED = 2
local STATE_REELING = 3

function TOOL:Initialize()
	self.state = STATE_READY
end

function TOOL:TeleportPlayer(dest)
	local ply_transform = GetPlayerTransform()
	ply_transform.pos = (dest or self.camerapos) - Vector(0, 1.6, 0)
	ply_transform.rot = ply_transform.rot * MakeQuaternion(QuatEuler(180, 0, 0))
	SetPlayerTransform(ply_transform)
end

function TOOL:LeftClick()
	local ply_transform = GetPlayerTransform()
	if self.state == STATE_READY then
		self.hookpos = MakeVector(TransformToParentPoint(ply_transform, Vector(0,0,0.5)))
		self.hookvel = ply_transform.rot * VEC_FORWARD * -0.3
		self.state = STATE_THROWN
	elseif self.state == STATE_THROWN then
		self.state = STATE_READY
	elseif self.state == STATE_ATTACHED then
		self.targetpos = self.hookpos + Vector(0, 1.6, 0)
		self.camerapos = ply_transform.pos
		SetCameraTransform(ply_transform, GetInt("options.gfx.fov"))
		self.state = STATE_REELING
	elseif self.state == STATE_REELING then
		self:TeleportPlayer()
		self.state = STATE_READY
	end
end

local offset = Vector(0.4,-0.2,-0.8)
function TOOL:Draw()
	if self.state >= STATE_THROWN then
		-- draw rope between hand and hook
		render.drawline(
			TransformToParentPoint(GetCameraTransform(), offset),
			self.hookpos or Vector(0,0,0), {r = 0, g = 0, b = 0}
		)
	end
end

local air_drag = 0.999
local gravity = Vector(0, -0.1, 0)
local reel_speed = 10
function TOOL:Tick()
	if self.state == STATE_THROWN then
		-- Hook physics
		local hit, dist = Raycast(self.hookpos, self.hookvel, self.hookvel:Length())
		local hitpos

		if hit then
			hitpos = self.hookpos + self.hookvel * dist
		else
			local ply_transform = GetPlayerTransform()
			local len = self.hookpos:Distance(ply_transform.pos)
			local dir = (self.hookpos - ply_transform.pos) / len
			hit, dist = Raycast(ply_transform.pos, dir, len)
			if hit then hitpos = ply_transform.pos + dir * dist end
		end

		if hitpos then
			self.hookpos = hitpos
			self.hookvel = nil
			self.state = STATE_ATTACHED
		else
			self.hookpos = self.hookpos + self.hookvel
			self.hookvel = self.hookvel * air_drag + gravity * GetTimeStep()
		end
	elseif self.state == STATE_REELING then
		local ply_transform = GetPlayerTransform()
		local diff = self.targetpos - self.camerapos
		local dist = diff:Length()
		local max_dist = reel_speed * GetTimeStep()
		self.camerapos = self.camerapos + (diff / dist) * math.min(dist, max_dist)
		ply_transform.pos = self.camerapos
		SetCameraTransform(ply_transform, GetInt("options.gfx.fov"))
		if max_dist > dist then
			self:TeleportPlayer()
			self.state = STATE_READY
		end
	end
end

function TOOL:Deploy()
end

function TOOL:Holster()
	if self.state == STATE_REELING then
		self:TeleportPlayer()
	end
	self.state = STATE_READY
end

local states = {
	[STATE_READY] = "READY",
	[STATE_THROWN] = "THROWN",
	[STATE_ATTACHED] = "HOOKED",
	[STATE_REELING] = "REELING",
}

function TOOL:GetAmmoString()
	return states[self.state]
end

RegisterTool("grappling_hook", TOOL)
