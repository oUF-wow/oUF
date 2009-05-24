--[[
	Elements handled: .Health

	Shared:
	 The following settings are listed by priority:
	 - colorTapping
	 - colorDisconnected
	 - colorHappiness
	 - colorClass (Colors player units based on class)
	 - colorClassPet (Colors pet units based on class)
	 - colorClassNPC (Colors non-player units based on class)
	 - colorReaction
	 - colorSmooth - will use smoothGradient instead of the internal gradient if set.
	 - colorHealth

	Background:
	 - multiplier - number used to manipulate the power background. (default: 1)

	WotLK only:
	 - frequentUpdates - do OnUpdate polling of health data.

	Functions that can be overridden from within a layout:
	 - :PreUpdateHealth(event, unit)
	 - :OverrideUpdateHealth(event, unit, bar, min, max) - Setting this function
	 will disable the above color settings.
	 - :PostUpdateHealth(event, unit, bar, min, max)
--]]
local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local OnHealthUpdate
do
	local UnitHealth = UnitHealth
	OnHealthUpdate = function(self)
		if(self.disconnected) then return end
		local health = UnitHealth(self.unit)

		if(health ~= self.min) then
			self.min = health

			self:GetParent():UNIT_MAXHEALTH("OnHealthUpdate", self.unit)
		end
	end
end

local Update = function(self, event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdateHealth) then self:PreUpdateHealth(event, unit) end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	local bar = self.Health
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	bar.disconnected = not UnitIsConnected(unit)
	bar.unit = unit

	if(not self.OverrideUpdateHealth) then
		local r, g, b, t
		if(bar.colorTapping and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
			t = self.colors.tapped
		elseif(bar.colorDisconnected and not UnitIsConnected(unit)) then
			t = self.colors.disconnected
		elseif(bar.colorHappiness and unit == "pet" and GetPetHappiness()) then
			t = self.colors.happiness[GetPetHappiness()]
		elseif(bar.colorClass and UnitIsPlayer(unit)) or
			(bar.colorClassNPC and not UnitIsPlayer(unit)) or
			(bar.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			t = self.colors.class[class]
		elseif(bar.colorReaction and UnitReaction(unit, 'player')) then
			t = self.colors.reaction[UnitReaction(unit, "player")]
		elseif(bar.colorSmooth and max ~= 0) then
			r, g, b = self.ColorGradient(min / max, unpack(bar.smoothGradient or self.colors.smooth))
		elseif(bar.colorHealth) then
			t = self.colors.health
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
		self:OverrideUpdateHealth(event, unit, bar, min, max)
	end

	if(self.PostUpdateHealth) then self:PostUpdateHealth(event, unit, bar, min, max) end
end

local Enable = function(self)
	local health = self.Health
	if(health) then
		if(health.frequentUpdates and (self.unit and not self.unit:match'%w+target$') or not self.unit) then
			health.disconnected = true
			health:SetScript('OnUpdate', OnHealthUpdate)
		else
			self:RegisterEvent("UNIT_HEALTH", Update)
		end
		self:RegisterEvent("UNIT_MAXHEALTH", Update)
		self:RegisterEvent('UNIT_HAPPINESS', Update)
		-- For tapping.
		self:RegisterEvent('UNIT_FACTION', Update)

		if(not health:GetStatusBarTexture()) then
			health:SetStatusBarTexture[[Interface\TargetingFrame\UI-StatusBar]]
		end

		return true
	end
end

local Disable = function(self)
	local health = self.Health
	if(health) then
		if(health:GetScript'OnUpdate') then
			health:SetScript('OnUpdate', nil)
		else
			self:UnregisterEvent('UNIT_HEALTH', Update)
		end

		self:UnregisterEvent('UNIT_MAXHEALTH', Update)
		self:UnregisterEvent('UNIT_HAPPINESS', Update)
		self:UnregisterEvent('UNIT_FACTION', Update)
	end
end

oUF:AddElement('Health', Update, Enable, Disable)
