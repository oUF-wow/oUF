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

class.name = "name"
class.type = "font"

local SetPoint = function(self, pos, element)
	pos = pos or "LEFT"
	local text = self.name
	local p1, p2, x, y = strsplit("#", anchors[pos])

	element = self[element] or text.bar
	
	text:SetParent(element)
	text:ClearAllPoints()
	text:SetPoint(p1, element, p2, x, y)
end

local updateName = function(self, unit)
	self.name:SetText(UnitName(unit))
end

function class:new(element, bar)
	local font = self:CreateFontString(nil, "OVERLAY")

	self.SetNamePosition = SetPoint
	
	font:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	font:SetText(UnitName(self.unit))
	font.bar = self[bar]

	self:RegisterOnShow("updateName", updateName)

	self.name = font
	updateName(self, self.unit)
end

core.name = class
