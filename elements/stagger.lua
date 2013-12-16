--[[ Element: Monk Stagger Bar

 Handles updating and visibility of the monk's stagger bar.

 Widget

 Stagger - A StatusBar

 Sub-Widgets

 .bg - A Texture that functions as a background. It will inherit the color
       of the main StatusBar.

 Notes

 The default StatusBar texture will be applied if the UI widget doesn't have a
 status bar texture or color defined.

 In order to override the internal update define the 'OnUpdate' script on the
 widget in the layout

 Options

 .throttle - A value in seconds used to throttle the OnUpdate script that handles
             updating the widget. Defaults to 0.5 if not present.

 Sub-Widgets Options

 .multiplier - Defines a multiplier, which is used to tint the background based
               on the main widgets R, G and B values. Defaults to 1 if not
               present.

 Examples

   local Stagger = CreateFrame('StatusBar', nil, self)
   Stagger:SetSize(120, 20)
   Stagger:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, 0)

   -- Register with oUF
   self.Stagger = Stagger

 Hooks

 Override(self) - Used to completely override the internal visibility function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

-- percentages at which the bar should change color
local STAGGER_YELLOW_TRANSITION = STAGGER_YELLOW_TRANSITION
local STAGGER_RED_TRANSITION = STAGGER_RED_TRANSITION

-- table indices of bar colors
local GREEN_INDEX = 1;
local YELLOW_INDEX = 2;
local RED_INDEX = 3;

local UnitHealthMax = UnitHealthMax
local UnitStagger = UnitStagger

local _, playerClass = UnitClass("player")

-- TODO: fix color in the power element
oUF.colors.power[BREWMASTER_POWER_BAR_NAME] = {
	{0.52, 1.0, 0.52},
	{1.0, 0.98, 0.72},
	{1.0, 0.42, 0.42},
}
local color

local Update = function(element, elapsed)
	element.elapsed = element.elapsed - elapsed
	if(element.elapsed > 0) then return end

	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local maxHealth = UnitHealthMax("player")
	local stagger = UnitStagger("player")
	local staggerPercent = stagger / maxHealth

	element:SetMinMaxValues(0, maxHealth)
	element:SetValue(stagger)

	local rgb
	if(staggerPercent >= STAGGER_RED_TRANSITION) then
		rgb = color[RED_INDEX]
	elseif(staggerPercent > STAGGER_YELLOW_TRANSITION) then
		rgb = color[YELLOW_INDEX]
	else
		rgb = color[GREEN_INDEX]
	end

	local r, g, b = rgb[1], rgb[2], rgb[3]
	element:SetStatusBarColor(r, g, b)

	local bg = element.bg
	if(bg) then
		local mu = bg.multiplier or 1
		bg:SetVertexColor(r * mu, g * mu, b * mu)
	end

	if(element.PostUpdate) then
		element:PostUpdate(maxHealth, stagger, staggerPercent, r, g, b)
	end

	element.elapsed = element.throttle or 0.5
end

local Visibility = function(self, event, unit)
	if(SPEC_MONK_BREWMASTER ~= GetSpecialization() or UnitHasVehiclePlayerFrameUI("player")) then
		self.Stagger:Hide()
	else
		self.Stagger:Show()
	end
end

local Path = function(self, ...)
	return (self.Stagger.Override or Visibility)(self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local Enable = function(self, unit)
	if(playerClass ~= "MONK") then return end

	local element = self.Stagger
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		color = self.colors.power[BREWMASTER_POWER_BAR_NAME]

		self:RegisterEvent('UNIT_DISPLAYPOWER', Path)
		self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', Path)

		if(not element:GetScript('OnUpdate')) then
			element:SetScript('OnUpdate', Update)
		end

		element.elapsed = element.throttle or 0.5

		if(element:IsObjectType'StatusBar' and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture[[Interface\TargetingFrame\UI-StatusBar]]
		end

		MonkStaggerBar.Show = MonkStaggerBar.Hide
		MonkStaggerBar:UnregisterEvent'PLAYER_ENTERING_WORLD'
		MonkStaggerBar:UnregisterEvent'PLAYER_SPECIALIZATION_CHANGED'
		MonkStaggerBar:UnregisterEvent'UNIT_DISPLAYPOWER'
		MonkStaggerBar:UnregisterEvent'UPDATE_VEHICLE_ACTION_BAR'

		return true
	end
end

local Disable = function(self)
	local element = self.Stagger
	if(element) then
		element:Hide()
		element:SetScript('OnUpdate', nil)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
		self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED', Path)

		MonkStaggerBar.Show = nil
		MonkStaggerBar:Show()
		MonkStaggerBar:UnregisterEvent'PLAYER_ENTERING_WORLD'
		MonkStaggerBar:UnregisterEvent'PLAYER_SPECIALIZATION_CHANGED'
		MonkStaggerBar:UnregisterEvent'UNIT_DISPLAYPOWER'
		MonkStaggerBar:UnregisterEvent'UPDATE_VEHICLE_ACTION_BAR'
	end
end

oUF:AddElement("Stagger", Path, Enable, Disable)