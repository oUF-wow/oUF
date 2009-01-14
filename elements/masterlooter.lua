local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local function Update(self, event)
	local unit = ''
	local method, id = GetLootMethod()
	if(method == 'master') then
		if(GetNumRaidMembers() > 1) then
			for i = 1, MAX_RAID_MEMBERS do local _, _, _, _, _, _, _, _, _, _, loot = GetRaidRosterInfo(i)
				if(loot) then
					unit = 'raid'..i
					break
				end
			end
		else
			if(id == 0) then
				unit = 'player'
			else
				unit = 'party'..id
			end
		end

		if(self.unit == unit) then
			self.MasterLooter:Show()
		else
			self.MasterLooter:Hide()
		end
	else
		self.MasterLooter:Hide()
	end
end

local function Enable(self, unit)
	local masterlooter = self.MasterLooter
	if(masterlooter) then
		self:RegisterEvent('PLAYER_MEMBERS_CHANGED', Update)
		self:RegisterEvent('RAID_ROSTER_UPDATE', Update)

		if(masterlooter:IsObjectType('Texture') and not masterlooter:GetTexture()) then
			masterlooter:SetTexture([=[Interface\GroupFrame\UI-Group-MasterLooter]=])
		end

		return true
	end
end

local function Disable(self)
	if(self.MasterLooter) then
		self:UnregisterEvent('PLAYER_MEMBERS_CHANGED', Update)
		self:UnregisterEvent('RAID_ROSTER_UPDATE', Update)
	end
end

oUF:AddElement('MasterLooter', Update, Enable, Disable)
