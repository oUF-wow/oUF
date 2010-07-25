local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_HealPrediction was unable to locate oUF install')

local function Update(self)
	local mhpb, ohpb = self.myHealPredictionBar, self.otherHealPredictionBar

	if(not self.displayHealPrediction) then
		if mhpb then mhpb:Hide() end
		if ohpb then ohpb:Hide() end
		return
	end

	local myIncomingHeal = UnitGetIncomingHeals(self.unit, 'player') or 0
	local allIncomingHeal = UnitGetIncomingHeals(self.unit) or 0

	local health = self.Health:GetValue()
	local _, maxHealth = frame.Health:GetMinMaxValues()

	if(health + allIncomingHeal > maxHealth * self.maxHealPredictionOverflow) then
		allIncomingHeal = maxHealth * self.maxHealPredictionOverflow - health
	end

	if(allIncomingHeal < myIncomingHeal) then
		myIncomingHeal = allIncomingHeal
		allIncomingHeal = 0
	else
		allIncomingHeal = allIncomingHeal - myIncomingHeal
	end

	if mhpb then
		mhpb:SetValue(myIncomingHeal)
		mhpb:Show()
	end

	if ohpb then
		ohpb:SetValue(allIncomingHeal)
		ohpb:Show()
	end
end


local function adjustMinMax(self)
	local maxHealth = UnitHealthMax(self.unit)
	self.myHealPredictionBar:SetMinMaxValues(0, maxHealth)
	self.otherHealPredictionBar:SetMinMaxValues(0, maxHealth)

	-- update the incoming heal values as well
	update(self)
end


local function Enable(self)
	local mhpb, ohpb = self.myHealPredictionBar, self.otherHealPredictionBar
	if not (mhpb or ohpb) then return end

	self:RegisterEvent('UNIT_HEAL_PREDICTION', Update)
	self:RegisterEvent('UNIT_MAXHEALTH', adjustMinMax)
	self:RegisterEvent('UNIT_HEALTH', Update)

	if not self.maxHealPredictionOverflow then
		self.maxHealPredictionOverflow = 1.05
	end

	if not mhpb:GetStatusBarTexture() then
		mhpb:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
	end
	if not ohpb:GetStatusBarTexture() then
		ohpb:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
	end

	return true
end


local function Disable(self)
	local mhpb, ohpb = self.myHealPredictionBar, self.otherHealPredictionBar
	if(mhpb or ohpb) then
		self:UnregisterEvent('UNIT_HEAL_PREDICTION', Update)
		self:UnregisterEvent('UNIT_MAXHEALTH', adjustMinMax)
		self:UnregisterEvent('UNIT_HEALTH', Update)
	end
end

oUF:AddElement('HealPrediction', Update, Enable, Disable)
