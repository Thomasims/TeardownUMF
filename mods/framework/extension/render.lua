
render = {}

if DrawSprite then
	local default_sprite = LoadSprite(Asset("image/white.png"))

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
end