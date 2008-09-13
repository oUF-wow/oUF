--[[
	Elements handled: .Power

	Shared:
	 The following settings are listed by priority:
	 - colorTapping
	 - colorDisconnected
	 - colorHappiness
	 - colorPower
	 - colorClass
	 - colorReaction
	 - colorSmooth - will use smoothGradient instead of the internal gradient if set.

	Background:
	 - multiplier - number used to manipulate the power background. (default: 1)

	WotLK only:
	 This option will only enable for player and pet.
	 - frequentUpdates - do OnUpdate polling of power data.

	Functions that can be overridden from within a layout:
	 - :PreUpdatePower(event, unit)
	 - :OverrideUpdatePower(event, unit, bar, min, max) - Setting this function
	 will disable the above color settings.
	 - :PostUpdatePower(event, unit, bar, min, max)
--]]

local wotlk = select(4, GetBuildInfo()) >= 3e4

local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType
local min, max, bar

local OnPowerUpdate
do
	local UnitMana = UnitMana
	OnPowerUpdate = function(self)
		if(self.disconnected) then return end
		local power = UnitMana(self.unit)

		if(power ~= self.min) then
			self:SetValue(power)
			self.min = power

			self:GetParent():UNIT_MANA("OnPowerUpdate", self.unit)
		end
	end
end

function oUF:UNIT_MAXMANA(event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdatePower) then self:PreUpdatePower(event, unit) end

	min, max = UnitMana(unit), UnitManaMax(unit)
	bar = self.Power
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	bar.disconnected = not UnitIsConnected(unit)
	bar.unit = unit

	if(not self.OverrideUpdatePower) then
		local r, g, b, t
		if(bar.colorTapping and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
			t = self.colors.tapped
		elseif(bar.colorDisconnected and not UnitIsConnected(unit)) then
			t = self.colors.disconnected
		elseif(bar.colorHappiness and unit == "pet" and GetPetHappiness()) then
			t = self.colors.happiness[GetPetHappiness()]
		elseif(bar.colorPower) then
			local _, ptype
			if(wotlk) then
				_, ptype = UnitPowerType(unit)
			else
				ptype = UnitPowerType(unit)
			end

			t = self.colors.power[ptype]
		elseif(bar.colorClass and UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			t = self.colors.class[class]
		elseif(bar.colorReaction) then
			t = self.colors.reaction[UnitReaction(unit, "player")]
		elseif(bar.colorSmooth) then
			r, g, b = self.ColorGradient(min / max, unpack(bar.smoothGradient or self.colors.smooth))
		end

		if(t) then
			r, g, b = t[1], t[2], t[3]
		end

		if(b) then
			bar:SetStatusBarColor(r, g, b)

			local bg = bar.bg
			if(bg) then
				local mu = bg.multiplier or 1
				bg:SetVertexColor(r * mu, g * mu, b * mu)
			end
		end
	else
		self:OverrideUpdatePower(event, unit, bar, min, max)
	end

	if(self.PostUpdatePower) then self:PostUpdatePower(event, unit, bar, min, max) end
end

oUF.UNIT_MANA = oUF.UNIT_MAXMANA
oUF.UNIT_RAGE = oUF.UNIT_MAXMANA
oUF.UNIT_FOCUS = oUF.UNIT_MAXMANA
oUF.UNIT_ENERGY = oUF.UNIT_MAXMANA
oUF.UNIT_MAXRAGE = oUF.UNIT_MAXMANA
oUF.UNIT_MAXFOCUS = oUF.UNIT_MAXMANA
oUF.UNIT_MAXENERGY = oUF.UNIT_MAXMANA
oUF.UNIT_DISPLAYPOWER = oUF.UNIT_MAXMANA
oUF.UNIT_RUNIC_POWER = oUF.UNIT_MAXMANA
oUF.UNIT_MAXRUNIC_POWER = oUF.UNIT_MAXMANA

table.insert(oUF.subTypes, function(self, unit)
	local power = self.Power
	if(power) then
		if(power.frequentUpdates and (unit == 'player' or unit == 'pet')) then
			power:SetScript("OnUpdate", OnPowerUpdate)
		else
			self:RegisterEvent"UNIT_MANA"
			self:RegisterEvent"UNIT_RAGE"
			self:RegisterEvent"UNIT_FOCUS"
			self:RegisterEvent"UNIT_ENERGY"
			self:RegisterEvent"UNIT_RUNIC_POWER"
		end
		self:RegisterEvent"UNIT_MAXMANA"
		self:RegisterEvent"UNIT_MAXRAGE"
		self:RegisterEvent"UNIT_MAXFOCUS"
		self:RegisterEvent"UNIT_MAXENERGY"
		self:RegisterEvent"UNIT_DISPLAYPOWER"
		self:RegisterEvent"UNIT_MAXRUNIC_POWER"

		self:RegisterEvent'UNIT_HAPPINESS'
		-- For tapping.
		self:RegisterEvent'UNIT_FACTION'

		if(not power:GetStatusBarTexture()) then
			power:SetStatusBarTexture[[Interface\TargetingFrame\UI-StatusBar]]
		end
	end
end)
oUF:RegisterSubTypeMapping"UNIT_MAXMANA"
