visual = {}
degreeToRadian = math.pi / 180
COLOR_WHITE = {r = 255/255, g = 255/255, b = 255/255, a = 255/255}
COLOR_BLACK = {r = 0, g = 0, b = 0, a = 255/255}
COLOR_RED = {r = 255/255, g = 0, b = 0, a = 255/255}
COLOR_ORANGE = {r = 255/255, g = 128/255, b = 0, a = 255/255}
COLOR_YELLOW = {r = 255/255, g = 255/255, b = 0, a = 255/255}
COLOR_GREEN = {r = 0, g = 255/255, b = 0, a = 1}
COLOR_CYAN = {r = 0, g = 255/255, b = 128/255, a = 1}
COLOR_AQUA = {r = 0, g = 255/255, b = 255/255, a = 255/255}
COLOR_BLUE = {r = 0, g = 0, b = 255/255, a = 1}
COLOR_VIOLET = {r = 128/255, g = 0, b = 255/255, a = 255/255}
COLOR_PINK = {r = 255/255, g = 0, b = 255/255, a = 255/255}

if DrawSprite then
    function visual.drawsprite(sprite, source, radius, info)
		local r, g, b, a = 1, 1, 1, 1
		local writeZ, additive = true, false
        local target = GetCameraTransform().pos
        local ratio = math.max(info.r, info.g, info.b, info.a)

		if info then
			height = info.height or height
			r = info.r / ratio or r
			g = info.g / ratio or g
			b = info.b / ratio or b
            a = info.a / ratio or a
			writeZ = info.writeZ ~= nil and info.writeZ or writeZ
			additive = info.additive ~= nil and info.additive or additive
			target = info.target or target
		end

		DrawSprite(sprite, Transform(source, QuatLookAt(source, target)), radius, radius, r, g, b, a, writeZ, additive)
    end
    function visual.drawsprites(sprites, sources, size, info)
		sprites = type(sprites) ~= "table" and {sprites} or sprites

        for i = 1, #sprites do
            for j = 1, #sources do
                visual.drawsprite(sprites[i], sources[j], size, info)
            end
        end
	end

    function visual.drawline(sprite, source, destination, info)
		local width = 0.03
		local r, g, b, a = 1, 1, 1, 1
		local writeZ, additive = true, false
        local target = GetCameraTransform().pos
        local ratio = math.max(info.r, info.g, info.b, info.a)
		local DrawFunction = writeZ and DrawLine or DebugLine

		if info then
			width = info.width or width
			r = info.r / ratio or r
			g = info.g / ratio or g
			b = info.b / ratio or b
            a = info.a / ratio or a
			writeZ = info.writeZ ~= nil and info.writeZ or writeZ
			additive = info.additive ~= nil and info.additive or additive
			target = info.target or target
		end

		if sprite then
			local middle = VecScale(VecAdd(source, destination), .5)
			local len = VecLength(VecSub(source, destination))
			local transform = Transform(middle, QuatRotateQuat(QuatLookAt(source, destination), QuatEuler(-90, 0, 0)))
			local target_local = TransformToLocalPoint(transform, target)
			target_local[2] = 0
			local transform_fixed = TransformToParentTransform(transform, Transform(nil, QuatLookAt(target_local, nil)))

			DrawSprite(sprite, transform_fixed, width, len, r, g, b, a, writeZ, additive)
		else
			DrawFunction(source, destination, r, g, b, a);
		end
    end
    function visual.drawlines(sprites, sources, connect, info)
        sprites = type(sprites) ~= "table" and {sprites} or sprites

        for i = 1, #sprites do
            local sourceCount = #sources

            for j = 1, sourceCount - 1 do
                visual.drawline(sprites[i], sources[j], sources[j + 1], info)
            end

            if connect then
                visual.drawline(sprites[i], sources[1], sources[sourceCount], info)
            end
        end
	end

	function visual.drawaxis(transform, quat, radius, writeZ)
		scale = scale or 1
		if not transform.pos then transform = Transform(transform, quat or QUAT_ZERO) end
		local DrawFunction = writeZ and DrawLine or DebugLine

		DrawFunction(transform.pos, TransformToParentPoint(transform, Vec(radius, 0, 0)), 1, 0, 0)
		DrawFunction(transform.pos, TransformToParentPoint(transform, Vec(0, radius, 0)), 0, 1, 0)
		DrawFunction(transform.pos, TransformToParentPoint(transform, Vec(0, 0, radius)), 0, 0, 1)
    end
    
    function visual.drawpolygon(transform, quat, radius, rotation, sides, info)
		local sin, cos, max = math.sin, math.cos, math.max
		local r, g, b, a = 1, 1, 1, 1
		local writeZ, additive = true, false
		if not transform.pos then transform = Transform(transform, quat or QUAT_ZERO) end
		local points = {}
		local ratio = max(info.r, info.g, info.b, info.a)
		local DrawFunction = writeZ and DrawLine or DebugLine
		local iteration = 1

		if info then
			r = info.r / ratio or r
			g = info.g / ratio or g
			b = info.b / ratio or b
            a = info.a / ratio or a
			writeZ = info.writeZ ~= nil and info.writeZ or writeZ
			additive = info.additive ~= nil and info.additive or additive
			target = info.target or target
		end
		
		for v = 0, 360, 360 / sides do
			points[iteration] = TransformToParentPoint(transform, Vec(sin((v + rotation) * degreeToRadian) * radius, 0, cos((v + rotation) * degreeToRadian) * radius))
			points[iteration + 1] = TransformToParentPoint(transform, Vec(sin(((v + 360 / sides) + rotation) * degreeToRadian) * radius, 0, cos(((v + 360 / sides) + rotation) * degreeToRadian) * radius))
			if iteration > 2 then
				DrawFunction(points[iteration], points[iteration + 1], r, g, b, a)
			end
			iteration = iteration + 2
		end
		
		return points
    end

	function visual.drawprism(transform, quat, radius, depth, rotation, sides, info)
		local sin, cos, max = math.sin, math.cos, math.max
		local r, g, b, a = 1, 1, 1, 1
		local writeZ, additive = true, false
		if not transform.pos then transform = Transform(transform, quat or QUAT_ZERO) end
		local points = {}
		local ratio = max(info.r, info.g, info.b, info.a)
		local DrawFunction = writeZ and DrawLine or DebugLine
		local iteration = 1

		if info then
			r = info.r / ratio or r
			g = info.g / ratio or g
			b = info.b / ratio or b
            a = info.a / ratio or a
			writeZ = info.writeZ ~= nil and info.writeZ or writeZ
			additive = info.additive ~= nil and info.additive or additive
			target = info.target or target
		end

		for v = 0, 360, 360 / sides do
			points[iteration] = TransformToParentPoint(transform, Vec(sin(v * degreeToRadian + rotation) * radius, 0, cos(v * degreeToRadian + rotation) * radius))
			points[iteration + 1] = TransformToParentPoint(transform, Vec(sin(v * degreeToRadian + rotation) * radius, -10, cos(v * degreeToRadian + rotation) * radius))
			if iteration > 2 then
				DrawFunction(points[iteration], points[iteration + 1], r, g, b, a)
				DrawFunction(points[iteration - 2], points[iteration], r, g, b, a)
				DrawFunction(points[iteration - 1], points[iteration + 1], r, g, b, a)
			end
			iteration = iteration + 2
		end
	end

	function visual.drawsphere(transform, radius, rotation, samples, info)
		local sqrt, sin, cos, max = math.sqrt, math.sin, math.cos, math.max
		local r, g, b, a = 1, 1, 1, 1
		local writeZ, additive = true, false
		if not transform.pos then transform = Transform(transform, quat or QUAT_ZERO) end
		local points = {}
		local ratio = max(info.r, info.g, info.b, info.a)
		local DrawFunction = writeZ and DrawLine or DebugLine

		if info then
			r = info.r / ratio or r
			g = info.g / ratio or g
			b = info.b / ratio or b
            a = info.a / ratio or a
			writeZ = info.writeZ ~= nil and info.writeZ or writeZ
			additive = info.additive ~= nil and info.additive or additive
			target = info.target or target
		end

		-- Converted from python to lua, see original code https://stackoverflow.com/a/26127012/5459461
		local points = {}
		for i = 0, samples do
			local y = 1 - (i / (samples - 1)) * 2  -- Y goes from 1 to -1
			local rad = sqrt(1 - y * y)  -- Radius at y
			local theta = (2.399963229728653 * i) + rotation  -- Golden angle increment

			local x = cos(theta) * rad
			local z = sin(theta) * rad
			local point = TransformToParentPoint(transform, Vec(x * radius, y * radius, z * radius))

			DrawFunction(point, VecAdd(point, Vec(0, .005, 0)), r, g, b, a)
			points[i + 1] = point
		end

		return points
	end
end