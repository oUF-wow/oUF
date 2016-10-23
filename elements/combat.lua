--[[ Element: Combat Icon
 Toggles the visibility of `self.Combat` based on the player's combat status.

 Widget

 Combat - Any UI widget.

 Notes

 The default assistant icon will be applied if the UI widget is a texture and
 doesn't have a texture or color defined.

 Examples

   -- Position and size
   local Combat = self:CreateTexture(nil, 'OVERLAY')
   Combat:SetSize(16, 16)
   Combat:SetPoint('TOP', self)

   -- Register it with oUF
   self.Combat = Combat

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.

]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.Combat
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local inCombat = UnitAffectingCombat('player')
	if(inCombat) then
		element:Show()
	else
		element:Hide()
	end

	if(element.PostUpdate) then
		return element:PostUpdate(inCombat)
	end
end

local function Path(self, ...)
	return (self.Combat.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.Combat
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('PLAYER_REGEN_DISABLED', Path, true)
		self:RegisterEvent('PLAYER_REGEN_ENABLED', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
			element:SetTexCoord(.5, 1, 0, .49)
		end

		return true
	end
end

local function Disable(self)
	local element = self.Combat
	if(element) then
		element:Hide()

		self:UnregisterEvent('PLAYER_REGEN_DISABLED', Path)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED', Path)
	end
end

oUF:AddElement('Combat', Path, Enable, Disable)
