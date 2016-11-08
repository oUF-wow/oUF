--[[
# Element: ClassPower

Toggles the visibility of icons depending on the player's class and specialization.

## Widget

ClassPower - An array consisting of as many UI Textures as the theoretical maximum return of `UnitPowerMax`.

## Notes

All     - Combo Points
Mage    - Arcane Charges
Monk    - Chi Orbs
Paladin - Holy Power
Warlock - Soul Shards

## Examples

    local ClassPower = {}
    for index = 1, 6 do
      local Icon = self:CreateTexture(nil, 'BACKGROUND')

      -- Position and size.
      Icon:SetSize(16, 16)
      Icon:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * Icon:GetWidth(), 0)

      ClassPower[index] = Icon
    end

    -- Register with oUF
    self.ClassPower = ClassPower
--]]

local parent, ns = ...
local oUF = ns.oUF

local _, PlayerClass = UnitClass('player')

-- Holds the class specific stuff.
local ClassPowerID, ClassPowerType
local ClassPowerEnable, ClassPowerDisable
local RequireSpec, RequireSpell

local function UpdateTexture(element)
	local color = oUF.colors.power[ClassPowerType or 'COMBO_POINTS']
	for i = 1, #element do
		local icon = element[i]
		if(icon.SetDesaturated) then
			icon:SetDesaturated(PlayerClass ~= 'PRIEST')
		end

		icon:SetVertexColor(color[1], color[2], color[3])
	end
end

