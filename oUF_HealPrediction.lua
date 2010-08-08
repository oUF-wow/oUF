local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_HealPrediction was unable to locate oUF install')

local function Update(self, event, unit)
	if self.unit ~= unit then return end

	local mhpb, ohpb = self.myHealPredictionBar, self.otherHealPredictionBar

	if mhpb and mhpb.PreUpdate then mhpb:PreUpdate(unit) end
	if ohpb and ohpb.PreUpdate then ohpb:PreUpdate(unit) end

	local myIncomingHeal = UnitGetIncomingHeals(unit, 'player') or 0
	local allIncomingHeal = UnitGetIncomingHeals(unit) or 0

	local health = self.Health:GetValue()
	local _, maxHealth = frame.Health:GetMinMaxValues()

	if(health + allIncomingHeal > maxHealth * self.maxHealPredictionOverflow) then
		allIncomingHeal = maxHealth * self.maxHealPredictionOverflow - health
	end

	if allIncomingHeal < myIncomingHeal then
		myIncomingHeal = allIncomingHeal
		allIncomingHeal = 0
	else
		allIncomingHeal = allIncomingHeal - myIncomingHeal
	end

	if mhpb then
		if event == 'UNIT_MAXHEALTH' then
			mhpb:SetMinMaxValues(0, maxHealth)
		end

		mhpb:SetValue(myIncomingHeal)
		mhpb:Show()

		if mhpb.PostUpdate then mhpb:PostUpdate(unit) end
	end

	if ohpb then
		if event == 'UNIT_MAXHEALTH' then
			ohpb:SetMinMaxValues(0, maxHealth)
		end

		ohpb:SetValue(allIncomingHeal)
		ohpb:Show()

		if ohpb.PostUpdate then ohpb:PostUpdate(unit) end
	end
end


local function Enable(self)
	local mhpb, ohpb = self.myHealPredictionBar, self.otherHealPredictionBar
	if not (mhpb or ohpb) then return end

	self:RegisterEvent('UNIT_HEAL_PREDICTION', Update)
	self:RegisterEvent('UNIT_MAXHEALTH', Update)
	self:RegisterEvent('UNIT_HEALTH', Update)

	if not self.maxHealPredictionOverflow then
		self.maxHealPredictionOverflow = 1.05
	end

	if mhpb and not mhpb:GetStatusBarTexture() then
		mhpb:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
	end
	if ohpb and not ohpb:GetStatusBarTexture() then
		ohpb:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
	end

	return true
end


local function Disable(self)
	local mhpb, ohpb = self.myHealPredictionBar, self.otherHealPredictionBar
	if(mhpb or ohpb) then
		self:UnregisterEvent('UNIT_HEAL_PREDICTION', Update)
		self:UnregisterEvent('UNIT_MAXHEALTH', Update)
		self:UnregisterEvent('UNIT_HEALTH', Update)
	end
end

oUF:AddElement('HealPrediction', Update, Enable, Disable)
