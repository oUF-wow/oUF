--[[
# Element: Health Prediction Bars

Handle updating and visibility of the heal prediction status bars.

## Widget

HealthPrediction - A table containing references to sub-widgets and options.

## Sub-Widgets

myBar          - A StatusBar used to represent your incoming heals.
otherBar       - A StatusBar used to represent other peoples incoming heals.
absorbBar      - A StatusBar used to represent total absorbs.
healAbsorbBar  - A StatusBar used to represent heal absorbs.
overAbsorb     - A Texture used to signify that the amount of damage absorb is greater than the unit's missing health.
overHealAbsorb - A Texture used to signify that the amount of heal absorb is greater than the unit's current health.

## Notes

A default texture will be applied if the widget is a StatusBar and doesn't have a texture or color set.

## Options

.maxOverflow     - Defines the maximum amount of overflow past the end of the health bar. Set this to 1 to disable the
                   overflow. Defaults to 1.05.
.frequentUpdates - Update on UNIT_HEALTH_FREQUENT instead of UNIT_HEALTH. Use this if .frequentUpdates is also set on
                   the Health element.

## Examples

    -- Position and size
    local myBar = CreateFrame('StatusBar', nil, self.Health)
    myBar:SetPoint('TOP')
    myBar:SetPoint('BOTTOM')
    myBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
    myBar:SetWidth(200)

    local otherBar = CreateFrame('StatusBar', nil, self.Health)
    otherBar:SetPoint('TOP')
    otherBar:SetPoint('BOTTOM')
    otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
    otherBar:SetWidth(200)

    local absorbBar = CreateFrame('StatusBar', nil, self.Health)
    absorbBar:SetPoint('TOP')
    absorbBar:SetPoint('BOTTOM')
    absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')
    absorbBar:SetWidth(200)

    local healAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
    healAbsorbBar:SetPoint('TOP')
    healAbsorbBar:SetPoint('BOTTOM')
    healAbsorbBar:SetPoint('RIGHT', self.Health:GetStatusBarTexture())
    healAbsorbBar:SetWidth(200)
    healAbsorbBar:SetReverseFill(true)

    local overAbsorb = self.Health:CreateTexture(nil, "OVERLAY")
    overAbsorb:SetPoint('TOP')
    overAbsorb:SetPoint('BOTTOM')
    overAbsorb:SetPoint('LEFT', self.Health, 'RIGHT')
    overAbsorb:SetWidth(10)

	local overHealAbsorb = self.Health:CreateTexture(nil, "OVERLAY")
    overHealAbsorb:SetPoint('TOP')
    overHealAbsorb:SetPoint('BOTTOM')
    overHealAbsorb:SetPoint('RIGHT', self.Health, 'LEFT')
    overHealAbsorb:SetWidth(10)

    -- Register with oUF
    self.HealthPrediction = {
        myBar = myBar,
        otherBar = otherBar,
        absorbBar = absorbBar,
        healAbsorbBar = healAbsorbBar,
        overAbsorb = overAbsorb,
        overHealAbsorb = overHealAbsorb,
        maxOverflow = 1.05,
        frequentUpdates = true,
    }
--]]

local _, ns = ...
local oUF = ns.oUF

local math_max = math.max

