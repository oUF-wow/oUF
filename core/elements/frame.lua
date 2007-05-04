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
local class = CreateFrame"Button"
local mt = {__index = class}

local backdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
	insets = {left = 2, right = -2, top = 2, bottom = -2},
}
local frames = {}
local numFrames = 0

local onEnter = function() UnitFrame_OnEnter() end
local onLeave = function() UnitFrame_OnLeave() end

function class:add(bar, unit)
	local frame = frames[unit]
	if(not frame) then frames[unit] = self:acquire(unit) ; frame = frames[unit] end

	bar:SetParent(frame)
	bar:SetPoint("LEFT", frame)
	bar:SetPoint("RIGHT", frame)

	bar.anchor = frame.last
	bar.owner = frame

	frame:SetHeight(bar:GetHeight() + frame:GetHeight())
	frame:SetWidth(200)

	frame[bar.type] = bar

	if(not frame.last) then
		frame.last = bar.type
		bar:SetPoint("TOP", frame)
	else
		bar:SetPoint("TOP", frame[frame.last], "BOTTOM")
		frame.last = bar.type
	end
end

function class:acquire(unit)
	local frame = CreateFrame("Button", "oUF"..unit, UIParent, "SecureUnitButtonTemplate")
	numFrames = numFrames + 1
	setmetatable(frame, mt)

	frame.unit = unit
	frame:EnableMouse(true)
	frame:SetMovable(true)

	frame:SetPoint("CENTER", UIParent, 0, -150+(numFrames*35))

	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0, 0, 0, .4)

	frame:SetScript("OnEnter", onEnter)
	frame:SetScript("OnLeave", onLeave)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")

	frame:SetAttribute("unit", unit)
	frame:SetAttribute("type1", "target")

	RegisterUnitWatch(frame)

	return frame
end

function class:updateAll()
	local unit = self.unit

	for key, object in pairs(self) do
		if(type(object) == "table" and object.onShows) then
			for _, func in pairs(object.onShows) do
				object[func](object, unit)
			end
		end
	end
end

function class:updateHeight(value)
	local old = self:GetHeight()
	self:SetHeight(old + value)
end

core.frame = class
