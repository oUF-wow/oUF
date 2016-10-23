--[[ Element: LFD Role Icon

 Toggles visibility of the LFD role icon based upon the units current dungeon
 role.

 Widget

 LFDRole - A Texture containing the LFD role icons at specific locations. Look
           at the default LFD role icon texture for an example of this.
           Alternatively you can look at the return values of
           GetTexCoordsForRoleSmallCircle(role).

 Notes

 The default LFD role texture will be applied if the UI widget is a texture and
 doesn't have a texture or color defined.

 Examples

   -- Position and size
   local LFDRole = self:CreateTexture(nil, 'OVERLAY')
   LFDRole:SetSize(16, 16)
   LFDRole:SetPoint('LEFT', self)

   -- Register it with oUF
   self.LFDRole = LFDRole

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.LFDRole
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

	if(element.PostUpdate) then
		return element:PostUpdate(role)
	end
end

local function Path(self, ...)
	return (self.LFDRole.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.LFDRole
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
	local element = self.LFDRole
	if(element) then
		element:Hide()

		self:UnregisterEvent('PLAYER_ROLES_ASSIGNED', Path)
		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('LFDRole', Path, Enable, Disable)
