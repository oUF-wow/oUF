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

local shade = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
	insets = {left = 6, right = 2, top = 6, bottom = 2},
}

local onEvent = function(self, event, unit)
	if(not self:IsShown() or not self.unit == unit) then return end
	self:updatePower()
end

function class:new(unit)
	local bar = core.frame:acquire"StatusBar"
	setmetatable(bar, mt)

	bar.unit = unit

	bar:SetBackdrop(shade)
	bar:SetBackdropColor(0, 0, 0, .4)

	bar:SetStatusBarTexture"Interface\\AddOns\\oUF\\textures\\glaze"

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
end

function class:updatePower()
end
