----------------
-- Visual Utilities
-- @script util.visual
visual = {}
degreeToRadian = math.pi / 180
COLOR_WHITE = { r = 255 / 255, g = 255 / 255, b = 255 / 255, a = 255 / 255 }
COLOR_BLACK = { r = 0, g = 0, b = 0, a = 255 / 255 }
COLOR_RED = { r = 255 / 255, g = 0, b = 0, a = 255 / 255 }
COLOR_ORANGE = { r = 255 / 255, g = 128 / 255, b = 0, a = 255 / 255 }
COLOR_YELLOW = { r = 255 / 255, g = 255 / 255, b = 0, a = 255 / 255 }
COLOR_GREEN = { r = 0, g = 255 / 255, b = 0, a = 255 / 255 }
COLOR_CYAN = { r = 0, g = 255 / 255, b = 128 / 255, a = 255 / 255 }
COLOR_AQUA = { r = 0, g = 255 / 255, b = 255 / 255, a = 255 / 255 }
COLOR_BLUE = { r = 0, g = 0, b = 255 / 255, a = 255 / 255 }
COLOR_VIOLET = { r = 128 / 255, g = 0, b = 255 / 255, a = 255 / 255 }
COLOR_PINK = { r = 255 / 255, g = 0, b = 255 / 255, a = 255 / 255 }

