--[[
# Element: Alternative Power Bar

Handles visibility and updating of the alternative power bar.
This bar is used to display encounter/quest related power information, such as the number of hour glass uses left on the
end boss in End Time.

## Widget

AlternativePower - A StatusBar to represent alternative power.

## Options

.colorTexture - Use the vertex color values returned by UnitAlternatePowerTextureInfo to color the bar.

## Notes

`OnEnter` and `OnLeave` handlers to display a tooltip will be set on the widget if it is mouse enabled.

## Examples

    -- Position and size
    local AlternativePower = CreateFrame('StatusBar', nil, self)
    AlternativePower:SetHeight(20)
    AlternativePower:SetPoint('BOTTOM')
    AlternativePower:SetPoint('LEFT')
    AlternativePower:SetPoint('RIGHT')

    -- Register with oUF
    self.AlternativePower = AlternativePower
--]]

local parent, ns = ...
local oUF = ns.oUF

local ALTERNATE_POWER_INDEX = ALTERNATE_POWER_INDEX

local function updateTooltip(self)
	GameTooltip:SetText(self.powerName, 1, 1, 1)
	GameTooltip:AddLine(self.powerTooltip, nil, nil, nil, 1)
	GameTooltip:Show()
end

local function onEnter(self)
	if(not self:IsVisible()) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	self:UpdateTooltip()
end

local function onLeave()
	GameTooltip:Hide()
end

local function UpdatePower(self, event, unit, powerType)
	if(self.unit ~= unit or powerType ~= 'ALTERNATE') then return end

	local element = self.AlternativePower

	--[[ Callback: AlternativePower:PreUpdate()
	Called before the element has been updated.

	* self - the AlternativePower element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local _, r, g, b
	if(element.colorTexture) then
		_, r, g, b = UnitAlternatePowerTextureInfo(unit, 2)
	end

	local cur = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)

	local barType, min, _, _, _, _, _, _, _, _, powerName, powerTooltip = UnitAlternatePowerInfo(unit)
	element.barType = barType
	element.powerName = powerName
	element.powerTooltip = powerTooltip
	element:SetMinMaxValues(min, max)
	element:SetValue(math.min(math.max(cur, min), max))

	if(r or g or b) then
		element:SetStatusBarColor(r, g, b)
	end

	--[[ Callback: AlternativePower:PostUpdate(min, cur, max)
	Called after the element has been updated.

	* self - the AlternativePower element
	* min  - the minimum possible power value for the active type
	* cur  - the current power value
	* max  - the maximum possible power value for the active type
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(min, cur, max)
	end
end

local function Path(self, ...)
	--[[ Override: AlternativePower:Override(...)
	Used to completely override the internal update function.

	* self - the AlternativePower element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.AlternativePower.Override or UpdatePower)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'ALTERNATE')
end

local function Toggler(self, event, unit)
	if(unit ~= self.unit) then return end
	local element = self.AlternativePower

	local barType, _, _, _, _, hideFromOthers, showOnRaid = UnitAlternatePowerInfo(unit)
	if(barType and (showOnRaid and (UnitInParty(unit) or UnitInRaid(unit)) or not hideFromOthers or unit == 'player' or self.realUnit == 'player')) then
		self:RegisterEvent('UNIT_POWER', Path)
		self:RegisterEvent('UNIT_MAXPOWER', Path)

		ForceUpdate(element)
		element:Show()
	else
		self:UnregisterEvent('UNIT_POWER', Path)
		self:UnregisterEvent('UNIT_MAXPOWER', Path)

		element:Hide()
	end
end

local function Enable(self, unit)
	local element = self.AlternativePower
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER_BAR_SHOW', Toggler)
		self:RegisterEvent('UNIT_POWER_BAR_HIDE', Toggler)

		element:Hide()

		if(element:IsMouseEnabled()) then
			if(not element:GetScript('OnEnter')) then
				element:SetScript('OnEnter', onEnter)
			end

			if(not element:GetScript('OnLeave')) then
				element:SetScript('OnLeave', onLeave)
			end

			--[[ Override: AlternativePower:UpdateTooltip()
			Called when the widget is hovered. Used to populate the tooltip.

			* self - the AlternativePower element
			--]]
			if(not element.UpdateTooltip) then
				element.UpdateTooltip = updateTooltip
			end
		end

		if(unit == 'player') then
			PlayerPowerBarAlt:UnregisterEvent('UNIT_POWER_BAR_SHOW')
			PlayerPowerBarAlt:UnregisterEvent('UNIT_POWER_BAR_HIDE')
			PlayerPowerBarAlt:UnregisterEvent('PLAYER_ENTERING_WORLD')
		end

		return true
	end
end

local function Disable(self, unit)
	local element = self.AlternativePower
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_POWER_BAR_SHOW', Toggler)
		self:UnregisterEvent('UNIT_POWER_BAR_HIDE', Toggler)

		if(unit == 'player') then
			PlayerPowerBarAlt:RegisterEvent('UNIT_POWER_BAR_SHOW')
			PlayerPowerBarAlt:RegisterEvent('UNIT_POWER_BAR_HIDE')
			PlayerPowerBarAlt:RegisterEvent('PLAYER_ENTERING_WORLD')
		end
	end
end

oUF:AddElement('AlternativePower', Toggler, Enable, Disable)
