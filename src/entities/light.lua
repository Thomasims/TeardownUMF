----------------
-- Light class and related functions
-- @script entities.light
UMF_REQUIRE "/"

---@class light_handle: integer

---@class Light: Entity
---@field handle light_handle
---@field private _C table property contrainer (internal)
---@field enabled boolean (dynamic property)
---@field color Vector (dynamic property -- writeonly)
---@field intensity number (dynamic property -- writeonly)
---@field transform Transformation (dynamic property -- readonly)
---@field shape Shape (dynamic property -- readonly)
local light_meta = global_metatable( "light", "entity", true )

--- Tests if the parameter is a light entity.
---
---@param e any
---@return boolean
function IsLight( e )
	return IsEntity( e ) and e.type == "light"
end

--- Wraps the given handle with the light class.
---
---@param handle number
---@return Light?
function Light( handle )
	if handle > 0 then
		return instantiate_global_metatable( "light", { handle = handle, type = "light" } )
	end
end

--- Finds a light with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Light?
function FindLightByTag( tag, global )
	return Light( FindLight( tag, global ) )
end

--- Finds all lights with the specified tag.
--- `global` determines whether to only look in the script's hierarchy or the entire scene.
---
---@param tag string
---@param global boolean
---@return Light[]
function FindLightsByTag( tag, global )
	local t = FindLights( tag, global )
	for i = 1, #t do
		t[i] = Light( t[i] )
	end
	return t
end

---@type Light

---@param self Light
---@return string
function light_meta:__tostring()
	return string.format( "Light[%d]", self.handle )
end

--- Sets if the light is enabled.
---
---@param self Light
---@param enabled boolean
function light_meta:SetEnabled( enabled )
	assert( self:IsValid() )
	return SetLightEnabled( self.handle, enabled )
end

--- Sets the color of the light.
---
---@param self Light
---@param r number
---@param g number
---@param b number
function light_meta:SetColor( r, g, b )
	assert( self:IsValid() )
	return SetLightColor( self.handle, r, g, b )
end

--- Sets the intensity of the light.
---
---@param self Light
---@param intensity number
function light_meta:SetIntensity( intensity )
	assert( self:IsValid() )
	return SetLightIntensity( self.handle, intensity )
end

--- Gets the transform of the light.
---
---@param self Light
---@return Transformation
function light_meta:GetTransform()
	assert( self:IsValid() )
	return MakeTransformation( GetLightTransform( self.handle ) )
end

--- Gets the shape the light is attached to.
---
---@param self Light
---@return Shape
function light_meta:GetShape()
	assert( self:IsValid() )
	local shape = Shape( GetLightShape( self.handle ) )
	---@cast shape Shape
	return shape
end

--- Gets if the light is active.
---
---@param self Light
---@return boolean
function light_meta:IsActive()
	assert( self:IsValid() )
	return IsLightActive( self.handle )
end

--- Gets if the specified point is affected by the light.
---
---@param self Light
---@param point vector
---@return boolean
function light_meta:IsPointAffectedByLight( point )
	assert( self:IsValid() )
	return IsPointAffectedByLight( self.handle, point )
end

----------------
-- Properties implementation

---@param self Light
---@param setter boolean
---@param val boolean
---@return boolean?
function light_meta._C:enabled( setter, val )
	if setter then
		self:SetEnabled( val )
	else
		return self:IsActive()
	end
end

---@param self Light
---@param setter boolean
---@param val vector
function light_meta._C:color( setter, val )
	assert(setter, "cannot get color")
	return self:SetColor( val[1], val[2], val[3] )
end

---@param self Light
---@param setter boolean
---@param val number
function light_meta._C:intensity( setter, val )
	assert(setter, "cannot get intensity")
	return self:SetIntensity( val )
end

---@param self Light
---@param setter boolean
---@return Transformation
function light_meta._C:transform( setter )
	assert(not setter, "cannot set transform")
	return self:GetTransform()
end

---@param self Light
---@param setter boolean
---@return Shape
function light_meta._C:shape( setter )
	assert(not setter, "cannot set shape")
	return self:GetShape()
end