if DrawSprite then
	function visual.huergb( p, q, t )
		if t < 0 then
			t = t + 1
		end
		if t > 1 then
			t = t - 1
		end
		if t < 1 / 6 then
			return p + (q - p) * 6 * t
		end
		if t < 1 / 2 then
			return q
		end
		if t < 2 / 3 then
			return p + (q - p) * (2 / 3 - t) * 6
		end
		return p
	end

	--- Converts hue, saturation, and light to RGB.
	---
	---@param h number
	---@param s number
	---@param l number
	---@return number[]
	function visual.hslrgb( h, s, l )
		local r, g, b

		if s == 0 then
			r = l
			g = l
			b = l
		else
			local huergb = visual.huergb

			local q = l < .5 and l * (1 + s) or l + s - l * s
			local p = 2 * l - q

			r = huergb( p, q, h + 1 / 3 )
			g = huergb( p, q, h )
			b = huergb( p, q, h - 1 / 3 )

		end
		return Vec( r, g, b )
	end

	--- Draws a sprite facing the camera.
	---
	---@param sprite number
	---@param source vector
	---@param radius number
	---@param info table
	function visual.drawsprite( sprite, source, radius, info )
		local r, g, b, a
		local writeZ, additive = true, false
		local target = GetCameraTransform().pos
		local DrawFunction = DrawSprite

		radius = radius or 1

		if info then
			r = info.r and info.r or 1
			g = info.g and info.g or 1
			b = info.b and info.b or 1
			a = info.a and info.a or 1
			target = info.target or target
			if info.writeZ ~= nil then
				writeZ = info.writeZ
			end
			if info.additive ~= nil then
				additive = info.additive
			end
			DrawFunction = info.DrawFunction ~= nil and info.DrawFunction or DrawFunction
		end

		DrawFunction( sprite, Transform( source, QuatLookAt( source, target ) ), radius, radius, r, g, b, a, writeZ, additive )
	end

	--- Draws sprites facing the camera.
	---
	---@param sprites number[]
	---@param sources vector[]
	---@param radius number
	---@param info table
	function visual.drawsprites( sprites, sources, radius, info )
		sprites = type( sprites ) ~= "table" and { sprites } or sprites

		for i = 1, #sprites do
			for j = 1, #sources do
				visual.drawsprite( sprites[i], sources[j], radius, info )
			end
		end
	end

	--- Draws a line using a sprite.
	---
	---@param sprite number
	---@param source vector
	---@param destination vector
	---@param info table
	function visual.drawline( sprite, source, destination, info )
		local r, g, b, a
		local writeZ, additive = true, false
		local target = GetCameraTransform().pos
		local DrawFunction = DrawLine
		local width = 0.03

		if info then
			r = info.r and info.r or 1
			g = info.g and info.g or 1
			b = info.b and info.b or 1
			a = info.a and info.a or 1
			width = info.width or width
			target = info.target or target
			if info.writeZ ~= nil then
				writeZ = info.writeZ
			end
			if info.additive ~= nil then
				additive = info.additive
			end
			DrawFunction = info.DrawFunction ~= nil and info.DrawFunction or (info.writeZ == false and DebugLine or DrawLine)
		end

		if sprite then
			local middle = VecScale( VecAdd( source, destination ), .5 )
			local len = VecLength( VecSub( source, destination ) )
			local transform = Transform( middle, QuatRotateQuat( QuatLookAt( source, destination ), QuatEuler( -90, 0, 0 ) ) )
			local target_local = TransformToLocalPoint( transform, target )
			target_local[2] = 0
			local trlook = Transform( nil, QuatLookAt( target_local, nil ) )
			if info and info.turn then
				trlook.rot = QuatRotateQuat(trlook.rot, QuatEuler(0,0,90))
				width, len = len, width
			end
			local transform_fixed = TransformToParentTransform( transform, trlook )

			DrawSprite( sprite, transform_fixed, width, len, r, g, b, a, writeZ, additive )
		else
			DrawFunction( source, destination, r, g, b, a );
		end
	end

	--- Draws lines using a sprite.
	---
	---@param sprites number[] | number
	---@param sources vector[]
	---@param connect boolean
	---@param info table
	function visual.drawlines( sprites, sources, connect, info )
		sprites = type( sprites ) ~= "table" and { sprites } or sprites

		for i = 1, #sprites do
			local sourceCount = #sources

			for j = 1, sourceCount - 1 do
				visual.drawline( sprites[i], sources[j], sources[j + 1], info )
			end

			if connect then
				visual.drawline( sprites[i], sources[1], sources[sourceCount], info )
			end
		end
	end

	--- Draws a debug axis.
	---
	---@param transform transform
	---@param quat? quaternion
	---@param radius number
	---@param writeZ boolean
	function visual.drawaxis( transform, quat, radius, writeZ )
		local DrawFunction = writeZ and DrawLine or DebugLine

		if not transform.pos then
			transform = Transform( transform, quat or QUAT_ZERO )
		end
		radius = radius or 1

		DrawFunction( transform.pos, TransformToParentPoint( transform, Vec( radius, 0, 0 ) ), 1, 0, 0 )
		DrawFunction( transform.pos, TransformToParentPoint( transform, Vec( 0, radius, 0 ) ), 0, 1, 0 )
		DrawFunction( transform.pos, TransformToParentPoint( transform, Vec( 0, 0, radius ) ), 0, 0, 1 )
	end

	--- Draws a polygon.
	---
	---@param transform transform
	---@param radius number
	---@param rotation number
	---@param sides number
	---@param info table
	function visual.drawpolygon( transform, radius, rotation, sides, info )
		sides = sides or 4
		radius = radius or 1

		local offset, interval = math.rad( rotation or 0 ), 2 * math.pi / sides
		local arc = false
		local r, g, b, a = 1, 1, 1, 1
		local DrawFunction = DrawLine

		if info then
			r = info.r or r
			g = info.g or g
			b = info.b or b
			a = info.a or a
			if info.arc then
				arc = true
				interval = interval * info.arc / 360
			end
			DrawFunction = info.DrawFunction or (info.writeZ == false and DebugLine or DrawLine)
		end

		local points = {}
		for i = 0, sides - 1 do
			points[i + 1] = TransformToParentPoint( transform, Vec( math.sin( offset + i * interval ) * radius, 0,
			                                                        math.cos( offset + i * interval ) * radius ) )
			if i > 0 then
				DrawFunction( points[i], points[i + 1], r, g, b, a )
			end
		end
		if arc then
			points[#points + 1] = TransformToParentPoint( transform, Vec( math.sin( offset + sides * interval ) * radius, 0,
			                                                              math.cos( offset + sides * interval ) * radius ) )
			DrawFunction( points[#points - 1], points[#points], r, g, b, a )
		else
			DrawFunction( points[#points], points[1], r, g, b, a )
		end

		return points
	end

	--- Draws a 3D box.
	---
	---@param transform transform
	---@param min vector
	---@param max vector
	---@param info table
	function visual.drawbox( transform, min, max, info )
		local r, g, b, a
		local DrawFunction = DrawLine
		local points = {
			TransformToParentPoint( transform, Vec( min[1], min[2], min[3] ) ),
			TransformToParentPoint( transform, Vec( max[1], min[2], min[3] ) ),
			TransformToParentPoint( transform, Vec( min[1], max[2], min[3] ) ),
			TransformToParentPoint( transform, Vec( max[1], max[2], min[3] ) ),
			TransformToParentPoint( transform, Vec( min[1], min[2], max[3] ) ),
			TransformToParentPoint( transform, Vec( max[1], min[2], max[3] ) ),
			TransformToParentPoint( transform, Vec( min[1], max[2], max[3] ) ),
			TransformToParentPoint( transform, Vec( max[1], max[2], max[3] ) ),
		}

		if info then
			r = info.r and info.r or 1
			g = info.g and info.g or 1
			b = info.b and info.b or 1
			a = info.a and info.a or 1
			DrawFunction = info.DrawFunction ~= nil and info.DrawFunction or (info.writeZ == false and DebugLine or DrawLine)
		end

		DrawFunction( points[1], points[2], r, g, b, a )
		DrawFunction( points[1], points[3], r, g, b, a )
		DrawFunction( points[1], points[5], r, g, b, a )
		DrawFunction( points[4], points[3], r, g, b, a )
		DrawFunction( points[4], points[2], r, g, b, a )
		DrawFunction( points[4], points[8], r, g, b, a )
		DrawFunction( points[6], points[5], r, g, b, a )
		DrawFunction( points[6], points[8], r, g, b, a )
		DrawFunction( points[6], points[2], r, g, b, a )
		DrawFunction( points[7], points[8], r, g, b, a )
		DrawFunction( points[7], points[5], r, g, b, a )
		DrawFunction( points[7], points[3], r, g, b, a )

		return points
	end

	--- Draws a prism.
	---
	---@param transform transform
	---@param radius number
	---@param depth number
	---@param rotation number
	---@param sides number
	---@param info table
	function visual.drawprism( transform, radius, depth, rotation, sides, info )
		local points = {}
		local iteration = 1
		local pow, sqrt, sin, cos = math.pow, math.sqrt, math.sin, math.cos
		local r, g, b, a
		local DrawFunction = DrawLine

		radius = sqrt( 2 * pow( radius, 2 ) ) or sqrt( 2 )
		depth = depth or 1
		rotation = rotation or 0
		sides = sides or 4

		if info then
			r = info.r and info.r or 1
			g = info.g and info.g or 1
			b = info.b and info.b or 1
			a = info.a and info.a or 1
			DrawFunction = info.DrawFunction ~= nil and info.DrawFunction or (info.writeZ == false and DebugLine or DrawLine)
		end

		for v = 0, 360, 360 / sides do
			points[iteration] = TransformToParentPoint( transform, Vec( sin( (v + rotation) * degreeToRadian ) * radius, depth,
			                                                            cos( (v + rotation) * degreeToRadian ) * radius ) )
			points[iteration + 1] = TransformToParentPoint( transform, Vec( sin( (v + rotation) * degreeToRadian ) * radius,
			                                                                -depth,
			                                                                cos( (v + rotation) * degreeToRadian ) * radius ) )
			if iteration > 2 then
				DrawFunction( points[iteration], points[iteration + 1], r, g, b, a )
				DrawFunction( points[iteration - 2], points[iteration], r, g, b, a )
				DrawFunction( points[iteration - 1], points[iteration + 1], r, g, b, a )
			end
			iteration = iteration + 2
		end

		return points
	end

	--- Draws a sphere.
	---
	---@param transform transform
	---@param radius number
	---@param rotation number
	---@param samples number
	---@param info table
	function visual.drawsphere( transform, radius, rotation, samples, info )
		local points = {}
		local sqrt, sin, cos = math.sqrt, math.sin, math.cos
		local r, g, b, a
		local DrawFunction = DrawLine

		radius = radius or 1
		rotation = rotation or 0
		samples = samples or 100

		if info then
			r = info.r and info.r or 1
			g = info.g and info.g or 1
			b = info.b and info.b or 1
			a = info.a and info.a or 1
			DrawFunction = info.DrawFunction ~= nil and info.DrawFunction or (info.writeZ == false and DebugLine or DrawLine)
		end

		-- Converted from python to lua, see original code https://stackoverflow.com/a/26127012/5459461
		local points = {}
		for i = 0, samples do
			local y = 1 - (i / (samples - 1)) * 2
			local rad = sqrt( 1 - y * y )
			local theta = 2.399963229728653 * i

			local x = cos( theta ) * rad
			local z = sin( theta ) * rad
			local point = TransformToParentPoint( Transform( transform.pos,
			                                                 QuatRotateQuat( transform.rot, QuatEuler( 0, rotation, 0 ) ) ),
			                                      Vec( x * radius, y * radius, z * radius ) )

			DrawFunction( point, VecAdd( point, Vec( 0, .01, 0 ) ), r, g, b, a )
			points[i + 1] = point
		end

		return points
	end

	--- Draws a wireframe sphere.
	---
	---@param transform transform
	---@param radius number
	---@param points number
	---@param info table
	function visual.drawwiresphere( transform, radius, points, info )
		radius = radius or 1
		points = points or 32
		if not info or not info.nolines then
			local tr_r = TransformToParentTransform( transform, Transform( Vec(), QuatEuler( 90, 0, 0 ) ) )
			local tr_f = TransformToParentTransform( transform, Transform( Vec(), QuatEuler( 0, 0, 90 ) ) )
			visual.drawpolygon( transform, radius, 0, points, info )
			visual.drawpolygon( tr_r, radius, 0, points, info )
			visual.drawpolygon( tr_f, radius, 0, points, info )
		end

		local cam = info and info.target or GetCameraTransform().pos
		local diff = VecSub( transform.pos, cam )
		local len = VecLength( diff )
		if len < radius then
			return
		end
		local a = math.pi / 2 - math.asin( radius / len )
		local vtr = Transform( VecAdd( transform.pos, VecScale( diff, -math.cos( a ) / len ) ),
		                       QuatRotateQuat( QuatLookAt( transform.pos, cam ), QuatEuler( 90, 0, 0 ) ) )
		visual.drawpolygon( vtr, radius * math.sin( a ), 0, points, info )
	end
end
