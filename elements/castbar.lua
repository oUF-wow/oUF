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
	if(self.unit ~= unit) then return end

	local name, rank, text, texture, startTime, endTime = UnitCastingInfo(unit)
	if(not name) then return end

	local castbar = self.Castbar
	castbar.startTime = startTime / 1000
	castbar.maxValue = endTime / 1000
	castbar.delay = 0
	castbar.casting = true

	castbar:SetMinMaxValues(0, 1)
	castbar:SetValue(0)

	if(castbar.Text) then castbar.Text:SetText(text) end
	if(castbar.Icon) then castbar.Icon:SetTexture(texture) end
	if(castbar.Time) then castbar.Time:SetText() end

	if(self.PostCastStart) then self:PostCastStart(event, unit, spell, spellrank) end
	castbar:Show()
end

function oUF:UNIT_SPELLCAST_FAILED(event, unit, spellname, spellrank)
	if(self.unit ~= unit) then return end

	local castbar = self.Castbar
	castbar.casting = nil

	castbar:SetValue(0)
	castbar:Hide()

	if(self.PostCastFailed) then self:PostCastFailed(event, unit, spellname, spellrank) end
end

function oUF:UNIT_SPELLCAST_INTERRUPTED(event, unit, spellname, spellrank)
	if(self.unit ~= unit) then return end

	local castbar = self.Castbar
	castbar.casting = nil
	castbar.channeling = nil

	castbar:SetValue(0)
	castbar:Hide()

	if(self.PostCastInterrupted) then self:PostCastInterrupted(event, unit, spellname, spellrank) end
end

function oUF:UNIT_SPELLCAST_DELAYED(event, unit, spellname, spellrank)
	if(self.unit ~= unit) then return end

	local name, rank, text, texture, startTime, endTime = UnitCastingInfo(unit)
	if(not startTime) then return end

	local castbar = self.Castbar
	local oldStart = castbar.startTime
	startTime = startTime / 1000

	castbar.startTime = startTime
	castbar.maxValue = endTime / 1000
	castbar.delay = castbar.delay + (startTime - oldStart)

	if(self.PostCastDelayed) then self:PostCastDelayed(event, unit, spellname, spellrank) end
end

function oUF:UNIT_SPELLCAST_STOP(event, unit, spellname, spellrank)
	if(self.unit ~= unit) then return end

	local castbar = self.Castbar
	if(not castbar.casting) then return end

	castbar:SetValue(0)
	castbar:Hide()
	castbar.casting = nil

	if(self.PostCastStop) then self:PostCastStop(event, unit, spellname, spellrank) end
end

function oUF:UNIT_SPELLCAST_CHANNEL_START(event, unit, spellname, spellrank)
	if(self.unit ~= unit) then return end

	local name, rank, text, texture, startTime, endTime = UnitChannelInfo(unit)
	if(not name) then return end

	startTime = startTime / 1000
	endTime = endTime / 1000

	local castbar = self.Castbar
	castbar.startTime = startTime
	castbar.endTime = endTime
	castbar.duration = endTime - startTime
	castbar.maxValue = startTime
	castbar.delay = 0
	castbar.channeling = true

	castbar:SetMinMaxValues(startTime, endTime)
	castbar:SetValue(endTime)

	if(castbar.Text) then castbar.Text:SetText(name) end
	if(castbar.Icon) then castbar.Icon:SetTexture(texture) end
	if(castbar.Time) then castbar.Time:SetText() end

	if(self.PostChannelStart) then self:PostChannelStart(event, unit, spellname, spellrank) end
	castbar:Show()
end

function oUF:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit, spellname, spellrank)
	if(self.unit ~= unit) then return end

	local name, rank, text, texture, startTime, endTime, oldStart = UnitChannelInfo(unit);

	endTime = endTime / 1000
	startTime = startTime / 1000

	local castbar = self.Castbar
	local oldStart = castbar.startTime

	castbar.startTime = startTime
	castbar.endTime = endTime
	castbar.maxValue = startTime
	castbar.delay = castbar.delay + (oldStart - startTime)

	if(self.PostChannelUpdate) then self:PostChannelUpdate(event, unit, spellname, spellrank) end
end

function oUF:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, spellname, spellrank)
	if(self.unit ~= unit) then return end

	local castbar = self.Castbar
	castbar.channeling = nil

	castbar:SetValue(1)
	castbar:Hide()

	if(self.PostChannelStop) then self:PostChannelStop(event, unit, spellname, spellrank) end
end

oUF.UNIT_SPELLCAST_CHANNEL_INTERRUPTED = oUF.UNIT_SPELLCAST_INTERRUPTED

local onUpdate = function(self, elapsed)
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

		local value = (status - self.startTime) / (self.maxValue - self.startTime)
		self:SetValue(value)

		if self.Spark then
			self.Spark:SetPoint("CENTER", self, "LEFT", value * self:GetWidth(), 0)
		end
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

		local remainingTime = self.endTime - status
		self:SetValue(self.startTime + remainingTime)

		if self.Spark then
			self.Spark:SetPoint("CENTER", self, "LEFT", (remainingTime / (self.endTime - self.startTime)) * self:GetWidth(), 0)
		end
	else
		self.unitName = nil
		self.casting = nil
		self.channeling = nil
		self:SetValue(1)
		self:Hide()
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
