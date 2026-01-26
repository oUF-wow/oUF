--[[
# Element: ClassPower

Handles the visibility and updating of the player's class resources (like Chi Orbs or Holy Power) and combo points.

## Widget

ClassPower - An `table` consisting of as many StatusBars as the theoretical maximum return of [UnitPowerMax](https://warcraft.wiki.gg/wiki/API_UnitPowerMax).

## Notes

A default texture will be applied if the sub-widgets are StatusBars and don't have a texture set.
If the sub-widgets are StatusBars, their minimum and maximum values will be set to 0 and 1 respectively.

Supported class powers:
  - All     - Combo Points
  - Evoker  - Essence
  - Mage    - Arcane Charges
  - Monk    - Chi Orbs
  - Paladin - Holy Power
  - Warlock - Soul Shards

## Examples

    local ClassPower = {}
    for index = 1, 10 do
        local Bar = CreateFrame('StatusBar', nil, self)

        -- Position and size.
        Bar:SetSize(16, 16)
        Bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (index - 1) * Bar:GetWidth(), 0)

        ClassPower[index] = Bar
    end

    -- Register with oUF
    self.ClassPower = ClassPower
--]]

local _, ns = ...
local oUF = ns.oUF

local playerClass = UnitClassBase('player')

-- sourced from Blizzard_FrameXMLBase/Constants.lua
local SPEC_DEMONHUNTER_DEVOURER = _G.SPEC_DEMONHUNTER_DEVOURER or 3
local SPEC_MAGE_ARCANE = _G.SPEC_MAGE_ARCANE or 1
local SPEC_MONK_WINDWALKER = _G.SPEC_MONK_WINDWALKER or 3
local SPEC_SHAMAN_ENCHANCEMENT = 2
local SPEC_WARLOCK_DESTRUCTION = _G.SPEC_WARLOCK_DESTRUCTION or 3

local SPELL_POWER_ENERGY = Enum.PowerType.Energy or 3
local SPELL_POWER_COMBO_POINTS = Enum.PowerType.ComboPoints or 4
local SPELL_POWER_SOUL_SHARDS = Enum.PowerType.SoulShards or 7
local SPELL_POWER_HOLY_POWER = Enum.PowerType.HolyPower or 9
local SPELL_POWER_CHI = Enum.PowerType.Chi or 12
local SPELL_POWER_ARCANE_CHARGES = Enum.PowerType.ArcaneCharges or 16
local SPELL_POWER_ESSENCE = Enum.PowerType.Essence or 19

local SPELL_DARK_HEART = Constants.UnitPowerSpellIDs.DARK_HEART_SPELL_ID or 1225789
local SPELL_MAELSTROM_WEAPON = 344179
local SPELL_MAELSTROM_WEAPON_TALENT = 187880
local SPELL_SHRED = 5221
local SPELL_SILENCE_THE_WHISPERS = Constants.UnitPowerSpellIDs.SILENCE_THE_WHISPERS_SPELL_ID or 1227702
local SPELL_VOID_METAMORPHOSIS = Constants.UnitPowerSpellIDs.VOID_METAMORPHOSIS_SPELL_ID or 1217607

local SOUL_FRAGMENTS_NO_META_INDEX = 1
local SOUL_FRAGMENTS_META_INDEX = 2

local ClassPowerEnable, ClassPowerDisable, RefreshEvents, GetPowerUpdaters

-- holds class-specific information for enablement toggles
local classPowerID, classPowerType, classAuraID
local requireSpec, requirePower, requireSpells

local function GetGenericPower(unit)
	return UnitPower(unit, classPowerID)
end

local function GetGenericPowerMax(unit)
	return UnitPowerMax(unit, classPowerID)
end

local function GetGenericPowerColor(element, powerType)
	return element.__owner.colors.power[powerType]
end

local function GetComboPoints(unit)
	return UnitPower(unit, SPELL_POWER_COMBO_POINTS), GetUnitChargedPowerPoints(unit)
end

local function GetComboPointsMax(unit)
	return UnitPowerMax(unit, SPELL_POWER_COMBO_POINTS)
end

local function GetSoulShardsDestro(unit)
	return UnitPower(unit, SPELL_POWER_SOUL_SHARDS, true) / UnitPowerDisplayMod(SPELL_POWER_SOUL_SHARDS)
end

local function GetMaelstromWeapon()
	local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(classAuraID)
	if(auraInfo) then
		return auraInfo.applications
	else
		return 0
	end
end

