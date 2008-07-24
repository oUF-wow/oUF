function oUF:UNIT_FACTION(event, unit)
	if(unit ~= self.unit) then return end

	local factionGroup = UnitFactionGroup(unit)
	if(UnitIsPVPFreeForAll(unit)) then
		self.PvP:SetTexture[[Interface\TargetingFrame\UI-PVP-FFA]]
		self.PvP:Show()
	elseif(factionGroup and UnitIsPVP(unit)) then
		self.PvP:SetTexture([[Interface\TargetingFrame\UI-PVP-]]..factionGroup)
		self.PvP:Show()
	else
		self.PvP:Hide()
	end
end

table.insert(oUF.subTypes, function(self)
	if(self.PvP) then
		self:RegisterEvent"UNIT_FACTION"
	end
end)
oUF.subTypesMapping.PvP = "UNIT_FACTION"
