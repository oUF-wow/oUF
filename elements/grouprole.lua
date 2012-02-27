--[[ Element: Group Role Icon

 Toggles visibility of the group role icon based upon the units current dungeon
 role.

 Widget

 GroupRole - A Texture containing the group role icons at specific locations. Look
           at the default LFD role icon texture for an example of this.
           Alternatively you can look at the return values of
           GetTexCoordsForRoleSmallCircle(role).

 Notes

 The default group role texture will be applied if the UI widget is a texture and
 doesn't have a texture or color defined.

 Examples

   -- Position and size
   local GroupRole = self:CreateTexture(nil, "OVERLAY")
   GroupRole:SetSize(16, 16)
   GroupRole:SetPoint("LEFT", self)
   
   -- Register it with oUF
   self.GroupRole = GroupRole

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event)
	local grouprole = self.GroupRole
	if(grouprole.PreUpdate) then
		grouprole:PreUpdate()
	end

	local role = UnitGroupRolesAssigned(self.unit)
	if(role == 'TANK' or role == 'HEALER' or role == 'DAMAGER') then
		grouprole:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
		grouprole:Show()
	else
		grouprole:Hide()
	end

	if(grouprole.PostUpdate) then
		return grouprole:PostUpdate(role)
	end
end

local Path = function(self, ...)
	return (self.GroupRole.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local Enable = function(self)
	local grouprole = self.GroupRole
	if(grouprole) then
		grouprole.__owner = self
		grouprole.ForceUpdate = ForceUpdate

		if(self.unit == "player") then
			self:RegisterEvent("PLAYER_ROLES_ASSIGNED", Path, true)
		else
			self:RegisterEvent("PARTY_MEMBERS_CHANGED", Path, true)
		end

		if(grouprole:IsObjectType"Texture" and not grouprole:GetTexture()) then
			grouprole:SetTexture[[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]]
		end

		return true
	end
end

local Disable = function(self)
	if(self.GroupRole) then
		self:UnregisterEvent("PLAYER_ROLES_ASSIGNED", Path)
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED", Path)
	end
end

oUF:AddElement('GroupRole', Path, Enable, Disable)
