local parent, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local function updateElement(self, event, element, specID)
	local el = self[element]
	if(el and self:IsElementEnabled(element)) then
		el:SetMinMaxValues(0, 1)
		el:SetValue(1)

		local r, g, b, t, _
		if(el.colorPower and element == 'Power') then
			-- FIXME: no idea if we can get power type here without the unit
		elseif(el.colorClass) then
			local _, _, _, _, _, _, class = GetSpecializationInfoByID(specID)
			t = self.colors.class[class]
		elseif(el.colorReaction) then
			t = self.colors.reaction[2]
		elseif(el.colorSmooth) then
			_, _, _, _, _, _, r, g, b = unpack(el.smoothGradient or self.colors.smooth)
		elseif(el.colorHealth and element == 'Health') then
			t = self.colors.health
		end

		if(t) then
			r, g, b = t[1], t[2], t[3]
		end

		if(r or g or b) then
			el:SetStatusBarColor(r, g, b)

			local bg = el.bg
			if(bg) then
				local mu = bg.multiplier or 1
				bg:SetVertexColor(r * mu, g * mu, b * mu)
			end
		end
	end
end

function Private.UpdateArenaPreperation(self, event)
	if(event == 'ARENA_OPPONENT_UPDATE' and not self:IsEnabled()) then
		self:Enable()
		self:UpdateAllElements('ArenaPreparation')
		self:UnregisterEvent(event, Private.UpdateArenaPreperation)

		-- show elements that don't handle their own visibility
		if(self:IsElementEnabled('Auras')) then
			if(self.Auras) then self.Auras:Show() end
			if(self.Buffs) then self.Buffs:Show() end
			if(self.Debuffs) then self.Debuffs:Show() end
		end

		if(self.Portrait and self:IsElementEnabled('Portrait')) then
			self.Portrait:Show()
		end
	elseif(event == 'PLAYER_ENTERING_WORLD' and not UnitExists(self.unit)) then
		Private.UpdateArenaPreperation(self, 'ARENA_PREP_OPPONENT_SPECIALIZATIONS')
	elseif(event == 'ARENA_PREP_OPPONENT_SPECIALIZATIONS') then
		local specID = GetArenaOpponentSpec(tonumber(id))
		if(specID) then
			if(self:IsEnabled()) then
				self:Disable()
				self:RegisterEvent('ARENA_OPPONENT_UPDATE', Private.UpdateArenaPreperation)
			end

			-- pseudo-element updates
			updateElement(self, event, 'Health', specID)
			updateElement(self, event, 'Power', specID)

			-- hide all other (relevant) elements
			if(self.Auras) then self.Auras:Hide() end
			if(self.Buffs) then self.Buffs:Hide() end
			if(self.Debuffs) then self.Debuffs:Hide() end
			if(self.Castbar) then self.Castbar:Hide() end
			if(self.CombatIndicator) then self.CombatIndicator:Hide() end
			if(self.GroupRoleIndicator) then self.GroupRoleIndicator:Hide() end
			if(self.Portrait) then self.Portrait:Hide() end
			if(self.PvPIndicator) then self.PvPIndicator:Hide() end
			if(self.RaidTargetIndicator) then self.RaidTargetIndicator:Hide() end

			self:Show()
			self:ForceUpdateTags()
		end
	end
end
