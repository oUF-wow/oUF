--[[ Element: Warlock Power Bar
 Handle updating of demonic fury and burning embers.
 (Soul shards are handled by the Class Icons element.)

 Widget

 WarlockPowerBar - an array consisting of 5 UI StatusBars

 Notes

 The first 4 status bars represent burning embers.
 The fifth status bar represents demonic fury.

 Example

   local wpb = {}
   for index = 1, 5 do
      local bar = CreateFrame("StatusBar", nil, self)

      -- Position and size.
      bar:SetSize(16, 16)
      bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * bar:GetWidth(), 0)

      wpb[index] = bar
   end

   -- Register it with oUF
   self.WarlockPowerBar = wpb

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.

 Callbacks
]]

local _, ns = ...
local oUF = ns.oUF

local _, playerClass = UnitClass'player'
local spec = 0
local specPowerType

local SPEC_WARLOCK_AFFLICTION = SPEC_WARLOCK_AFFLICTION
local SPEC_WARLOCK_DEMONOLOGY = SPEC_WARLOCK_DEMONOLOGY
local SPEC_WARLOCK_DESTRUCTION = SPEC_WARLOCK_DESTRUCTION
local WARLOCK_BURNING_EMBERS = WARLOCK_BURNING_EMBERS
local WARLOCK_GREEN_FIRE = WARLOCK_GREEN_FIRE
local SPELL_POWER_DEMONIC_FURY = SPELL_POWER_DEMONIC_FURY
local SPELL_POWER_BURNING_EMBERS = SPELL_POWER_BURNING_EMBERS
local MAX_POWER_PER_EMBER = MAX_POWER_PER_EMBER

oUF.colors.power['DEMONIC_FURY'] = {155/255, 70/255, 209/255}
oUF.colors.power['BURNING_EMBERS'] = {242/255, 149/255, 32/255}
oUF.colors.power['GREEN_EMBERS'] = {100/255, 173/255, 21/255}

local Update = function(self, event, unit, powerType)
	if(unit and unit ~= 'player' or powerType and powerType ~= specPowerType) then return end

	local element = self.WarlockPowerBar
	local power = 0

	--[[ :PreUpdate()

	 Called before the element has been updated.

	 Arguments

	 self - The WarlockPowerBar element.
	]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	if(powerType == 'DEMONIC_FURY') then
		power = UnitPower('player', SPELL_POWER_DEMONIC_FURY)

		element[5]:SetValue(power)
	elseif(powerType == 'BURNING_EMBERS') then
		power = UnitPower('player', SPELL_POWER_BURNING_EMBERS, true)

		for i = 1, 4 do
			element[i]:SetValue(power)
		end
	end

	--[[ :PostUpdate(powerType, power)

	 Called after the element has been updated.

	 Arguments

	 self      - The WarlockPowerBar element.
	 powerType - Power type which the update was done for (`'DEMONIC_FURY'` or `'BURNING_EMBERS'`).
	 power     - Current amount of demonic fury or burning embers.
	 spec      - The current spec of the warlock (`2` or `3`).
	]]
	if(element.PostUpdate) then
		element:PostUpdate(powerType, power, spec)
	end
end

local Path = function(self, ...)
	return (self.WarlockPowerBar.Override or Update)(self, ...)
end

local Visibility
Visibility = function(self, event)
	local element = self.WarlockPowerBar
	local show

	spec = GetSpecialization() or 0

	if(spec > SPEC_WARLOCK_AFFLICTION and not UnitHasVehicleUI'player') then
		if(spec == SPEC_WARLOCK_DEMONOLOGY) then
			self:UnregisterEvent('SPELLS_CHANGED', Visibility)

			show = true
			specPowerType = 'DEMONIC_FURY'

			local color = self.colors.power[specPowerType]
			local red, green, blue = color[1], color[2], color[3]

			for i = 1, 5 do
				local segment = element[i]
				if(i < 5) then
					segment:Hide()
				else
					segment:SetMinMaxValues(0, UnitPowerMax('player', SPELL_POWER_DEMONIC_FURY))
					segment:SetStatusBarColor(red, green, blue)
					if(segment.bg) then
						local mult = segment.bg.multiplier or 1
						segment.bg:SetVertexColor(red * mult, green * mult, blue * mult)
					end
					segment:Show()
				end
			end
		elseif(spec == SPEC_WARLOCK_DESTRUCTION) then
			-- we keep this registered because of green fire
			self:RegisterEvent('SPELLS_CHANGED', Visibility, true)

			if(IsPlayerSpell(WARLOCK_BURNING_EMBERS)) then
				show = true
				specPowerType = 'BURNING_EMBERS'

				local color
				if(IsSpellKnown(WARLOCK_GREEN_FIRE)) then
					color = self.colors.power['GREEN_EMBERS']
				else
					color = self.colors.power[specPowerType]
				end
				local red, green, blue = color[1], color[2], color[3]

				for i = 1, 4 do
					local segment = element[i]
					segment:SetStatusBarColor(red, green, blue)
					segment:SetMinMaxValues(MAX_POWER_PER_EMBER * i - MAX_POWER_PER_EMBER, MAX_POWER_PER_EMBER * i)
					if(segment.bg) then
						local mult = segment.bg.multiplier or 1
						segment.bg:SetVertexColor(red * mult, green * mult, blue * mult)
					end
					segment:Show()
				end
				element[5]:Hide()
			end
		end
	end

	if(not show) then
		self:UnregisterEvent('UNIT_POWER', Path)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
		self:UnregisterEvent('SPELLS_CHANGED', Visibility)

		for i = 1, 5 do
			element[i]:Hide()
		end
	end

	--[[ :PostVisibility(spec, show)

	 Called after updating the elements visibility

	 Arguments

	 self - The WarlockPowerBar element.
	 spec - The current spec of the warlock. Either 1, 2, or 3.
	 show - `true` is the element is currently shown, `nil` otherwise.
	]]
	if(element.PostVisibility) then
		element:PostVisibility(spec, show)
	end

	if(show) then
		self:RegisterEvent('UNIT_POWER', Path)
		self:RegisterEvent('UNIT_DISPLAYPOWER', Path)

		return Path(self, 'Visibility', self.unit, specPowerType)
	end
end

local ForceUpdate = function(element)
	return Visibility(element.__owner, 'ForceUpdate')
end

local Enable = function(self, unit)
	if(unit ~= 'player' or playerClass ~= 'WARLOCK') then return end

	local element = self.WarlockPowerBar

	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		for i = 1, 5 do
			local segment = element[i]
			if(segment:IsObjectType'StatusBar' and not segment:GetStatusBarTexture()) then
				segment:SetStatusBarTexture[=[Interface\TargetingFrame\UI-StatusBar]=]
			end
		end

		self:RegisterEvent('PLAYER_TALENT_UPDATE', Visibility, true)

		return true
	end
end

local Disable = function(self)
	local element = self.WarlockPowerBar

	if(element) then
		self:UnregisterEvent('UNIT_POWER', Path)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
		self:UnregisterEvent('PLAYER_TALENT_UPDATE', Visibility)
		self:UnregisterEvent('SPELLS_CHANGED', Visibility)

		for i = 1, 5 do
			element[i]:Hide()
		end
	end
end

oUF:AddElement('WarlockPowerBar', Visibility, Enable, Disable)
