--[[
	Elements handled: .Threat

	Functions that can be overridden from within a layout:
	 - :PreUpdateThreat(event, unit)
	 - :OverrideUpdateThreat(event, unit, status)
	 - :PostUpdateThreat(event, unit, status)
--]]

local function Debug(...) ChatFrame6:AddMessage(string.join(", ", "oUF.threat", tostringall(...))) end

function oUF:UNIT_THREAT_SITUATION_UPDATE(event, unit)
	local threat = self.Threat
	if not threat then return end

	if self.PreUpdateThreat then self:PreUpdateThreat(event, unit) end

	if not unit or unit == self.unit then
		local status = UnitThreatSituation(self.unit)

		if self.OverrideUpdateThreat then self:OverrideUpdateThreat(event, unit, status)
		else
			if status > 0 then
				local r, g, b = GetThreatStatusColor(status)

				if threat then
					threat:SetVertexColor(r, g, b)
					threat:Show()
				end

			else threat:Hide() end
		end

		if self.PostUpdateThreat then self:PostUpdateThreat(event, unit, status) end
	end
end

table.insert(oUF.subTypes, function(self, unit)
	if self.Threat then
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
		self.Threat:Hide()
	end
end)
oUF:RegisterSubTypeMapping("UNIT_THREAT_SITUATION_UPDATE")
