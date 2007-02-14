local G = getfenv(0)

local unit = "party"
local disableBlizzard = function()
	for i=1,4 do
		G["PartyMemberFrame"..i]:Hide() G["PartyMemberFrame"..i]:UnregisterAllEvents()
	end
end

oUF.addUnit(function(self)
	for i=1,4 do
		oUF.unit[unit..i] = self.class.unit:new(unit..i, i)
	end
	
	disableBlizzard()
end)
