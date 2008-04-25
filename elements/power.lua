local type = type
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType

local power = oUF.colors.power
local min, max, bar, color

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
		self:OverrideUpdatePower(event, bar, unit, min, max)
	end

	if(self.PostUpdatePower) then self:PostUpdatePower(event, bar, unit, min, max) end
end

oUF.UNIT_RAGE = oUF.UNIT_MANA
oUF.UNIT_FOCUS = oUF.UNIT_MANA
oUF.UNIT_ENERGY = oUF.UNIT_MANA
oUF.UNIT_MAXMANA = oUF.UNIT_MANA
oUF.UNIT_MAXRAGE = oUF.UNIT_MANA
oUF.UNIT_MAXFOCUS = oUF.UNIT_MANA
oUF.UNIT_MAXENERGY = oUF.UNIT_MANA
oUF.UNIT_DISPLAYPOWER = oUF.UNIT_MANA
