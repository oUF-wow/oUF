local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event)
	if(UnitAffectingCombat"player") then
		self.Combat:Show()
	else
		self.Combat:Hide()
	end
end

local Path = function(self, ...)
	return (self.Combat.Override or Update) (self, ...)
end

local Enable = function(self, unit)
	local combat = self.Combat
	if(combat and unit == 'player') then
		self:RegisterEvent("PLAYER_REGEN_DISABLED", Path)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", Path)

		if(self.Combat:IsObjectType"Texture" and not self.Combat:GetTexture()) then
			self.Combat:SetTexture[[Interface\CharacterFrame\UI-StateIcon]]
			self.Combat:SetTexCoord(.5, 1, 0, .49)
		end

		return true
	end
end

local Disable = function(self)
	local combat = self.Combat
	if(combat) then
		self:UnregisterEvent("PLAYER_REGEN_DISABLED", Path)
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", Path)
	end
end

oUF:AddElement('Combat', Path, Enable, Disable)
