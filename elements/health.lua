local health = oUF.colors.health
local happiness = oUF.colors.happiness
local min, max, bar, color

function oUF:UNIT_HEALTH(event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdateHealth) then self:PreUpdateHealth(event, unit) end

	min, max = UnitHealth(unit), UnitHealthMax(unit)
	bar = self.Health
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	if(not self.OverrideUpdateHealth) then
		-- TODO: Rewrite this block.
		if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
			color = health[1]
		elseif(unit == "pet" and GetPetHappiness()) then
			color = happiness[GetPetHappiness()]
		else
			color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or UnitReactionColor[UnitReaction(unit, "player")]
		end
		if(color) then
			bar:SetStatusBarColor(color.r, color.g, color.b)

			if(bar.bg) then
				bar.bg:SetVertexColor(color.r*.5, color.g*.5, color.b*.5)
			end
		end
	else
		self:OverrideUpdateHealth(event, bar, unit, min, max)
	end

	if(self.PostUpdateHealth) then self:PostUpdateHealth(event, bar, unit, min, max) end
end
oUF.UNIT_MAXHEALTH = oUF.UNIT_HEALTH

table.insert(oUF.subTypes, function(self, unit)
	if(self.Health) then
		self:RegisterEvent"UNIT_HEALTH"
		self:RegisterEvent"UNIT_MAXHEALTH"
	end
end)
oUF:RegisterSubTypeMapping"UNIT_HEALTH"
