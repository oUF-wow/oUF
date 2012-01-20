local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event)
	local raidID = UnitInRaid(self.unit)
	if(not raidID) then return end

	local raidrole = self.RaidRole
	if(raidrole.PreUpdate) then
		raidrole:PreUpdate()
	end

	local _, _, _, _, _, _, _, _, _, rinfo = GetRaidRosterInfo(raidID)
	if(rinfo == 'MAINTANK' and not UnitHasVehicleUI(self.unit)) then
		raidrole:Show()
	else
		raidrole:Hide()
	end

	if(raidrole.PostUpdate) then
		return raidrole:PostUpdate(rinfo)
	end
end

local Path = function(self, ...)
	return (self.RaidRole.Override or Update)(self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local Enable = function(self)
	local raidrole = self.RaidRole

	if(raidrole) then
		raidrole.__owner = self
		raidrole.ForceUpdate = ForceUpdate

		self:RegisterEvent('PARTY_MEMBERS_CHANGED', Path, true)
		self:RegisterEvent('RAID_ROSTER_UPDATE', Path, true)

		if(raidrole:IsObjectType'Texture' and not raidrole:GetTexture()) then
			raidrole:SetTexture[[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]]
		end

		return true
	end
end

local Disable = function(self)
	local raidrole = self.RaidRole

	if(raidrole) then
		self:UnregisterEvent('PARTY_MEMBERS_CHANGED', Path)
		self:UnregisterEvent('RAID_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('RaidRole', Path, Enable, Disable)
