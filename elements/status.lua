local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

function oUF:PLAYER_UPDATE_RESTING(event)
	if(IsResting()) then
		self.Resting:Show()
	else
		self.Resting:Hide()
	end
end

function oUF:PLAYER_REGEN_DISABLED(event)
	if(UnitAffectingCombat"player") then
		self.Combat:Show()
	else
		self.Combat:Hide()
	end
end

oUF.PLAYER_REGEN_ENABLED = oUF.PLAYER_REGEN_DISABLED

table.insert(oUF.subTypes, function(self, unit)
	if(self.Resting and unit == 'player') then
		self:RegisterEvent"PLAYER_UPDATE_RESTING"
	end
end)

table.insert(oUF.subTypes, function(self)
	if(self.Combat) then
		self:RegisterEvent"PLAYER_REGEN_DISABLED"
		self:RegisterEvent"PLAYER_REGEN_ENABLED"
	end
end)

oUF:RegisterSubTypeMapping"PLAYER_UPDATE_RESTING"
oUF:RegisterSubTypeMapping"PLAYER_REGEN_DISABLED"
