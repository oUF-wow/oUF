local unit = "player"

local updateCombat = function(self)
	if(UnitAffectingCombat"player") then
		self:SetBackdropBorderColor(.8, .3, .22)
	elseif(IsResting()) then
		self:SetBackdropBorderColor(.6, .6, 1)
	else
		self:SetBackdropBorderColor(.3, .3, .3)
	end
end

local disableBlizzard = function()
	PlayerFrame:UnregisterAllEvents()
	PlayerFrame:Hide()
end

oUF.addUnit(function(self)
	local frame = self.class.unit:new(unit)
	oUF.unit[unit] = frame

	disableBlizzard()

	frame.updateCombat = updateCombat

	frame:RegisterEvent("PLAYER_REGEN_ENABLED", "updateCombat")
	frame:RegisterEvent("PLAYER_REGEN_DISABLED", "updateCombat")
	frame:RegisterEvent("PLAYER_UPDATE_RESTING", "updateCombat")
end)
