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

 Callbacks
]]

local parent, ns = ...
local oUF = ns.oUF

local _, PlayerClass = UnitClass'player'

-- Holds the class specific stuff.
local ClassPowerType, ClassPowerTypes
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

	for i = 1, 5 do
        local icon = element[i]
		if(icon.SetDesaturated) then
			icon:SetDesaturated(desaturated)
		end

		icon:SetVertexColor(red, green, blue)
	end
end

local Update = function(self, event, unit, powerType)
	if(unit and unit ~= 'player' or powerType and not ClassPowerTypes[powerType]) then
		return
	end

    local element = self.ClassIcons

    --[[ :PreUpdate()

     Called before the element has been updated

     Arguments

     self - The ClassIcons element
    ]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local cur = UnitPower('player', ClassPowerType)
	local max = UnitPowerMax('player', ClassPowerType)

	for i = 1, max do
		if(i <= cur) then
			element[i]:Show()
		else
			element[i]:Hide()
		end
	end

	local oldMax = element.__max
	if(max ~= oldMax) then
		if(max < oldMax) then
			for i = max + 1, oldMax do
				element[i]:Hide()
			end
		end

		element.__max = max
	end

    --[[ :PostUpdate(cur, max, hasMaxChanged)

     Called after the element has been updated

     Arguments

     self          - The ClassIcons element
     cur           - The current amount of power
     max           - The maximum amount of power
     hasMaxChanged - Shows if the maximum amount has changed since the last
                     update
    ]]
	if(element.PostUpdate) then
		return element:PostUpdate(cur, max, oldMax ~= max)
	end
end

local Visibility = function(self, event, unit)
    local element = self.ClassIcons
    local hasVehicle = UnitHasVehicleUI('player')
    local isEnabled
    if(hasVehicle or RequireSpell and not IsPlayerSpell(RequireSpell)) then
        ClassPowerDisable(self)
    else
        ClassPowerEnable(self)
        isEnabled = true
    end

    --[[ :PostVisibility(isEnabled)

     Called after the visibility of the element has been updated

     Arguments

     self      - The ClassIcons element
     isEnabled - Shows if the update function is enabled.
                 If it isn't then the element is hidden.
    ]]
    if(element.PostVisibility) then
        return element:PostVisibility(isEnabled)
    end
end
--[[ Hooks

  Override(self) - Used to completely override the internal update function.
                   Removing the table key entry will make the element fall-back
                   to its internal function again.
]]
local Path = function(self, ...)
    return (self.ClassIcons.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Visibility(element.__owner, 'ForceUpdate', element.__owner.unit)
end

do
	ClassPowerEnable = function(self)
		self:RegisterEvent('UNIT_DISPLAYPOWER', Path)
		self:RegisterEvent('UNIT_POWER_FREQUENT', Path)
	end

	ClassPowerDisable = function(self, event)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
		self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)

        local element = self.ClassIcons
        for i = 1, 5 do
            element[i]:Hide()
        end
	end

	if(PlayerClass == 'MONK') then
		ClassPowerType = SPELL_POWER_CHI
		ClassPowerTypes = {
			CHI = true,
			DARK_FORCE = true,
		}
	elseif(PlayerClass == 'PALADIN') then
		ClassPowerType = SPELL_POWER_HOLY_POWER
		ClassPowerTypes = {
			HOLY_POWER = true,
		}
        RequireSpell = 85673 -- Word of Glory
	elseif(PlayerClass == 'PRIEST') then
		ClassPowerType = SPELL_POWER_SHADOW_ORBS
		ClassPowerTypes = {
			SHADOW_ORBS = true,
		}
        RequireSpell = 95740 -- Shadow Orbs
	elseif(PlayerClass == 'WARLOCK') then
		ClassPowerType = SPELL_POWER_SOUL_SHARDS
		ClassPowerTypes = {
			SOUL_SHARDS = true,
		}
		RequireSpell = WARLOCK_SOULBURN
	end
end

local Enable = function(self, unit)
    if(unit ~= 'player' or not ClassPowerType) then return end

	local element = self.ClassIcons
	if(not element) then return end

	element.__owner = self
	element.__max = 0
	element.ForceUpdate = ForceUpdate

    if(RequireSpell) then
        self:RegisterEvent('SPELLS_CHANGED', Visibility, true)
    end

	for i = 1, 5 do
		local icon = element[i]
		if(icon:IsObjectType'Texture' and not icon:GetTexture()) then
			icon:SetTexCoord(0.45703125, 0.60546875, 0.44531250, 0.73437500)
			icon:SetTexture([[Interface\PlayerFrame\Priest-ShadowUI]])
		end
	end

	(element.UpdateTexture or UpdateTexture) (element)

	return true
end

local Disable = function(self)
	local element = self.ClassIcons
	if(not element) then return end

	ClassPowerDisable(self)
end

oUF:AddElement('ClassIcons', Visibility, Enable, Disable)
