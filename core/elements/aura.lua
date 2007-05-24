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
local mt = {__call = function(self, k) self:new(k) end}

local auras = {buffs = 32, debuffs = 40} -- meh..
local OnAuraEnter = function(self)
	if(not self:IsVisible()) then return end
	local unit = self:GetParent():GetParent().unit

	GameTooltip:SetOwner(self, "ANHOR_BOTTOMRIGHT")
	if(self.isdebuff) then
		GameTooltip:SetUnitDebuff(unit, self.id)
	else
		GameTooltip:SetUnitBuff(unit, self.id)
	end
end
-- do this for now...
local createAuras = function(self)
	for type, num in pairs(auras) do
		self[type] = CreateFrame("Frame", nil, self)
		self[type]:SetWidth(260)
		self[type]:SetHeight(14*4)
		for i=1,num do
			self[type][i] = CreateFrame("Button", nil, self[type])
			self[type][i]:Hide()
			self[type][i]:SetWidth(14)
			self[type][i]:SetHeight(14)
			self[type][i]:SetScript("OnEnter", OnAuraEnter)
			self[type][i]:SetScript("OnLeave", function() GameTooltip:Hide() end)
			self[type][i].id = i
			self[type][i].isdebuff = (type == "debuffs" and 1 or nil)

			self[type][i].Icon = self[type][i]:CreateTexture(nil, "BACKGROUND")
			self[type][i].Icon:SetAllPoints(self[type][i])
			self[type][i].Icon:SetAlpha(.6)

			if(type == "debuffs") then
				self[type][i].Overlay = self[type][i]:CreateTexture(nil, "OVERLAY")
				self[type][i].Overlay:SetTexture"Interface\\Buttons\\UI-Debuff-Overlays"
				self[type][i].Overlay:SetAllPoints(self[type][i])
				self[type][i].Overlay:SetTexCoord(.296875, .5703125, 0, .515625)
			end

			self[type][i].Count = self[type][i]:CreateFontString(nil, "OVERLAY")
			self[type][i].Count:SetFontObject(NumberFontNormal)
			self[type][i].Count:SetPoint("BOTTOMRIGHT", self[type][i])
		end
	end
end
-- and this for now...
local setPosition = function(self)
	for type, num in pairs(auras) do
		local limit = 16
		local row = 1

		self[type]:ClearAllPoints()
		if(type == "buffs") then
			self[type]:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0)
		else
			self[type]:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
		end
		self[type][1]:ClearAllPoints()
		if(type == "buffs") then
			self[type][1]:SetPoint("BOTTOMLEFT", self[type], "BOTTOMLEFT")
		else
			self[type][1]:SetPoint("TOPLEFT", self[type], "TOPLEFT")
		end

		for i=2, num do
			self[type][i]:ClearAllPoints()
			self[type][i]:SetPoint("LEFT", self[type][i-1], "RIGHT", 0, 0)
		end

		for i=2, num do
			local r = math.fmod(i -1, limit)
			if(r == 0) then
				self[type][num]:ClearAllPoints()
				if(type == "buffs") then
					self[type][num]:SetPoint("BOTTOMLEFT", self[type][row], "TOPLEFT", 0, 2)
				else
					self[type][num]:SetPoint("TOPLEFT", self[type][row], "BOTTOMLEFT", 0, -2)
				end
				row = i
			end
		end
	end
end

local updateAura = function(self, unit)
	if(self.unit ~= unit) then return end

	local name, rank, texture, count, type, color
	for i=1,32 do
		name, rank, texture, count = UnitBuff(unit, i)

		if(name) then
			self.buffs[i]:Show()
			self.buffs[i].Icon:SetTexture(texture)
			self.buffs[i].Count:SetText((count > 1 and count) or nil)
			self.buffs[i].index = i
		else
			self.buffs[i]:Hide()
		end
	end

	for i=1,40 do
		name, rank, texture, count, type, color = UnitDebuff(unit, i)

		if(name) then
			self.debuffs[i]:Show()
			self.debuffs[i].Icon:SetTexture(texture)
			if(type) then
				color = DebuffTypeColor[type]
			else
				color = DebuffTypeColor["none"]
			end
			self.debuffs[i].Overlay:SetVertexColor(color.r, color.g, color.b)

			if(count > 1) then
				self.debuffs[i].Count:SetText(count)
				self.debuffs[i].index = i
			else
				self.debuffs[i].Count:SetText(nil)
			end
		else
			self.debuffs[i]:Hide()
		end
	end
end

local class = setmetatable({}, mt)

class.name = "aura"
class.type = "texture"

function class:new(unit)
	self:RegisterEvent("UNIT_AURA", updateAura)

	createAuras(self)
	setPosition(self)

	self:RegisterOnShow("updateAura", updateAura)

	if(UnitExists(unit)) then updateAura(self, unit) end
end



core.aura = class
