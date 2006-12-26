--[[-------------------------------------------------------------------------
  Copyright (c) 2006, Trond A Ekseth
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of Trond A Ekseth nor the names of its
        contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------]]

oUF.class.unit = CreateFrame("Button")

local Metatable = {__index = oUF.class.unit}
local P = DongleStub("DongleUtils")
local G = getfenv(0)

local function RaidColor(c)
	c = RAID_CLASS_COLORS[c]
	return (c and P.RGBPercToHex(c.r, c.g, c.b)) or "ffffff|r"
end

local function SetSmoothColor(bar, barbg, unit, alpha)
	if(not type or not bar) then return end
	local min, max = bar:GetMinMaxValues()
	if(min == max) then return end

	local perc = 1 - bar:GetValue()/(max-min)
	local c = oUF.getHealthColor()
--	local c = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
--	local r, g, b = P.ColorGradient(perc, c.r, c.g, c.b, 1, 1, 0, 1, 0, 0)
	local r, g, b = P.ColorGradient(perc, c.r1, c.g1, c.b1, 1, 1, 0, 1, 0, 0)

	barbg:SetStatusBarColor(r, g, b, .25)
	bar:SetStatusBarColor(r, g ,b, alpha)
end

function oUF.class.unit:new(unit)
	local name = "oUF_" .. oUF.getCapitalized(unit)
	local frame = oUF.class.frame:new(unit, name)
	setmetatable(frame, Metatable)
	self.unit = unit

	oUF:RegisterClassEvent(self.unit, "UNIT_HEALTH", "updateHealth")

	oUF:RegisterClassEvent(self.unit, "UNIT_MANA", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_RAGE", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_FOCUS", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_ENERGY", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_MAXMANA", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_MAXRAGE", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_MAXFOCUS", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_MAXENERGY", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_HAPPINESS", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_DISPLAYPOWER", "updatePower")
	oUF:RegisterClassEvent(self.unit, "UNIT_MAXHAPPINESS", "updatePower")

	oUF:RegisterClassEvent(self.unit, "UNIT_LEVEL", "updateInfoLevel")
	oUF:RegisterClassEvent(self.unit, "UNIT_NAME_UPDATE", "updateInfoName")

	oUF:RegisterClassEvent(self.unit, "UNIT_AURA", "updateAura")

	oUF:RegisterClassEvent(self.unit, "PLAYER_ENTERING_WORLD", "updateAll")

	if(oUF.getUnitType(unit) == "party") then
		oUF:RegisterClassEvent(self.unit, "PARTY_MEMBERS_CHANGED", "updateAll")
	end
	return G[name]
end

function oUF.class.unit:updateAll()
	if(UnitExists(self.unit)) then
		self:updateHealth(self.unit)
		self:updatePower(self.unit)
		self:updateInfoName(self.unit)
		self:updateInfoLevel(self.unit)
		self:updateAura(self.unit)
	end
end

function oUF.class.unit:updateHealth(a1)
	local vc, vm, health, bg = UnitHealth(a1), UnitHealthMax(a1), self.Health, self.HealthBG
	local unit = oUF.getUnitType(a1)

	health:SetMinMaxValues(0, vm)
	health:SetValue(vc)

	SetSmoothColor(health, bg, unit, 1)

	return self:updateHealthText(a1, unit, vc, vm, health)
end

function oUF.class.unit:updateHealthText(unit, db, vc, vm, health)
	if(unit == "target") then
		-- MobHealth shit!
	end

	if(UnitIsDead(unit)) then
		health:SetValue(0)
		health.Points:SetText("Dead")
	elseif(UnitIsGhost(unit)) then
		health:SetValue(0)
		health.Points:SetText("Ghost")
	elseif(not UnitIsConnected(unit)) then
		health.Points:SetText("Offline")
	else
		health.Points:SetText(oUF.getStringFormat(1)(vc, vm))
	end
end

function oUF.class.unit:updatePower(unit)
	local vc, vm, power, bg = UnitMana(unit), UnitManaMax(unit), self.Power, self.PowerBG
	local c = oUF.getPowerColor(unit)

	power:SetMinMaxValues(0, vm)

	if(not UnitIsConnected(unit)) then
		power:SetValue(0)
		bg:SetStatusBarColor(.5, .5, .5)

		power.Points:SetText(nil)
	elseif(UnitIsGhost(unit) or UnitIsDead(unit)) then
		power:SetValue(0)
		bg:SetStatusBarColor(c.r1, c.g1, c.b1, .25)

		power.Points:SetText(nil)
	else
		power:SetStatusBarColor(c.r1, c.g1, c.b1)
		bg:SetStatusBarColor(c.r1, c.g1, c.b1, .25)

		power:SetValue(vc)
		
		if(vm == 0) then
			power.Points:SetText(nil)
		else
			power.Points:SetText(oUF.getStringFormat(1)(vc, vm))
		end
	end
end

function oUF.class.unit:updateInfoName(unit)
	local f = self.Health.Name
	f:SetText(GetUnitName(unit))
	f:SetTextColor(1, 1, 1)
end

function oUF.class.unit:updateInfoLevel(unit)
	local tl = UnitLevel(unit)

	if(unit == "player") then
		self.Power.Info:SetText(string.format("L%d %s", UnitLevel(unit), UnitClass(unit)))
	else
		local c, class, cl
		if(tl > 0) then
			if(UnitCanAttack("player", unit)) then
				local c = GetDifficultyColor(tl)
				self.Power.Info:SetTextColor(c.r, c.g, c.b)
			else
				self.Power.Info:SetTextColor(1, 1, 1)
			end
		else
			tl = "??"
			if(UnitCanAttack("player", unit)) then
				self.Power.Info:SetTextColor(1, 0, 0)
			else
				self.Power.Info:SetTextColor(1, 1, 1)
			end
		end
		if(UnitIsPlusMob(unit)) then tl = tl.."+" end
		if(UnitIsPlayer(unit)) then
			class, cl = UnitClass(unit)
		else
			class = UnitCreatureFamily(unit) or UnitCreatureType(unit)
		end
		if(unit == "pet") then
			local h = GetPetHappiness()
			if(h == 1) then h = ":<"
			elseif(h == 2) then h = ":1"
			elseif(h == 3) then h = ":D" end
		end
		cl = RaidColor(cl)
		self.Power.Info:SetText(string.format("L%s |cff%s%s|r", tl, cl, tostring(class)))
	end
end

function oUF.class.unit:updateAura(unit)
	local name, rank, texture, count, type, color
	for i=1,32 do
		name, rank, texture, count = UnitBuff(unit, i)

		if(name) then
			self.Buffs[i]:Show()
			self.Buffs[i].Icon:SetTexture(texture)
			self.Buffs[i].Count:SetText((count > 1 and count) or nil)
			self.Buffs[i].index = i
		else
			self.Buffs[i]:Hide()
		end
	end

	for i=1,40 do
		name, rank, texture, count, type, color = UnitDebuff(unit, i)

		if(name) then
			self.Debuffs[i]:Show()
			self.Debuffs[i].Icon:SetTexture(texture)
			if(type) then
				color = DebuffTypeColor[type]
			else
				color = DebuffTypeColor["none"]
			end
			self.Debuffs[i].Overlay:SetVertexColor(color.r, color.g, color.b)

			if(count > 1) then
				self.Debuffs[i].Count:SetText(count)
				self.Debuffs[i].index = i
			else
				self.Debuffs[i].Count:SetText(nil)
			end
		else
			self.Debuffs[i]:Hide()
		end
	end
end
