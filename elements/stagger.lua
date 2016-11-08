--[[
# Element: Monk Stagger Bar

Handles updating and visibility of the monk's stagger bar.

## Widget

Stagger - A StatusBar

## Sub-Widgets

.bg - A Texture that functions as a background. It will inherit the color of the main StatusBar.

## Notes

The default StatusBar texture will be applied if the UI widget doesn't have a status bar texture or color defined.

## Sub-Widgets Options

.multiplier - A Number used to tint the background based on the main widgets R, G and B values.
              Defaults to 1 if not present.

## Examples

    local Stagger = CreateFrame('StatusBar', nil, self)
    Stagger:SetSize(120, 20)
    Stagger:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, 0)

    -- Register with oUF
    self.Stagger = Stagger
--]]

local parent, ns = ...
local oUF = ns.oUF

-- percentages at which the bar should change color
local STAGGER_YELLOW_TRANSITION = STAGGER_YELLOW_TRANSITION
local STAGGER_RED_TRANSITION = STAGGER_RED_TRANSITION

-- table indices of bar colors
local STAGGER_GREEN_INDEX = STAGGER_GREEN_INDEX or 1
local STAGGER_YELLOW_INDEX = STAGGER_YELLOW_INDEX or 2
local STAGGER_RED_INDEX = STAGGER_RED_INDEX or 3

local UnitHealthMax = UnitHealthMax
local UnitStagger = UnitStagger

local playerClass = select(2, UnitClass('player'))

local function Update(self, event, unit)
	if(unit and unit ~= self.unit) then return end

	local element = self.Stagger

	--[[ Callback: Stagger:PreUpdate()
	Called before the element has been updated.

	* self - the Stagger element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local maxHealth = UnitHealthMax('player')
	local stagger = UnitStagger('player')
	local staggerPercent = stagger / maxHealth

	element:SetMinMaxValues(0, maxHealth)
	element:SetValue(stagger)

	local t
	local color = self.colors.power[BREWMASTER_POWER_BAR_NAME]
	if(staggerPercent >= STAGGER_RED_TRANSITION) then
		t = color[STAGGER_RED_INDEX]
	elseif(staggerPercent > STAGGER_YELLOW_TRANSITION) then
		t = color[STAGGER_YELLOW_INDEX]
	else
		t = color[STAGGER_GREEN_INDEX]
	end

	local r, g, b = unpack(t)
	element:SetStatusBarColor(r, g, b)

	local bg = element.bg
	if(bg) then
		local mu = bg.multiplier or 1
		bg:SetVertexColor(r * mu, g * mu, b * mu)
	end

	--[[ Callback: Stagger:PostUpdate(maxHealth, stagger, staggerPercent, r, g, b)
	Called after the element has been updated.

	* self           - the Stagger element
	* maxHealth      - the player's maximum possible health value
	* stagger        - the amount of staggered damage
	* staggerPercent - the amount of staggered damage relative to the player's maximum health
	* r              - the red component of the StatusBar color (depends on staggerPercent)
	* g              - the green component of the StatusBar color (depends on staggerPercent)
	* b              - the blue component of the StatusBar color (depends on staggerPercent)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(maxHealth, stagger, staggerPercent, r, g, b)
	end
end

local function Path(self, ...)
	--[[ Override: Stagger:Override(...)
	Used to completely override the internal update function.

	* self - the Stagger element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.Stagger.Override or Update)(self, ...)
end

local function Visibility(self, event, unit)
	if(SPEC_MONK_BREWMASTER ~= GetSpecialization() or UnitHasVehiclePlayerFrameUI('player')) then
		if(self.Stagger:IsShown()) then
			self.Stagger:Hide()
			self:UnregisterEvent('UNIT_AURA', Path)
		end
	else
		if(not self.Stagger:IsShown()) then
			self.Stagger:Show()
			self:RegisterEvent('UNIT_AURA', Path)
		end

		return Path(self, event, unit)
	end
end

local function VisibilityPath(self, ...)
	--[[ Override: Stagger:OverrideVisibility(...)
	Used to completely override the internal visibility toggling function.

	* self - the Stagger element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.Stagger.OverrideVisibility or Visibility)(self, ...)
end

local function ForceUpdate(element)
	return VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	if(playerClass ~= 'MONK') then return end

	local element = self.Stagger
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element:Hide()

		self:RegisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		self:RegisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath, true)

		if(element:IsObjectType('StatusBar') and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		MonkStaggerBar:UnregisterEvent('PLAYER_ENTERING_WORLD')
		MonkStaggerBar:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED')
		MonkStaggerBar:UnregisterEvent('UNIT_DISPLAYPOWER')
		MonkStaggerBar:UnregisterEvent('UPDATE_VEHICLE_ACTION_BAR')

		return true
	end
end

local function Disable(self)
	local element = self.Stagger
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_AURA', Path)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		self:UnregisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath)

		MonkStaggerBar:UnregisterEvent('PLAYER_ENTERING_WORLD')
		MonkStaggerBar:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED')
		MonkStaggerBar:UnregisterEvent('UNIT_DISPLAYPOWER')
		MonkStaggerBar:UnregisterEvent('UPDATE_VEHICLE_ACTION_BAR')
	end
end

oUF:AddElement('Stagger', VisibilityPath, Enable, Disable)
