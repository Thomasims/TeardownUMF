local entity_meta = global_metatable( "entity" )

function GetEntityHandle( e )
	if IsEntity( e ) then
		return e.handle
	end
	return e
end

function IsValid( e )
	if type( e ) == "table" and e.IsValid then
		return e:IsValid()
	end
	return false
end

function IsEntity( e )
	return type( e ) == "table" and type( e.handle ) == "number"
end

function Entity( handle )
	if handle > 0 then
		return setmetatable( { handle = handle, type = "unknown" }, entity_meta )
	end
end

function entity_meta:__unserialize( data )
	self.handle = tonumber( data )
	return self
end

function entity_meta:__serialize()
	return tostring( self.handle )
end

function entity_meta:__tostring()
	return string.format( "Entity[%d]", self.handle )
end

function entity_meta:GetType()
	return self.type
end

local IsHandleValid = IsHandleValid
function entity_meta:IsValid()
	return IsHandleValid( self.handle )
end

local SetTag = SetTag
function entity_meta:SetTag( tag, value )
	assert( self:IsValid() )
	return SetTag( self.handle, tag, value )
end

local RemoveTag = RemoveTag
function entity_meta:RemoveTag( tag )
	assert( self:IsValid() )
	return RemoveTag( self.handle, tag )
end

local HasTag = HasTag
function entity_meta:HasTag( tag )
	assert( self:IsValid() )
	return HasTag( self.handle, tag )
end

local GetTagValue = GetTagValue
function entity_meta:GetTagValue( tag )
	assert( self:IsValid() )
	return GetTagValue( self.handle, tag )
end

local GetDescription = GetDescription
function entity_meta:GetDescription()
	assert( self:IsValid() )
	return GetDescription( self.handle )
end

local Delete = Delete
function entity_meta:Delete()
	return Delete( self.handle )
end
