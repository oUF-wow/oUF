function oUF:PARTY_LEADER_CHANGED(event)
	if(UnitIsPartyLeader(self.unit)) then
		self.Leader:Show()
	else
		self.Leader:Hide()
	end
end
