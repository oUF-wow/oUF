local _, ns = ...
local oUF = ns.oUF

if(not oUF.isClassic) then return end

local _, playerClass = UnitClass('player')

local CAT_FORM = 768
local SPELL_POWER_ENERGY = Enum.PowerType.Energy or 3
local SPELL_POWER_COMBO_POINTS = Enum.PowerType.ComboPoints or 14

local function Update(self, event, unit, powerType)
	if (not UnitIsUnit(unit, 'player') or powerType and powerType ~= 'COMBO_POINTS') then
		return
	end

	local element = self.ComboPoints
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local cur

	if(event ~= 'ElementDisable') then
		cur = UnitPower('player', SPELL_POWER_COMBO_POINTS)

		for i = 1, #element do
			if i <= cur then
				element[i]:Show()
			else
				element[i]:Hide()
			end
		end
	end

	if(element.PostUpdate) then
		element:PostUpdate(cur)
	end
end

local function Path(self, ...)
	return (self.ComboPoints.Override or Update) (self, ...)
end

local function Visibility(self, event, unit)
	local element = self.ComboPoints
	local shouldEnable

	if(playerClass == 'ROGUE') then
		shouldEnable = true
	elseif(playerClass == 'DRUID') then
		if(UnitPowerType('player') == SPELL_POWER_ENERGY) then
			if(IsPlayerSpell(CAT_FORM)) then
				self:UnregisterEvent('SPELLS_CHANGED', Visibility)
				shouldEnable = true
			else
				self:RegisterEvent('SPELLS_CHANGED', Visibility, true)
			end
		end
	end

	if(shouldEnable) then
		if(not element.isEnabled) then
			self:RegisterEvent('UNIT_POWER_UPDATE', Path, self.unit ~= 'player')

			element.isEnabled = true
		end

		Path(self, event, 'player')
	else
		if(element.isEnabled or element.isEnabled == nil) then
			self:UnregisterEvent('UNIT_POWER_UPDATE', Path)

			for i = 1, #element do
				element[i]:Hide()
			end

			element.isEnabled = false
		end

		Path(self, 'ElementDisable', 'player')
	end
end

local function VisibilityPath(self, ...)
	return (self.ComboPoints.VisibilityOverride or Visibility) (self, ...)
end

local function ForceUpdate(element)
	return VisibilityPath(element.__owner, 'ForceUpdate', 'player')
end

local function Enable(self, unit)
	local element = self.ComboPoints
	if(element) then
		element.__owner = self
		element.__max = #element
		element.ForceUpdate = ForceUpdate

		for i = 1, #element do
			local cpoint = element[i]
			if(cpoint:IsObjectType('Texture') and not cpoint:GetTexture()) then
				cpoint:SetTexture([[Interface\ComboFrame\ComboPoint]])
				cpoint:SetTexCoord(0, 0.375, 0, 1)
			end
		end

		if(playerClass == 'DRUID') then
			self:RegisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		end

		return true
	end
end

local function Disable(self, unit)
	local element = self.ComboPoints
	if(element) then
		for i = 1, #element do
			element[i]:Hide()
		end

		self:UnregisterEvent('SPELLS_CHANGED', Visibility)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		self:UnregisterEvent('UNIT_POWER_UPDATE', Path)
	end
end

oUF:AddElement('ComboPoints', VisibilityPath, Enable, Disable)
