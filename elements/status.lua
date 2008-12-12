local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

do
	local Update = function(self, event)
		if(IsResting()) then
			self.Resting:Show()
		else
			self.Resting:Hide()
		end
	end

	local Enable = function(self)
		if(self.Resting and unit == 'player') then
			self:RegisterEvent("PLAYER_UPDATE_RESTING", Update)

			return true
		end
	end

	local Disable = function(self)
		if(self.Resting and unit == 'player') then
			self:UnregisterEvent("PLAYER_UPDATE_RESTING", Update)
		end
	end

	oUF:AddElement('Resting', Update, Enable, Disable)
end

do
	local Update = function(self, event)
		if(UnitAffectingCombat"player") then
			self.Combat:Show()
		else
			self.Combat:Hide()
		end
	end

	local Enable = function(self, unit)
		if(self.Combat and unit == 'player') then
			self:RegisterEvent("PLAYER_REGEN_DISABLED", Update)
			self:RegisterEvent("PLAYER_REGEN_ENABLED", Update)

			return true
		end
	end

	local Disable = function(self)
		if(self.Combat) then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED", Update)
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", Update)
		end
	end

	oUF:AddElement('Combat', Update, Enable, Disable)
end
