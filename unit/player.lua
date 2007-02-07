local unit = "player"

local registerEvent = function(event, handler)
	oUF:RegisterClassEvent(unit, event, handler)
end

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
	oUF.unit[unit] = self.class.unit:new(unit)

	disableBlizzard()

	oUF.unit[unit].updateCombat = updateCombat

	registerEvent("PLAYER_REGEN_ENABLED", "updateCombat")
	registerEvent("PLAYER_REGEN_DISABLED", "updateCombat")
	registerEvent("PLAYER_UPDATE_RESTING", "updateCombat")
end)
