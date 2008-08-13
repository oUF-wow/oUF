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

			self:GetParent():UNIT_MANA("OnHealthUpdate", 'player')
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
		if(bar.colorType) then
			local _, ptype
			if(wotlk) then
				_, ptype = UnitPowerType(unit)
			else
				ptype = UnitPowerType(unit)
			end

			local t = self.colors.power[ptype]
			local r, g, b = t[1], t[2], t[3]
			bar:SetStatusBarColor(r, g, b)

			if(bar.bg) then
				bar.bg:SetVertexColor(r*.5, g*.5, b*.5)
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
	end
end)
oUF:RegisterSubTypeMapping"UNIT_MANA"
