local GetReactionColors = oUF.GetReactionColors
local unit = "targettarget"
local M = DongleStub("MetrognomeNano-Beta0")
local frame

local updateTargetTarget = function(self)
	if(UnitExists(unit)) then
		frame:updateHealth(unit)
		frame:updatePower(unit)
		frame:updateInfoName(unit)
		frame:updateInfoLevel(unit)
		frame:updateReaction()
	end
end

local updateReaction = function(self)
	local r, g, b = GetReactionColors(unit)
	self:SetBackdropBorderColor(r, g, b)
end

local disableBlizzard = function()
	TargetofTargetFrame:UnregisterAllEvents()
end

oUF.addUnit(function(self)
	frame = self.class.unit:new(unit, nil, updateTargetTarget)
	self.unit[unit] = frame

	frame.updateTargetTarget = updateTargetTarget
	frame.updateReaction = updateReaction

	disableBlizzard()
	
	frame:RegisterEvent("PLAYER_TARGET_CHANGED", "updateTargetTarget")

	M:Register(self, "oUF Targets Target", updateTargetTarget, .5)
	M:Start("oUF Targets Target")
end)
