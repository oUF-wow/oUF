--[[
-- Experimental oUF tags
-- Status: Untested, Incomplete
--
-- Credits: Vika, Cladhaire, Tekkub
--
-- TODO:
--	- Do a full test, so we konw that it actually works.
--	- Tag and Untag should be able to handle more than one fontstring at a time.
--	- Eventless units needs a initial onshow update.
--	- Report when we don't find a matching tag.
]]

local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local function Hex(r, g, b)
	if type(r) == "table" then
		if r.r then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
	end
	return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

local tags
tags = {
	["[class]"]       = function(u) return UnitClass(u) or "" end,
	["[creature]"]    = function(u) return UnitCreatureFamily(u) or UnitCreatureType(u) or "" end,
	["[curhp]"]       = UnitHealth,
	["[curpp]"]       = UnitPower,
	["[dead]"]        = function(u) return UnitIsDead(u) and "Dead" or UnitIsGhost(u) and "Ghost" or "" end,
	["[difficulty]"]  = function(u) if UnitCanAttack("player", u) then local l = UnitLevel(u); return Hex(GetDifficultyColor((l > 0) and l or 99)) else return "" end end,
	["[faction]"]     = function(u) return UnitFactionGroup(u) or "" end,
	["[leader]"]      = function(u) return UnitIsPartyLeader(u) and "(L)" or "" end,
	["[leaderlong]"]  = function(u) return UnitIsPartyLeader(u) and "(Leader)" or "" end,
	["[level]"]       = function(u) local l = UnitLevel(u) return (l > 0) and l or "??" end,
	["[maxhp]"]       = UnitHealthMax,
	["[maxpp]"]       = UnitPowerMax,
	["[missinghp]"]   = function(u) return UnitHealthMax(u) - UnitHealth(u) end,
	["[missingpp]"]   = function(u) return UnitPowerMax(u) - UnitPower(u) end,
	["[name]"]        = function(u, r) return UnitName(r or u) or '' end,
	["[offline]"]     = function(u) return UnitIsConnected(u) and "" or "Offline" end,
	["[perhp]"]       = function(u) local m = UnitHealthMax(u); return m == 0 and 0 or math.floor(UnitHealth(u)/m*100+0.5) end,
	["[perpp]"]       = function(u) local m = UnitPowerMax(u); return m == 0 and 0 or math.floor(UnitPower(u)/m*100+0.5) end,
	["[plus]"]        = function(u) return UnitIsPlusMob(u) and "+" or "" end,
	["[pvp]"]         = function(u) return UnitIsPVP(u) and "PvP" or "" end,
	["[race]"]        = function(u) return UnitRace(u) or "" end,
	["[raidcolor]"]   = function(u) local _, x = UnitClass(u); return x and Hex(RAID_CLASS_COLORS[x]) or "" end,
	["[rare]"]        = function(u) local c = UnitClassification(u); return (c == "rare" or c == "rareelite") and "Rare" or "" end,
	["[resting]"]     = function(u) return u == "player" and IsResting() and "zzz" or "" end,
	["[sex]"]         = function(u) local s = UnitSex(u) return s == 2 and "Male" or s == 3 and "Female" or "" end,
	["[smartclass]"]  = function(u) return UnitIsPlayer(u) and tags["[class]"](u) or tags["[creature]"](u) end,
	["[smartlevel]"]  = function(u) return UnitClassification(u) == "worldboss" and "Boss" or tags["[level]"](u).. tags["[plus]"](u) end,
	["[status]"]      = function(u) return UnitIsDead(u) and "Dead" or UnitIsGhost(u) and "Ghost" or not UnitIsConnected(u) and "Offline" or tags["[resting]"](u) end,
	["[threat]"]      = function(u) local s = UnitThreatSituation(u) return s == 1 and "++" or s == 2 and "--" or s == 3 and "Aggro" or "" end,
	["[threatcolor]"] = function(u) return Hex(GetThreatStatusColor(UnitThreatSituation(u))) end,

	["[classification]"] = function(u)
		local c = UnitClassification(u)
		return c == "rare" and "Rare" or c == "eliterare" and "Rare Elite" or c == "elite" and "Elite" or c == "worldboss" and "Boss" or ""
	end,

	["[shortclassification]"] = function(u)
		local c = UnitClassification(u)
		return c == "rare" and "R" or c == "eliterare" and "R+" or c == "elite" and "+" or c == "worldboss" and "B" or ""
	end,
}
local tagEvents = {
	["[curhp]"]       = "UNIT_HEALTH",
	["[curpp]"]       = "UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE",
	["[dead]"]        = "UNIT_HEALTH",
	["[leader]"]      = "PARTY_LEADER_CHANGED",
	["[leaderlong]"]  = "PARTY_LEADER_CHANGED",
	["[level]"]       = "UNIT_LEVEL PLAYER_LEVEL_UP",
	["[maxhp]"]       = "UNIT_MAXHEALTH",
	["[maxpp]"]       = "UNIT_MAXENERGY UNIT_MAXFOCUS UNIT_MAXMANA UNIT_MAXRAGE",
	["[missinghp]"]   = "UNIT_HEALTH UNIT_MAXHEALTH",
	["[missingpp]"]   = "UNIT_MAXENERGY UNIT_MAXFOCUS UNIT_MAXMANA UNIT_MAXRAGE UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE UNIT_MAXRUNIC_POWER UNIT_RUNIC_POWER",
	["[name]"]        = "UNIT_NAME_UPDATE",
	["[offline]"]     = "UNIT_HEALTH",
	["[perhp]"]       = "UNIT_HEALTH UNIT_MAXHEALTH",
	["[perpp]"]       = "UNIT_MAXENERGY UNIT_MAXFOCUS UNIT_MAXMANA UNIT_MAXRAGE UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE UNIT_MAXRUNIC_POWER UNIT_RUNIC_POWER",
	["[pvp]"]         = "UNIT_FACTION",
	["[resting]"]     = "PLAYER_UPDATE_RESTING",
	["[status]"]      = "UNIT_HEALTH PLAYER_UPDATE_RESTING",
	["[smartlevel]"]  = "UNIT_LEVEL PLAYER_LEVEL_UP",
	["[threat]"]      = "UNIT_THREAT_SITUATION_UPDATE",
	["[threatcolor]"] = "UNIT_THREAT_SITUATION_UPDATE",
}

