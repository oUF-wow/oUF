--[[
	Elements handled: .Threat, .ThreatText

	Functions that can be overridden from within a layout:
	 - :PreUpdateThreat(event, unit)
	 - :OverrideUpdateThreat(event, unit, unit2, isTanking, status, scaledPercent, rawPercent, threatValue)
	 - :PostUpdateThreat(event, unit, unit2, isTanking, status, scaledPercent, rawPercent, threatValue)
--]]

function oUF:UNIT_THREAT_SITUATION_UPDATE(event, unit)
	local threat, threattext = self.Threat, self.ThreatText
	if not threat or not threattext then return end

	if self.PreUpdateThreat then self:PreUpdateThreat(event, unit) end

	if not unit or unit == self.feedbackUnit then
		local unit2 = self.feedbackUnit ~= self.unit and self.unit or nil
		local isTanking, status, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation(self.feedbackUnit, unit2)

		if self.OverrideUpdateThreat then self:OverrideUpdateThreat(event, unit, unit2, isTanking, status, scaledPercent, rawPercent, threatValue)
		else
			if status > 0 and IsThreatWarningEnabled() then
				local r, g, b = GetThreatStatusColor(status)

				if threat then
					threat:SetVertexColor(r, g, b)
					threat:Show()
				end

				if threattext then
					threattext:SetFormattedText("|cff%02x%02x%02x%d%%", r*255, g*255, b*255, percentage)
					threattext:Show()
				end
			else
				if threat then threat:Hide() end
				if threattext then threattext:Hide() end
			end
		end

		if self.PostUpdateThreat then self:PostUpdateThreat(event, unit, unit2, isTanking, status, scaledPercent, rawPercent, threatValue) end
	end
end

table.insert(oUF.subTypes, function(self, unit)
	if self.Threat or self.ThreatText then
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
		if unit:match("target") or unit == "focus" then self.feedbackUnit = "player" end
		if self.Threat then self.Threat:Hide() end
		if self.ThreatText then self.ThreatText:Hide() end
	end
end)
oUF:RegisterSubTypeMapping("UNIT_THREAT_SITUATION_UPDATE")
