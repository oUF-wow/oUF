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

local ver = "$Id$"
local _G = getfenv(0)
local select = select
local type = type
local tostring = tostring

local print = function(a) ChatFrame1:AddMessage("|cff33ff99oUF:|r "..tostring(a)) end
local error = function(...) print("|cffff0000Error:|r ", string.format(...)) end

-- Colors
local colors = {
	power = {
		[0] = { r = 48/255, g = 113/255, b = 191/255}, -- Mana
		[1] = { r = 226/255, g = 45/255, b = 75/255}, -- Rage
		[2] = { r = 255/255, g = 178/255, b = 0}, -- Focus
		[3] = { r = 1, g = 1, b = 34/255}, -- Energy
		[4] = { r = 0, g = 1, b = 1} -- Happiness
	},
	health = {
		[0] = {r = 49/255, g = 207/255, b = 37/255}, -- Health
		[1] = {r = .6, g = .6, b = .6} -- Tapped targets
	},
	happiness = {
		[1] = {r = 1, g = 0, b = 0}, -- need.... | unhappy
		[2] = {r = 1 ,g = 1, b = 0}, -- new..... | content
		[3] = {r = 0, g = 1, b = 0}, -- colors.. | happy
	},
}

-- For debugging
local log = {}

-- add-on object
local oUF = CreateFrame"Button"
local RegisterEvent = oUF.RegisterEvent
local metatable = {__index = oUF}

local style, raid, party, cache
local styles = {}
local furui = {}

local select = select
local type = type
local pairs = pairs
local math_modf = math.modf
local UnitExists = UnitExists
local UnitName = UnitName
local UnitInRange = UnitInRange or CheckInteractDistance

local objects = {}
local subTypes = {
	["Health"] = "UNIT_HEALTH",
	["Power"] = "UNIT_MANA",
	["Name"] = "UNIT_NAME_UPDATE",
	["CPoints"] = "PLAYER_COMBO_POINTS",
	["RaidIcon"] = "RAID_TARGET_UPDATE",
	["Auras"] = "UNIT_AURA",
	["Buffs"] = "UNIT_AURA",
	["Debuffs"] = "UNIT_AURA",
	["Leader"] = "PARTY_LEADER_CHANGED",
	["Combat"] = "PLAYER_REGEN_DISABLED",
	["Resting"] = "PLAYER_UPDATE_RESTING",
	["PvP"] = "UNIT_FACTION",
	["Range"] = true,
}

local dummy = function() end

-- Events
local OnEvent = function(self, event, ...)
	self[event](self, event, ...)
end

local OnAttributeChanged = function(self, name, value)
	if(name == "unit" and value) then
		if(self.unit and self.unit == value) then
			return
		else
			self.unit = value
			self.id = value:match"^.-(%d+)"
			self:PLAYER_ENTERING_WORLD()
		end
	end
end

-- Updates
-- updating of range.
local timer = 0
local OnRangeFrame
local OnRangeUpdate = function(self, elapsed)
	timer = timer + elapsed

	if(timer >= .25) then
		for object, v in pairs(objects) do
			if(object:IsShown() and object.Range) then
				if(UnitIsConnected(object.unit) and not UnitInRange(object.unit, 1)) then
					if(object:GetAlpha() == object.inRangeAlpha) then
						object:SetAlpha(object.outsideRangeAlpha)
					end
				elseif(object:GetAlpha() ~= object.inRangeAlpha) then
					object:SetAlpha(object.inRangeAlpha)
				end
			end
		end

		timer = 0
	end
end

-- updating of "invalid" units.
local OnTargetUpdate = function(self, elapsed)
	if(not self.unit) then
		return
	elseif(not self.timer) then
		self.timer = .5
	elseif(self.timer <= .5) then
		self:PLAYER_ENTERING_WORLD()
		self.timer = .5
	else
		self.timer = self.timer - elapsed
	end
end

