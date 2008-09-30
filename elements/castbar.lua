--[[
	Original codebase:
		oUF_Castbar by starlon.
		http://svn.wowace.com/wowace/trunk/oUF_Castbar/
--]]
local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local UnitName = UnitName
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo

function oUF:UNIT_SPELLCAST_START(event, unit, spell, spellrank)
	if(self.unit ~= unit) then return end

	local castbar = self.Castbar
	local name, rank, text, texture, startTime, endTime = UnitCastingInfo(unit)
	if(not name) then
		if(not castbar.channeling) then castbar:Hide() end
		return
	end

	endTime = endTime / 1e3
	startTime = startTime / 1e3
	local max = endTime - startTime

	castbar.duration = GetTime() - startTime
	castbar.max = max
	castbar.delay = 0
	castbar.casting = true

	castbar:SetMinMaxValues(0, max)
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
	if(not castbar.casting) then return end
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
	local duration = GetTime() - (startTime / 1000)
	if(duration < 0) then duration = 0 end

	castbar.delay = castbar.delay + castbar.duration - duration
	castbar.duration = duration

	castbar:SetValue(duration)

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

	local castbar = self.Castbar
	local name, rank, text, texture, startTime, endTime = UnitChannelInfo(unit)
	if(not name) then
		if(not castbar.casting) then castbar:Hide() end
		return
	end

	endTime = endTime / 1e3
	startTime = startTime / 1e3
	local max = (endTime - startTime)
	local duration = endTime - GetTime()

	castbar.duration = duration
	castbar.max = max
	castbar.delay = 0
	castbar.channeling = true

	castbar:SetMinMaxValues(0, max)
	castbar:SetValue(duration)

	if(castbar.Text) then castbar.Text:SetText(name) end
	if(castbar.Icon) then castbar.Icon:SetTexture(texture) end
	if(castbar.Time) then castbar.Time:SetText() end

	if(self.PostChannelStart) then self:PostChannelStart(event, unit, spellname, spellrank) end
	castbar:Show()
end

function oUF:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit, spellname, spellrank)
	if(self.unit ~= unit) then return end

	local name, rank, text, texture, startTime, endTime, oldStart = UnitChannelInfo(unit)
	local castbar = self.Castbar
	local duration = (endTime / 1000) - GetTime()

	castbar.delay = castbar.delay + castbar.duration - duration
	castbar.duration = duration
	castbar.max = (endTime - startTime) / 1000

	castbar:SetMinMaxValues(0, castbar.max)
	castbar:SetValue(duration)

	if(self.PostChannelUpdate) then self:PostChannelUpdate(event, unit, spellname, spellrank) end
end

function oUF:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, spellname, spellrank)
	if(self.unit ~= unit) then return end

	local castbar = self.Castbar
	castbar.channeling = nil

	castbar:SetValue(castbar.max)
	castbar:Hide()

	if(self.PostChannelStop) then self:PostChannelStop(event, unit, spellname, spellrank) end
end

oUF.UNIT_SPELLCAST_CHANNEL_INTERRUPTED = oUF.UNIT_SPELLCAST_INTERRUPTED

local onUpdate = function(self, elapsed)
	if self.casting then
		local duration = self.duration + elapsed
		if (duration >= self.max) then
			self.casting = nil
			self:Hide()
		end
		if self.SafeZone then
			local width = self:GetWidth()
			local _, _, ms = GetNetStats()
			-- MADNESS!
			local safeZonePercent = (width / self.max) * (ms / 1e5)
			if(safeZonePercent > 1) then safeZonePercent = 1 end
			self.SafeZone:SetWidth(width * safeZonePercent)
		end
		if self.Time then
			if self.delay ~= 0 then
				self.Time:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, self.delay)
			else
				self.Time:SetFormattedText("%.1f", duration)
			end
		end

		self.duration = duration
		self:SetValue(duration)

		if self.Spark then
			self.Spark:SetPoint("CENTER", self, "LEFT", (duration / self.max) * self:GetWidth(), 0)
		end
	elseif self.channeling then
		local duration = self.duration - elapsed

		if(duration <= 0) then
			self.channeling = nil
			self:Hide()
			return
		end

		if self.Time then
			if self.delay ~= 0 then
				self.Time:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, self.delay)
			else
				self.Time:SetFormattedText("%.1f", duration)
			end
		end

		self.duration = duration
		self:SetValue(duration)
		if self.Spark then
			self.Spark:SetPoint("CENTER", self, "LEFT", (duration / self.max) * self:GetWidth(), 0)
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
	local castbar = object.Castbar
	if(unit and unit:match'%wtarget$') then return end

	if(castbar) then
		object:RegisterEvent"UNIT_SPELLCAST_START"
		object:RegisterEvent"UNIT_SPELLCAST_FAILED"
		object:RegisterEvent"UNIT_SPELLCAST_STOP"
		object:RegisterEvent"UNIT_SPELLCAST_INTERRUPTED"
		object:RegisterEvent"UNIT_SPELLCAST_DELAYED"
		object:RegisterEvent"UNIT_SPELLCAST_CHANNEL_START"
		object:RegisterEvent"UNIT_SPELLCAST_CHANNEL_UPDATE"
		object:RegisterEvent"UNIT_SPELLCAST_CHANNEL_INTERRUPTED"
		object:RegisterEvent"UNIT_SPELLCAST_CHANNEL_STOP"

		castbar.parent = object
		castbar:SetScript("OnUpdate", object.OnCastbarUpdate or onUpdate)

		if object.unit == "player" then
			CastingBarFrame:UnregisterAllEvents()
			CastingBarFrame.Show = function() end
			CastingBarFrame:Hide()
		end

		if(not castbar:GetStatusBarTexture()) then
			castbar:SetStatusBarTexture[[Interface\TargetingFrame\UI-StatusBar]]
		end

		local spark = castbar.Spark
		if(spark and spark:IsObjectType'Texture' and not spark:GetTexture()) then
			spark:SetTexture[[Interface\CastingBar\UI-CastingBar-Spark]]
		end

		local sz = castbar.SafeZone
		if(sz and sz:IsObjectType'Texture' and not sz:GetTexture()) then
			sz:SetTexture(1, 0, 0)
		end

		castbar:Hide()
	end
end)

oUF:RegisterSubTypeMapping"UNIT_SPELLCAST_START"
oUF:RegisterSubTypeMapping"UNIT_SPELLCAST_CHANNEL_START"
