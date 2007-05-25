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

local buffOnEnter = function(self)
	if(not self:IsVisible()) then return end
	local unit = self:GetParent().unit

	GameTooltip:SetOwner(self, "ANHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitBuff(unit, self:GetID())
end
local debuffOnEnter = function(self)
	if(not self:IsVisible()) then return end
	local unit = self:GetParent().unit

	GameTooltip:SetOwner(self, "ANHOR_BOTTOMRIGHT")

	GameTooltip:SetUnitDebuff(unit, self:GetID())
end
local onLeave = function() GameTooltip:Hide() end

local createBuff = function(self, index)
	local buff = CreateFrame("Frame", nil, self)
	buff:EnableMouse(true)
	buff:SetID(index)

	buff:SetWidth(14)
	buff:SetHeight(14)

	local icon = buff:CreateTexture(nil, "BACKGROUND")
	icon:SetAllPoints(buff)

	local count = buff:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(NumberFontNormal)
	count:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", -1, 0)

	buff:SetScript("OnEnter", buffOnEnter)
	buff:SetScript("OnLeave", onLeave)

	table.insert(self.buffs, buff)

	buff.icon = icon
	buff.count = count

	return buff
end

local createDebuff = function(self, index)
	local debuff = CreateFrame("Frame", nil, self)
	debuff:EnableMouse(true)
	debuff:SetID(index)

	debuff:SetWidth(14)
	debuff:SetHeight(14)

	local icon = debuff:CreateTexture(nil, "BACKGROUND")
	icon:SetAllPoints(debuff)

	local count = debuff:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(NumberFontNormal)
	count:SetPoint("BOTTOMRIGHT", debuff, "BOTTOMRIGHT", -1, 0)

	local overlay = debuff:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture"Interface\\Buttons\\UI-Debuff-Overlays"
	overlay:SetAllPoints(debuff)
	overlay:SetTexCoord(.296875, .5703125, 0, .515625)

	debuff:SetScript("OnEnter", debuffOnEnter)
	debuff:SetScript("OnLeave", onLeave)

	table.insert(self.debuffs, debuff)

	debuff.icon = icon
	debuff.count = count
	debuff.overlay = overlay

	return debuff
end

-- /wrists
local limit, row, button, r, icons = 16
local setPosition = function(self, nb, nd)
	row = 1
	icons = self.buffs

	for i=1, nb do
		button = icons[i]
		if(i == 1) then
			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
		else
			button:ClearAllPoints()
			button:SetPoint("LEFT", icons[i-1], "RIGHT", 0, 0)

			r = math.fmod(i - 1, limit)
			if(r == 0) then
				button:ClearAllPoints()
				button:SetPoint("BOTTOMLEFT", icons[row], "TOPLEFT", 0, 2)
				row = i
			end
		end
	end

	icons = self.debuffs

	for i=1, nd do
		button = icons[i]
		if(i == 1) then
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, -2)
		else
			button:ClearAllPoints()
			button:SetPoint("LEFT", icons[i-1], "RIGHT", 0, 0)

			r = math.fmod(i - 1, limit)
			if(r == 0) then
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", icons[row], "BOTTOMLEFT", 0, -2)
				row = i
			end
		end
	end
end
local nb, nd, name, texture, count, type, color, buffs, debuffs
local updateAura = function(self, unit)
	if(self.unit ~= unit) then return end

	nb, nd = 0, 0
	buffs = self.buffs
	
	for i=1,32 do
		buff = buffs[i]
		name, rank, texture, count = UnitBuff(unit, i)

		if(not buff and not name) then
			break
		elseif(name) then
			if(not buff) then buff = createBuff(self, i) end
			buff:Show()
			buff.icon:SetTexture(texture)
			buff.count:SetText((count > 1 and count) or nil)

			nb = nb + 1
		elseif(buff) then
			buff:Hide()
		end
	end

	debuffs = self.debuffs
	for i=1,40 do
		debuff = debuffs[i]
		name, rank, texture, count, type, color = UnitDebuff(unit, i)

		if(not debuff and not name) then
			break;
		elseif(name) then
			if(not debuff) then debuff = createDebuff(self, i) end
			debuff:Show()
			debuff.icon:SetTexture(texture)

			color = DebuffTypeColor[type or "none"]
			debuff.overlay:SetVertexColor(color.r, color.g, color.b)
			debuff.count:SetText((count > 1 and count) or nil)

			nd = nd + 1
		elseif(debuff) then
			debuff:Hide()
		end
	end

	setPosition(self, nb, nd)
end

local class = {}

class.name = "aura"
class.type = "texture"

function class:new(unit)
	self.buffs = {}
	self.debuffs = {}

	self:RegisterOnShow("updateAura", updateAura)
	self:RegisterEvent("UNIT_AURA", updateAura)
	if(UnitExists(unit)) then updateAura(self, unit) end
end



core.aura = class