-- Gigantic function of doom
local HandleUnit = function(unit, object)
	if(unit == "player") then
		-- Hide the blizzard stuff
		PlayerFrame:UnregisterAllEvents()
		PlayerFrame.Show = dummy
		PlayerFrame:Hide()

		PlayerFrameHealthBar:UnregisterAllEvents()
		PlayerFrameManaBar:UnregisterAllEvents()
	elseif(unit == "pet")then
		-- Hide the blizzard stuff
		PetFrame:UnregisterAllEvents()
		PetFrame.Show = dummy
		PetFrame:Hide()

		PetFrameHealthBar:UnregisterAllEvents()
		PetFrameManaBar:UnregisterAllEvents()

		-- Enable our shit
		-- Temp solution :----D
		object:RegisterEvent"UNIT_HAPPINESS"
	elseif(unit == "target") then
		-- Hide the blizzard stuff
		TargetFrame:UnregisterAllEvents()
		TargetFrame.Show = dummy
		TargetFrame:Hide()

		TargetFrameHealthBar:UnregisterAllEvents()
		TargetFrameManaBar:UnregisterAllEvents()
		TargetFrameSpellBar:UnregisterAllEvents()

		ComboFrame:UnregisterAllEvents()
		ComboFrame.Show = dummy
		ComboFrame:Hide()

		-- Enable our shit
		object:RegisterEvent"PLAYER_TARGET_CHANGED"
	elseif(unit == "focus") then
		object:RegisterEvent"PLAYER_FOCUS_CHANGED"
	elseif(unit == "mouseover") then
		object:RegisterEvent"UPDATE_MOUSEOVER_UNIT"
	elseif(unit:match"target") then
		-- Hide the blizzard stuff
		if(unit == "targettarget") then
			TargetofTargetFrame:UnregisterAllEvents()
			TargetofTargetFrame.Show = dummy
			TargetofTargetFrame:Hide()

			TargetofTargetHealthBar:UnregisterAllEvents()
			TargetofTargetManaBar:UnregisterAllEvents()
		end

		object:SetScript("OnUpdate", OnTargetUpdate)
	elseif(unit == "party") then
		for i=1,4 do
			local party = "PartyMemberFrame"..i
			local frame = _G[party]

			frame:UnregisterAllEvents()
			frame.Show = dummy
			frame:Hide()

			_G[party..'HealthBar']:UnregisterAllEvents()
			_G[party..'ManaBar']:UnregisterAllEvents()
		end
	end
end

local initObject = function(object, unit)
	local style = styles[style]

	object = setmetatable(object, metatable)

	if(object:GetParent() == oUF_Party) then
		object:SetAttribute("initial-width", party["initial-width"])
		object:SetAttribute("initial-height", party["initial-height"])
		object:SetAttribute("initial-scale", party["initial-scale"])
	elseif(object:GetParent():GetName():sub(1, 8) == "oUF_Raid") then
		object:SetAttribute("initial-width", raid["initial-width"])
		object:SetAttribute("initial-height", raid["initial-height"])
		object:SetAttribute("initial-scale", raid["initial-scale"])
	else
		object:SetAttribute("initial-width", style["initial-width"])
		object:SetAttribute("initial-height", style["initial-height"])
		object:SetAttribute("initial-scale", style["initial-scale"])
	end
	object:SetAttribute("*type1", "target")

	object:SetScript("OnEvent", OnEvent)
	object:SetScript("OnAttributeChanged", OnAttributeChanged)
	object:SetScript("OnShow", object.PLAYER_ENTERING_WORLD)

	object:RegisterEvent"PLAYER_ENTERING_WORLD"

	style(object, unit)
	-- We might want to go deeper then the first level of the table, but there is honestly
	-- nothing preventing us from just placing all the interesting vars at the first level
	-- of it.
	for subType, subObject in pairs(object) do
		if(subTypes[subType]) then
			object:RegisterObject(object, subType)
		end
	end

	-- We could use ClickCastFrames only, but it will probably contain frames that
	-- we don't care about.
	objects[object] = true
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[object] = true
end

