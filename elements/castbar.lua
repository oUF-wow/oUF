--[[
	Original codebase:
		oUF_Castbar by starlon.
		http://svn.wowace.com/wowace/trunk/oUF_Castbar/
--]]

local UnitName = UnitName
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo

function oUF:UNIT_SPELLCAST_START(event, unit, spell, spellrank)
	if self.unit ~= unit then return end
	if not self.SpellcastStart then
		local castbar = self.Castbar
		local name, rank, text, texture, startTime, endTime = UnitCastingInfo(unit)
		if not name then return end

		castbar.startTime = startTime / 1000
		castbar.maxValue = endTime / 1000
		castbar.delay = 0

		castbar:SetMinMaxValues(0, 1)
		castbar:SetValue(0)
		if(castbar.Text) then castbar.Text:SetText(text) end
		if castbar.Icon then castbar.Icon:SetTexture(texture) end
		if castbar.Time then castbar.Time:SetText() end
		castbar:Show()
		castbar.casting = true
		if unit == "target" or unit:sub(1,4) == "raid" then castbar.unitName = UnitName(unit) end
	else
		self:SpellcastStart(event, unit, spell, spellrank)
	end
end

function oUF:UNIT_SPELLCAST_FAILED(event, unit, spellname, spellrank)
	if self.unit ~= unit then return end
	if not self.SpellcastFailed then
		local castbar = self.Castbar
		castbar:SetValue(0)
		castbar:Hide()
		castbar.casting = nil
	else
		self:SpellcastFailed(event, unit, spellname, spellrank)
	end
end

function oUF:UNIT_SPELLCAST_INTERRUPTED(event, unit, spellname, spellrank)
	if self.unit ~= unit then return end
	if not self.SpellcastInterrupted then
		local castbar = self.Castbar
		castbar:SetValue(0)
		castbar:Hide()
		castbar.casting = nil
		castbar.channeling = nil
	else
		self:SpellcastInterrupted(event, unit, spellname, spellrank)
	end
end

function oUF:UNIT_SPELLCAST_DELAYED(event, unit, spellname, spellrank)
	if self.unit ~= unit then return end
	if not self.SpellcastDelayed then
		local name, rank, text, texture, startTime, endTime = UnitCastingInfo(unit)
		if not startTime then return end

		local castbar = self.Castbar
		local oldStart = castbar.startTime
		castbar.startTime = startTime / 1000
		castbar.maxValue = endTime / 1000
		castbar.delay = castbar.delay + (castbar.startTime - oldStart)
	else
		self:SpellcastDelayed(event, unit, spellname, spellrank)
	end
end

function oUF:UNIT_SPELLCAST_STOP(event, unit, spellname, spellrank)
	if self.unit ~= unit then return end
	if not self.Castbar.casting then return end
	if not self.SpellcastStop then
		local castbar = self.Castbar
		castbar:SetValue(0)
		castbar:Hide()
		castbar.casting = nil
	else
		self:SpellcastStop(event, unit, spellname, spellrank)
	end
end

function oUF:UNIT_SPELLCAST_CHANNEL_START(event, unit, spellname, spellrank)
	if self.unit ~= unit then return end
	if not self.SpellcastChannelStart then
		local name, rank, text, texture, startTime, endTime = UnitChannelInfo(unit)
		if(not name) then return end
		local castbar = self.Castbar
		castbar.startTime = startTime / 1000
		castbar.endTime = endTime / 1000
		castbar.duration = castbar.endTime - castbar.startTime
		castbar.maxValue = castbar.startTime
		castbar.delay = 0
		castbar:SetMinMaxValues(castbar.startTime, castbar.endTime)
		castbar:SetValue(castbar.endTime)
		if(castbar.Text) then castbar.Text:SetText(name) end
		if castbar.Icon then castbar.Icon:SetTexture(texture) end
		if castbar.Time then castbar.Time :SetText() end
		castbar:Show()
		castbar.channeling = true
		if unit == "target" or unit:sub(1,4) == "raid" then castbar.unitName = UnitName(unit) end
	else
		self:SpellcastChannelStart(event, unit, spellname, spellrank)
	end
end

