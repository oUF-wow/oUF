local G = getfenv(0)
local unit = "party"

local disableBlizzard = function()
	for i=1,4 do
		G["PartyMemberFrame"..i]:Hide() G["PartyMemberFrame"..i]:UnregisterAllEvents()
	end
end

local updateLoot = function(self)
	if(GetLootMethod() == self:GetID()) then
		self.Loot:Show()
	else
		self.Loot:Hide()
	end
end

oUF.addUnit(function(self)
	local frame
	for i=1,4 do
		frame = self.class.unit:new(unit..i, i)
		
		--frame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED", "updateLoot")
		frame:RegisterEvent("PARTY_MEMBERS_CHANGED", "updateAll")

		frame.updateLoot = updateLoot
		
		self.unit[unit..i] = frame
	end
	
	disableBlizzard()
end)
