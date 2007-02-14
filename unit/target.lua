local GetReactionColors, GetComboPoints = oUF.GetReactionColors, GetComboPoints
local unit = "target"

local updateTarget = function(self)
	if(UnitExists(unit)) then
		self:updateAll()
		self:updateReaction()
		self:updateCP()
	end
end

local createCP = function(self)
	local c = select(2, UnitClass("player"))

	if(c == "ROGUE" or c == "DRUID") then
		self.CPoints = self:CreateFontString(nil, "OVERLAY")
		self.CPoints:SetFont("Fonts\\FRIZQT__.TTF", 24, "THICKOUTLINE")
		self.CPoints:SetTextColor(1, 1, 1)
		self.CPoints:SetPoint("LEFT", self, "RIGHT", 5, -1)
		self.CPoints:SetJustifyH("LEFT")
	end
end

local updateReaction = function(self)
	local r, g, b = GetReactionColors(unit)
	self:SetBackdropBorderColor(r, g, b)
end

local updateCP = function(self)
	local cpoints = self.CPoints

	if(not cpoints) then
		return
	elseif(GetComboPoints() > 0) then
		cpoints:SetText(GetComboPoints())
	else
		cpoints:SetText(nil)
	end
end

local disableBlizzard = function()
	TargetFrame:UnregisterAllEvents()
	ComboFrame:UnregisterAllEvents()
end

oUF.addUnit(function(self)
	local frame = self.class.unit:new(unit)
	self.unit[unit] = frame

	frame.updateCP = updateCP
	frame.updateTarget = updateTarget
	frame.updateReaction = updateReaction

	disableBlizzard()
	createCP(frame)

	frame:RegisterEvent("PLAYER_COMBO_POINTS", "updateCP")
	frame:RegisterEvent("PLAYER_TARGET_CHANGED", "updateTarget")
end)