function oUF:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit, spellname, spellrank)
	if self.unit ~= unit then return end
	if not self.SpellcastChannelUpdate then
		local spell, _, _, _, startTime, endTime, oldStart = UnitChannelInfo(unit);
		local castbar = self.Castbar
		local oldStart = castbar.startTime
		castbar.startTime = startTime / 1000
		castbar.endTime = endTime / 1000
		castbar.maxValue = castbar.startTime
		castbar.delay = castbar.delay + (oldStart - castbar.startTime)
	else
		self:SpellcastChannelUpdate(event, unit, spellname, spellrank)
	end
end

function oUF:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, spellname, spellrank)
	if self.unit ~= unit then return end
	if not self.SpellcastChannelStop then
		local castbar = self.Castbar
		castbar:SetValue(1)
		castbar:Hide()
		castbar.channeling = nil
	else
		self:SpellcastChannelStop(event, unit, spellname, spellrank)
	end
end

oUF.UNIT_SPELLCAST_CHANNEL_INTERRUPTED = oUF.UNIT_SPELLCAST_INTERRUPTED

local onUpdate = function(self, elapsed)
	if self.unitName and self.unitName ~= UnitName(self.parent.unit) then
		self.unitName = nil
		self.casting = nil
		self.channeling = nil
		self:SetValue(1)
		self:Hide()
	end
	if self.casting then
		local status = GetTime()
		if (status >= self.maxValue) then
			self.casting = nil
			self:Hide()
			return
		end
		if self.safezone then
			local castTime = (self.maxValue - self.startTime) * 1000
			local safeZonePercent = ( (self:GetWidth() / castTime ) * select(3,GetNetStats()) );
			if safeZonePercent > 100 then safeZonePercent = 100 end
			self.safezone:SetWidth((self:GetWidth() / 100) * safeZonePercent);
		end
		if self.Time then
			if self.delay ~= 0 then
				self.Time:SetFormattedText("%.1f|cffff0000-%.1f|r", self.maxValue - status, self.delay)
			else
				self.Time:SetFormattedText("%.1f", self.maxValue - status)
			end
		end
		self:SetValue( ((status - self.startTime) / (self.maxValue - self.startTime)))
	elseif self.channeling then
		local status = GetTime()
		if ( status >= self.endTime ) then
			self.channeling = nil
			self:Hide()
			return
		end
		if self.Time then
			if self.delay ~= 0 then
				self.Time:SetFormattedText("%.1f|cffff0000-%.1f|r", self.endTime - status, self.delay)
			else
				self.Time:SetFormattedText("%.1f", self.endTime - status)
			end
		end
		self:SetValue( self.startTime + (self.endTime - status) )
	end
end

table.insert(oUF.subTypes, function(object, unit)
	if not object.Castbar or (unit and unit:match"%wtarget$") then return end

	object:RegisterEvent"UNIT_SPELLCAST_START"
	object:RegisterEvent"UNIT_SPELLCAST_FAILED"
	object:RegisterEvent"UNIT_SPELLCAST_STOP"
	object:RegisterEvent"UNIT_SPELLCAST_INTERRUPTED"
	object:RegisterEvent"UNIT_SPELLCAST_DELAYED"
	object:RegisterEvent"UNIT_SPELLCAST_CHANNEL_START"
	object:RegisterEvent"UNIT_SPELLCAST_CHANNEL_UPDATE"
	object:RegisterEvent"UNIT_SPELLCAST_CHANNEL_INTERRUPTED"
	object:RegisterEvent"UNIT_SPELLCAST_CHANNEL_STOP"
	--~   object.timeSinceLastUpdate = 0

	object.Castbar.parent = object
	object.Castbar:SetScript("OnUpdate", object.OnCastbarUpdate or onUpdate)

	if object.unit == "player" then
		CastingBarFrame:UnregisterAllEvents()
		CastingBarFrame.Show = function() end
		CastingBarFrame:Hide()
	end

	object.Castbar:Hide()
end)

oUF:RegisterSubTypeMapping"UNIT_SPELLCAST_START"
oUF:RegisterSubTypeMapping"UNIT_SPELLCAST_CHANNEL_START"
