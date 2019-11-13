--[[
# Element: ClassPower

Toggles visibility of the player's combo points.

## Widget

ClassPower - A `table` holding five UI widgets.

## Notes

The default combo point texture will be applied if the widgets are of type `Texture` and don't have a texture or color
defined.

A default texture will be applied if the widgets are of type `StatusBar` and don't have a texture defined.
If the widgets are StatusBars, their minimum and maximum values will be set to 0 and 1 respectively, and their value
will be set to 1.

## Examples

    local ClassPower = {}
    for index = 1, MAX_COMBO_POINTS do
        local CPoint = self:CreateTexture(nil, 'BACKGROUND')

        -- Position and size of the combo point.
        CPoint:SetSize(12, 16)
        CPoint:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * CPoint:GetWidth(), 0)

        ClassPower[index] = CPoint
    end

   -- Register with oUF
   self.ClassPower = ClassPower

--]]

local _, ns = ...
local oUF = ns.oUF

if(not oUF.isClassic) then return end

local _, playerClass = UnitClass('player')

local CAT_FORM = 768
local SPELL_POWER_ENERGY = Enum and Enum.PowerType.Energy or 3
local SPELL_POWER_COMBO_POINTS = Enum and Enum.PowerType.ComboPoints or 14

local function Update(self, event, unit, powerType)
	if (not UnitIsUnit(unit, 'player') or powerType and powerType ~= 'COMBO_POINTS') then
		return
	end

	local element = self.ClassPower
	if(element.PreUpdate) then
		--[[ Callback: ClassPower:PostUpdate()
		Called before the element has been updated.

		* self - the ClassPower element
		--]]
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
		--[[ Callback: ClassPower:PostUpdate(cur)
		Called after the element has been updated.

		* self - the ClassPower element
		* cur  - the amount of combo points on the current target (number)
		--]]
		element:PostUpdate(cur)
	end
end

local function Path(self, ...)
	--[[ Override: ClassPower.Override(self, event, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.ClassPower.Override or Update) (self, ...)
end

local function Visibility(self, event, unit)
	local element = self.ClassPower
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
	--[[ Override: ClassPower.OverrideVisibility(self, event, ...)
	Used to completely override the internal visibility function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* ...   - the arguments accompanying the event (string)
	--]]
	return (self.ClassPower.VisibilityOverride or Visibility) (self, ...)
end

local function ForceUpdate(element)
	return VisibilityPath(element.__owner, 'ForceUpdate', 'player')
end

local function Enable(self, unit)
	local element = self.ClassPower
	if(element) then
		element.__owner = self
		element.__max = #element
		element.ForceUpdate = ForceUpdate

		for i = 1, #element do
			local cpoint = element[i]
			if(cpoint:IsObjectType('Texture') and not cpoint:GetTexture()) then
				cpoint:SetTexture([[Interface\ComboFrame\ComboPoint]])
				cpoint:SetTexCoord(0, 0.375, 0, 1)
			elseif(cpoint:IsObjectType('StatusBar')) then
				if(not cpoint:GetStatusBarTexture()) then
					cpoint:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
				end

				cpoint:SetMinMaxValues(0, 1)
				cpoint:SetValue(1)
			end
		end

		if(playerClass == 'DRUID') then
			self:RegisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		end

		return true
	end
end

local function Disable(self, unit)
	local element = self.ClassPower
	if(element) then
		for i = 1, #element do
			element[i]:Hide()
		end

		self:UnregisterEvent('SPELLS_CHANGED', Visibility)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		self:UnregisterEvent('UNIT_POWER_UPDATE', Path)
	end
end

oUF:AddElement('ClassPower', VisibilityPath, Enable, Disable)