function oUF:RegisterStyle(name, func)
	if(type(name) ~= "string") then return error("Bad argument #1 to 'RegisterStyle' (string expected, got %s)", type(name)) end
	if(type(func) ~= "table" and type(getmetatable(func).__call) ~= "function") then return error("Bad argument #2 to 'RegisterStyle' (table expected, got %s)", type(func)) end
	if(styles[name]) then return error("Style [%s] already registered.", name) end
	if(not style) then style = name end

	styles[name] = func
end

function oUF:SetActiveStyle(name)
	if(type(name) ~= "string") then return error("Bad argument #1 to 'SetActiveStyle' (string expected, got %s)", type(name)) end
	if(not styles[name]) then return error("Style [%s] does not exist.", name) end

	furui[style] = cache
	cache = furui[name] or {}

	style = name
end

function oUF:Spawn(unit, name, group)
	if(not unit) then return error("Bad argument #1 to 'Spawn' (string expected, got %s)", type(unit)) end
	if(not style) then return error("Unable to create frame. No styles have been registered.") end

	local style = styles[style]
	local object
	if(unit == "party") then
		if(not party) then party = style end

		local header = CreateFrame("Frame", "oUF_Party", UIParent, "SecurePartyHeaderTemplate")
		header:SetAttribute("template", "SecureUnitButtonTemplate")
		header:SetAttribute("templateType", style["party-templateType"])
		header:SetMovable(true)
		header:EnableMouse(true)

		header:SetAttribute("point", style["party-point"])
		header:SetAttribute("sortDir", style["party-sortDir"])
		header:SetAttribute("sortMethod", style["party-sortMethod"])
		header:SetAttribute("xOffset", style["party-xOffset"])
		header:SetAttribute("yOffset", style["party-yOffset"])
		header:SetAttribute("showRaid", style["party-showRaid"])
		header.initialConfigFunction = initObject
		header:Show()

		HandleUnit"party"

		return header
	elseif(unit == "raid") then
		if(not raid) then raid = style end

		local header = CreateFrame("Frame", "oUF_Raid"..(group or 1), UIParent, "SecureRaidGroupHeaderTemplate")
		header:SetAttribute("template", "SecureUnitButtonTemplate")
		header:SetAttribute("templateType", style["raid-templateType"])
		header:SetMovable(true)
		header:EnableMouse(true)

		header:SetAttribute("point", style["raid-point"])
		header:SetAttribute("sortDir", style["raid-sortDir"])
		header:SetAttribute("xOffset", style["raid-xOffset"])
		header:SetAttribute("yOffset", style["raid-yOffset"])
		header:SetAttribute("sortMethod", style["raid-sortMethod"])
		header:SetAttribute("startingIndex ", style["raid-startingIndex "])
		header:SetAttribute("nameList", style["raid-nameList"])
		header:SetAttribute("strictFiltering", style["raid-strictFiltering"])
		header:SetAttribute("groupBy", style["raid-groupBy"])
		header:SetAttribute("groupFilter", style["raid-groupFilter"])
		header:SetAttribute("groupingOrder", style["raid-groupingOrder"])
		header:SetAttribute("maxColumns", style["raid-maxColumns"])
		header:SetAttribute("unitsPerColumn", style["raid-unitsPerColumn"])
		header:SetAttribute("columnSpacing", style["raid-columnSpacing"])
		header:SetAttribute("columnAnchorPoint", style["raid-columnAnchorPoint"])
		header.initialConfigFunction = initObject
		header:Show()

		return header
	else
		object = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
		object:SetAttribute("unit", unit)
		object.unit = unit
		object.id = unit:match"^.-(%d+)"

		initObject(object, unit)
		HandleUnit(unit, object)
		RegisterUnitWatch(object)

		if(UnitExists(unit)) then
			object:PLAYER_ENTERING_WORLD()
		end
	end

	return object
end

function oUF:RegisterFrameObject()
	error":RegisterFrameObject is deprecated"
end

