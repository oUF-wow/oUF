local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event)
	local isQuestBoss = UnitIsQuestBoss(self.unit)
	local qicon = self.QuestIcon

	if(isQuestBoss) then
		return qicon:Show()
	else
		return qicon:Hide()
	end
end

local Path = function(self, ...)
	return (self.QuestIcon.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local Enable = function(self)
	local qicon = self.QuestIcon
	if(qicon) then
		qicon.__owner = self
		qicon.ForceUpdate = ForceUpdate

		if(qicon:IsObjectType'Texture' and not qicon:GetTexture()) then
			qicon:SetTexture[[Interface\TargetingFrame\PortraitQuestBadge]]
		end

		return true
	end
end

local Disable = function(self)
end

oUF:AddElement('QuestIcon', Path, Enable, Disable)
