--[[
# Element: PingIndicator

Handles the visibility and updating of an indicator for a ping pin on the unit.

## Widget

PingIndicator - A `Texture` used to display the ping pin on a unit.

## Sub-Widgets

Background - A `Texture` used to display the ping pin background texture on a unit.

## Notes

This element updates by changing the texture.
The `Background` sub-widget has to be on a lower sub-layer than the `PingIndicator` texture.

## Options

.useAtlasSize - Makes the element use preprogrammed atlas' size instead of its set dimensions (boolean)

## Examples

    -- Position and size
    local PingIndicator = self:CreateTexture(nil, 'ARTWORK', nil, 1)
    PingIndicator:SetSize(32, 32)
    PingIndicator:SetPoint('CENTER', self)

    local Background = PingIndicator:CreateTexture(nil, 'ARTWORK')
    Background:SetSize(32, 32)
    Background:SetPoint('CENTER', PingIndicator)

    -- Register it with oUF
    PingIndicator.Background = Background
    self.PingIndicator = PingIndicator
--]]

local _, ns = ...
local oUF = ns.oUF

local function Update(self, event, unitGUID, textureKit)
	if(issecretvalue(unitGUID)) then
		return
	elseif(unitGUID ~= (self.unitGUID or UnitGUID(self.unit))) then
		return
	end

	local element = self.PingIndicator

	--[[ Callback: PingIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the PingIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	if(event == 'UNIT_PING_PIN_ADDED') then
		element:SetAtlas('Ping_Frame_' .. textureKit, element.useAtlasSize)

		if(element.Background) then
			element.Background:SetAtlas('Ping_Frame_BG_' .. textureKit, element.useAtlasSize)
		end

		element:Show()
	elseif(event == 'UNIT_PING_PIN_REMOVED') then
		element:Hide()
	end

	--[[ Callback: PingIndicator:PostUpdate(textureKit)
	Called after the element has been updated.

	* self       - the PingIndicator element
	* textureKit - the texture kit associated with the ping pin
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(textureKit)
	end
end

local function Path(self, ...)
	--[[ Override: PingIndicator.Override(self, event)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.PingIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.PingIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_PING_PIN_ADDED', Path, true)
		self:RegisterEvent('UNIT_PING_PIN_REMOVED', Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.PingIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_PING_PIN_ADDED', Path, true)
		self:UnregisterEvent('UNIT_PING_PIN_REMOVED', Path, true)
	end
end

oUF:AddElement('PingIndicator', Path, Enable, Disable)
