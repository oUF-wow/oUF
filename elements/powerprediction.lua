--[[
# Element: Power Prediction Bar

Handles updating and visibility of power prediction status bars.

## Widget

PowerPrediction - A table containing `mainBar` and `altBar`.

## Sub-Widgets

mainBar - A StatusBar used to represent power cost of spells for the Power element.
altBar  - A StatusBar used to represent power cost of spells for the AdditionalPower element.

## Notes

A default texture will be applied if the widget is a StatusBar and doesn't have a texture or color set.

## Examples

    -- Position and size
    local mainBar = CreateFrame('StatusBar', nil, self.Power)
    mainBar:SetReverseFill(true)
    mainBar:SetPoint('TOP')
    mainBar:SetPoint('BOTTOM')
    mainBar:SetPoint('RIGHT', self.Power:GetStatusBarTexture(), 'RIGHT')
    mainBar:SetWidth(200)

    local altBar = CreateFrame('StatusBar', nil, self.AdditionalPower)
    altBar:SetReverseFill(true)
    altBar:SetPoint('TOP')
    altBar:SetPoint('BOTTOM')
    altBar:SetPoint('RIGHT', self.AdditionalPower:GetStatusBarTexture(), 'RIGHT')
    altBar:SetWidth(200)

    -- Register with oUF
    self.PowerPrediction = {
        mainBar = mainBar,
        altBar = altBar
    }
--]]

local _, ns = ...
local oUF = ns.oUF

-- sourced from FrameXML/AlternatePowerBar.lua
local ADDITIONAL_POWER_BAR_INDEX = ADDITIONAL_POWER_BAR_INDEX or 0
local ALT_MANA_BAR_PAIR_DISPLAY_INFO = ALT_MANA_BAR_PAIR_DISPLAY_INFO

local playerClass = select(2, UnitClass('player'))

local function Update(self, event, unit)
	if(self.unit ~= unit) then return end

	local element = self.PowerPrediction

	--[[ Callback: PowerPrediction:PreUpdate(unit)
	Called before the element has been updated.

	* self - the PowerPrediction element
	* unit - the event unit that the update has been triggered for
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local _, _, _, _, startTime, endTime, _, _, _, spellID = UnitCastingInfo(unit)
	local mainPowerType = UnitPowerType(unit)
	local hasAltManaBar = ALT_MANA_BAR_PAIR_DISPLAY_INFO[playerClass] and ALT_MANA_BAR_PAIR_DISPLAY_INFO[playerClass][mainPowerType]
	local mainCost, altCost = 0, 0

	if(event == 'UNIT_SPELLCAST_START' or startTime ~= endTime) then
		local costTable = GetSpellPowerCost(spellID)

		for _, costInfo in pairs(costTable) do
			-- costInfo content:
			-- - name: string (powerToken)
			-- - type: number (powerType)
			-- - cost: number
			-- - costPercent: number
			-- - costPerSec: number
			-- - minCost: number
			-- - hasRequiredAura: boolean
			-- - requiredAuraID: number
			if(costInfo.type == mainPowerType) then
				mainCost = costInfo.cost

				break
			elseif(costInfo.type == ADDITIONAL_POWER_BAR_INDEX) then
				altCost = costInfo.cost

				break
			end
		end
	end

	if(element.mainBar) then
		element.mainBar:SetMinMaxValues(0, UnitPowerMax(unit, mainPowerType))
		element.mainBar:SetValue(mainCost)
		element.mainBar:Show()
	end

	if(element.altBar and hasAltManaBar) then
		element.altBar:SetMinMaxValues(0, UnitPowerMax(unit, ADDITIONAL_POWER_BAR_INDEX))
		element.altBar:SetValue(altCost)
		element.altBar:Show()
	end

	--[[ Callback: PowerPrediction:PostUpdate(unit, mainCost, altCost, hasAltManaBar)
	Called after the element has been updated.

	* self          - the PowerPrediction element
	* unit          - the event unit that the update has been triggered for
	* mainCost      - a Number representing the main power type cost of the cast ability
	* altCost       - a Number representing the secondary power type cost of the cast ability
	* hasAltManaBar - a Boolean indicating if the unit has a secondary power bar
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, mainCost, altCost, hasAltManaBar)
	end
end

local function Path(self, ...)
	--[[ Override: PowerPrediction.Override(self, event, unit, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update
	* unit  - the unit accompanying the event
	* ...   - the arguments accompanying the event
	--]]
	return (self.PowerPrediction.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.PowerPrediction
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_SPELLCAST_START', Path)
		self:RegisterEvent('UNIT_SPELLCAST_STOP', Path)
		self:RegisterEvent('UNIT_SPELLCAST_FAILED', Path)
		self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED', Path)
		self:RegisterEvent('UNIT_DISPLAYPOWER', Path)

		if(element.mainBar) then
			if(element.mainBar:IsObjectType('StatusBar') and not element.mainBar:GetStatusBarTexture()) then
				element.mainBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.altBar) then
			if(element.altBar:IsObjectType('StatusBar') and not element.altBar:GetStatusBarTexture()) then
				element.altBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		return true
	end
end

local function Disable(self)
	local element = self.PowerPrediction
	if(element) then
		if(element.mainBar) then
			element.mainBar:Hide()
		end

		if(element.altBar) then
			element.altBar:Hide()
		end

		self:UnregisterEvent('UNIT_SPELLCAST_START', Path)
		self:UnregisterEvent('UNIT_SPELLCAST_STOP', Path)
		self:UnregisterEvent('UNIT_SPELLCAST_FAILED', Path)
		self:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED', Path)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
	end
end

oUF:AddElement('PowerPrediction', Path, Enable, Disable)
