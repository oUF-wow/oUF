local type = type
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType
local power
local min, max, bar, color

if(select(4, GetBuildInfo()) >= 3e4) then
	power = PowerBarColor
else
	power = oUF.colors.power
end

function oUF:UNIT_MANA(event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdatePower) then self:PreUpdatePower(event, unit) end

	min, max = UnitMana(unit), UnitManaMax(unit)
	bar = self.Power
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	if(not self.OverrideUpdatePower) then
		-- TODO: Rewrite this block.
		color = power[UnitPowerType(unit)]
		bar:SetStatusBarColor(color.r, color.g, color.b)

		if(bar.bg) then
			bar.bg:SetVertexColor(color.r*.5, color.g*.5, color.b*.5)
		end
	else
		self:OverrideUpdatePower(event, unit, bar, min, max)
	end

	if(self.PostUpdatePower) then self:PostUpdatePower(event, unit, bar, min, max) end
end

oUF.UNIT_RAGE = oUF.UNIT_MANA
oUF.UNIT_FOCUS = oUF.UNIT_MANA
oUF.UNIT_ENERGY = oUF.UNIT_MANA
oUF.UNIT_MAXMANA = oUF.UNIT_MANA
oUF.UNIT_MAXRAGE = oUF.UNIT_MANA
oUF.UNIT_MAXFOCUS = oUF.UNIT_MANA
oUF.UNIT_MAXENERGY = oUF.UNIT_MANA
oUF.UNIT_DISPLAYPOWER = oUF.UNIT_MANA
oUF.UNIT_RUNIC_POWER = oUF.UNIT_MANA

table.insert(oUF.subTypes, function(self)
	if(self.Power) then
		self:RegisterEvent"UNIT_MANA"
		self:RegisterEvent"UNIT_RAGE"
		self:RegisterEvent"UNIT_FOCUS"
		self:RegisterEvent"UNIT_ENERGY"
		self:RegisterEvent"UNIT_MAXMANA"
		self:RegisterEvent"UNIT_MAXRAGE"
		self:RegisterEvent"UNIT_MAXFOCUS"
		self:RegisterEvent"UNIT_MAXENERGY"
		self:RegisterEvent"UNIT_DISPLAYPOWER"
		self:RegisterEvent"UNIT_RUNIC_POWER"
	end
end)
oUF:RegisterSubTypeMapping"UNIT_MANA"
