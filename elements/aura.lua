--[[-------------------------------------------------------------------------
  Copyright (c) 2006-2008, Trond A Ekseth
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

local table_insert = table.insert
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetTime = GetTime
local DebuffTypeColor = DebuffTypeColor

local col, row, cols, rows, icons, button, nb, buff, timeLeft, count, texture
local dtype, debuff, rank, name, nd, color, duration, size, anchor, growth

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	if(self.overlay) then
		GameTooltip:SetUnitDebuff(self.unit, self:GetID())
	else
		GameTooltip:SetUnitBuff(self.unit, self:GetID())
	end
end

local OnLeave = function()
	GameTooltip:Hide()
end

local createButton = function(self, icons, index, debuff)
	local button = CreateFrame("Frame", nil, self)
	button:EnableMouse(true)
	button:SetID(index)

	button:SetWidth(icons.size or 16)
	button:SetHeight(icons.size or 16)

	local cd = CreateFrame("Cooldown", nil, button)
	cd:SetAllPoints(button)

	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetAllPoints(button)

	local count = button:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(NumberFontNormal)
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 0)

	if(debuff) then
		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetTexture"Interface\\Buttons\\UI-Debuff-Overlays"
		overlay:SetAllPoints(button)
		overlay:SetTexCoord(.296875, .5703125, 0, .515625)
		button.overlay = overlay
	end

	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)

	table_insert(icons, button)

	button.icon = icon
	button.count = count
	button.cd = cd
	button.unit = self.unit

	return button
end

function oUF:SetAuraPosition(unit, nb, nd)
	if(self.Auras) then
		icons = self.Auras
	elseif(self.Buffs) then
		icons = self.Buffs
	end

	col = 0
	row = 0
	size = icons.size or 16
	anchor = icons.initialAnchor or "BOTTOMLEFT"
	growth = (icons.growth or "RIGHT") == "RIGHT" and 1 or -1
	cols = math.floor(icons:GetWidth() / size)
	rows = math.floor(icons:GetHeight() / size)

	if(icons and nb > 0) then
		for i = 1, nb do
			button = icons[i]
			button:ClearAllPoints()
			button:SetPoint(anchor, icons, anchor, col * (size * growth), row * size)
			
			if col >= cols then
				col = 0
				row = row + 1
			else
				col = col + 1
			end
		end
	end
	
	if(self.Auras and col > 0) then
		-- Create a space between buffs and debuffs
		col = col + 1
		
		if col >= cols then
			col = 0
			row = row + 1
		end
	elseif(self.Debuffs) then
		icons = self.Debuffs
		
		col = 0
		row = 0
		size = icons.size or 16
		anchor = icons.initialAnchor or "BOTTOMLEFT"
		growth = (icons.growth or "RIGHT") == "RIGHT" and 1 or -1
		cols = math.floor(icons:GetWidth() / size)
		rows = math.floor(icons:GetHeight() / size)
	end
	
	if(icons and nd > 0) then
		for i = 1, nd do
			button = icons[i]
			button:ClearAllPoints()
			button:SetPoint(anchor, icons, anchor, col * (size * growth), row * size)

			if col >= cols then
				col = 0
				row = row + 1
			else
				col = col + 1
			end
		end
	end
end

function oUF:UNIT_AURA(event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdateAura) then self:PreUpdateAura(event, unit) end

	nb = 0
	nd = 0

	if self.Auras then
		icons = self.Auras
	else
		icons = self.Buffs
	end

	if icons then
		for i=1, self.numBuffs do
			buff = icons[i]
			name, rank, texture, count, duration, timeLeft = UnitBuff(unit, i)

			if(not buff and not name) then
				break
			elseif(name) then
				if(not buff) then buff = createButton(self, icons, i) end

				if(duration and duration > 0) then
					buff.cd:SetCooldown(GetTime()-(duration-timeLeft), duration)
					buff.cd:Show()
				else
					buff.cd:Hide()
				end

				buff:Show()
				buff.icon:SetTexture(texture)
				buff.count:SetText((count > 1 and count) or nil)

				nb = nb + 1
			elseif(buff) then
				buff:Hide()
			end
		end
	end

	if self.Auras then
		icons = self.Auras
	else
		icons = self.Debuffs
	end
	
	if icons then
		for i=1, self.numDebuffs do
			debuff = icons[i]
			name, rank, texture, count, dtype, duration, timeLeft = UnitDebuff(unit, i)

			if(not debuff and not name) then
				break
			elseif(name) then
				if(not debuff) then debuff = createButton(self, icons, i, true) end

				if(duration and duration > 0) then
					debuff.cd:SetCooldown(GetTime()-(duration-timeLeft), duration)
					debuff.cd:Show()
				else
					debuff.cd:Hide()
				end

				debuff:Show()
				debuff.icon:SetTexture(texture)

				color = DebuffTypeColor[dtype or "none"]
				debuff.overlay:SetVertexColor(color.r, color.g, color.b)
				debuff.count:SetText((count > 1 and count) or nil)

				nd = nd + 1
			elseif(debuff) then
				debuff:Hide()
			end
		end
	end

	self:SetAuraPosition(unit, nb, nd)
	if(self.PostUpdateAura) then self:PostUpdateAura(event, unit) end
end
