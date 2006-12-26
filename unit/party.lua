local oParty = oUF:NewModule("oUF_Party")
local G = getfenv(0)

function oParty:Enable()
	for i=1,4 do
		oUF.unit["party"..i] = oUF.class.unit:new("party"..i)
		oUF.unit["party"..i]:loadPosition()
	end
end

function oParty:disableBlizzard()
	for i=1,4 do
		G["PartyFrame"..i]:UnregisterAllEvents()
		G["PartyFrame"..i]:Hide()
	end
end

