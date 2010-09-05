local parent, ns = ...
local oUF = ns.oUF
local CC = select(4, GetBuildInfo()) == 4e4

local Update = function(self, event)
	local lfdrole = self.LFDRole

	if(CC) then
		local role = UnitGroupRolesAssigned(self.unit)

		if(role == 'TANK' or role == 'HEALER' or role == 'DAMAGER') then
			lfdrole:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
			lfdrole:Show()
		else
			lfdrole:Hide()
		end
	else
		local isTank, isHealer, isDamage = UnitGroupRolesAssigned(self.unit)

		if(isTank) then
			lfdrole:SetTexCoord(0, 19/64, 22/64, 41/64)
			lfdrole:Show()
		elseif(isHealer) then
			lfdrole:SetTexCoord(20/64, 39/64, 1/64, 20/64)
			lfdrole:Show()
		elseif(isDamage) then
			lfdrole:SetTexCoord(20/64, 39/64, 22/64, 41/64)
			lfdrole:Show()
		else
			lfdrole:Hide()
		end
	end
end

local Path = function(self, ...)
	return (self.LFDRole.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local Enable = function(self)
	local lfdrole = self.LFDRole
	if(lfdrole) then
		lfdrole.__owner = self
		lfdrole.ForceUpdate = ForceUpdate

		if(self.unit == "player") then
			self:RegisterEvent("PLAYER_ROLES_ASSIGNED", Path)
		else
			self:RegisterEvent("PARTY_MEMBERS_CHANGED", Path)
		end

		if(lfdrole:IsObjectType"Texture" and not lfdrole:GetTexture()) then
			lfdrole:SetTexture[[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]]
		end

		return true
	end
end

local Disable = function(self)
	local lfdrole = self.LFDRole
	if(lfdrole) then
		self:UnregisterEvent("PLAYER_ROLES_ASSIGNED", Path)
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED", Path)
	end
end

oUF:AddElement('LFDRole', Path, Enable, Disable)
