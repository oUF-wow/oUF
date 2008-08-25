local wotlk = select(4, GetBuildInfo()) >= 3e4

local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType
local min, max, bar

local OnPowerUpdate
do
	local UnitMana = UnitMana
	OnPowerUpdate = function(self)
		if(self.disconnected) then return end
		local power = UnitMana('player')

		if(power ~= self.min) then
			self:SetValue(power)
			self.min = power

			self:GetParent():UNIT_MANA("OnPowerUpdate", 'player')
		end
	end
end

function oUF:UNIT_MAXMANA(event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdatePower) then self:PreUpdatePower(event, unit) end

	min, max = UnitMana(unit), UnitManaMax(unit)
	bar = self.Power
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)
	bar.disconnected = not UnitIsConnected(unit)

	if(not self.OverrideUpdatePower) then
		local r, g, b, t
		if(bar.colorTapping and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
			t = self.colors.tapped
		elseif(bar.colorDisconnected and not UnitIsConnected(unit)) then
			t = self.colors.disconnected
		elseif(bar.colorHappiness and unit == "pet" and GetPetHappiness()) then
			t = self.colors.happiness[GetPetHappiness()]
		elseif(bar.colorPower) then
			local _, ptype
			if(wotlk) then
				_, ptype = UnitPowerType(unit)
			else
				ptype = UnitPowerType(unit)
			end

			t = self.colors.power[ptype]
		elseif(bar.colorClass and UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			t = self.colors.class[class]
		elseif(bar.colorReaction) then
			t = self.colors.reaction[UnitReaction(unit, "player")]
		elseif(bar.colorSmooth) then
			r, g, b = self.ColorGradient(min / max, unpack(bar.smoothGradient or self.colors.smooth))
		end

		if(t) then
			r, g, b = t[1], t[2], t[3]
		end

		if(r and g and b) then
			bar:SetStatusBarColor(r, g, b)

			if(bar.bg) then
				bar.bg:SetVertexColor(r, g, b)
			end
		end
	else
		self:OverrideUpdatePower(event, unit, bar, min, max)
	end

	if(self.PostUpdatePower) then self:PostUpdatePower(event, unit, bar, min, max) end
end

oUF.UNIT_MANA = oUF.UNIT_MAXMANA
oUF.UNIT_RAGE = oUF.UNIT_MAXMANA
oUF.UNIT_FOCUS = oUF.UNIT_MAXMANA
oUF.UNIT_ENERGY = oUF.UNIT_MAXMANA
oUF.UNIT_MAXRAGE = oUF.UNIT_MAXMANA
oUF.UNIT_MAXFOCUS = oUF.UNIT_MAXMANA
oUF.UNIT_MAXENERGY = oUF.UNIT_MAXMANA
oUF.UNIT_DISPLAYPOWER = oUF.UNIT_MAXMANA
oUF.UNIT_RUNIC_POWER = oUF.UNIT_MAXMANA
oUF.UNIT_MAXRUNIC_POWER = oUF.UNIT_MAXMANA

table.insert(oUF.subTypes, function(self, unit)
	if(self.Power) then
		if(self.Power.frequentUpdates and unit == 'player') then
			self.Power:SetScript("OnUpdate", OnPowerUpdate)
		else
			self:RegisterEvent"UNIT_MANA"
			self:RegisterEvent"UNIT_RAGE"
			self:RegisterEvent"UNIT_FOCUS"
			self:RegisterEvent"UNIT_ENERGY"
			self:RegisterEvent"UNIT_RUNIC_POWER"
		end
		self:RegisterEvent"UNIT_MAXMANA"
		self:RegisterEvent"UNIT_MAXRAGE"
		self:RegisterEvent"UNIT_MAXFOCUS"
		self:RegisterEvent"UNIT_MAXENERGY"
		self:RegisterEvent"UNIT_DISPLAYPOWER"
		self:RegisterEvent"UNIT_MAXRUNIC_POWER"

		self:RegisterEvent'UNIT_HAPPINESS'
		-- For tapping.
		self:RegisterEvent'UNIT_FACTION'
	end
end)
oUF:RegisterSubTypeMapping"UNIT_MANA"
