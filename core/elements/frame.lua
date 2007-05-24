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
local printf = function(...) ChatFrame1:AddMessage(string.format(...)) end

local class = CreateFrame"Button"
local mt = {__index = class}

local RegisterEvent = class.RegisterEvent

local methods = {"RegisterOnShow", "RegisterEvent"}
local backdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
	insets = {left = 2, right = -2, top = 2, bottom = -2},
}
local frames = {}
local numFrames = 0

local onEnter = function() UnitFrame_OnEnter() end
local onLeave = function() UnitFrame_OnLeave() end
local onEvent = function(self, event, unit, ...)
	local func = self.events[event]
	if(func and type(func) == "function") then
		func(self, unit, ...)
	end
end
local onShow = function(self)
	local unit = self.unit

	if(not UnitExists(unit)) then return end
	for _, func in pairs(self.onShow) do
		func(self, unit)
	end
end

class.updateAll = onShow

function class:addElement(element, ...)
	local obj = core[element]
	if(not obj) then return printf("%s is not a valid element.", element) end

	if(obj.type == "bar") then
		obj.new(self, self.unit, ...)
	elseif(obj.type == "font") then
		obj.new(self, element, ...)
	elseif(obj.type == "texture") then
		obj.new(self, self.unit, ...)
	end
end

function class:delElement(element)
	-- dummy
end

function class:add(unit)
	local frame = frames[unit]
	if(not frame) then frames[unit] = self:acquire(unit) ; frame = frames[unit] end

	frame:SetWidth(200)

	return frame
end

function class:acquire(unit)
	local frame = CreateFrame("Button", "oUF"..caps(unit), UIParent, "SecureUnitButtonTemplate")
	numFrames = numFrames + 1
	setmetatable(frame, mt)

	frame.id = unit:match("^.-(%d+)") or 0
	frame.unit = unit
	frame.events = {}
	frame.onShow = {}

	frame:EnableMouse(true)
	frame:SetMovable(true)

	frame:SetPoint("CENTER", UIParent, 0, -350+(numFrames*70))

	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0, 0, 0, .4)

	frame:SetScript("OnEnter", onEnter)
	frame:SetScript("OnLeave", onLeave)
	frame:SetScript("OnEvent", onEvent)
	frame:SetScript("OnShow", onShow)

	frame:RegisterForClicks"anyup"

	frame:SetAttribute("unit", unit)
	frame:SetAttribute("type1", "target")

	RegisterUnitWatch(frame)

	return frame
end

function class:updateHeight(value)
	local old = self:GetHeight()
	self:SetHeight(old + value)
end

function class:RegisterEvent(event, func)
	if(not self.events[event]) then
		self.events[event] = func
		RegisterEvent(self, event)
	end
end

function class:RegisterOnShow(key, func)
	if(not self.onShow[key]) then
		table.insert(self.onShow, func)
	end
end

core.frame = class