local function Update(self, event, unit)
	if(self.unit ~= unit) then return end

	local element = self.HealthPrediction
	--[[ Callback: HealthPrediction:PreUpdate(unit)
	Called before the element has been updated.

	* self - the HealthPrediction element
	* unit - the event unit that the update has been triggered for
	--]]
	if(element.PreUpdate) then element:PreUpdate(unit) end

	local myIncomingHeal = UnitGetIncomingHeals(unit, 'player') or 0
	local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
	local totalAbsorb = UnitGetTotalAbsorbs(unit) or 0
	local myCurrentHealAbsorb = UnitGetTotalHealAbsorbs(unit) or 0
	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)

	local overHealAbsorb = false
	if(health < myCurrentHealAbsorb) then
		overHealAbsorb = true
		myCurrentHealAbsorb = health
	end

	local overHealAmount = 0
	if(health - myCurrentHealAbsorb + allIncomingHeal > maxHealth * element.maxOverflow) then
		local newAllIncomingHeal = maxHealth * element.maxOverflow - health + myCurrentHealAbsorb
		overHealAmount = allIncomingHeal - newAllIncomingHeal
		allIncomingHeal = newAllIncomingHeal
	end

	local otherIncomingHeal = 0
	if(allIncomingHeal < myIncomingHeal) then
		myIncomingHeal = allIncomingHeal
	else
		otherIncomingHeal = allIncomingHeal - myIncomingHeal
	end

	local overAbsorb = false
	if(health - myCurrentHealAbsorb + allIncomingHeal + totalAbsorb >= maxHealth or health + totalAbsorb >= maxHealth) then
		if(totalAbsorb > 0) then
			overAbsorb = true
		end

		if(allIncomingHeal > myCurrentHealAbsorb) then
			totalAbsorb = math_max(0, maxHealth - (health - myCurrentHealAbsorb + allIncomingHeal))
		else
			totalAbsorb = math_max(0, maxHealth - health)
		end
	end

	if(myCurrentHealAbsorb > allIncomingHeal) then
		myCurrentHealAbsorb = myCurrentHealAbsorb - allIncomingHeal
	else
		myCurrentHealAbsorb = 0
	end

	if(element.myBar) then
		element.myBar:SetMinMaxValues(0, maxHealth)
		element.myBar:SetValue(myIncomingHeal)
		element.myBar:Show()
	end

	if(element.otherBar) then
		element.otherBar:SetMinMaxValues(0, maxHealth)
		element.otherBar:SetValue(otherIncomingHeal)
		element.otherBar:Show()
	end

	if(element.absorbBar) then
		element.absorbBar:SetMinMaxValues(0, maxHealth)
		element.absorbBar:SetValue(totalAbsorb)
		element.absorbBar:Show()
	end

	if(element.healAbsorbBar) then
		element.healAbsorbBar:SetMinMaxValues(0, maxHealth)
		element.healAbsorbBar:SetValue(myCurrentHealAbsorb)
		element.healAbsorbBar:Show()
	end

	if(element.overAbsorb) then
		if(overAbsorb) then
			element.overAbsorb:Show()
		else
			element.overAbsorb:Hide()
		end
	end

	if(element.overHealAbsorb) then
		if(overHealAbsorb) then
			element.overHealAbsorb:Show()
		else
			element.overHealAbsorb:Hide()
		end
	end

	--[[ Callback: HealthPrediction:PostUpdate(unit, overAbsorb, overHealAbsorb)
	Called after the element has been updated.

	* self           - the HealthPrediction element
	* unit           - the event unit that the updated has been triggered for
	* overAbsorb     - a Boolean indicating if the amount of damage absorb is higher than the unit's missing health
	* overHealAbsorb - a Boolean indicating if the amount of heal absorb is bigger than the unit's current health
	* overHealAmount - a Number representing the amount of overheal after the widget's .maxOverflow option and
	                   healabsorb effect have been taken into account
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, overAbsorb, overHealAbsorb, overHealAmount)
	end
end

local function Path(self, ...)
	--[[ Override: HealthPrediction.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update
	* unit  - the unit accompanying the event
	--]]
	return (self.HealthPrediction.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.HealthPrediction
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:RegisterEvent('UNIT_MAXHEALTH', Path)

		if(element.frequentUpdates) then
			self:RegisterEvent('UNIT_HEALTH_FREQUENT', Path)
		else
			self:RegisterEvent('UNIT_HEALTH', Path)
		end
		self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
		self:RegisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)

		if(not element.maxOverflow) then
			element.maxOverflow = 1.05
		end

		if(element.myBar) then
			if(element.myBar:IsObjectType('StatusBar') and not element.myBar:GetStatusBarTexture()) then
				element.myBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end

			element.myBar:Show()
		end
		if(element.otherBar) then
			if(element.otherBar:IsObjectType('StatusBar') and not element.otherBar:GetStatusBarTexture()) then
				element.otherBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end

			element.otherBar:Show()
		end
		if(element.absorbBar) then
			if(element.absorbBar:IsObjectType('StatusBar') and not element.absorbBar:GetStatusBarTexture()) then
				element.absorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end

			element.absorbBar:Show()
		end
		if(element.healAbsorbBar) then
			if(element.healAbsorbBar:IsObjectType('StatusBar') and not element.healAbsorbBar:GetStatusBarTexture()) then
				element.healAbsorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end

			element.healAbsorbBar:Show()
		end
		if(element.overAbsorb) then
			if(element.overAbsorb:IsObjectType('Texture') and not element.overAbsorb:GetTexture()) then
				element.overAbsorb:SetTexture([[Interface\RaidFrame\Shield-Overshield]])
				element.overAbsorb:SetBlendMode('ADD')
			end
		end
		if(element.overHealAbsorb) then
			if(element.overHealAbsorb:IsObjectType('Texture') and not element.overHealAbsorb:GetTexture()) then
				element.overHealAbsorb:SetTexture([[Interface\RaidFrame\Absorb-Overabsorb]])
				element.overHealAbsorb:SetBlendMode('ADD')
			end
		end

		return true
	end
end

local function Disable(self)
	local element = self.HealthPrediction
	if(element) then
		if(element.myBar) then
			element.myBar:Hide()
		end
		if(element.otherBar) then
			element.otherBar:Hide()
		end
		if(element.absorbBar) then
			element.absorbBar:Hide()
		end
		if(element.healAbsorbBar) then
			element.healAbsorbBar:Hide()
		end
		if(element.overAbsorb) then
			element.overAbsorb:Hide()
		end
		if(element.overHealAbsorb) then
			element.overHealAbsorb:Hide()
		end

		self:UnregisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:UnregisterEvent('UNIT_MAXHEALTH', Path)
		self:UnregisterEvent('UNIT_HEALTH', Path)
		self:UnregisterEvent('UNIT_HEALTH_FREQUENT', Path)
		self:UnregisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
		self:UnregisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)
	end
end

oUF:AddElement('HealthPrediction', Path, Enable, Disable)
