--[[ Element: Class Icons
 Toggles the visibility of icons depending on the player's class and
 specialization.

 Widget

 ClassIcons - An array consisting of five UI widgets.

 Notes

 Monk    - Harmony Orbs
 Paladin - Holy Power
 Priest  - Shadow Orbs
 Warlock - Soul Shards

 Examples

   local ClassIcons = {}
   for index = 1, 5 do
      local Icon = self:CreateTexture(nil, 'BACKGROUND')
   
      -- Position and size.
      Icon:SetSize(16, 16)
      Icon:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * Icon:GetWidth(), 0)
   
      ClassIcons[index] = Icon
   end
   
   -- Register with oUF
   self.ClassIcons = ClassIcons
]]

local parent, ns = ...
local oUF = ns.oUF

local PlayerClass = select(2, UnitClass'player')

-- Holds the class specific stuff.
local ClassPowerType, ClassPowerTypes
local ClassPowerEnable, ClassPowerDisable

local UpdateTexture = function(element)
	local red, green, blue, desaturated
	if(PlayerClass == 'MONK') then
		red, green, blue = 0, 1, .59
		desaturated = true
	elseif(PlayerClass == 'WARLOCK') then
		red, green, blue = 1, .5, 1
		desaturated = true
	elseif(PlayerClass == 'PRIEST') then
		red, green, blue = 1, 1, 1
	elseif(PlayerClass == 'PALADIN') then
		red, green, blue = 1, .96, .41
		desaturated = true
	end

	for i=1, 5 do
		if(element[i].SetDesaturated) then
			element[i]:SetDesaturated(desaturated)
		end
		element[i]:SetVertexColor(red, green, blue)
	end
end

local ToggleVehicle = function(self, state)
	local element = self.ClassIcons
	for i=1, 5 do
		element[i]:Hide()
	end

	(element.UpdateTexture or UpdateTexture) (element)

	if(state) then
		ClassPowerDisable(self)
	else
		ClassPowerEnable(self)
	end
end

local Update = function(self, event, unit, powerType)
	local element = self.ClassIcons
	local hasVehicle = UnitHasVehicleUI('player')
	if(element.__inVehicle ~= hasVehicle) then
		element.__inVehicle = hasVehicle
		ToggleVehicle(self, hasVehicle)

		-- Continue the update if we left a vehicle.
		if(hasVehicle) then return end
	end

	if((unit and unit ~= 'player') or (powerType and not ClassPowerTypes[powerType])) then
		return
	end

	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local cur = UnitPower('player', ClassPowerType)
	local max = UnitPowerMax('player', ClassPowerType)

	for i=1, max do
		if(i <= cur) then
			element[i]:Show()
		else
			element[i]:Hide()
		end
	end

	local oldMax = element.__max
	if(max ~= element.__max) then
		if(max < element.__max) then
			for i=max + 1, element.__max do
				element[i]:Hide()
			end
		end

		element.__max = max
	end

	if(element.PostUpdate) then
		return element:PostUpdate(cur, max, oldMax ~= max)
	end
end

local Path = function(self, ...)
	return (self.ClassIcons.Override or Update) (self, ...)
end

local Visibility = function(self, event, unit)
	local element = self.ClassIcons
	if(
		(RequireSpec and RequireSpec ~= GetSpecialization())
		or (RequireSpell and not IsPlayerSpell(RequireSpell))) then
		for i=1, 5 do
			element[i]:Hide()
		end
		ClassPowerDisable(self)
	else
		ClassPowerEnable(self)
		return Path(self, 'UpdateVisibility')
	end
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

