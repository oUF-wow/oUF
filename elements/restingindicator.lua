--[[
# Element: Resting Indicator

Toggles visibility of the resting icon.

## Widget

RestingIndicator - Any UI widget.

## Notes

The default resting icon will be used if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local RestingIndicator = self:CreateTexture(nil, 'OVERLAY')
    RestingIndicator:SetSize(16, 16)
    RestingIndicator:SetPoint('TOPLEFT', self)

    -- Register it with oUF
    self.RestingIndicator = RestingIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.RestingIndicator

	--[[ Callback: RestingIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the RestingIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local isResting = IsResting()
	if(isResting) then
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: RestingIndicator:PostUpdate(isResting)
	Called after the element has been updated.

	* self      - the RestingIndicator element
	* isResting - a Boolean indicating if the player is resting
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(isResting)
	end
end

local function Path(self, ...)
	--[[ Override: RestingIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the RestingIndicator element
	* ...  - the event and the argument that accompany it
	--]]
	return (self.RestingIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.RestingIndicator
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('PLAYER_UPDATE_RESTING', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
			element:SetTexCoord(0, 0.5, 0, 0.421875)
		end

		return true
	end
end

local function Disable(self)
	local element = self.RestingIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('PLAYER_UPDATE_RESTING', Path)
	end
end

oUF:AddElement('RestingIndicator', Path, Enable, Disable)
