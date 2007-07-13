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

-- locals are faster
local string_format = string.format

local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsConnected = UnitIsConnected

local color = {
	[0] = { r = 48/255, g = 113/255, b = 191/255}, -- Mana
	[1] = { r = 226/255, g = 45/255, b = 75/255}, -- Rage
	[2] = { r = 255/255, g = 178/255, b = 0}, -- Focus
	[3] = { r = 1, g = 1, b = 34/255}, -- Energy
	[4] = { r = 0, g = 1, b = 1} -- Happiness
}

local updateValue = function(self, unit, min, max)
	if(UnitIsDead(unit) or UnitIsGhost(unit) or not UnitIsConnected(unit)) then
		self:SetValue(0)
		self.value:SetText(nil)
	else
		self.value:SetText(string_format("%s / %s", min, max))
	end
end

local min, max, bar, c
local updatePower = function(self, unit)
	if(self.unit ~= unit) then return end

	min, max = UnitMana(unit), UnitManaMax(unit)
	bar = self.power

	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	c = color[UnitPowerType(unit)]
	bar.bg:SetVertexColor(c.r*.5, c.g*.5, c.b*.5)
	bar:SetStatusBarColor(c.r, c.g, c.b)

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

local SetPowerPosition = function(self, pos, element, x2, y2)
	SetPoint(self.power, pos, element, x2, y2)
end

-- oh shi-
class.name = "power"
class.type = "bar"

local bg, font
function class:new(unit)
	if(self.power) then return end -- should be done by addElement
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

	bar:SetHeight(10)
	bar:SetStatusBarTexture"Interface\\AddOns\\oUF\\textures\\glaze"

	bg = bar:CreateTexture(nil, "BORDER")
	bar.bg = bg

	bg:SetAllPoints(bar)
	bg:SetTexture"Interface\\AddOns\\oUF\\textures\\glaze"

	self:RegisterEvent("UNIT_MANA", updatePower)
	self:RegisterEvent("UNIT_RAGE", updatePower)
	self:RegisterEvent("UNIT_FOCUS", updatePower)
	self:RegisterEvent("UNIT_ENERGY", updatePower)
	self:RegisterEvent("UNIT_MAXMANA", updatePower)
	self:RegisterEvent("UNIT_MAXRAGE", updatePower)
	self:RegisterEvent("UNIT_MAXFOCUS", updatePower)
	self:RegisterEvent("UNIT_MAXENERGY", updatePower)
	self:RegisterEvent("UNIT_DISPLAYPOWER", updatePower)

	self:RegisterOnShow("updatePower", updatePower)

	self.power = bar

	self.SetPowerPosition = SetPowerPosition
	bar.value = font
	font:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")

	if(UnitExists(unit)) then
		updatePower(self, self.unit)
	end
end

function class:SetHeight(value)
	local diff = value - self:GetHeight()
	SetHeight(self, value)
	self.owner:updateHeight(diff)
end

core.power = class
