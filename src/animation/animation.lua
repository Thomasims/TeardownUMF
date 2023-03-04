UMF_REQUIRE "util/meta.lua"

local animator_meta = global_metatable( "animator" )

function animator_meta:Update( dt )
	self.value = self._func( self._state, self._modifier * dt ) or self._state.value or 0
	return self.value
end

function animator_meta:Reset()
	self._state = {}
	if self._init then
		self._init( self._state )
	end
	self.value = self._state.value or 0
end

function animator_meta:SetModifier( num )
	self._modifier = num
end

function animator_meta:__newindex( k, v )
	self._state[k] = v
end

function animator_meta:__index( k )
	local v = animator_meta[k]
	if v then
		return v
	end
	return rawget( self, "_state" )[k]
end

Animator = {
	Base = function( easing )
		local t = instantiate_global_metatable( "animator", {
			_state = {},
			_func = type( easing ) == "table" and easing.update or easing,
			_init = type( easing ) == "table" and easing.init,
			_modifier = 1,
			value = 0,
		} )
		if t._init then
			t._init( t._state )
		end
		return t
	end,
}

Animator.LinearApproach = function( init, speed, down_speed )
	return Animator.Base {
		update = function( state, dt )
			if state.target < state.value then
				state.value = state.value + math.max( state.target - state.value, dt * state.down_speed )
			elseif state.target > state.value then
				state.value = state.value + math.min( state.target - state.value, dt * state.speed )
			end
		end,
		init = function( state )
			state.value = init
			state.speed = speed
			state.down_speed = down_speed or -speed
			state.target = init
		end,
	}
end

Animator.SpeedLinearApproach = function( init, acceleration, down_acceleration )
	return Animator.Base {
		update = function( state, dt )
			state.driver.target = state.target
			state.driver.speed = state.acceleration
			state.driver.down_speed = state.down_acceleration
			state.value = state.value + state.driver:Update( dt ) * dt
		end,
		init = function( state )
			state.driver = Animator.LinearApproach( init, acceleration )
			state.target = init
			state.acceleration = acceleration
			state.down_acceleration = down_acceleration
			state.value = 0
		end,
	}
end
