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

local class = {}

-- oh shi-
class.name = "icon"
class.type = "texture"

local SetSize = function(self, n)
	if(not type(n) == "number") then return end -- Error here

	local icon = self.icon
	icon:SetHeight(n)
	icon:SetWidth(n)
end

local SetPoint = function(self, pos, element, x2, y2)
	local icon = self.icon
	local p1, p2, x, y = strsplit("#", anchors[pos])

	if(x2 and type(x2) == "number") then x = x + x2 end
	if(y2 and type(y2) == "number") then y = y + y2 end

	element = self[element] or self
	icon:SetParent(element)
	icon:ClearAllPoints()
	icon:SetPoint(p1, element, p2, x, y)
end

local updateIcon = function(self)
	local index = GetRaidTargetIndex(self.unit)
	
	if(index) then
		SetRaidTargetIconTexture(self.icon, index)
		self.icon:Show()
	else
		self.icon:Hide()
	end
end

function class:new(unit)
	local icon = self:CreateTexture(nil, "ARTWORK")
	icon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	
	self.SetIconPosition = SetPoint
	self.SetIconSize = SetSize

	self:RegisterOnShow("updateIcon", updateIcon)
	self:RegisterEvent("RAID_TARGET_UPDATE", updateIcon)

	self.icon = icon

	if(UnitExists(unit)) then updateIcon(self) end
end

core.icon = class
