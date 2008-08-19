local wotlk = select(4, GetBuildInfo()) >= 3e4

local	select, table_insert, math_floor, UnitDebuff, UnitBuff, GetTime, DebuffTypeColor =
		select, table.insert, math.floor, UnitDebuff, UnitBuff, GetTime, DebuffTypeColor

local timeLeft, duration, dtype, count, texture, rank, name, color
local total, col, row, size, anchor, button, growthx, growthy, cols, rows, spacing, gap
local auras, buffs, debuffs, mod, max, filter, index, icon

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	if(wotlk) then
		GameTooltip:SetUnitAura(self.frame.unit, self:GetID(), self.filter)
	else
		if(self.debuff) then
			GameTooltip:SetUnitDebuff(self.frame.unit, self:GetID(), self.parent.filter)
		else
			GameTooltip:SetUnitBuff(self.frame.unit, self:GetID(), self.parent.filter)
		end
	end
end

local OnLeave = function()
	GameTooltip:Hide()
end

local createAuraIcon = function(self, icons, index, debuff)
	local button = CreateFrame("Frame", nil, icons)
	button:EnableMouse(true)

	button:SetWidth(icons.size or 16)
	button:SetHeight(icons.size or 16)

	local cd = CreateFrame("Cooldown", nil, button)
	cd:SetAllPoints(button)

	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetAllPoints(button)

	local count = button:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(NumberFontNormal)
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 0)

	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture"Interface\\Buttons\\UI-Debuff-Overlays"
	overlay:SetAllPoints(button)
	overlay:SetTexCoord(.296875, .5703125, 0, .515625)
	button.overlay = overlay

	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)

	table_insert(icons, button)

	button.parent = icons
	button.frame = self
	button.debuff = debuff

	button.icon = icon
	button.count = count
	button.cd = cd

	if(self.PostCreateAuraIcon) then self:PostCreateAuraIcon(button, icons, index, debuff) end

	return button
end

local updateIcon = function(self, unit, icons, index, offset, filter, isDebuff, max)
	if(index == 0) then index = max end
	if(wotlk) then
		name, rank, texture, count, dtype, duration, timeLeft = UnitAura(unit, index, filter)
	else
		if(isDebuff) then
			name, rank, texture, count, dtype, duration, timeLeft = UnitDebuff(unit, index, filter)
		else
			name, rank, texture, count, duration, timeLeft = UnitBuff(unit, index, filter)
		end
	end

	icon = icons[index + offset]
	if((icons.onlyShowDuration and duration) or (not icons.onlyShowDuration and name)) then
		if(not icon) then icon = (self.CreateAuraIcon and self:CreateAuraIcon(icons, index, isDebuff)) or createAuraIcon(self, icons, index, isDebuff) end

		if(duration and duration > 0) then
			if(wotlk) then
				icon.cd:SetCooldown(timeLeft - duration, duration)
			else
				icon.cd:SetCooldown(GetTime()-(duration-timeLeft), duration)
			end
			icon.cd:Show()
		else
			icon.cd:Hide()
		end

		if((isDebuff and icons.showDebuffType) or (not isDebuff and icons.showBuffType) or icons.showType) then
			color = DebuffTypeColor[dtype or "none"]
			icon.overlay:SetVertexColor(color.r, color.g, color.b)
			icon.overlay:Show()
			icon.count:SetText((count > 1 and count))
		else
			icon.overlay:Hide()
		end

		icon:Show()
		icon:SetID(index)

		icon.filter = filter
		icon.debuff = isDebuff
		icon.icon:SetTexture(texture)
		icon.count:SetText((count > 1 and count))

		if(self.PostUpdateAuraIcon) then self:PostUpdateAuraIcon(icons, unit, icon, index, offset, filter, isDebuff) end
		return true
	elseif(icon) then
		icon:Hide()
	end
end

function oUF:SetAuraPosition(icons, x)
	if(icons and x > 0) then
		col = 0
		row = 0
		spacing = icons.spacing or 0
		gap = icons.gap
		size = (icons.size or 16) + spacing
		anchor = icons.initialAnchor or "BOTTOMLEFT"
		growthx = (icons["growth-x"] == "LEFT" and -1) or 1
		growthy = (icons["growth-y"] == "DOWN" and -1) or 1
		cols = math_floor(icons:GetWidth() / size + .5)
		rows = math_floor(icons:GetHeight() / size + .5)

		for i = 1, x do
			button = icons[i]
			if(button and button:IsShown()) then
				if(gap and button.debuff) then
					if(col > 0) then
						col = col + 1
					end

					gap = false
				end

				if(col >= cols) then
					col = 0
					row = row + 1
				end
				button:ClearAllPoints()
				button:SetPoint(anchor, icons, anchor, col * size * growthx, row * size * growthy)

				col = col + 1
			end
		end
	end
end

function oUF:UNIT_AURA(event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdateAura) then self:PreUpdateAura(event, unit) end

	auras, buffs, debuffs = self.Auras, self.Buffs, self.Debuffs

	if(auras) then
		buffs = auras.numBuffs or 32
		debuffs = auras.numDebuffs or 40
		max = debuffs + buffs

		local visibleBuffs, visibleDebuffs = 0, 0
		for index = 1, max do
			if(index > buffs) then
				if(updateIcon(self, unit, auras, index % debuffs, buffs, auras.debuffFilter or 'HARMFUL', true, debuffs)) then
					visibleBuffs = visibleBuffs + 1
				end
			else
				if(updateIcon(self, unit, auras, index, 0, auras.buffFilter or 'HELPFUL')) then
					visibleDebuffs = visibleDebuffs + 1
				end
			end
		end

		auras.visibleBuffs = visibleBuffs
		auras.visibleDebuffs = visibleDebuffs
		auras.visibleAuras = visibleBuffs + visibleDebuffs

		self:SetAuraPosition(auras, max)
	else
		if(buffs) then
			if(wotlk) then
				filter = buffs.filter or 'HELPFUL'
			else
				filter = buffs.filter
			end
			max = buffs.num or 32
			local visibleBuffs = 0
			for index = 1, max do
				if(not updateIcon(self, unit, buffs, index, 0, filter)) then
					max = index - 1

					while(buffs[index]) do
						buffs[index]:Hide()
						index = index + 1
					end
					break
				end

				visibleBuffs = visibleBuffs + 1
			end

			buffs.visibleBuffs = visibleBuffs
			self:SetAuraPosition(buffs, max)
		end
		if(debuffs) then
			if(wotlk) then
				filter = debuffs.filter or 'HARMFUL'
			else
				filter = debuffs.filter
			end
			max = debuffs.num or 40
			local visibleDebuffs = 0
			for index = 1, max do
				if(not updateIcon(self, unit, debuffs, index, 0, filter, true)) then
					max = index - 1

					while(debuffs[index]) do
						debuffs[index]:Hide()
						index = index + 1
					end
					break
				end

				visibleDebuffs = visibleDebuffs + 1
			end
			debuffs.visibleDebuffs = visibleDebuffs
			self:SetAuraPosition(debuffs, max)
		end
	end

	if(self.PostUpdateAura) then self:PostUpdateAura(event, unit) end
end

table.insert(oUF.subTypes, function(self)
	if(self.Buffs or self.Debuffs or self.Auras) then
		self:RegisterEvent"UNIT_AURA"
	end
end)

oUF:RegisterSubTypeMapping"UNIT_AURA"
