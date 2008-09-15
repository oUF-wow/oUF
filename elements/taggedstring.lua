local parent = debugstack():match[[Interface\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

-------------------------------
--      Tag definitions      --
-------------------------------

local function Hex(r, g, b)
	if type(r) == "table" then
		if r.r then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
	end
	return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

local tags = {
	["[class]"]       = function(u) return UnitClass(u) or "" end,
	["[creature]"]    = function(u) return UnitCreatureFamily(u) or UnitCreatureType(u) or "" end,
	["[curhp]"]       = UnitHealth,
	["[curpp]"]       = UnitMana,
	["[dead]"]        = function(u) return UnitIsDead(u) and "Dead" or UnitIsGhost(u) and "Ghost" or "" end,
	["[difficulty]"]  = function(u) if UnitCanAttack("player", u) then local l = UnitLevel(u); return Hex(GetDifficultyColor((l > 0) and l or 99)) else return "" end end,
	["[faction]"]     = function(u) return UnitFactionGroup(u) or "" end,
	["[leader]"]      = function(u) return UnitIsPartyLeader(u) and "(L)" or "" end,
	["[leaderlong]"]  = function(u) return UnitIsPartyLeader(u) and "(Leader)" or "" end,
	["[level]"]       = function(u) local l = UnitLevel(u) return (l > 0) and l or "??" end,
	["[maxhp]"]       = UnitHealthMax,
	["[maxpp]"]       = UnitManaMax,
	["[missinghp]"]   = function(u) return UnitHealthMax(u) - UnitHealth(u) end,
	["[missingpp]"]   = function(u) return UnitManaMax(u) - UnitMana(u) end,
	["[name]"]        = UnitName,
	["[offline]"]     = function(u) return UnitIsConnected(u) and "" or "Offline" end,
	["[perhp]"]       = function(u) local m = UnitHealthMax(u); return m == 0 and 0 or math.floor(UnitHealth(u)/m*100+0.5) end,
	["[perpp]"]       = function(u) local m = UnitPowerMax(u); return m == 0 and 0 or math.floor(UnitPower(u)/m*100+0.5) end,
	["[plus]"]        = function(u) return UnitIsPlusMob(u) and "+" or "" end,
	["[pvp]"]         = function(u) return UnitIsPVP(u) and "PvP" or "" end,
	["[race]"]        = function(u) return UnitRace(u) or "" end,
	["[raidcolor]"]   = function(u) local _, x = UnitClass(u); return x and Hex(RAID_CLASS_COLORS[x]) or "" end,
	["[rare]"]        = function(u) local c = UnitClassification(u); return (c == "rare" or c == "rareelite") and "Rare" or "" end,
	["[resting]"]     = function(u) return u == "player" and IsResting() and "zzz" or "" end,
	["[sex]"]         = function(u) local s = UnitSex(u) return s == 2 and "Male" or s == 1 and "Female" or "" end,
	["[smartclass]"]  = function(u) return UnitIsPlayer(u) and oUF.Tags["[class]"](u) or oUF.Tags["[creature]"](u) end,
	["[smartlevel]"]  = function(u) return UnitClassification(u) == "worldboss" and "Boss" or UnitLevel(u).. oUF.Tags["[plus]"](u) end,
	["[status]"]      = function(u) return UnitIsDead(u) and "Dead" or UnitIsGhost(u) and "Ghost" or not UnitIsConnected(u) and "Offline" or oUF.Tags["[resting]"](u) end,
	["[threat]"]      = function(u) local s = UnitThreatSituation(u) return s == 1 and "++" or s == 2 and "--" or s == 3 and "Aggro" or "" end,
	["[threatcolor]"] = function(u) return Hex(GetThreatStatusColor(UnitThreatSituation(u))) end,
}
local events = {
	["[curhp]"]       = "UNIT_HEALTH",
	["[curpp]"]       = "UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE",
	["[dead]"]        = "UNIT_HEALTH",
	["[leader]"]      = "PARTY_LEADER_CHANGED",
	["[leaderlong]"]  = "PARTY_LEADER_CHANGED",
	["[level]"]       = "UNIT_LEVEL",
	["[maxhp]"]       = "UNIT_MAXHEALTH",
	["[maxpp]"]       = "UNIT_MAXENERGY UNIT_MAXFOCUS UNIT_MAXMANA UNIT_MAXRAGE",
	["[missinghp]"]   = "UNIT_HEALTH UNIT_MAXHEALTH",
	["[missingpp]"]   = "UNIT_MAXENERGY UNIT_MAXFOCUS UNIT_MAXMANA UNIT_MAXRAGE UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE",
	["[name]"]        = "UNIT_NAME_UPDATE",
	["[offline]"]     = "UNIT_HEALTH",
	["[perhp]"]       = "UNIT_HEALTH UNIT_MAXHEALTH",
	["[perpp]"]       = "UNIT_MAXENERGY UNIT_MAXFOCUS UNIT_MAXMANA UNIT_MAXRAGE UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE",
	["[pvp]"]         = "UNIT_FACTION",
	["[resting]"]     = "PLAYER_UPDATE_RESTING",
	["[status]"]      = "UNIT_HEALTH PLAYER_UPDATE_RESTING",
	["[threat]"]      = "UNIT_THREAT_SITUATION_UPDATE",
	["[threatcolor]"] = "UNIT_THREAT_SITUATION_UPDATE",
}

tags["[classification]"] = function(u)
	local c = UnitClassification(u)
	return c == "rare" and "Rare" or c == "eliterare" and "Rare Elite" or c == "elite" and "Elite" or c == "worldboss" and "Boss" or ""
end

tags["[shortclassification]"] = function(u)
	local c = UnitClassification(u)
	return c == "rare" and "R" or c == "eliterare" and "R+" or c == "elite" and "+" or c == "worldboss" and "B" or ""
end


----------------------
--      Tagger      --
----------------------

local currentunit
local function subber(tag)
	local f = tags[tag]
	return f and f(currentunit) or tag
end

local function processtags(taggedstring, unit)
	if not unit then return taggedstring end
	currentunit = unit
	return (taggedstring:gsub("[[][%w]+[]]", subber):gsub(" +", " "))
end


local unitlessevents = {PLAYER_TARGET_CHANGED = true, PLAYER_FOCUS_CHANGED = true}
local function OnEvent(self, event, unit)
	if not unitlessevents[event] and unit ~= self.parent.unit then return end
	self.fontstring:SetText(processtags(self.tagstring, self.parent.unit))
end


local function OnShow(self)
	self.fontstring:SetText(processtags(self.tagstring, self.parent.unit))
end


--------------------------------
--      oUF Registration      --
--------------------------------

-- Store our tables somewhere so people can add custom tags
oUF.Tags, oUF.TagEvents, oUF.UnitlessTagEvents = tags, events, unitlessevents


table.insert(oUF.subTypes, function(self, unit)
	if self.TaggedStrings then
		for i,fs in pairs(self.TaggedStrings) do
			local parent = fs:GetParent()
			local tagstring = fs:GetText()

			local f = CreateFrame("Frame", nil, parent)
			f:SetScript("OnEvent", OnEvent)
			f:SetScript("OnShow", OnShow)
			f.tagstring, f.fontstring, f.parent = tagstring, fs, self

			-- Register any update events we need
			for tag in string.gmatch(tagstring, "[[][%w]+[]]") do
				local tagevents = events[tag]
				if tagevents then
					for event in string.gmatch(tagevents, "%S+") do
						f:RegisterEvent(event)
					end
				end
			end
			if unit == "target" then f:RegisterEvent("PLAYER_TARGET_CHANGED") end
			if unit == "focus" then f:RegisterEvent("PLAYER_FOCUS_CHANGED") end

			OnShow(f)
		end
	end
end)


if true then return end


local tags = {
	["[smartcurhp]"] = function(u) return siVal(UnitHealthMax(u)) end,
	["[smartmaxhp]"] = function(u) return siVal(UnitHealth(u)) end,
	["[smartcurpp]"] = function(u) return siVal(UnitMana(u)) end,
	["[smartmaxpp]"] = function(u) return siVal(UnitManaMax(u)) end,
}

local eventsTable = {
	["[smartcurhp]"] = {"UNIT_HEALTH"},
	["[smartmaxhp]"] = {"UNIT_MAXHEALTH"},
	["[smartcurpp]"] = {"UNIT_ENERGY", "UNIT_FOCUS", "UNIT_MANA", "UNIT_RAGE"},
	["[smartmaxpp]"] = {"UNIT_MAXENERGY", "UNIT_MAXFOCUS", "UNIT_MAXMANA", "UNIT_MAXRAGE"},
}



-- OMG ANCIENT TAGS FROM WATCHDOG
WatchDog_UnitInformation = {
	["statuscolor"] = function (u) if UnitIsDead(u) then return "|cffff0000" elseif UnitIsGhost(u) then return "|cff9d9d9d" elseif (not UnitIsConnected(u)) then return "|cffff8000" elseif (UnitAffectingCombat(u)) then return "|cffFF0000" elseif (u== "player" and IsResting()) then return GetHex(UnitReactionColor[4]) else return "" end end,
	["happycolor"] = function (u) local x=GetPetHappiness() return ( (x==2) and "|cffFFFF00" or (x==1) and "|cffFF0000" or "" ) end,

	["typemp"] = function (u) local p=UnitPowerType(u) return ( (p==1) and "Rage" or (p==2) and "Focus" or (p==3) and "Energy" or "Mana" ) end,
	["combos"] = function (u) return (GetComboPoints() or 0) end,
	["combos2"] = function (u) return string.rep("@", GetComboPoints()) end,
	["rested"] = function (u) return (GetRestState()==1 and "Rested" or "") end,

	["happynum"] = function (u) return (GetPetHappiness() or 0) end,
	["happytext"] = function (u) return ( getglobal("PET_HAPPINESS"..(GetPetHappiness() or 0)) or "" ) end,
	["happyicon"] = function (u) local x=GetPetHappiness() return ( (x==3) and ":)" or (x==2) and ":|" or (x==1) and ":(" or "" ) end,

	["curxp"] = function (u) return (UnitXP(u) or "") end,
	["maxxp"] = function (u) return (UnitXPMax(u) or "") end,
	["percentxp"] = function (u) local x=UnitXPMax(u) if (x>0) then return floor( UnitXP(u)/x*100+0.5) else return 0 end end,
	["missingxp"] = function (u) return (UnitXPMax(u) - UnitXP(u)) end,
	["restedxp"] = function (u) return (GetXPExhaustion() or "") end,

	["tappedbyme"] = function (u) if UnitIsTappedByPlayer("target") then return "*" else return "" end end,
	["istapped"] = function (u) if UnitIsTapped(u) and (not UnitIsTappedByPlayer("target")) then return "*" else return "" end end,
	["pvpranknum"] = function (u) return (UnitPVPRank(u) or "") end,
	["pvprank"] = function (u) if (UnitPVPRank(u) >= 1) then return (GetPVPRankInfo(UnitPVPRank(u), u) or "" ) else return "" end end,
	["fkey"] = function (u) local _,_,fkey = string.find(u, "^party(%d)$") if not fkey then return "" else return "F"..fkey end end,

	["aggro"] = function (u) local reaction = UnitReaction(u, "player"); return UnitPlayerControlled(u) and (UnitCanAttack(u, "player") and UnitCanAttack("player", u) and "|cffFF0000" or UnitCanAttack("player", u) and "|cffffff00" or UnitIsPVP("target") and "|cff00ff00" or "|cFFFFFFFF") or (UnitIsTapped(u) and (not UnitIsTappedByPlayer(u)) and "|cff808080") or ((reaction == 1) and "|cffff0000" or (reaction == 2) and "|cffff0000" or (reaction == 4) and "|cffffff00" or (reaction == 5) and "|cff00ff00") or "|cFFFFFFFF"; end,
	["colormp"] = function (u) local x = ManaBarColor[UnitPowerType(u)] return GetHex(x.r, x.g, x.b) end,
	["inmelee"] = function (u) if PlayerFrame.inCombat then return "|cffFF0000" else return "" end end,
	["incombat"] = function (u) if UnitAffectingCombat(u) then return "|cffFF0000" else return "" end end,
	["lowhpcolor"] = function (u) if wd_perhp <= 20 then return "|cffFF0000" else return "" end end,
	["lowmpcolor"] = function (u) if wd_permp <= 20 then return "|cff0000FF" else return "" end end,
}
