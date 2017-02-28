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

if select(2, UnitClass('player')) ~= 'MONK' then return end

local parent, ns = ...
local oUF = ns.oUF


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

	local cur = UnitStagger('player')
	local max = UnitHealthMax('player')
	local perc = cur / max

	element:SetMinMaxValues(0, max)
	element:SetValue(cur)

	local colors = self.colors.power[BREWMASTER_POWER_BAR_NAME]
	local t

	if(perc >= STAGGER_RED_TRANSITION) then
		t = colors and colors[STAGGER_RED_INDEX]
	elseif(perc > STAGGER_YELLOW_TRANSITION) then
		t = colors and colors[STAGGER_YELLOW_INDEX]
	else
		t = colors and colors[STAGGER_GREEN_INDEX]
	end

	local r, g, b
	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	if(b) then
		element:SetStatusBarColor(r, g, b)
	end

	local bg = element.bg
	if(bg and b) then
		local mu = bg.multiplier or 1
		bg:SetVertexColor(r * mu, g * mu, b * mu)
	end

	--[[ Callback: Stagger:PostUpdate(cur, max, perc, r, g, b)
	Called after the element has been updated.

	* self           - the Stagger element
	* cur            - the amount of staggered damage
	* max            - the player's maximum possible health value
	* perc           - the amount of staggered damage relative to the player's maximum health
	* r              - the red component of the StatusBar color (depends on perc)
	* g              - the green component of the StatusBar color (depends on perc)
	* b              - the blue component of the StatusBar color (depends on perc)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(cur, max, perc, r, g, b)
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
