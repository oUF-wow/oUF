--[[
# Element: Assistant Indicator

Toggles visibility of an indicator based on the units raid officer status.

## Widget

AssistantIndicator - Any UI widget.

## Notes

The default assistant icon will be applied if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local AssistantIndicator = self:CreateTexture(nil, 'OVERLAY')
    AssistantIndicator:SetSize(16, 16)
    AssistantIndicator:SetPoint('TOP', self)

    -- Register it with oUF
    self.AssistantIndicator = AssistantIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.AssistantIndicator

	--[[ Callback: AssistantIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the AssistantIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local unit = self.unit
	local isAssistant = UnitInRaid(unit) and UnitIsGroupAssistant(unit) and not UnitIsGroupLeader(unit)
	if(isAssistant) then
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: AssistantIndicator:PostUpdate(isAssistant)
	Called after the element has been updated.

	* self        - the AssistantIndicator element
	* isAssistant - a boolean indicating whether the unit is a raid officer or not
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(isAssistant)
	end
end

local function Path(self, ...)
	--[[ Override: AssistantIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the AssistantIndicator element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.AssistantIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.AssistantIndicator
	if(element) then
		self:RegisterEvent('GROUP_ROSTER_UPDATE', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\GroupFrame\UI-Group-AssistantIcon]])
		end

		element.__owner = self
		element.ForceUpdate = ForceUpdate

		return true
	end
end

local function Disable(self)
	local element = self.AssistantIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('AssistantIndicator', Path, Enable, Disable)
