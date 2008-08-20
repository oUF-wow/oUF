local ColorGradient = oUF.ColorGradient

local min, max, bar

local OnHealthUpdate
do
	local UnitHealth = UnitHealth
	OnHealthUpdate = function(self)
		if(self.disconnected) then return end
		local health = UnitHealth(self.unit)

		if(health ~= self.min) then
			self:SetValue(health)
			self.min = health

			self:GetParent():UNIT_MAXHEALTH("OnHealthUpdate", self.unit)
		end
	end
end

function oUF:UNIT_MAXHEALTH(event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdateHealth) then self:PreUpdateHealth(event, unit) end

	min, max = UnitHealth(unit), UnitHealthMax(unit)
	bar = self.Health
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

		if(r and g and b) then
			bar:SetStatusBarColor(r, g, b)

			if(bar.bg) then
				bar.bg:SetVertexColor(r, g, b)
			end
		end
	else
		self:OverrideUpdateHealth(event, unit, bar, min, max)
	end

	if(self.PostUpdateHealth) then self:PostUpdateHealth(event, unit, bar, min, max) end
end
oUF.UNIT_HEALTH = oUF.UNIT_MAXHEALTH

table.insert(oUF.subTypes, function(self)
	if(self.Health) then
		if(self.Health.frequentUpdates) then
			self.Health:SetScript('OnUpdate', OnHealthUpdate)
		else
			self:RegisterEvent"UNIT_HEALTH"
		end
		self:RegisterEvent"UNIT_MAXHEALTH"
		self:RegisterEvent'UNIT_HAPPINESS'
		-- For tapping.
		self:RegisterEvent'UNIT_FACTION'
	end
end)
oUF:RegisterSubTypeMapping"UNIT_MAXHEALTH"
