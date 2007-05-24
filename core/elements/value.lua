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
local caps = core.caps
local anchors = core.anchors

local class = {}

class.name = "value"
class.type = "font"

local SetPoint = function(self, pos, element)
	pos = pos or "RIGHT"
	local text = self.value
	local p1, p2, x, y = strsplit("#", anchors[pos])

	element = self.owner[element] or self
	text:SetParent(element)
	text:ClearAllPoints()
	text:SetPoint(p1, element, p2, x, y)
end

local siRotation = function(val)
	--[[local prefix, si

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

	return int..float]]

	return val
end

local updateValue = function(self)
	local _, max = self:GetMinMaxValues()
	local value = self:GetValue()
	local unit = self.owner.unit
	local type = self.name

	value, max = siRotation(value), siRotation(max)
	if(UnitIsDead(unit)) then
		self:SetValue(0)
		if(type == "health") then self.value:SetText"Dead"
		else self.value:SetText(nil) end
	elseif(UnitIsGhost(unit)) then
		self:SetValue(0)
		if(type == "health") then self.value:SetText"Ghost"
		else self.value:SetText(nil) end
	elseif(not UnitIsConnected(unit)) then
		if(type == "health") then self.value:SetText"Offline"
		else self.value:SetText(nil) end
	else
		self.value:SetText(("%s / %s"):format(value, max))
	end
end

-- oh shi-
class.name = "value"
class.type = "font"

function class:new(element, bar)
	local font = self:CreateFontString(nil, "OVERLAY")
	local name = "Set"..caps(bar).."Position"

	bar = self[bar]
	self[name] = function(self, pos, element)
		SetPoint(bar, pos, element)
	end

	bar.value = font
	font:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	font.bar = bar
	bar:SetScript("OnValueChanged", updateValue)
	
	updateValue(bar)
end

core.value = class
