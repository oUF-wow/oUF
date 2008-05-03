local table_insert = table.insert
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetTime = GetTime
local DebuffTypeColor = DebuffTypeColor

local icon, timeLeft, duration, dtype, count, texture, rank, name, color
local total, col, row, size, anchor, button, growthx, growthy, cols, rows, spacing

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	if(self.overlay) then
		GameTooltip:SetUnitDebuff(self.frame.unit, self:GetID(), self.parent.filter)
	else
		GameTooltip:SetUnitBuff(self.frame.unit, self:GetID(), self.parent.filter)
	end
end

local OnLeave = function()
	GameTooltip:Hide()
end

local createAuraIcon = function(self, icons, index, debuff)
	local button = CreateFrame("Frame", nil, icons)
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

	button.parent = icons
	button.frame = self
	button.icon = icon
	button.count = count
	button.cd = cd

	if(self.PostCreateAuraIcon) then self:PostCreateAuraIcon(button, icons, index, debuff) end

	return button
end

local updateIcons = function(self, unit, icons, isDebuff)
	total = 0
	for i=1, icons.num do
		icon = icons[i]
		if(isDebuff) then
			name, rank, texture, count, dtype, duration, timeLeft = UnitDebuff(unit, i, icons.filter)
		else
			name, rank, texture, count, duration, timeLeft = UnitBuff(unit, i, icons.filter)
		end

		if(not icon and not name) then
			break
		elseif(name) then
			-- Clearly easy to read:
			if(not icon) then icon = (self.CreateAuraIcon and self:CreateAuraIcon(icons, i, isDebuff)) or createAuraIcon(self, icons, i, isDebuff) end

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
		spacing = icons.spacing or 0
		size = (icons.size or 16) + spacing
		anchor = icons.initialAnchor or "BOTTOMLEFT"
		growthx = (icons["growth-x"] == "LEFT" and -1) or 1
		growthy = (icons["growth-y"] == "UP" and -1) or 1
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
