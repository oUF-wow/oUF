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

local icon, timeLeft, duration, dtype, count, texture, rank, name, color
local total, col, row, size, anchor, button, growthx, growthy, cols, rows

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	if(self.overlay) then
		GameTooltip:SetUnitDebuff(self:GetParent().unit, self:GetID())
	else
		GameTooltip:SetUnitBuff(self:GetParent().unit, self:GetID())
	end
end

local OnLeave = function()
	GameTooltip:Hide()
end

local createAuraIcon = function(self, icons, index, debuff)
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

	if(self.PostCreateAuraIcon) then self:PostCreateAuraIcon(button) end

	return button
end

local updateIcons = function(self, unit, icons, isDebuff)
	total = 0
	for i=1, icons.num do
		icon = icons[i]
		if(isDebuff) then
			name, rank, texture, count, dtype, duration, timeLeft = UnitDebuff(unit, i, self.filter)
		else
			name, rank, texture, count, duration, timeLeft = UnitBuff(unit, i, self.filter)
		end

		if(not icon and not name) then
			break
		elseif(name) then
			-- Clearly easy to read:
			if(not icon) then icon = (self.CreateAuraIcon and self:CreateAuraIcon(self, icons, i, isDebuff)) or createAuraIcon(self, icons, i, isDebuff) end

			if(duration and duration > 0) then
				icon.cd:SetCooldown(GetTime()-(duration-timeLeft), duration)
				icon.cd:Show()
			else
				icon.cd:Hide()
			end

			if(isDebuff) then
				color = DebuffTypeColor[dtype or "none"]
				icon.overlay:SetVertexColor(color.r, color.g, color.b)
				icon.count:SetText((count > 1 and count) or nil)
			end

			icon:Show()
			icon.icon:SetTexture(texture)
			icon.count:SetText((count > 1 and count) or nil)

			total = total + 1
		elseif(icon) then
			icon:Hide()
		end
	end

	return icons, total
end

function oUF:SetAuraPosition(icons, x)
	if(icons and x > 0) then
		col = 0
		row = 0
		size = icons.size or 16
		anchor = icons.initialAnchor or "BOTTOMLEFT"
		growthx = (icons["growth-x"] == "LEFT" and -1) or 1
		growthy = (icons["growth-y"] == "DOWN" and -1) or 1
		cols = math.floor(icons:GetWidth() / size)
		rows = math.floor(icons:GetHeight() / size)

		for i = 1, x do
			button = icons[i]
			button:ClearAllPoints()
			button:SetPoint(anchor, icons, anchor, col * size * growthx, row * size * growthy)

			if(col >= cols) then
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

	if(self.Aura) then
	else
		if(self.Buffs) then
			self:SetAuraPosition(updateIcons(self, unit, self.Buffs))
		end

		if(self.Debuffs) then
			self:SetAuraPosition(updateIcons(self, unit, self.Debuffs, true))
		end
	end

	if(self.PostUpdateAura) then self:PostUpdateAura(event, unit) end
end
