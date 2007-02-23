local unit = "pet"

oUF.addUnit(function(self)
	local frame = self.class.unit:new(unit)
	
	frame:RegisterEvent("UNIT_HAPPINESS", "updateInfoLevel")
	
	oUF.unit[unit] = frame
end)
