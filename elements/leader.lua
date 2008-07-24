function oUF:PARTY_LEADER_CHANGED(event)
	if(UnitIsPartyLeader(self.unit)) then
		self.Leader:Show()
	else
		self.Leader:Hide()
	end
end

table.insert(oUF.subTypes, function(self)
	if(self.Leader) then
		self:RegisterEvent"PARTY_LEADER_CHANGED"
		self:RegisterEvent"PARTY_MEMBERS_CHANGED"
	end
end)
oUF:RegisterSubTypeMapping"PARTY_LEADER_CHANGED"
