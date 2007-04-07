local unit = "pet"

local updatePet = function(self, unit)
	oUF:Print(unit)
	if(unit ~= "player") then return end

	oUF:Print(GetPetHappiness())
	self:updateInfoLevel"pet"
end

oUF.addUnit(function(self)
	local frame = self.class.unit:new(unit)
	
	frame:RegisterEvent("UNIT_PET", "updatePet")
	frame:RegisterEvent("UNIT_HAPPINESS", "updateInfoLevel")

	frame.updatePet = updatePet

	oUF.unit[unit] = frame
end)
