--[[
# Element: Raid Role Indicator

Handles visibility and updating of an indicator based on the unit's party assignment.

## Widget

RaidRoleIndicator - A Texture representing the unit's party assignment (main tank, main assist or blank).

## Notes

This element updates by changing the texture.

## Examples

    -- Position and size
    local RaidRoleIndicator = self:CreateTexture(nil, 'OVERLAY')
    RaidRoleIndicator:SetSize(16, 16)
    RaidRoleIndicator:SetPoint('TOPLEFT')

    -- Register it with oUF
    self.RaidRoleIndicator = RaidRoleIndicator
--]]

local _, ns = ...
local oUF = ns.oUF

local MAINTANK_ICON = [[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]]
local MAINASSIST_ICON = [[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]]

local function Update(self, event)
	local unit = self.unit
	if(not UnitInRaid(unit)) then return end

	local element = self.RaidRoleIndicator

	--[[ Callback: RaidRoleIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the RaidRoleIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local inVehicle = UnitHasVehicleUI(unit)
	local role
	if(GetPartyAssignment('MAINTANK', unit) and not inVehicle) then
		element:Show()
		element:SetTexture(MAINTANK_ICON)
		role = 'MAINTANK'
	elseif(GetPartyAssignment('MAINASSIST', unit) and not inVehicle) then
		element:Show()
		element:SetTexture(MAINASSIST_ICON)
		role = 'MAINASSIST'
	else
		element:Hide()
	end

	--[[ Callback: RaidRoleIndicator:PostUpdate(role)
	Called after the element has been updated.

	* self - the RaidRoleIndicator element
	* role - a String representing the unit's party assignment ('MAINTANK', 'MAINASSIST' or nil)
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(role)
	end
end

local function Path(self, ...)
	--[[ Override: RaidRoleIndicator:Override(event, ...)
	Used to completely override the internal update function.

	* self  - the RaidRoleIndicator element
	* event - the event triggering the update
	* ...   - the arguments accompanying the event
	--]]
	return (self.RaidRoleIndicator.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.RaidRoleIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('GROUP_ROSTER_UPDATE', Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.RaidRoleIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('RaidRoleIndicator', Path, Enable, Disable)
