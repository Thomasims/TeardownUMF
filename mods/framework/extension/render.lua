
render = {}

if DrawSprite then
	local default_sprite = LoadSprite(Asset("image/white.png"))
	local frame_sprite = LoadSprite(Asset("image/frame.png"))
	local grid_sprite = LoadSprite(Asset("image/grid.png"))

	function render.drawline(source, destination, info)
		local width = 0.03
		local r, g, b, a = 1, 1, 1, 1
		local writeZ, additive = true, false
		local sprite = default_sprite
		local target = info and info.target or GetCameraTransform().pos

		if info then
			width = info.width or width
			r = info.r or r
			g = info.g or g
			b = info.b or b
			a = info.a or a
			writeZ = info.writeZ ~= nil and info.writeZ or writeZ
			additive = info.additive ~= nil and info.additive or additive
			sprite = info.sprite or sprite
		end

		local middle = (MakeVector(source) + destination) / 2
		local len = source:Distance(destination)
		local transform = Transformation(middle, source:LookAt(destination) * QuatEuler(-90, 0, 0))
		local target_local = TransformToLocalPoint(transform, target)
		target_local[2] = 0
		local transform_fixed = TransformToParentTransform(transform, Transform(VEC_ZERO, QuatLookAt(target_local, VEC_ZERO)))

		DrawSprite(sprite, transform_fixed, width, len, r, g, b, a, writeZ, additive)
	end

	function render.drawsprite(pos, image, size, info)
		local height = size
		local r, g, b, a = 1, 1, 1, 1
		local writeZ, additive = true, false
		local sprite = image or default_sprite
		local target = info and info.target or GetCameraTransform().pos

		if info then
			height = info.height or height
			r = info.r or r
			g = info.g or g
			b = info.b or b
			a = info.a or a
			writeZ = info.writeZ ~= nil and info.writeZ or writeZ
			additive = info.additive ~= nil and info.additive or additive
		end

		DrawSprite(sprite, Transform(pos, QuatLookAt(pos, target)), size, height, r, g, b, a, writeZ, additive)
	end

	function render.drawaxis(transform, rot)
		if not transform.pos then transform = Transform(transform, rot or QUAT_ZERO) end
		MakeTransformation(transform)

		render.drawline(transform.pos, transform:ToGlobal(VEC_LEFT), {r = 1, g = 0, b = 0})
		render.drawline(transform.pos, transform:ToGlobal(VEC_UP), {r = 0, g = 1, b = 0})
		render.drawline(transform.pos, transform:ToGlobal(VEC_FORWARD), {r = 0, g = 0, b = 1})
	end

	local QUAT_LEFT = MakeQuaternion(QuatEuler(0, 90, 90))
	local QUAT_UP = MakeQuaternion(QuatEuler(90, 0, 0))
	function render.drawbox(transform, min, max, sprite)
		sprite = sprite or frame_sprite
		MakeTransformation(transform)
		MakeVector(min)
		local mid = (min + max) / 2
		DrawSprite(sprite,
			transform:ToGlobal(Transform(Vec(mid[1], mid[2], min[3]), QUAT_ZERO)),
			max[1] - min[1], max[2] - min[2],
			1, 1, 1, 1, true, false)
		DrawSprite(sprite,
			transform:ToGlobal(Transform(Vec(mid[1], mid[2], max[3]), QUAT_ZERO)),
			max[1] - min[1], max[2] - min[2],
			1, 1, 1, 1, true, false)
		DrawSprite(sprite,
			transform:ToGlobal(Transform(Vec(mid[1], min[2], mid[3]), QUAT_UP)),
			max[1] - min[1], max[3] - min[3],
			1, 1, 1, 1, true, false)
		DrawSprite(sprite,
			transform:ToGlobal(Transform(Vec(mid[1], max[2], mid[3]), QUAT_UP)),
			max[1] - min[1], max[3] - min[3],
			1, 1, 1, 1, true, false)
		DrawSprite(sprite,
			transform:ToGlobal(Transform(Vec(min[1], mid[2], mid[3]), QUAT_LEFT)),
			max[2] - min[2], max[3] - min[3],
			1, 1, 1, 1, true, false)
		DrawSprite(sprite,
			transform:ToGlobal(Transform(Vec(max[1], mid[2], mid[3]), QUAT_LEFT)),
			max[2] - min[2], max[3] - min[3],
			1, 1, 1, 1, true, false)
	end

	function render.drawgrid(transform, x, y, sx, sy)
		for ix = (sx or 0) + 1, x do
			for iy = (sy or 0) + 1, y do
				DrawSprite(grid_sprite, MakeTransformation(transform) + Vector(ix-.5, iy-.5, 0), 1, 1, 1, 1, 1, 1, true, false)
			end
		end
	end
end