--[[
--:RegisterObject(object, subType)
--	Notes:
--		- Internal function, but externally avaible as someone might want to call it.
--]]
function oUF:RegisterObject(object, subType)
	local unit = object.unit

	-- We could use a table containing this info, but it's just as easy to do it
	-- manually.
	if(subType == "Health") then
		object:RegisterEvent"UNIT_HEALTH"
		object:RegisterEvent"UNIT_MAXHEALTH"
	elseif(subType == "Power") then
		object:RegisterEvent"UNIT_MANA"
		object:RegisterEvent"UNIT_RAGE"
		object:RegisterEvent"UNIT_FOCUS"
		object:RegisterEvent"UNIT_ENERGY"
		object:RegisterEvent"UNIT_MAXMANA"
		object:RegisterEvent"UNIT_MAXRAGE"
		object:RegisterEvent"UNIT_MAXFOCUS"
		object:RegisterEvent"UNIT_MAXENERGY"
		object:RegisterEvent"UNIT_DISPLAYPOWER"
	elseif(subType == "Name") then
		object:RegisterEvent"UNIT_NAME_UPDATE"
	elseif(subType == "CPoints" and unit == "target") then
		object:RegisterEvent"PLAYER_COMBO_POINTS"
	elseif(subType == "RaidIcon") then
		object:RegisterEvent"RAID_TARGET_UPDATE"
	elseif(subType == "Leader") then
		object:RegisterEvent"PARTY_LEADER_CHANGED"
		object:RegisterEvent"PARTY_MEMBERS_CHANGED"
	elseif(subType == "Combat") then
		object:RegisterEvent"PLAYER_REGEN_DISABLED"
		object:RegisterEvent"PLAYER_REGEN_ENABLED"
	elseif(subType == "PvP") then
		object:RegisterEvent"UNIT_FACTION"
	elseif(subType == "Range") then
		if(not OnRangeFrame) then
			OnRangeFrame = CreateFrame"Frame"
			OnRangeFrame:SetScript("OnUpdate", OnRangeUpdate)
		end
	elseif(subType == "Resting" and unit == "player") then
		object:RegisterEvent"PLAYER_UPDATE_RESTING"
	elseif(subType == "Buffs" or subType == "Debuffs" or subType == "Auras") then
		object:RegisterEvent"UNIT_AURA"
	end
end

--[[
--:PLAYER_ENTERING_WORLD()
--	Notes:
--		- Does a full update of all elements on the object.
--]]
function oUF:PLAYER_ENTERING_WORLD(event)
	local unit = self.unit
	if(not UnitExists(unit)) then return end

	for key, func in pairs(subTypes) do
		if(self[key] and type(func) == "string") then
			self[func](self, event, unit)
		end
	end
end

oUF.PLAYER_TARGET_CHANGED = oUF.PLAYER_ENTERING_WORLD
oUF.PLAYER_FOCUS_CHANGED = oUF.PLAYER_ENTERING_WORLD
oUF.UPDATE_MOUSEOVER_UNIT = oUF.PLAYER_ENTERING_WORLD

--[[ My 8-ball tells me we'll need this one later on.
local ColorGradient = function(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then
		return r3, g3, b3
	elseif perc <= 0 then
		return r1, g1, b1
	end

	local segment, relperc = math_modf(perc*(3-1))
	local offset = (segment*3)+1

	if(offset == 1) then
		return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
	end

	return r2 + (r3-r2)*relperc, g2 + (g3-g2)*relperc, b2 + (b3-b2)*relperc
end]]

function oUF:PARTY_MEMBERS_CHANGED(event)
	self:PARTY_LEADER_CHANGED()
end

function oUF:UNIT_NAME_UPDATE(event, unit)
	if(self.unit ~= unit) then return end
	local name = UnitName(unit)

	-- This is really really temporary, at least until someone writes a tag
	-- library that doesn't eat babies and spew poison (or any other common
	-- solution to this problem).
	self.Name:SetText(name)
end

oUF.OnTargetUpdate = OnTargetUpdate
oUF.OnRangeUpdate = OnRangeUpdate

oUF.version = ver
oUF.objects = objects
oUF.subTypes = subTypes
oUF.colors = colors
_G.oUF = oUF
