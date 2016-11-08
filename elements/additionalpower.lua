--[[
# Element: Additional Power Bar

Handles updating and visibility of a status bar displaying the player's additional power, such as Mana for Balance
druids.

## Widget

AdditionalPower - A StatusBar to represent the player's current additional power.

## Sub-Widgets

.bg - A Texture, which functions as a background. It will inherit the color of the main StatusBar.

## Notes

The default StatusBar texture will be applied if the UI widget doesn't have a status bar texture or color defined.

## Options

.colorClass  - Use `self.colors.class[class]` to color the bar.
.colorSmooth - Use `self.colors.smooth` to color the bar with a smooth gradient based on the players current additional
               power percentage.
.colorPower  - Use `self.colors.power[token]` to color the bar. This will always use MANA as token.

## Sub-Widget Options

.multiplier - Defines a multiplier that is used to tint the background based on the main widgets R, G and B values.
              Defaults to 1 if not present.

## Examples

    -- Position and size
    local AdditionalPower = CreateFrame('StatusBar', nil, self)
    AdditionalPower:SetSize(20, 20)
    AdditionalPower:SetPoint('TOP')
    AdditionalPower:SetPoint('LEFT')
    AdditionalPower:SetPoint('RIGHT')

    -- Add a background
    local Background = AdditionalPower:CreateTexture(nil, 'BACKGROUND')
    Background:SetAllPoints(AdditionalPower)
    Background:SetTexture(1, 1, 1, .5)

    -- Register it with oUF
	AdditionalPower.bg = Background
    self.AdditionalPower = AdditionalPower
--]]

local _, ns = ...
local oUF = ns.oUF

local playerClass = select(2, UnitClass('player'))

local ADDITIONAL_POWER_BAR_NAME = ADDITIONAL_POWER_BAR_NAME
local ADDITIONAL_POWER_BAR_INDEX = ADDITIONAL_POWER_BAR_INDEX

local function Update(self, event, unit, powertype)
	if(unit ~= 'player' or (powertype and powertype ~= ADDITIONAL_POWER_BAR_NAME)) then return end

	local element = self.AdditionalPower
	--[[ Callback: AdditionalPower:PreUpdate(unit)
	Called before the element has been updated.

	* self - the AdditionalPower element
	* unit - the event unit that the update has been triggered for
	--]]
	if(element.PreUpdate) then element:PreUpdate(unit) end

	local cur = UnitPower('player', ADDITIONAL_POWER_BAR_INDEX)
	local max = UnitPowerMax('player', ADDITIONAL_POWER_BAR_INDEX)
	element:SetMinMaxValues(0, max)
	element:SetValue(cur)

	local r, g, b, t
	if(element.colorClass) then
		t = self.colors.class[playerClass]
	elseif(element.colorSmooth) then
		r, g, b = self.ColorGradient(cur, max, unpack(element.smoothGradient or self.colors.smooth))
	elseif(element.colorPower) then
		t = self.colors.power[ADDITIONAL_POWER_BAR_NAME]
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	if(r or g or b) then
		element:SetStatusBarColor(r, g, b)

		local bg = element.bg
		if(bg) then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	--[[ Callback: AdditionalPower:PostUpdate(unit, cur, max)
	Called after the element has been updated.

	* self - the AdditionalPower element
	* unit - the event unit that the update has been triggered for
	* cur  - the current value of the player's additional power
	* max  - the maximum possible value of the player's additional power
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, cur, max)
	end
end

local function Path(self, ...)
	--[[ Override: AdditionalPower:Override(...)
	Used to completely override the internal update function.

	* self - the AdditionalPower element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.AdditionalPower.Override or Update) (self, ...)
end

local function ElementEnable(self)
	self:RegisterEvent('UNIT_POWER_FREQUENT', Path)
	self:RegisterEvent('UNIT_DISPLAYPOWER', Path)
	self:RegisterEvent('UNIT_MAXPOWER', Path)

	self.AdditionalPower:Show()

	Path(self, 'ElementEnable', 'player', ADDITIONAL_POWER_BAR_NAME)
end

local function ElementDisable(self)
	self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
	self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
	self:UnregisterEvent('UNIT_MAXPOWER', Path)

	self.AdditionalPower:Hide()

	Path(self, 'ElementDisable', 'player', ADDITIONAL_POWER_BAR_NAME)
end

local function Visibility(self, event, unit)
	local shouldEnable

	if(not UnitHasVehicleUI('player')) then
		if(UnitPowerMax(unit, ADDITIONAL_POWER_BAR_INDEX) ~= 0) then
			if(ALT_MANA_BAR_PAIR_DISPLAY_INFO[playerClass]) then
				local powerType = UnitPowerType(unit)
				shouldEnable = ALT_MANA_BAR_PAIR_DISPLAY_INFO[playerClass][powerType]
			end
		end
	end

	if(shouldEnable) then
		ElementEnable(self)
	else
		ElementDisable(self)
	end
end

local function VisibilityPath(self, ...)
	--[[ Hook: AdditionalPower:OverrideVisibility(...)
	Used to completely override the internal function that toggles the element's visibility.

	* self - the AdditionalPower element
	* ...  - the event that has triggered the element's visibility change and the unit that the event has been fired for
	--]]
	return (self.AdditionalPower.OverrideVisibility or Visibility) (self, ...)
end

local function ForceUpdate(element)
	return VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.AdditionalPower
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)

		if(element:IsObjectType('StatusBar') and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.AdditionalPower
	if(element) then
		ElementDisable(self)

		self:UnregisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
	end
end

oUF:AddElement('AdditionalPower', VisibilityPath, Enable, Disable)