local function Update(self, event, unit, powerType)
	if(not (unit == 'player' and powerType == ClassPowerType
		or unit == 'vehicle' and powerType == 'COMBO_POINTS')) then
		return
	end

	local element = self.ClassPower

	--[[ Callback: ClassPower:PreUpdate(event)
	Called before the element has been updated.

	* self  - the ClassPower element
	* event - the event that triggered the update
	]]
	if(element.PreUpdate) then
		element:PreUpdate(event)
	end

	local cur, max, oldMax
	if(event ~= 'ClassPowerDisable') then
		if(unit == 'vehicle') then
			-- BUG: UnitPower always returns 0 combo points for vehicles
			cur = GetComboPoints(unit)
			max = MAX_COMBO_POINTS
		else
			cur = UnitPower('player', ClassPowerID)
			max = UnitPowerMax('player', ClassPowerID)
		end

		for i = 1, max do
			if(i <= cur) then
				element[i]:Show()
			else
				element[i]:Hide()
			end
		end

		oldMax = element.__max
		if(max ~= oldMax) then
			if(max < oldMax) then
				for i = max + 1, oldMax do
					element[i]:Hide()
				end
			end

			element.__max = max
		end
	end
	--[[ Callback: ClassPower:PostUpdate(cur, max, hasMaxChanged, powerType, event)
	Called after the element has been updated.

	* self          - the ClassPower element
	* cur           - the current amount of power
	* max           - the maximum amount of power
	* hasMaxChanged - shows if the maximum amount has changed since the last update
	* powerType     - the type of power used
	* event         - the event that triggered the update
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(cur, max, oldMax ~= max, powerType, event)
	end
end

local function Path(self, ...)
	--[[ Override: ClassPower:Override(...)
	Used to completely override the internal update function.

	* self - the ClassPower element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.ClassPower.Override or Update) (self, ...)
end

local function Visibility(self, event, unit)
	local element = self.ClassPower
	local shouldEnable

	if(UnitHasVehicleUI('player')) then
		shouldEnable = true
		unit = 'vehicle'
	elseif(ClassPowerID) then
		if(not RequireSpec or RequireSpec == GetSpecialization()) then
			if(not RequireSpell or IsPlayerSpell(RequireSpell)) then
				self:UnregisterEvent('SPELLS_CHANGED', Visibility)
				shouldEnable = true
			else
				self:RegisterEvent('SPELLS_CHANGED', Visibility, true)
			end
		end
	end

	local isEnabled = element.isEnabled
	if(shouldEnable and not isEnabled) then
		ClassPowerEnable(self)
	elseif(not shouldEnable and (isEnabled or isEnabled == nil)) then
		ClassPowerDisable(self)
	elseif(shouldEnable and isEnabled) then
		Path(self, event, unit, unit == 'vehicle' and 'COMBO_POINTS' or ClassPowerType)
	end
end

local function VisibilityPath(self, ...)
	--[[ Override: ClassPower:OverrideVisibility(...)
	Used to completely override the internal visibility function.

	* self - the ClassPower element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.ClassPower.OverrideVisibility or Visibility) (self, ...)
end

local function ForceUpdate(element)
	return VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.unit)
end

do
	function ClassPowerEnable(self)
		self:RegisterEvent('UNIT_DISPLAYPOWER', Path)
		self:RegisterEvent('UNIT_POWER_FREQUENT', Path)
		self:RegisterEvent('UNIT_MAXPOWER', Path)

		if(UnitHasVehicleUI('player')) then
			Path(self, 'ClassPowerEnable', 'vehicle', 'COMBO_POINTS')
		else
			Path(self, 'ClassPowerEnable', 'player', ClassPowerType)
		end
		self.ClassPower.isEnabled = true
	end

	function ClassPowerDisable(self)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
		self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
		self:UnregisterEvent('UNIT_MAXPOWER', Path)

		local element = self.ClassPower
		for i = 1, #element do
			element[i]:Hide()
		end

		Path(self, 'ClassPowerDisable', 'player', ClassPowerType)
		self.ClassPower.isEnabled = false
	end

	if(PlayerClass == 'MONK') then
		ClassPowerID = SPELL_POWER_CHI
		ClassPowerType = 'CHI'
		RequireSpec = SPEC_MONK_WINDWALKER
	elseif(PlayerClass == 'PALADIN') then
		ClassPowerID = SPELL_POWER_HOLY_POWER
		ClassPowerType = 'HOLY_POWER'
		RequireSpec = SPEC_PALADIN_RETRIBUTION
	elseif(PlayerClass == 'WARLOCK') then
		ClassPowerID = SPELL_POWER_SOUL_SHARDS
		ClassPowerType = 'SOUL_SHARDS'
	elseif(PlayerClass == 'ROGUE' or PlayerClass == 'DRUID') then
		ClassPowerID = SPELL_POWER_COMBO_POINTS
		ClassPowerType = 'COMBO_POINTS'

		if(PlayerClass == 'DRUID') then
			RequireSpell = 5221 -- Shred
		end
	elseif(PlayerClass == 'MAGE') then
		ClassPowerID = SPELL_POWER_ARCANE_CHARGES
		ClassPowerType = 'ARCANE_CHARGES'
		RequireSpec = SPEC_MAGE_ARCANE
	end
end

local function Enable(self, unit)
	if(unit ~= 'player') then return end

	local element = self.ClassPower
	if(element) then
		element.__owner = self
		element.__max = #element
		element.ForceUpdate = ForceUpdate

		if(RequireSpec or RequireSpell) then
			self:RegisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath, true)
		end

		element.ClassPowerEnable = ClassPowerEnable
		element.ClassPowerDisable = ClassPowerDisable

		local isChildrenTextures
		for i = 1, #element do
			local icon = element[i]
			if(icon:IsObjectType('Texture')) then
				if(not icon:GetTexture()) then
					icon:SetTexCoord(0.45703125, 0.60546875, 0.44531250, 0.73437500)
					icon:SetTexture([[Interface\PlayerFrame\Priest-ShadowUI]])
				end

				isChildrenTextures = true
			end
		end

		if(isChildrenTextures) then
			--[[ Override: ClassPower:UpdateTexture()
			Used to completely override the internal function for updating the power icon textures.

			* self - the ClassPower element
			--]]
			(element.UpdateTexture or UpdateTexture) (element)
		end

		return true
	end
end

local function Disable(self)
	if(self.ClassPower) then
		ClassPowerDisable(self)
	end
end

oUF:AddElement('ClassPower', VisibilityPath, Enable, Disable)
