local parent = debugstack():match[[Interface\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

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
	local ricon = self.RaidIcon
	if(ricon) then
		self:RegisterEvent"RAID_TARGET_UPDATE"

		if(ricon:IsObjectType"Texture" and not ricon:GetTexture()) then
			ricon:SetTexture[[Interface\TargetingFrame\UI-RaidTargetingIcons]]
		end
	end
end)
oUF:RegisterSubTypeMapping"RAID_TARGET_UPDATE"
