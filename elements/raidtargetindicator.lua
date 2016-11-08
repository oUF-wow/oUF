--[[
# Element: Raid Target Indicator

Handles updating and toggles visibility of raid target icons.

## Widget

RaidTargetIndicator - A Texture used to display the raid target icon.

## Notes

The default raid icons will be used if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local RaidTargetIndicator = self:CreateTexture(nil, 'OVERLAY')
    RaidTargetIndicator:SetSize(16, 16)
    RaidTargetIndicator:SetPoint('TOPRIGHT', self)

    -- Register it with oUF
    self.RaidTargetIndicator = RaidTargetIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTargetIconTexture = SetRaidTargetIconTexture

local function Update(self, event)
	local element = self.RaidTargetIndicator

	--[[ Callback: RaidTargetIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the PowerPrediction element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		SetRaidTargetIconTexture(element, index)
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback:RaidTargetIndicator:PostUpdate(index)
	Called after the element has been updated.

	* self  - the RaidTargetIndicator element
	* index - a Number representing the index of the raid target marker
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(index)
	end
end

local function Path(self, ...)
	--[[ Override: RaidTargetIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the RaidTargetIndicator element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.RaidTargetIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	if(not element.__owner.unit) then return end
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.RaidTargetIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('RAID_TARGET_UPDATE', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.RaidTargetIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('RAID_TARGET_UPDATE', Path)
	end
end

oUF:AddElement('RaidTargetIndicator', Path, Enable, Disable)
