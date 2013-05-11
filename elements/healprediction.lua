--[[ Element: Heal Prediction
 Handle updating and visibility of the heal prediction and total absorb bars.

 Widget

 HealPrediction - A table containing `myBar`, `otherBar`, `absorbBar`
  and `overAbsorbGlow`

 Sub-Widgets

 myBar          - A Texture used to represent your incoming heals.
 otherBar       - A Texture used to represent other peoples incoming heals.
 absorbBar      - A Texture used to represent total absorbs.
 overAbsorbGlow - A Texture used to represent over absorbs.

 Notes

 A default texture will be applied if the UI widget doesn't have a texture defined.

 Options

 .maxOverflow - Defines the maximum amount of overflow past the end of the
                health bar.

 Examples

	local health = self.Health

	local myBar = health:CreateTexture(nil, 'OVERLAY')
	local otherBar = health:CreateTexture(nil, 'OVERLAY')
	local absorbBar = health:CreateTexture(nil, 'OVERLAY')
	local overAbsorbGlow = health:CreateTexture(nil, 'OVERLAY')

	-- Register with oUF
	self.HealPrediction = {
		myBar = myBar,
		otherBar = otherBar,
		absorbBar = absorbBar,
		overAbsorbGlow = overAbsorbGlow,
		maxOverflow = 1.05,
	}

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local _, ns = ...
local oUF = ns.oUF

local UpdateFillBar = function(frame, previousTexture, bar, amount, maxHealth)
	if(amount == 0) then
		bar:Hide()
		return previousTexture
	end

	bar:SetPoint('TOPLEFT', previousTexture, 'TOPRIGHT', 0, 0)
	bar:SetPoint('BOTTOMLEFT', previousTexture, 'BOTTOMRIGHT', 0, 0)

	local barWidth = (amount / maxHealth) * frame.Health:GetWidth()
	bar:SetWidth(barWidth)
	bar:Show()

	return bar
end

local Update = function(self, event, unit)
	if(self.unit ~= unit) then return end

	local hp = self.HealPrediction
	if(hp.PreUpdate) then hp:PreUpdate(unit) end

	local myIncomingHeal = UnitGetIncomingHeals(unit, 'player') or 0
	local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
	local totalAbsorb, overAbsorb

	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)

	if(health + allIncomingHeal > maxHealth * hp.maxOverflow) then
		allIncomingHeal = maxHealth * hp.maxOverflow - health
	end

	if(allIncomingHeal < myIncomingHeal) then
		myIncomingHeal = allIncomingHeal
		allIncomingHeal = 0
	else
		allIncomingHeal = allIncomingHeal - myIncomingHeal
	end

	if(hp.absorbBar) then
		totalAbsorb = UnitGetTotalAbsorbs(unit) or 0
		if(health + myIncomingHeal + allIncomingHeal + totalAbsorb >= maxHealth) then
			if(totalAbsorb > 0) then
				overAbsorb = true
			end
			totalAbsorb = max(0, maxHealth - (health + myIncomingHeal + allIncomingHeal))
		end
		if(hp.overAbsorbGlow) then
			if(overAbsorb) then
				hp.overAbsorbGlow:Show()
			else
				hp.overAbsorbGlow:Hide()
			end
		end
	end

	local previousTexture = self.Health:GetStatusBarTexture()

	if(hp.myBar) then
		previousTexture = UpdateFillBar(self, previousTexture, hp.myBar, myIncomingHeal, maxHealth)
	end

	if(hp.otherBar) then
		previousTexture = UpdateFillBar(self, previousTexture, hp.otherBar, allIncomingHeal, maxHealth)
	end

	if(hp.absorbBar) then
		previousTexture = UpdateFillBar(self, previousTexture, hp.absorbBar, totalAbsorb, maxHealth)
	end

	if(hp.PostUpdate) then
		return hp:PostUpdate(unit, myIncomingHeal, allIncomingHeal, totalAbsorb, overAbsorb)
	end
end

local Path = function(self, ...)
	return (self.HealPrediction.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local hp = self.HealPrediction
	if(hp) then
		hp.__owner = self
		hp.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:RegisterEvent('UNIT_MAXHEALTH', Path)
		self:RegisterEvent('UNIT_HEALTH', Path)

		if(not hp.maxOverflow) then
			hp.maxOverflow = 1.05
		end

		if(hp.myBar and hp.myBar:IsObjectType'Texture' and not hp.myBar:GetTexture()) then
			hp.myBar:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		if(hp.otherBar and hp.otherBar:IsObjectType'Texture' and not hp.otherBar:GetTexture()) then
			hp.otherBar:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		if(hp.absorbBar) then
			self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)

			if(hp.absorbBar:IsObjectType'Texture' and not hp.absorbBar:GetTexture()) then
				hp.absorbBar:SetTexture([[Interface\RaidFrame\Shield-Fill]])
			end

			if(hp.overAbsorbGlow) then
				local overAbsorbGlow = hp.overAbsorbGlow
				if(overAbsorbGlow:IsObjectType'Texture' and not overAbsorbGlow:GetTexture()) then
					overAbsorbGlow:SetTexture([[Interface\RaidFrame\Shield-Overshield]])
					overAbsorbGlow:SetBlendMode('ADD')
					if(not overAbsorbGlow:GetPoint()) then
						overAbsorbGlow:SetPoint("TOP")
						overAbsorbGlow:SetPoint("BOTTOM")
						overAbsorbGlow:SetPoint("LEFT", self.Health, "RIGHT", -7, 0)
					end
				end
			end
		end

		return true
	end
end

local Disable = function(self)
	local hp = self.HealPrediction
	if(hp) then
		self:UnregisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:UnregisterEvent('UNIT_MAXHEALTH', Path)
		self:UnregisterEvent('UNIT_HEALTH', Path)
		if(hp.absorbBar) then
			self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Path)
		end
	end
end

oUF:AddElement('HealPrediction', Path, Enable, Disable)
