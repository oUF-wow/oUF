--[[
# Element: Combat Indicator

Toggles the visibility of `self.CombatIndicator` based on the player's combat status.

## Widget

CombatIndicator - Any UI widget.

## Notes

The default assistant icon will be applied if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local CombatIndicator = self:CreateTexture(nil, 'OVERLAY')
    CombatIndicator:SetSize(16, 16)
    CombatIndicator:SetPoint('TOP', self)

    -- Register it with oUF
    self.CombatIndicator = CombatIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.CombatIndicator

	--[[ Callback: CombatIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the CombatIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local inCombat = UnitAffectingCombat('player')
	if(inCombat) then
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: CombatIndicator:PostUpdate(inCombat)
	Called after the element has been updated.

	* self     - the CombatIndicator element
	* inCombat - a boolean indicating if the player is affectiong combat
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(inCombat)
	end
end

local function Path(self, ...)
	--[[ Override: CombatIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the CombatIndicator element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.CombatIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.CombatIndicator
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('PLAYER_REGEN_DISABLED', Path, true)
		self:RegisterEvent('PLAYER_REGEN_ENABLED', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
			element:SetTexCoord(.5, 1, 0, .49)
		end

		return true
	end
end

local function Disable(self)
	local element = self.CombatIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('PLAYER_REGEN_DISABLED', Path)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED', Path)
	end
end

oUF:AddElement('CombatIndicator', Path, Enable, Disable)
