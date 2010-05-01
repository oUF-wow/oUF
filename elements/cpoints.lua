local parent, ns = ...
local oUF = ns.oUF

local GetComboPoints = GetComboPoints
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local Update = function(self, event, unit)
	if(unit == 'pet') then return end

	local cp
	if(UnitExists'vehicle') then
		cp = GetComboPoints('vehicle', 'target')
	else
		cp = GetComboPoints('player', 'target')
	end

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

local Enable = function(self)
	local cpoints = self.CPoints
	if(cpoints) then
		local Update = cpoints.Update or Update
		self:RegisterEvent('UNIT_COMBO_POINTS', Update)
		self:RegisterEvent('PLAYER_TARGET_CHANGED', Update)

		return true
	end
end

local Disable = function(self)
	local cpoints = self.CPoints
	if(cpoints) then
		local Update = cpoints.Update or Update
		self:UnregisterEvent('UNIT_COMBO_POINTS', Update)
		self:UnregisterEvent('PLAYER_TARGET_CHANGED', Update)
	end
end

oUF:AddElement('CPoints', Update, Enable, Disable)