local function GetMaelstromWeaponMax()
	return C_Spell.GetSpellMaxCumulativeAuraApplications(SPELL_MAELSTROM_WEAPON)
end

local function GetSoulFragments()
	if(C_UnitAuras.GetPlayerAuraBySpellID(SPELL_VOID_METAMORPHOSIS)) then
		local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_SILENCE_THE_WHISPERS)
		if(auraInfo) then
			return auraInfo.applications / GetCollapsingStarCost()
		end
	else
		local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_DARK_HEART)
		if(auraInfo) then
			return auraInfo.applications / C_Spell.GetSpellMaxCumulativeAuraApplications(SPELL_DARK_HEART)
		end
	end

	return 0
end

local function GetSoulFragmentsMax()
	return 1
end

local function GetSoulFragmentsColor(element, powerType)
	local color = element.__owner.colors.power[powerType]
	if(color) then
		if(C_UnitAuras.GetPlayerAuraBySpellID(SPELL_VOID_METAMORPHOSIS)) then
			return color[SOUL_FRAGMENTS_META_INDEX]
		else
			return color[SOUL_FRAGMENTS_NO_META_INDEX]
		end
	end
end

if(playerClass == 'MONK') then
	classPowerID = SPELL_POWER_CHI
	classPowerType = 'CHI'
	requireSpec = SPEC_MONK_WINDWALKER

	GetPowerUpdaters = function()
		return GetGenericPower, GetGenericPowerMax, GetGenericPowerColor
	end
elseif(playerClass == 'PALADIN') then
	classPowerID = SPELL_POWER_HOLY_POWER
	classPowerType = 'HOLY_POWER'

	GetPowerUpdaters = function()
		return GetGenericPower, GetGenericPowerMax, GetGenericPowerColor
	end
elseif(playerClass == 'WARLOCK') then
	classPowerID = SPELL_POWER_SOUL_SHARDS
	classPowerType = 'SOUL_SHARDS'

	GetPowerUpdaters = function()
		local cur = GetGenericPower
		if(C_SpecializationInfo.GetSpecialization() == SPEC_WARLOCK_DESTRUCTION) then
			cur = GetSoulShardsDestro
		end

		return cur, GetGenericPowerMax, GetGenericPowerColor
	end
elseif(playerClass == 'ROGUE' or playerClass == 'DRUID') then
	classPowerID = SPELL_POWER_COMBO_POINTS
	classPowerType = 'COMBO_POINTS'

	if(playerClass == 'DRUID') then
		requirePower = SPELL_POWER_ENERGY
		requireSpells = SPELL_SHRED
	end

	GetPowerUpdaters = function()
		return GetComboPoints, GetComboPointsMax, GetGenericPowerColor
	end
elseif(playerClass == 'MAGE') then
	classPowerID = SPELL_POWER_ARCANE_CHARGES
	classPowerType = 'ARCANE_CHARGES'
	requireSpec = SPEC_MAGE_ARCANE

	GetPowerUpdaters = function()
		return GetGenericPower, GetGenericPowerMax, GetGenericPowerColor
	end
elseif(playerClass == 'EVOKER') then
	classPowerID = SPELL_POWER_ESSENCE
	classPowerType = 'ESSENCE'

	GetPowerUpdaters = function()
		return GetGenericPower, GetGenericPowerMax, GetGenericPowerColor
	end
elseif(playerClass == 'SHAMAN') then
	requireSpells = SPELL_MAELSTROM_WEAPON_TALENT
	classAuraID = SPELL_MAELSTROM_WEAPON
	requireSpec = SPEC_SHAMAN_ENCHANCEMENT
	classPowerType = 'MAELSTROM'

	GetPowerUpdaters = function()
		return GetMaelstromWeapon, GetMaelstromWeaponMax, GetGenericPowerColor
	end
elseif(playerClass == 'DEMONHUNTER') then
	requireSpec = SPEC_DEMONHUNTER_DEVOURER
	classAuraID = SPELL_VOID_METAMORPHOSIS
	classPowerType = 'SOUL_FRAGMENTS'

	GetPowerUpdaters = function()
		return GetSoulFragments, GetSoulFragmentsMax, GetSoulFragmentsColor
	end
end

-- jic
local GetPower, GetPowerMax, GetPowerColor = GetGenericPower, GetGenericPowerMax, GetGenericPowerColor

