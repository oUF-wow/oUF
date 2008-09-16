--[[
	Elements handled: .Threat

	Functions that can be overridden from within a layout:
	 - :PreUpdateThreat(event, unit)
	 - :OverrideUpdateThreat(event, unit, status)
	 - :PostUpdateThreat(event, unit, status)
--]]
if(select(4, GetBuildInfo()) < 3e4) then return end
local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

function oUF:UNIT_THREAT_SITUATION_UPDATE(event, unit)
	if(unit and unit ~= self.unit) then return end
	if(self.PreUpdateThreat) then self:PreUpdateThreat(event, unit) end

	unit = unit or self.unit
	local threat = self.Threat
	local status = UnitThreatSituation(unit)

	if(not self.OverrideUpdateThreat) then
		if(status > 0) then
			local r, g, b = GetThreatStatusColor(status)
			threat:SetVertexColor(r, g, b)
			threat:Show()
		else
			threat:Hide()
		end
	else
		self:OverrideUpdateThreat(event, unit, status)
	end

	if(self.PostUpdateThreat) then self:PostUpdateThreat(event, unit, status) end
end

table.insert(oUF.subTypes, function(self, unit)
	if self.Threat then
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
		self.Threat:Hide()
	end
end)
oUF:RegisterSubTypeMapping("UNIT_THREAT_SITUATION_UPDATE")
