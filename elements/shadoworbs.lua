--[[ Element: Shadow Orbs
 Toggles visibility of the players Shadow Orbs.

 Widget

 ShadowOrbs - An array consisting of three UI widgets.

 Notes

 The default shadow orbs texture will be applied to textures within the ShadowOrbs
 array that don't have a texture or color defined.

 Examples

   local ShadowOrbs = {}
   for index = 1, PRIEST_BAR_NUM_ORBS do
      local Orb = self:CreateTexture(nil, 'BACKGROUND')
   
      -- Position and size of the orb.
      Orb:SetSize(14, 14)
      Orb:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * Orb:GetWidth(), 0)
   
      ShadowOrbs[index] = Orb
   end
   
   -- Register with oUF
   self.ShadowOrbs = ShadowOrbs

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local SPELL_POWER_SHADOW_ORBS = SPELL_POWER_SHADOW_ORBS
local PRIEST_BAR_NUM_ORBS = PRIEST_BAR_NUM_ORBS
local SPEC_PRIEST_SHADOW = SPEC_PRIEST_SHADOW

local Update = function(self, event, unit, powerType)
	if(self.unit ~= unit or (powerType and powerType ~= 'SHADOW_ORBS')) then return end

	local element = self.ShadowOrbs
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local numOrbs = UnitPower(unit, SPELL_POWER_SHADOW_ORBS)

	for index = 1, PRIEST_BAR_NUM_ORBS do
		if(index <= numOrbs) then
			element[index]:Show()
		else
			element[index]:Hide()
		end
	end

	if(element.PostUpdate) then
		return element:PostUpdate(numOrbs)
	end
end

local Visibility = function(self, event, unit)
	local element = self.ShadowOrbs
	if(GetSpecialization() == SPEC_PRIEST_SHADOW) then
		element:Show()
	else
		element:Hide()
	end
end

local Path = function(self, ...)
	return (self.ShadowOrbs.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self, unit)
	local element = self.ShadowOrbs
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER', Path)
		self:RegisterEvent('UNIT_DISPLAYPOWER', Path)
		self:RegisterEvent('PLAYER_TALENT_UPDATE', Visibility, true)

		for index = 1, PRIEST_BAR_NUM_ORBS do
			local orb = element[index]
			if(orb:IsObjectType'Texture' and not orb:GetTexture()) then
				orb:SetTexture[[Interface\PlayerFrame\Priest-ShadowUI]]
				orb:SetTexCoord(0.45703125, 0.60546875, 0.44531250, 0.73437500)
			end
		end

		return true
	end
end

local Disable = function(self)
	local element = self.ShadowOrbs
	if(element) then
		self:UnregisterEvent('UNIT_POWER', Path)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
		self:UnregisterEvent('PLAYER_TALENT_UPDATE', Visibility)
	end
end

oUF:AddElement('ShadowOrbs', Path, Enable, Disable)
