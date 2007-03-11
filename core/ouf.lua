--[[-------------------------------------------------------------------------
  Copyright (c) 2006-2007, Trond A Ekseth
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
      * Neither the name of oUF nor the names of its contributors
        may be used to endorse or promote products derived from this
	software without specific prior written permission.

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

local G = getfenv(0)
local unitTypeLookup = setmetatable({
    party1 = "party",
    party2 = "party",
    party3 = "party",
    party4 = "party",
    partypet1 = "partypet",
    partypet2 = "partypet",
    partypet3 = "partypet",
    partypet4 = "partypet",
}, {__index = function(t, k) return k end})
local default = {
	width = 260,
	height = 46,
}

local BC = {
	P = {
		[0] = { r1 = 48/255, g1 = 113/255, b1 = 191/255, r2 = 1.00, g2 = 0.00, b2 = 0.00}, -- Mana
		[1] = { r1 = 226/255, g1 = 45/255, b1 = 75/255}, -- Rage
		[2] = { r1 = 255/255, g1 = 178/255, b1 = 0, r2 = 1.00, g2 = 0.00, b2 = 0.00}, -- Focus
		[3] = { r1 = 1.00, g1 = 1.00, b1 = 34/255, r2 = 1.00, g2 = 0.00, b2 = 0.00}, -- Energy
		[4] = { r1 = 0.00, g1 = 1.00, b1 = 1.00, r2 = 1.00, g2 = 0.00, b2 = 0.00} -- Happiness
	},
	H =  {
		[0] = { r1 = 49/255, g1 = 227/255, b1 = 37/255, r2 = 1, g2 = 0, b2 = 0}
	}
}
local strings = {
	[1] = function(vCur, vMax) return string.format("%s/%s", oUF.kRotation(vCur), oUF.kRotation(vMax)) end,
	[2] = function(vCur, vMax) return string.format("%s%%", oUF.round(vCur/vMax*100)) end,
	[3] = function(vCur, vMax) return string.format("%s", vCur-vMax) end,
	[4] = function(vCur, vMax) return string.format("%s/%s", vCur-vMax,vMax) end,
	[5] = function(vCur, vMax) return string.format("%s/%s", vCur-vMax,vCur) end,
	[6] = function(vCur, vMax) return string.format("%s", vCur) end,
	[7] = function(vCur, vMax) return string.format("%s | %s", vMax,vCur-vMax) end,
}
local events = {}
local loadup = {}

local addon = DongleStub('Dongle-Beta1'):New('oUF')
addon.class = {}
addon.unit = {}

function addon:Initialize()
	self.db = self:InitializeDB("oUFDB")
	self.profile = self.db.profile
	self.db:RegisterDefaults(self.defaults)
end

function addon:Enable()
	for _, func in pairs(loadup) do func(self) end
end

function addon.getHealthColor()
	return BC["H"][0]
end

function addon.getPowerColor(unit)
	return BC["P"][UnitPowerType(unit)]
end

function addon.getStringFormat(type)
	return strings[type]
end

function addon.getCapitalized(str)
	return string.upper(string.sub(str, 1, 1)) ..  string.lower(string.sub(str, 2))
end

function addon.getUnitType(unit)
	return unitTypeLookup[unit]
end

function addon.kRotation(val)
	local prefix, si

	if(val >= 100000) then
		prefix = "m" ; si = 1000000
	elseif(val >= 10000) then
		prefix = "k" ; si = 1000
	else
		return val
	end

	local int, float = math.modf(("%.1f"):format(val / si))
	float = tostring(float)

	if(int == 0) then int = "" end
	if(#float > 4) then
		float = ("%.1f"):format(float):gsub("0%.", prefix, 1)
	elseif(#float ~= 1) then
		float = float:gsub("0%.", prefix, 1)
	else
		float = prefix
	end

	return int..float
end

function addon.GetReactionColors(u)
	local r, g, b
	if UnitPlayerControlled(u) then
		if ( UnitCanAttack(u, "player") ) then
			-- Hostile players are red
			if ( not UnitCanAttack("player", u) ) then
				r = 0.3
				g = 0.3
				b = 0.3
			else
				r = UnitReactionColor[2].r
				g = UnitReactionColor[2].g
				b = UnitReactionColor[2].b
			end
		elseif ( UnitCanAttack("player", u) ) then
			-- Players we can attack but which are not hostile are yellow
			r = UnitReactionColor[4].r
			g = UnitReactionColor[4].g
			b = UnitReactionColor[4].b
		elseif ( UnitIsPVP("target") ) then
			-- Players we can assist but are PvP flagged are green
			r = UnitReactionColor[6].r
			g = UnitReactionColor[6].g
			b = UnitReactionColor[6].b
		else
			-- All other players are blue (the usual state on the "blue" server)
			r = 0.3
			g = 0.3
			b = 0.3
		end
	elseif UnitIsTapped(u) and not UnitIsTappedByPlayer(u) then
		r = 0.3
		g = 0.3
		b = 0.3
	else
		local reac = UnitReaction("player", u)
		
		if reac then
			r = FACTION_BAR_COLORS[reac].r
			g = FACTION_BAR_COLORS[reac].g
			b = FACTION_BAR_COLORS[reac].b
		else --neutral
			r = 0.3
			g = 0.3
			b = 0.3
		end
		
	end
	return r,g,b
end

function addon.addUnit(func)
	table.insert(loadup, func)
end

function addon:unitDB(unit)
	self.profile[unit] = setmetatable(self.profile[unit] or {}, {__index = default})
	return self.profile[unit]
end

function addon:RegisterClassEvent(class, event, func)
	self[event] = function(self, event, a1) self:handleEvent(event, a1) end
	if(not events[event]) then events[event] = {} end
	
	events[event][class] = func or event
	self:RegisterEvent(event)
end

function addon:handleEvent(event, unit)
	local class = self.unit[unit]
	if(unit and class) then
		local func = events[event][class]
		if(func) then
			class[func](class, unit, event)
		end
	elseif(not unit) then
		unit = self.unit
		for k, f in pairs(events[event]) do
			k[f](k, k)
		end
	end
end

G['oUF'] = addon
