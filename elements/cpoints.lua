local wotlk = select(4, GetBuildInfo()) >= 3e4
local GetComboPoints = GetComboPoints
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local ename
if(wotlk) then
	ename = 'UNIT_COMBO_POINTS'
else
	ename = 'PLAYER_COMBO_POINTS'
end

-- TODO: This shouldn't be hardcoded in wotlk.
oUF[ename] = function(self, event, unit)
	if(wotlk and unit ~= 'player') then return end
	local cp = GetComboPoints('player', 'target')
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
		self:RegisterEvent(ename)
	end
end)
oUF:RegisterSubTypeMapping(ename)
