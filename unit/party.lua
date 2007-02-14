local G = getfenv(0)
local unit = "party"

local disableBlizzard = function()
	for i=1,4 do
		G["PartyMemberFrame"..i]:Hide() G["PartyMemberFrame"..i]:UnregisterAllEvents()
	end
end

oUF.addUnit(function(self)
	local frame
	for i=1,4 do
		frame = self.class.unit:new(unit..i, .i)
		frame:RegisterEvent("PARTY_MEMBERS_CHANGED", "updateAll")
		oUF.unit[unit..i] = frame
	end
	
	disableBlizzard()
end)
