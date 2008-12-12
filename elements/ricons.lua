local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTargetIconTexture = SetRaidTargetIconTexture

local Update = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	local icon = self.RaidIcon

	if(index) then
		SetRaidTargetIconTexture(icon, index)
		icon:Show()
	else
		icon:Hide()
	end
end

local Enable = function(self)
	local ricon = self.RaidIcon
	if(ricon) then
		self:RegisterEvent("RAID_TARGET_UPDATE", Update)

		if(ricon:IsObjectType"Texture" and not ricon:GetTexture()) then
			ricon:SetTexture[[Interface\TargetingFrame\UI-RaidTargetingIcons]]
		end

		return true
	end
end

local Disable = function(self)
	local ricon = self.RaidIcon
	if(ricon) then
		self:UnregisterEvent("RAID_TARGET_UPDATE", Update)
	end
end

oUF:AddElement('RaidIcon', Update, Enable, Disable)
