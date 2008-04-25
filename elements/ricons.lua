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
