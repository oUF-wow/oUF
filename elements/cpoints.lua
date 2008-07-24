local GetComboPoints = GetComboPoints
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

function oUF:PLAYER_COMBO_POINTS(event)
	local cp = GetComboPoints()
	local cpoints = self.CPoints

	if(#cpoints == 0) then
		cpoints:SetText((cp > 0) and cp)
	else
		for i=1, MAX_COMBO_POINTS do
			if(i <= cp) then
				cpoints[i]:Show()
			else
				cpoints[i]:Hide()
			end
		end
	end
end

table.insert(oUF.subTypes, function(self, unit)
	if(self.CPoints and unit == "target") then
		self:RegisterEvent"PLAYER_COMBO_POINTS"
	end
end)
oUF:RegisterSubTypeMapping"PLAYER_COMBO_POINTS"
