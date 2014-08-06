--[[ Element: Class Icons
 Toggles the visibility of icons depending on the player's class and
 specialization.

 Widget

 ClassIcons - An array consisting of five UI Textures.

 Notes

 Monk    - Chi Orbs
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

 Hooks

 OverrideVisibility(self) - Used to completely override the internal visibility function.
                            Removing the table key entry will make the element fall-back
                            to its internal function again.
 Override(self)           - Used to completely override the internal update function.
                            Removing the table key entry will make the element fall-back
                            to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local PlayerClass = select(2, UnitClass'player')

-- Holds the class specific stuff.
local ClassPowerTypeID, ClassPowerType
local ClassPowerEnable, ClassPowerDisable
local RequireSpell

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
		local icon = element[i]
		if(icon.SetDesaturated) then
			icon:SetDesaturated(desaturated)
		end

		icon:SetVertexColor(red, green, blue)
	end
end

local Update = function(self, event, unit, powerType)
	local element = self.ClassIcons

	if((unit and unit ~= 'player') or (powerType and not ClassPowerType == powerType)) then
		return
	end

	if((event ~= 'UNIT_DISPLAYPOWER' and event ~= 'UNIT_POWER_FREQUENT') and
		RequireSpell and not IsPlayerSpell(RequireSpell)) then
		return
	end

	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local cur = UnitPower('player', ClassPowerTypeID)
	local max = UnitPowerMax('player', ClassPowerTypeID)

	for i=1, max do
		if(i <= cur) then
			element[i]:Show()
		else
			element[i]:Hide()
		end
	end

	local oldMax = element.__max
	if(max ~= oldMax) then
		if(max < oldMax) then
			for i=max + 1, oldMax do
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
	if(UnitHasVehicleUI('player') or (RequireSpell and not IsPlayerSpell(RequireSpell))) then
		for i=1, 5 do
			element[i]:Hide()
		end
		ClassPowerDisable(self)
	else
		ClassPowerEnable(self)
		return Path(self, 'UpdateVisibility')
	end
end

local VisibilityPath = function(self, ...)
	return (self.ClassIcons.OverrideVisibility or Visibility) (self, ...)
end

local ForceUpdate = function(element)
	return VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.unit)
end

do
	ClassPowerEnable = function(self)
		self:RegisterEvent('UNIT_DISPLAYPOWER', Path)
		self:RegisterEvent('UNIT_POWER_FREQUENT', Path)
	end

	ClassPowerDisable = function(self)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
		self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
	end

	if(PlayerClass == 'MONK') then
		ClassPowerTypeID = SPELL_POWER_CHI
		ClassPowerType = 'CHI'
	elseif(PlayerClass == 'PALADIN') then
		ClassPowerTypeID = SPELL_POWER_HOLY_POWER
		ClassPowerType = 'HOLY_POWER'
		RequireSpell = 85673 -- Word of Glory
	elseif(PlayerClass == 'PRIEST') then
		ClassPowerTypeID = SPELL_POWER_SHADOW_ORBS
		ClassPowerType = 'SHADOW_ORBS'
		RequireSpell = 95740 -- Shadow Orbs
	elseif(PlayerClass == 'WARLOCK') then
		ClassPowerTypeID = SPELL_POWER_SOUL_SHARDS
		ClassPowerType = 'SOUL_SHARDS'
		RequireSpell = WARLOCK_SOULBURN
	end
end

local Enable = function(self, unit)
	local element = self.ClassIcons
	if(not element) then return end

	element.__owner = self
	element.__max = 0
	element.ForceUpdate = ForceUpdate

	if(ClassPowerType) then
		VisibilityPath(self)

		if(RequireSpell) then
			self:RegisterEvent('SPELLS_CHANGED', VisibilityPath, true)
		end

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

	ClassPowerDisable(self)

	if(RequireSpell) then
		self:UnregisterEvent('SPELLS_CHANGED', VisibilityPath)
	end
end

oUF:AddElement('ClassIcons', VisibilityPath, Enable, Disable)
