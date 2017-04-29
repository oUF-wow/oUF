--[[
# Element: Runes

Handles visibility and updating of Death Knight's runes.

## Widget

Runes - An array holding StatusBar's.

## Sub-Widgets

.bg - A Texture which functions as a background. It will inherit the color of the main StatusBar.

## Notes

A default texture will be applied if the sub-widgets are StatusBars and doesn't have a texture or color set.

## Sub-Widgets Options

.multiplier - A Number used to tint the background based on the main widgets R, G and B values.
              Defaults to 1 if not present.

## Examples

    local Runes = {}
    for index = 1, 6 do
        -- Position and size of the rune bar indicators
        local Rune = CreateFrame('StatusBar', nil, self)
        Rune:SetSize(120 / 6, 20)
        Rune:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * 120 / 6, 0)

        Runes[index] = Rune
    end

    -- Register with oUF
    self.Runes = Runes
--]]

if(select(2, UnitClass('player')) ~= 'DEATHKNIGHT') then return end

local _, ns = ...
local oUF = ns.oUF

local function OnUpdate(self, elapsed)
	local duration = self.duration + elapsed
	self.duration = duration
	self:SetValue(duration)
end

local function Update(self, event, runeID, energized)
	local element = self.Runes
	local rune = element[runeID]
	if(not rune) then return end

	local start, duration, runeReady
	if(UnitHasVehicleUI('player')) then
		rune:Hide()
	else
		start, duration, runeReady = GetRuneCooldown(runeID)
		if(not start) then return end

		if(energized or runeReady) then
			rune:SetMinMaxValues(0, 1)
			rune:SetValue(1)
			rune:SetScript('OnUpdate', nil)
		else
			rune.duration = GetTime() - start
			rune.max = duration
			rune:SetMinMaxValues(1, duration)
			rune:SetScript('OnUpdate', OnUpdate)
		end

		rune:Show()
	end

	--[[ Callback: Runes:PostUpdate(rune, runeID, start, duration, isReady)
	Called after the element has been updated.

	* self     - the Runes element
	* rune     - the StatusBar representing the updated rune
	* runeID   - the index of the updated rune
	* start    - the value of `GetTime()` when the rune cooldown started (0 for ready or energized runes)
	* duration - the duration of the rune's cooldown
	* isReady  - a Boolean indicating if the rune is ready for use
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(rune, runeID, energized and 0 or start, duration, energized or runeReady)
	end
end

local function Path(self, event, ...)
	local element = self.Runes
	--[[ Override: Runes.Override(self, event, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update
	* ...   - the arguments accompanying the event
	--]]
	local UpdateMethod = element.Override or Update
	if(event == 'RUNE_POWER_UPDATE') then
		return UpdateMethod(self, event, ...)
	else
		for index = 1, #element do
			UpdateMethod(self, event, index)
		end
	end
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.Runes
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		for i = 1, #element do
			local rune = element[i]

			local r, g, b = unpack(self.colors.power.RUNES)
			if(rune:IsObjectType('StatusBar') and not rune:GetStatusBarTexture()) then
				rune:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
				rune:SetStatusBarColor(r, g, b)
			end

			if(rune.bg) then
				local mu = rune.bg.multiplier or 1
				rune.bg:SetVertexColor(r * mu, g * mu, b * mu)
			end
		end

		self:RegisterEvent('RUNE_POWER_UPDATE', Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.Runes
	if(element) then
		for i = 1, #element do
			element[i]:Hide()
		end

		self:UnregisterEvent('RUNE_POWER_UPDATE', Path)
	end
end

oUF:AddElement('Runes', Path, Enable, Disable)
