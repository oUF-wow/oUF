local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event, unit)
	if(unit ~= self.unit) then return end

	local icon = self.QuestIcon
	if(icon.PreUpdate) then
		icon:PreUpdate()
	end

	local isQuestBoss = UnitIsQuestBoss(unit)
	if(isQuestBoss) then
		icon:Show()
	else
		icon:Hide()
	end

	if(icon.PostUpdate) then
		return icon:PostUpdate(isQuestBoss)
	end
end

local Path = function(self, ...)
	return (self.QuestIcon.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local icon = self.QuestIcon
	if(icon) then
		icon.__owner = self
		icon.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)

		if(icon:IsObjectType'Texture' and not icon:GetTexture()) then
			icon:SetTexture[[Interface\TargetingFrame\PortraitQuestBadge]]
		end

		return true
	end
end

local Disable = function(self)
	if(self.QuestIcon) then
		self:UnregisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)
	end
end

oUF:AddElement('QuestIcon', Path, Enable, Disable)
