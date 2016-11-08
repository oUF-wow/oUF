--[[
# Element: Group Role Indicator

Toggles visibility of the assigned role icon based upon the units current dungeon role.

## Widget

GroupRoleIndicator - A Texture containing the LFD role icons at specific locations.
                     See the default LFD role icon texture for an example of this.
                     Alternatively look up the return values of `GetTexCoordsForRoleSmallCircle(role)`.

## Notes

The default LFD role texture will be applied if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local GroupRoleIndicator = self:CreateTexture(nil, 'OVERLAY')
    GroupRoleIndicator:SetSize(16, 16)
    GroupRoleIndicator:SetPoint('LEFT', self)

    -- Register it with oUF
    self.GroupRoleIndicator = GroupRoleIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.GroupRoleIndicator

	--[[ Callback: GroupRoleIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the GroupRoleIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local role = UnitGroupRolesAssigned(self.unit)
	if(role == 'TANK' or role == 'HEALER' or role == 'DAMAGER') then
		element:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: GroupRoleIndicator:PostUpdate(role)
	Called after the element has been updated.

	* self - the GroupRoleIndicator element
	* role - the role as returned by `UnitGroupRolesAssigned`
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(role)
	end
end

local function Path(self, ...)
	--[[ Override: GroupRoleIndicator:Override(self, ...)
	Used to completely override the internal update function.

	* self - the GroupRoleIndicator element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.GroupRoleIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.GroupRoleIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		if(self.unit == 'player') then
			self:RegisterEvent('PLAYER_ROLES_ASSIGNED', Path, true)
		else
			self:RegisterEvent('GROUP_ROSTER_UPDATE', Path, true)
		end

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.GroupRoleIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('PLAYER_ROLES_ASSIGNED', Path)
		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('GroupRoleIndicator', Path, Enable, Disable)
