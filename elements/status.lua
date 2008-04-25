function oUF:PLAYER_UPDATE_RESTING(event)
	if(IsResting()) then
		self.Resting:Show()
	else
		self.Resting:Hide()
	end
end

function oUF:PLAYER_REGEN_DISABLED(event)
	if(UnitAffectingCombat"player") then
		self.Combat:Show()
	else
		self.Combat:Hide()
	end
end

oUF.PLAYER_REGEN_ENABLED = oUF.PLAYER_REGEN_DISABLED
