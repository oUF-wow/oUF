--[[
# Element: Health Bar

Handles updating of `self.Health` based on the units health.

## Widget

Health - A StatusBar used to represent current unit health.

## Sub-Widgets

.bg - A Texture which functions as a background. It will inherit the color of the main StatusBar.

## Notes

The default StatusBar texture will be applied if the UI widget doesn't have a status bar texture or color defined.

## Options

The following options are listed by priority. The first check that returns true decides the color of the bar.

.colorTapping      - Use `self.colors.tapping` to color the bar if the unit isn't tapped by the player.
.colorDisconnected - Use `self.colors.disconnected` to color the bar if the unit is offline.
.colorClass        - Use `self.colors.class[class]` to color the bar based on unit class. `class` is defined by the
                     second return of [UnitClass](http://wowprogramming.com/docs/api/UnitClass).
.colorClassNPC     - Use `self.colors.class[class]` to color the bar if the unit is a NPC.
.colorClassPet     - Use `self.colors.class[class]` to color the bar if the unit is player controlled, but not a player.
.colorReaction     - Use `self.colors.reaction[reaction]` to color the bar based on the player's reaction towards the
                     unit. `reaction` is defined by the return value of
                     [UnitReaction](http://wowprogramming.com/docs/api/UnitReaction).
.smoothGradient    - A table consisting of 9 color values to be used with the .colorSmooth option.
.colorSmooth       - Use `smoothGradient` if present or `self.colors.smooth` to color the bar with a smooth gradient
                     based on the player's current health percentage.
.colorHealth       - Use `self.colors.health` to color the bar. This flag is used to reset the bar color back to default
                     if none of the above conditions are met.

## Sub-Widgets Options

.multiplier - Defines a multiplier, which is used to tint the background based on the main widgets R, G and B values.
              Defaults to 1 if not present.

## Examples

    -- Position and size
    local Health = CreateFrame('StatusBar', nil, self)
    Health:SetHeight(20)
    Health:SetPoint('TOP')
    Health:SetPoint('LEFT')
    Health:SetPoint('RIGHT')

    -- Add a background
    local Background = Health:CreateTexture(nil, 'BACKGROUND')
    Background:SetAllPoints(Health)
    Background:SetTexture(1, 1, 1, .5)

    -- Options
    Health.frequentUpdates = true
    Health.colorTapping = true
    Health.colorDisconnected = true
    Health.colorClass = true
    Health.colorReaction = true
    Health.colorHealth = true

    -- Make the background darker.
    Background.multiplier = .5

    -- Register it with oUF
	Health.bg = Background
    self.Health = Health
--]]
local parent, ns = ...
local oUF = ns.oUF

oUF.colors.health = {49/255, 207/255, 37/255}

local function Update(self, event, unit)
	if(not unit or self.unit ~= unit) then return end
	local element = self.Health

	--[[ Callback: Health:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Health element
	* unit - the event unit that the update has been triggered for
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local disconnected = not UnitIsConnected(unit)
	element:SetMinMaxValues(0, max)

	if(disconnected) then
		element:SetValue(max)
	else
		element:SetValue(cur)
	end

	element.disconnected = disconnected

	local r, g, b, t
	if(element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
		t = self.colors.tapped
	elseif(element.colorDisconnected and disconnected) then
		t = self.colors.disconnected
	elseif(element.colorClass and UnitIsPlayer(unit)) or
		(element.colorClassNPC and not UnitIsPlayer(unit)) or
		(element.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		t = self.colors.class[class]
	elseif(element.colorReaction and UnitReaction(unit, 'player')) then
		t = self.colors.reaction[UnitReaction(unit, 'player')]
	elseif(element.colorSmooth) then
		r, g, b = self.ColorGradient(cur, max, unpack(element.smoothGradient or self.colors.smooth))
	elseif(element.colorHealth) then
		t = self.colors.health
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	if(r or g or b) then
		element:SetStatusBarColor(r, g, b)

		local bg = element.bg
		if(bg) then local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	--[[ Callback: Health:PostUpdate(unit, cur, max)
	Called after the element has been updated.

	* self - the Health element
	* unit - the event unit that the update has been triggered for
	* cur  - the current health value of the unit
	* max  - the maximum possible value of the unit
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, cur, max)
	end
end

local function Path(self, ...)
	--[[ Override: Health:Override(...)
	Used to completely override the internal update function.

	* self - the Health element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.Health.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.Health
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		if(element.frequentUpdates) then
			self:RegisterEvent('UNIT_HEALTH_FREQUENT', Path)
		else
			self:RegisterEvent('UNIT_HEALTH', Path)
		end

		self:RegisterEvent('UNIT_MAXHEALTH', Path)
		self:RegisterEvent('UNIT_CONNECTION', Path)

		-- For tapping.
		self:RegisterEvent('UNIT_FACTION', Path)

		if(element:IsObjectType('StatusBar') and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.Health
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_HEALTH_FREQUENT', Path)
		self:UnregisterEvent('UNIT_HEALTH', Path)
		self:UnregisterEvent('UNIT_MAXHEALTH', Path)
		self:UnregisterEvent('UNIT_CONNECTION', Path)
		self:UnregisterEvent('UNIT_FACTION', Path)
	end
end

oUF:AddElement('Health', Path, Enable, Disable)
