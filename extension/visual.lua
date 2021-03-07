
visual = {}

if DrawSprite then
	function visual.drawline(sprite, source, destination, info)
		local width = 0.03
		local r, g, b, a = 1, 1, 1, 1
		local writeZ, additive = true, false
		local target = GetCameraTransform().pos

		if info then
			width = info.width or width
			r = info.r or r
			g = info.g or g
			b = info.b or b
			a = info.a or a
			writeZ = info.writeZ ~= nil and info.writeZ or writeZ
			additive = info.additive ~= nil and info.additive or additive
			target = info.target or target
		end

		local middle = VecScale(VecAdd(source, destination), .5)
		local len = VecLength(VecSub(source, destination))
		local transform = Transform(middle, QuatRotateQuat(QuatLookAt(source, destination), QuatEuler(-90, 0, 0)))
		local target_local = TransformToLocalPoint(transform, target)
		target_local[2] = 0
		local transform_fixed = TransformToParentTransform(transform, Transform(nil, QuatLookAt(target_local, nil)))

		DrawSprite(sprite, transform_fixed, width, len, r, g, b, a, writeZ, additive)
	end

	function visual.drawsprite(sprite, pos, size, info)
		local height = size
		local r, g, b, a = 1, 1, 1, 1
		local writeZ, additive = true, false
		local target = GetCameraTransform().pos

		if info then
			height = info.height or height
			r = info.r or r
			g = info.g or g
			b = info.b or b
			a = info.a or a
			writeZ = info.writeZ ~= nil and info.writeZ or writeZ
			additive = info.additive ~= nil and info.additive or additive
			target = info.target or target
		end

		DrawSprite(sprite, Transform(pos, QuatLookAt(pos, target)), size, height, r, g, b, a, writeZ, additive)
	end

	function visual.drawaxis(transform, rot, mul, writeZ)
		mul = mul or 1
		if not transform.pos then transform = Transform(transform, rot or QUAT_ZERO) end
		local DrawFunc = writeZ and DrawLine or DebugLine
		DrawFunc(transform.pos, TransformToParentPoint(transform, Vec(mul, 0, 0)), 1, 0, 0)
		DrawFunc(transform.pos, TransformToParentPoint(transform, Vec(0, mul, 0)), 0, 1, 0)
		DrawFunc(transform.pos, TransformToParentPoint(transform, Vec(0, 0, mul)), 0, 0, 1)
	end

	function visual.drawbox(transform, min, max, cr, cg, cb, ca, writeZ)
		cr = cr or 1
		cg = cg or 1
		cb = cb or 1
		ca = ca or 1
		local a, b, c, d, e, f, g, h =
			TransformToParentPoint(transform, Vec(min[1], min[2], min[3])),
			TransformToParentPoint(transform, Vec(max[1], min[2], min[3])),
			TransformToParentPoint(transform, Vec(min[1], max[2], min[3])),
			TransformToParentPoint(transform, Vec(max[1], max[2], min[3])),
			TransformToParentPoint(transform, Vec(min[1], min[2], max[3])),
			TransformToParentPoint(transform, Vec(max[1], min[2], max[3])),
			TransformToParentPoint(transform, Vec(min[1], max[2], max[3])),
			TransformToParentPoint(transform, Vec(max[1], max[2], max[3]))
		local DrawFunc = writeZ and DrawLine or DebugLine
		DrawFunc(a, b, cr, cg, cb, ca)
		DrawFunc(a, c, cr, cg, cb, ca)
		DrawFunc(a, e, cr, cg, cb, ca)
		DrawFunc(d, c, cr, cg, cb, ca)
		DrawFunc(d, b, cr, cg, cb, ca)
		DrawFunc(d, h, cr, cg, cb, ca)
		DrawFunc(f, e, cr, cg, cb, ca)
		DrawFunc(f, h, cr, cg, cb, ca)
		DrawFunc(f, b, cr, cg, cb, ca)
		DrawFunc(g, h, cr, cg, cb, ca)
		DrawFunc(g, e, cr, cg, cb, ca)
		DrawFunc(g, c, cr, cg, cb, ca)
	end
end