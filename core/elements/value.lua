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
local mt = {__call = function(t, k) t:new(k) end}

local class = setmetatable({}, mt)

local updateValue = function(self)
	local _, max = self:GetMinMaxValues()
	local value = self:GetValue()
	local unit = self.unit
	local type = self.type

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

function class:new(bar)
	local font = bar:CreateFontString(nil, "OVERLAY")
	bar.value = font

--	font:SetShadowOffset(.8, -.8)
--	font:SetShadowColor(0, 0, 0, 1)
	font:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	font:SetPoint("RIGHT", bar, -1, -1)

	bar:SetScript("OnValueChanged", updateValue)
	updateValue(bar)
end

core.value = class
