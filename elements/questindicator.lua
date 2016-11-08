--[[
# Element: Quest Indicator

Handles updating and toggles visibility based upon the units connection to a quest.

## Widget

QuestIndicator - Any UI widget.

## Notes

The default quest icon will be used if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local QuestIndicator = self:CreateTexture(nil, 'OVERLAY')
    QuestIndicator:SetSize(16, 16)
    QuestIndicator:SetPoint('TOPRIGHT', self)

    -- Register it with oUF
    self.QuestIndicator = QuestIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event, unit)
	if(unit ~= self.unit) then return end

	local element = self.QuestIndicator

	--[[ Callback: QuestIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the QuestIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local isQuestBoss = UnitIsQuestBoss(unit)
	if(isQuestBoss) then
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: QuestIndicator:PostUpdate(isQuestBoss)
	Called after the element has been updated.

	* self        - the QuestIndicator element
	* isQuestBoss - a Boolean indicating if the unit is a quest boss
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(isQuestBoss)
	end
end

local function Path(self, ...)
	--[[ Override: QuestIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the QuestIndicator element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.QuestIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.QuestIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\TargetingFrame\PortraitQuestBadge]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.QuestIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)
	end
end

oUF:AddElement('QuestIndicator', Path, Enable, Disable)
