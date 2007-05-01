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

local RegisterEvent = class.RegisterEvent
local SetHeight = class.SetHeight

-- locals are faster
local UnitReactionColor = UnitReactionColor
local UnitReaction = UnitReaction
local UnitIsPlayer = UnitIsPlayer
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitExists = UnitExists

local ColorGradient = function(perc, ...)
	if perc >= 1 then
		local r, g, b = select(select('#', ...) - 2, ...)
		return r, g, b
	elseif perc <= 0 then
		local r, g, b = ...
		return r, g, b
	end
	
	local num = select('#', ...) / 3

	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local onShow = function(self) self:update() end
local onEvent = function(self, event, unit, ...)
	if(self.unit ~= unit) then return end

	local func = self.events[event]
	if(func) then
		if(type(func) == "string") then
			self[func](self, unit, ...)
		end
	end
end

function class:new(unit)
	local bar = --[[core.frame:acquire"StatusBar"]] CreateFrame"StatusBar"
	setmetatable(bar, mt)

	bar.unit = unit
	bar.type = "health"
	bar.events = {}

	bar:SetHeight(18)
	bar:SetStatusBarTexture"Interface\\AddOns\\oUF\\textures\\glaze"

	local bg = bar:CreateTexture(nil, "BORDER")
	bar.bg = bg

	bg:SetAllPoints(bar)
	bg:SetTexture"Interface\\AddOns\\oUF\\textures\\glaze"

	bar:SetScript("OnShow", onShow)
	bar:SetScript("OnEvent", onEvent)

	bar:RegisterEvent("UNIT_HEALTH", "updateHealth")
	bar:RegisterEvent("UNIT_MAXHEALTH", "updateHealth")

	local font = bar:CreateFontString(nil, "OVERLAY")
	bar.text = font
	
	font:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	font:SetPoint("LEFT", bar, 1, -1)

	font:SetText(UnitName(unit))

	core.frame:add(bar, unit)
	return bar
end

function class:RegisterEvent(event, func)
	func = func or event

	if(not self.events[event]) then
		self.events[event] = func
		RegisterEvent(self, event)
	end
end

function class:updateHealth(unit)
	local min, max = UnitHealth(unit), UnitHealthMax(unit)

	self:SetMinMaxValues(0, max)
	self:SetValue(min)
	self:updateColor(min, max)
end

function class:updateColor(min, max)
	local perc = 1 - min/max
	local unit = self.unit
	local r, g, b

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
		r, g, b = .6, .6, .6
	else
		local c = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or UnitReactionColor[UnitReaction(unit, "player")]
		r, g, b = ColorGradient(perc, c.r, c.g, c.b, 1, 1, 0, 1, 0, 0)
	end

	self.bg:SetVertexColor(r*.5, g*.5, b*.5)
	self:SetStatusBarColor(r, g , b)
end

function class:updateName(unit)
	self.text:SetText(UnitName(unit))
end

function class:SetHeight(value)
	local diff = value - self:GetHeight()
	SetHeight(self, value)
	if(self.owner) then self.owner:updateHeight(diff) end
end

function class:update()
	local unit = self.unit
	if(UnitExists(unit)) then
		self:updateHealth(unit)
		self:updateName(unit)
	end
end

core.health = class
