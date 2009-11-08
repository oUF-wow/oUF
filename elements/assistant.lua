local oUF
local parent
if(...) then
	parent = ...
else
	parent = debugstack():match[[\AddOns\(.-)\]]
end

local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
if(...) then
	local _, ns = ...
	oUF = ns.oUF
else
	oUF = _G[global]
end

local Update = function(self, event)
	local unit = self.unit
	if(UnitInRaid(unit) and UnitIsRaidOfficer(unit) and not UnitIsPartyLeader(unit)) then
		self.Assistant:Show()
	else
		self.Assistant:Hide()
	end
end

local Enable = function(self)
	local assistant = self.Assistant
	if(assistant) then
		self:RegisterEvent("PARTY_MEMBERS_CHANGED", Update)

		if(assistant:IsObjectType"Texture" and not assistant:GetTexture()) then
			assistant:SetTexture[[Interface\GroupFrame\UI-Group-AssistantIcon]]
		end

		return true
	end
end

local Disable = function(self)
	local assistant = self.Assistant
	if(assistant) then
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED", Update)
	end
end

oUF:AddElement('Assistant', Update, Enable, Disable)