local function UpdateColor(element, powerType)
	local color = GetPowerColor(element, powerType)
	if(color) then
		for i = 1, #element do
			local bar = element[i]
			bar:GetStatusBarTexture():SetVertexColor(color:GetRGB())
		end
	end

	--[[ Callback: ClassPower:PostUpdateColor(color)
	Called after the element color has been updated.

	* self  - the ClassPower element
	* color - the used ColorMixin-based object (table?)
	--]]
	if(element.PostUpdateColor) then
		element:PostUpdateColor(color)
	end
end

local function Update(self, event, unit, powerType)
	if(not (unit and (UnitIsUnit(unit, 'player') and (not powerType or powerType == classPowerType or event == 'UNIT_AURA')
	or unit == 'vehicle' and powerType == 'COMBO_POINTS'))) then
		return
	end

	local element = self.ClassPower

	--[[ Callback: ClassPower:PreUpdate(event)
	Called before the element has been updated.

	* self  - the ClassPower element
	]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local cur, max, chargedPoints, hasMaxChanged
	if(event ~= 'ClassPowerDisable') then
		cur, chargedPoints = GetPower(unit)
		max = GetPowerMax(unit)

		local hasCurChanged = cur ~= element.__cur
		if(hasCurChanged) then
			local numActive = cur + 0.9
			for i = 1, max do
				if(i > numActive) then
					element[i]:Hide()
					element[i]:SetValue(0)
				else
					element[i]:Show()
					element[i]:SetValue(cur - i + 1)
				end
			end

			element.__cur = cur
		end

		hasMaxChanged = max ~= element.__max
		if(hasMaxChanged) then
			local oldMax = element.__max
			if(max < oldMax) then
				for i = max + 1, oldMax do
					element[i]:Hide()
					element[i]:SetValue(0)
				end
			end

			element.__max = max

			--[[ Override: ClassPower:UpdateColor(powerType)
			Used to completely override the internal function for updating the widgets' colors.

			* self      - the ClassPower element
			* powerType - the active power type (string)
			--]]
			do
				(element.UpdateColor or UpdateColor) (element, powerType)
			end
		end
	end
	--[[ Callback: ClassPower:PostUpdate(cur, max, hasMaxChanged, powerType)
	Called after the element has been updated.

	* self          - the ClassPower element
	* cur           - the current amount of power (number)
	* max           - the maximum amount of power (number)
	* hasMaxChanged - indicates whether the maximum amount has changed since the last update (boolean)
	* powerType     - the active power type (string)
	* ...           - the indices of currently charged power points, if any
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(cur, max, hasMaxChanged, powerType, unpack(chargedPoints or {}))
	end
end

local function Path(self, ...)
	--[[ Override: ClassPower.Override(self, event, unit, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.ClassPower.Override or Update) (self, ...)
end

-- this function is needed in case we need to track multiple spells/talents
local function anySpellKnown(requireSpellss)
	if(type(requireSpellss) == 'table') then
		for _, spellID in next, requireSpellss do
			if C_SpellBook.IsSpellKnown(spellID) then
				return true
			end
		end

		return false
	else
		return C_SpellBook.IsSpellKnown(requireSpellss)
	end
end

local function Visibility(self, event, unit)
	local element = self.ClassPower
	local shouldEnable, shouldRegisterAuraEvent

	if(UnitHasVehicleUI('player')) then
		shouldEnable = PlayerVehicleHasComboPoints()
		unit = 'vehicle'
	elseif(classAuraID) then
		if(not requireSpec or requireSpec == C_SpecializationInfo.GetSpecialization()) then
			if(not requireSpells or anySpellKnown(requireSpells)) then
				shouldEnable = true
				unit = 'player'
			end
		end

		shouldRegisterAuraEvent = shouldEnable == true
	elseif(classPowerID) then
		if(not requireSpec or requireSpec == C_SpecializationInfo.GetSpecialization()) then
			-- use 'player' instead of unit because 'SPELLS_CHANGED' is a unitless event
			if(not requirePower or requirePower == UnitPowerType('player')) then
				if(not requireSpells or anySpellKnown(requireSpells)) then
					shouldEnable = true
					unit = 'player'
				end
			end
		end
	end

	local oldIsClassAura = element.__isClassAura
	element.__isClassAura = shouldRegisterAuraEvent

	local isEnabled = element.__isEnabled
	local powerType = unit == 'vehicle' and 'COMBO_POINTS' or classPowerType

	if(shouldEnable) then
		if(unit == 'vehicle') then
			GetPower, GetPowerMax, GetPowerColor = GetComboPoints, GetComboPointsMax, GetGenericPowerColor
		else
			GetPower, GetPowerMax, GetPowerColor = GetPowerUpdaters()
		end

		--[[ Override: ClassPower:UpdateColor(powerType)
		Used to completely override the internal function for updating the widgets' colors.

		* self      - the ClassPower element
		* powerType - the active power type (string)
		--]]
		(element.UpdateColor or UpdateColor) (element, powerType)
	end

	if(shouldEnable and not isEnabled) then
		ClassPowerEnable(self)

		--[[ Callback: ClassPower:PostVisibility(isVisible)
		Called after the element's visibility has been changed.

		* self      - the ClassPower element
		* isVisible - the current visibility state of the element (boolean)
		--]]
		if(element.PostVisibility) then
			element:PostVisibility(true)
		end
	elseif(not shouldEnable and (isEnabled or isEnabled == nil)) then
		ClassPowerDisable(self)

		if(element.PostVisibility) then
			element:PostVisibility(false)
		end
	elseif(shouldEnable and isEnabled) then
		if(oldIsClassAura and shouldRegisterAuraEvent) then
			RefreshEvents(self)
		end

		Path(self, event, unit, powerType)
	end
end

local function VisibilityPath(self, ...)
	--[[ Override: ClassPower.OverrideVisibility(self, event, unit)
	Used to completely override the internal visibility function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	return (self.ClassPower.OverrideVisibility or Visibility) (self, ...)
end

local function ForceUpdate(element)
	return VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.unit)
end

do
	function RefreshEvents(self)
		if(self.ClassPower.__isClassAura) then
			self:RegisterEvent('UNIT_AURA', Path)

			self:UnregisterEvent('UNIT_POWER_UPDATE', Path)
			self:UnregisterEvent('UNIT_MAXPOWER', Path)
			self:UnregisterEvent('UNIT_POWER_POINT_CHARGE', Path)
		else
			self:RegisterEvent('UNIT_MAXPOWER', Path)
			self:RegisterEvent('UNIT_POWER_UPDATE', Path)
			self:RegisterEvent('UNIT_POWER_POINT_CHARGE', Path)

			self:UnregisterEvent('UNIT_AURA', Path)
		end
	end

	function ClassPowerEnable(self)
		if(self.ClassPower.__isClassAura) then
			self:RegisterEvent('UNIT_AURA', Path)
		else
			self:RegisterEvent('UNIT_MAXPOWER', Path)
			self:RegisterEvent('UNIT_POWER_UPDATE', Path)

			-- according to Blizz any class may receive this event due to specific spell auras
			self:RegisterEvent('UNIT_POWER_POINT_CHARGE', Path)
		end

		self.ClassPower.__isEnabled = true

		if(UnitHasVehicleUI('player')) then
			Path(self, 'ClassPowerEnable', 'vehicle', 'COMBO_POINTS')
		else
			Path(self, 'ClassPowerEnable', 'player', classPowerType)
		end
	end

	function ClassPowerDisable(self)
		self:UnregisterEvent('UNIT_AURA', Path)
		self:UnregisterEvent('UNIT_POWER_UPDATE', Path)
		self:UnregisterEvent('UNIT_MAXPOWER', Path)
		self:UnregisterEvent('UNIT_POWER_POINT_CHARGE', Path)

		local element = self.ClassPower
		for i = 1, #element do
			element[i]:Hide()
		end

		element.__isEnabled = false
		Path(self, 'ClassPowerDisable', 'player', classPowerType)
	end
end

local function Enable(self, unit)
	local element = self.ClassPower
	if(element and UnitIsUnit(unit, 'player')) then
		element.__owner = self
		element.__max = #element
		element.ForceUpdate = ForceUpdate

		if(requireSpec or requireSpells) then
			self:RegisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath, true)
			self:RegisterEvent('SPELLS_CHANGED', VisibilityPath, true)
		end

		if(requirePower) then
			self:RegisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		end

		element.ClassPowerEnable = ClassPowerEnable
		element.ClassPowerDisable = ClassPowerDisable

		for i = 1, #element do
			local bar = element[i]
			if(bar:IsObjectType('StatusBar')) then
				if(not bar:GetStatusBarTexture()) then
					bar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
				end

				bar:SetMinMaxValues(0, 1)
			end
		end

		return true
	end
end

local function Disable(self)
	if(self.ClassPower) then
		ClassPowerDisable(self)

		self:UnregisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		self:UnregisterEvent('SPELLS_CHANGED', Visibility)
	end
end

oUF:AddElement('ClassPower', VisibilityPath, Enable, Disable)