do
	if(PlayerClass == 'MONK') then
		ClassPowerType = SPELL_POWER_LIGHT_FORCE
		ClassPowerTypes = {
			LIGHT_FORCE = true,
			DARK_FORCE = true,
		}

		ClassPowerEnable = function(self)
			local element = self.ClassIcons
			element.__max = 4

			self:RegisterEvent('UNIT_DISPLAYPOWER', Update)
			self:RegisterEvent('UNIT_POWER_FREQUENT', Update)
		end

		ClassPowerDisable = function(self)
			self:UnregisterEvent('UNIT_DISPLAYPOWER', Update)
			self:UnregisterEvent('UNIT_POWER_FREQUENT', Update)
		end
	elseif(PlayerClass == 'PALADIN') then
		ClassPowerType = SPELL_POWER_HOLY_POWER
		ClassPowerTypes = {
			HOLY_POWER = true,
		}

		ClassPowerEnable = function(self)
			local element = self.ClassIcons
			element.__max = HOLY_POWER_FULL

			self:RegisterEvent('UNIT_DISPLAYPOWER', Update)
			self:RegisterEvent('UNIT_POWER', Update)
		end

		ClassPowerDisable = function(self)
			self:UnregisterEvent('UNIT_DISPLAYPOWER', Update)
			self:UnregisterEvent('UNIT_POWER', Update)
		end
	elseif(PlayerClass == 'PRIEST') then
		ClassPowerType = SPELL_POWER_SHADOW_ORBS
		ClassPowerTypes = {
			SHADOW_ORBS = true,
		}
		RequireSpec = SPEC_PRIEST_SHADOW

		ClassPowerEnable = function(self)
			local element = self.ClassIcons
			element.__max = PRIEST_BAR_NUM_ORBS

			self:RegisterEvent('UNIT_DISPLAYPOWER', Update)
			self:RegisterEvent('UNIT_POWER_FREQUENT', Update)
		end

		ClassPowerDisable = function(self)
			self:UnregisterEvent('UNIT_DISPLAYPOWER', Update)
			self:UnregisterEvent('UNIT_POWER_FREQUENT', Update)
		end
	elseif(PlayerClass == 'WARLOCK') then
		ClassPowerType = SPELL_POWER_SOUL_SHARDS
		ClassPowerTypes = {
			SOUL_SHARDS = true,
		}
		RequireSpell = WARLOCK_SOULBURN

		ClassPowerEnable = function(self)
			local element = self.ClassIcons
			element.__max = 3

			self:RegisterEvent('UNIT_DISPLAYPOWER', Update)
			self:RegisterEvent('UNIT_POWER_FREQUENT', Update)
		end

		ClassPowerDisable = function(self)
			self:UnregisterEvent('UNIT_DISPLAYPOWER', Update)
			self:UnregisterEvent('UNIT_POWER_FREQUENT', Update)
		end
	end
end

local Enable = function(self, unit)
	local element = self.ClassIcons
	if(not element) then return end

	element.__owner = self
	element.ForceUpdate = ForceUpdate

	if(ClassPowerEnable) then
		if(PlayerClass == 'PRIEST') then
			self:RegisterEvent('PLAYER_TALENT_UPDATE', Visibility, true)
		elseif(PlayerClass == 'WARLOCK') then
			self:RegisterEvent('SPELLS_CHANGED', Visibility, true)
		end
		ClassPowerEnable(self)

		for i=1, 5 do
			local icon = element[i]
			if(icon:IsObjectType'Texture' and not icon:GetTexture()) then
				icon:SetTexCoord(0.45703125, 0.60546875, 0.44531250, 0.73437500)
				icon:SetTexture([[Interface\PlayerFrame\Priest-ShadowUI]])
			end
		end

		(element.UpdateTexture or UpdateTexture) (element)

		return true
	end
end

local Disable = function(self)
	local element = self.ClassIcons
	if(not element) then return end

	self:UnregisterEvent('SPELLS_CHANGED', Visibility)
	self:UnregisterEvent('PLAYER_TALENT_UPDATE', Visibility)
	ClassPowerDisable(self)
end

oUF:AddElement('ClassIcons', Update, Enable, Disable)
