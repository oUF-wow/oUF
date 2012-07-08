--[[ Element: Harmony Orbs
 Toggles visibility of the players Chi.

 Widget

 Harmomy - An array consisting of four UI widgets.

 Notes

 The default harmony orb texture will be applied to textures within the Harmony
 array that don't have a texture or color defined.

 Examples

   local Harmony = {}
   for index = 1, UnitPowerMax('player', SPELL_POWER_LIGHT_FORCE) do
      local Chi = self:CreateTexture(nil, 'BACKGROUND')
   
      -- Position and size of the chi orbs.
      Chi:SetSize(14, 14)
      Chi:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * Chi:GetWidth(), 0)
   
      Harmony[index] = Chi
   end
   
   -- Register with oUF
   self.Harmony = Harmony

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local SPELL_POWER_LIGHT_FORCE = SPELL_POWER_LIGHT_FORCE

local Update = function(self, event, unit)
	if(unit ~= 'player') then return end

	local element = self.Harmony
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local chi = UnitPower(unit, SPELL_POWER_LIGHT_FORCE)

	for index = 1, UnitPowerMax(unit, SPELL_POWER_LIGHT_FORCE) do
		if(index <= chi) then
			element[index]:Show()
		else
			element[index]:Hide()
		end
	end

	if(element.PostUpdate) then
		return element:PostUpdate(chi)
	end
end

local Path = function(self, ...)
	return (self.Harmony.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self, unit)
	local element = self.Harmony
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER', Path, true)
		self:RegisterEvent('UNIT_DISPLAYPOWER', Path, true)

		for index = 1, UnitPowerMax(unit, SPELL_POWER_LIGHT_FORCE) do
			local chi = element[index]
			if(chi:IsObjectType'Texture' and not chi:GetTexture()) then
				chi:SetTexture[[Interface\PlayerFrame\MonkUI]]
				chi:SetTexCoord(0.00390625, 0.08593750, 0.71093750, 0.87500000)
			end
		end

		return true
	end
end

local Disable = function(self)
	local element = self.Harmony
	if(element) then
		self:UnregisterEvent('UNIT_POWER', Path)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
	end
end

oUF:AddElement('Harmony', Path, Enable, Disable)
