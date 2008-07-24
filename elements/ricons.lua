local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTargetIconTexture = SetRaidTargetIconTexture

function oUF:RAID_TARGET_UPDATE(event)
	local index = GetRaidTargetIndex(self.unit)
	local icon = self.RaidIcon

	if(index) then
		SetRaidTargetIconTexture(icon, index)
		icon:Show()
	else
		icon:Hide()
	end
end

table.insert(oUF.subTypes, function(self)
	if(self.RaidIcon) then
		self:RegisterEvent"RAID_TARGET_UPDATE"
	end
end)
oUF.subTypesMapping.RaidIcon = "RAID_TARGET_UPDATE"
