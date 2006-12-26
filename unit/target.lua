oUF.unit.target = oUF.class.unit:new("target")
oUF:NewModule('oUF_Target', oUF.unit.target)

function oUF.unit.target:Enable()
	self:disableBlizzard()
	self:createCP()

	self:RegisterEvent("PLAYER_COMBO_POINTS", "updateCP")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "updateTarget")
end

function oUF.unit.target:updateTarget()
	if(UnitExists("target")) then
		self:updateAll()
		self:updateReaction()
		self:updateCP()
	end
end

function oUF.unit.target:createCP()
	local c = select(2, UnitClass("player"))

	if(c == "ROGUE" or c == "DRUID") then
		self.CPoints = self:CreateFontString(nil, "OVERLAY")
		self.CPoints:SetFont("Fonts\\FRIZQT__.TTF", 24, "THICKOUTLINE")
		self.CPoints:SetTextColor(1, 1, 1)
		self.CPoints:SetPoint("LEFT", self, "RIGHT", 5, -1)
		self.CPoints:SetJustifyH("LEFT")
	end
end

function oUF.unit.target:updateReaction()
	local r, g, b = oUF:GetReactionColors("target")
	self:SetBackdropBorderColor(r, g, b)
end

function oUF.unit.target:updateCP()
	if not self.CPoints then return end
	
	if(GetComboPoints() > 0) then
		self.CPoints:SetText(GetComboPoints())
	else
		self.CPoints:SetText(nil)
	end
end

function oUF.unit.target:disableBlizzard()
	TargetFrame:UnregisterAllEvents()
end
