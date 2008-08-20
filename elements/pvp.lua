function oUF:UNIT_FACTION(event, unit)
	if(unit ~= self.unit) then return end

	-- For tapping
	if(event == 'UNIT_FACTION') then
		if(self:IsEventRegistered'UNIT_MAXHEALTH') then self:UNIT_MAXHEALTH(event, unit) end
		if(self:IsEventRegistered'UNIT_MAXMANA') then self:UNIT_MAXMANA(event, unit) end
	end

	if(self.PvP) then
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
end

table.insert(oUF.subTypes, function(self)
	if(self.PvP) then
		self:RegisterEvent"UNIT_FACTION"
	end
end)
oUF:RegisterSubTypeMapping"UNIT_FACTION"
