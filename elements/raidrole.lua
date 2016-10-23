--[[ Element: Raid Role Icon

 Handles visibility and updating of `self.RaidRole` based upon the units
 party assignment.

 Widget

 RaidRole - A Texture representing the units party assignment. This is can be
            main tank, main assist or blank.

 Notes

 This element updates by changing the texture.

 Examples

   -- Position and size
   local RaidRole = self:CreateTexture(nil, 'OVERLAY')
   RaidRole:SetSize(16, 16)
   RaidRole:SetPoint('TOPLEFT')

   -- Register it with oUF
   self.RaidRole = RaidRole

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local MAINTANK_ICON = [[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]]
local MAINASSIST_ICON = [[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]]

local function Update(self, event)
	local unit = self.unit
	if(not UnitInRaid(unit)) then return end

	local element = self.RaidRole
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local inVehicle = UnitHasVehicleUI(unit)
	if(GetPartyAssignment('MAINTANK', unit) and not inVehicle) then
		element:Show()
		element:SetTexture(MAINTANK_ICON)
	elseif(GetPartyAssignment('MAINASSIST', unit) and not inVehicle) then
		element:Show()
		element:SetTexture(MAINASSIST_ICON)
	else
		element:Hide()
	end

	if(element.PostUpdate) then
		return element:PostUpdate(rinfo)
	end
end

local function Path(self, ...)
	return (self.RaidRole.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.RaidRole
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('GROUP_ROSTER_UPDATE', Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.RaidRole
	if(element) then
		element:Hide()

		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('RaidRole', Path, Enable, Disable)
