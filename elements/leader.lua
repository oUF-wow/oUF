function oUF:PARTY_LEADER_CHANGED(event)
	if(UnitIsPartyLeader(self.unit)) then
		self.Leader:Show()
	else
		self.Leader:Hide()
	end
end

table.insert(oUF.subTypes, function(self)
	local leader = self.Leader
	if(leader) then
		self:RegisterEvent"PARTY_LEADER_CHANGED"
		self:RegisterEvent"PARTY_MEMBERS_CHANGED"

		if(leader:IsObjectType"Texture" and not leader:GetTexture()) then
			leader:SetTexture[[Interface\GroupFrame\UI-Group-LeaderIcon]]
		end
	end
end)
oUF:RegisterSubTypeMapping"PARTY_LEADER_CHANGED"