local unitlessEvents = {
	PLAYER_TARGET_CHANGED = true,
	PLAYER_FOCUS_CHANGED = true,
	PLAYER_LEVEL_UP = true,
}

local events = {}
local frame = CreateFrame"Frame"
frame:SetScript('OnEvent', function(self, event, unit)
	local strings = events[event]
	if(strings) then
		for k, fontstring in ipairs(strings) do
			if(not unitlessEvents[event] and fontstring.parent.unit == unit) then
				fontstring:UpdateTag()
			end
		end
	end
end)

local eventlessUnits = {}
local timer = .5
local OnUpdate = function(self, elapsed)
	if(timer >= .5) then
		for k, fs in ipairs(eventlessUnits) do
			if(fs.parent:IsShown() and UnitExists(fs.parent.unit)) then
				fs:UpdateTag()
			end
		end

		timer = 0
	end

	timer = timer + elapsed
end

local OnShow = function(self)
	for _, fs in ipairs(self.__tags) do
		fs:UpdateTag()
	end
end

local RegisterEvent = function(fontstr, event)
	if(not events[event]) then events[event] = {} end

	table.insert(events[event], fontstr)
end

local RegisterEvents = function(fontstr, tagstr)
	for tag in tagstr:gmatch'[[][%w]+[]]' do
		local tagevents = tagEvents[tag]
		if(tagevents) then
			for event in tagevents:gmatch'%S+' do
				if(not events[event]) then events[event] = {} end
				table.insert(events[event], fontstr)
				frame:RegisterEvent(event)
			end
		end
	end
end

local UnregisterEvents = function(fontstr)
	for events, data in pairs(events) do
		for k, tagfsstr in ipairs(data) do
			if(tagfsstr == fontstr) then
				if(#data[k] == 1) then frame:UnregisterEvent(event) end
				data[k] = nil
			end
		end
	end
end

local pool = {}
local tmp = {}

local Tag = function(self, fs, tagstr)
	if(not fs or not tagstr or self == oUF) then return end

	if(not self.__tags) then
		self.__tags = {}
		table.insert(self.__elements, OnShow)
	end

	fs.parent = self

	local func = pool[tagstr]
	if(not func) then
		local format = tagstr:gsub('%%', '%%%%'):gsub('[[][%w]+[]]', '%%s')
		local args = {}

		for tag in tagstr:gmatch'[[][%w]+[]]' do
			local tfunc = tags[tag]
			if(tfunc) then
				table.insert(args,tfunc)
			end
		end

		func = function(self)
			local unit = self.parent.unit
			local __unit = self.parent.__unit

			for i, func in ipairs(args) do
				tmp[i] = func(unit, __unit)
			end

			self:SetFormattedText(format, unpack(tmp))
		end

		pool[tagstr] = func
	end
	fs.UpdateTag = func

	local unit = self.unit
	if(unit and unit:match'%w+target') then
		table.insert(eventlessUnits, fs)

		if(not frame:GetScript'OnUpdate') then
			frame:SetScript('OnUpdate', OnUpdate)
		end
	else
		RegisterEvents(fs, tagstr)

		if(unit == 'focus') then
			RegisterEvent(fs, 'PLAYER_FOCUS_CHANGED')
		elseif(unit == 'target') then
			RegisterEvent(fs, 'PLAYER_TARGET_CHANGED')
		elseif(unit == 'mouseover') then
			RegisterEvent(fs, 'UPDATE_MOUSEOVER_UNIT')
		end
	end

	for k, tag in ipairs(self.__tags) do
		if(fs == tag) then
			return
		end
	end

	table.insert(self.__tags, fs)
end

local Untag = function(self, fs)
	if(not fs or self == oUF) then return end

	UnregisterEvents(fs)
	for k, fontstr in ipairs(eventlessUnits) do
		if(fs == fontstr) then
			table.remove(eventlessUnits, k)
		end
	end

	for k, fontstr in ipairs(self.__tags) do
		if(fontstr == fs) then
			table.remove(self.__tags, k)
		end
	end
end

oUF.Tags = tags
oUF.TagEvents = tagEvents
oUF.UnitlessTagEvents = unitlessEvents

oUF.Tag = Tag
oUF.Untag = Untag
