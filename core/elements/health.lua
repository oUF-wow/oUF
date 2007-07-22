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
      * Neither the name of oUF nor the names of its contributors may
        be used to endorse or promote products derived from this
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

local core = oUF
local anchors = core.anchors
local class = CreateFrame"StatusBar"
local mt = {__index = class}

local RegisterEvent = class.RegisterEvent
local SetHeight = class.SetHeight

local phColor = {
	[1] = {r = 1, g = 0, b = 0},
	[2] = {r = 1 ,g = 1, b = 0},
	[3] = {r = 0, g = 1, b = 0},
}

-- locals are faster
local string_format = string.format
local math_modf = math.modf
local select = select

local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitReactionColor = UnitReactionColor

local UnitReaction = UnitReaction
local UnitIsPlayer = UnitIsPlayer
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitExists = UnitExists
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsConnected = UnitIsConnected
local GetPetHappiness = GetPetHappiness

local ColorGradient = function(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then
		return r3, g3, b3
	elseif perc <= 0 then
		return r1, g1, b1
	end
	
	local segment, relperc = math_modf(perc*(3-1))
	local offset = (segment*3)+1

	if(offset == 1) then
		return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
	end

	return r2 + (r3-r2)*relperc, g2 + (g3-g2)*relperc, b2 + (b3-b2)*relperc
end

local updateValue = function(self, unit, min, max)
	if(not self:IsVisible()) then return end

	if(UnitIsDead(unit)) then
		self:SetValue(0)
		self.value:SetText"Dead"
	elseif(UnitIsGhost(unit)) then
		self:SetValue(0)
		self.value:SetText"Ghost"
	elseif(not UnitIsConnected(unit)) then
		self.value:SetText"Offline"
	else
		self.value:SetText(string_format("%s / %s", min, max))
	end
end

local min, max, bar
local updateHealth = function(self, unit)
	if(self.unit ~= unit) then return end

	min, max = UnitHealth(unit), UnitHealthMax(unit)
	bar = self.health

	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)
	bar:setColor(min, max)

	updateValue(bar, unit, min, max)
end

local SetPoint = function(self, pos, element, x2, y2)
	local text = self.value
	local p1, p2, x, y = strsplit("#", anchors[pos])

	if(x2 and type(x2) == "number") then x = x + x2 end
	if(y2 and type(y2) == "number") then y = y + y2 end

	element = self.owner[element] or self
	text:SetParent(element)
	text:ClearAllPoints()
	text:SetPoint(p1, element, p2, x, y)
end

local SetHealthPosition = function(self, pos, element, x2, y2)
	SetPoint(self.health, pos, element, x2, y2)
end

local siRotation = function(val)
	return val
end

-- oh shi-
class.name = "health"
class.type = "bar"

local bg, font
function class:new(unit)
	if(self.health) then return end -- should be done by addElement
	bar = --[[core.frame:acquire"StatusBar"]] CreateFrame"StatusBar"
	font = self:CreateFontString(nil, "OVERLAY")
	setmetatable(bar, mt)

	bar.unit = unit
	bar.owner = self

	bar:SetParent(self)
	bar:SetPoint("LEFT", self)
	bar:SetPoint("RIGHT", self)

	if(self.last) then
		bar:SetPoint("TOP", self.last, "BOTTOM")
	else
		bar:SetPoint("TOP", self)
		self.last = bar
	end

	bar:SetHeight(18)
	bar:SetStatusBarTexture"Interface\\AddOns\\oUF\\textures\\glaze"

	bg = bar:CreateTexture(nil, "BORDER")
	bar.bg = bg

	bg:SetAllPoints(bar)
	bg:SetTexture"Interface\\AddOns\\oUF\\textures\\glaze"

	self:RegisterEvent("UNIT_HEALTH", updateHealth)
	self:RegisterEvent("UNIT_MAXHEALTH", updateHealth)

	self:RegisterOnShow("updateHealth", updateHealth)

	self.health = bar

	self.SetHealthPosition = SetHealthPosition
	bar.value = font
	font:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")

	if(UnitExists(unit)) then
		updateHealth(self, self.unit)
	end
end

local perc, unit, r, g, b, c, h
function class:setColor(min, max)
	perc = 1 - min/max
	unit = self.unit
	h = GetPetHappiness()

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		r, g, b = .6, .6, .6
	elseif(h and self.unit == "pet") then
		r, g, b = phColor[h].r, phColor[h].g, phColor[h].b
	else
		c = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or UnitReactionColor[UnitReaction(unit, "player")]
		r, g, b = ColorGradient(perc, c.r, c.g, c.b, 1, 1, 0, 1, 0, 0)
	end

	self.bg:SetVertexColor(r*.5, g*.5, b*.5)
	self:SetStatusBarColor(r, g , b)
end

function class:SetHeight(value)
	local diff = value - self:GetHeight()
	SetHeight(self, value)
	if(self.owner) then self.owner:updateHeight(diff) end
end

core.health = class
