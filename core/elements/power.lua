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

local core = oUF
local class = CreateFrame"StatusBar"
local mt = {__index = class}

local SetHeight = class.SetHeight

-- locals are faster
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType

local color = {
	[0] = { r = 48/255, g = 113/255, b = 191/255}, -- Mana
	[1] = { r = 226/255, g = 45/255, b = 75/255}, -- Rage
	[2] = { r = 255/255, g = 178/255, b = 0}, -- Focus
	[3] = { r = 1, g = 1, b = 34/255}, -- Energy
	[4] = { r = 0, g = 1, b = 1} -- Happiness
}

local onShow = function(self)
	self:update(self.unit)
end

local onEvent = function(self, event, unit)
	if(not self:IsShown() or self.unit ~= unit) then return end
	self:update(unit)
end

function class:new(unit)
	local bar = --[[core.frame:acquire"StatusBar"]] CreateFrame"StatusBar"
	setmetatable(bar, mt)

	bar.unit = unit
	bar.type = "power"

	bar:SetHeight(4)
	bar:SetStatusBarTexture"Interface\\AddOns\\oUF\\textures\\glaze"

	local bg = bar:CreateTexture(nil, "BORDER")
	bar.bg = bg

	bg:SetAllPoints(bar)
	bg:SetTexture"Interface\\AddOns\\oUF\\textures\\glaze"

	bar:SetScript("OnShow", onShow)
	bar:SetScript("OnEvent", onEvent)

	bar:RegisterEvent"UNIT_MANA"
	bar:RegisterEvent"UNIT_RAGE"
	bar:RegisterEvent"UNIT_FOCUS"
	bar:RegisterEvent"UNIT_ENERGY"
	bar:RegisterEvent"UNIT_MAXMANA"
	bar:RegisterEvent"UNIT_MAXRAGE"
	bar:RegisterEvent"UNIT_MAXFOCUS"
	bar:RegisterEvent"UNIT_MAXENERGY"
	bar:RegisterEvent"UNIT_DISPLAYPOWER"

	core.frame:add(bar, unit)
	return bar
end

function class:update(unit)
	local vc, vm = UnitMana(unit), UnitManaMax(unit)

	self:SetMinMaxValues(0, vm)
	self:SetValue(vc)

	local c = color[UnitPowerType(unit)]
	self.bg:SetVertexColor(c.r*.5, c.g*.5, c.b*.5)
	self:SetStatusBarColor(c.r, c.g, c.b)
end

function class:SetHeight(value)
	local diff = value - self:GetHeight()
	SetHeight(self, value)
	if(self.owner) then self.owner:updateHeight(diff) end
end

core.power = class
