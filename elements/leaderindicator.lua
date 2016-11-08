--[[
# Element: Leader Indicator

Toggles visibility based on the units leader status.

## Widget

LeaderIndicator - Any UI widget.

## Notes

The default leader icon will be applied if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local LeaderIndicator = self:CreateTexture(nil, 'OVERLAY')
    LeaderIndicator:SetSize(16, 16)
    LeaderIndicator:SetPoint('BOTTOM', self, 'TOP')

    -- Register it with oUF
    self.LeaderIndicator = Leadera
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.LeaderIndicator

	--[[ Callback: LeaderIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the HealthPrediction element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local unit = self.unit
	local isLeader = (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsGroupLeader(unit)
	if(isLeader) then
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: LeaderIndicator:PostUpdate(isLeader)
	Called after the element has been updated.

	* self     - the LeaderIndicator element
	* isLeader - a Boolean indicating whether the element is shown
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(isLeader)
	end
end

local function Path(self, ...)
	--[[ Override: LeaderIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the LeaderIndicator element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.LeaderIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.LeaderIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('PARTY_LEADER_CHANGED', Path, true)
		self:RegisterEvent('GROUP_ROSTER_UPDATE', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\GroupFrame\UI-Group-LeaderIcon]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.LeaderIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('PARTY_LEADER_CHANGED', Path)
		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('LeaderIndicator', Path, Enable, Disable)
