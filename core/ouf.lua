--[[-------------------------------------------------------------------------
  Copyright (c) 2006-2007, Trond A Ekseth
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

local _G = getfenv(0)
local select = select
local type = type
local tostring = tostring

local argstostring = function(v, ...) if select('#', ...) == 0 then return v end return v..tostring(...) end
local print = function(...) ChatFrame1:AddMessage("|cff33ff99oUF:|r "..argstostring(...)) end
local error = function(...) print("|cffff0000Error:|r ", string.format(...)) end

local objects = {}
local subTypes = {
	["Health"] = true,
	["Power"] = true,
	["Name"] = true,
	["CPoints"] = true,
	["RaidIcon"] = true,
}

-- Events
local events = {}
local OnEvent = function(self, event, ...)
	local func = self.events[event]

	if(type(func) == "string") then
		self[func](self, event, ...)
	elseif(type(func) == "function") then
		func(self, event, unit, ...)
	end
end

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
		[0] = {r = 49/255, g1 = 207/255, b1 = 37/255}, -- Health
	},
	happiness = {
		[1] = {r = 1, g = 0, b = 0}, -- need | unhappy
		[2] = {r = 1 ,g = 1, b = 0}, -- new | content
		[3] = {r = 0, g = 1, b = 0}, -- colors | happy
	},
}

-- For debugging
local log = {}

-- add-on object
local oUF = CreateFrame"Button"
local RegisterEvent = oUF.RegisterEvent
local metatable = {__index = oUF}

--[[
--:RegisterEvent(event, func)
--	Notes:
--		- Internal function, but externally avaible as someone might want to call it.
--]]
function oUF:RegisterEvent(event, func)
	if(not self.events[event]) then
		self.events[event] = func or event
		RegisterEvent(self, event)
	end
end

--[[
--:RegisterFrameObject(object)
--	Arguments:
--		- object: WoW frame table
--	Returns:
--		- oUF frame object
--]]
function oUF:RegisterFrameObject(object)
	if(type(object) ~= "table") then return end
	if(type(object.unit) ~= "string") then return end
	if(objects[unit]) then return error("Unit '%s' is already registered.", unit) end

	local unit = object.unit

	object = setmetatable(object, metatable)
	object.events = {}
	object:SetScript("OnEvent", OnEvent)
	table.insert(log, string.format("[%s]: Parsing frame table.", unit))

	-- We might want to go deeper then the first level of the table, but there is honestly
	-- nothing preventing us from just placing all the interesting vars at the first level
	-- of it.
	for subType, subObject in pairs(object) do
		if(subTypes[subType]) then
			table.insert(log, string.format("[%s] Valid key '%s' found.", unit, subType))

			self:RegisterObject(object, subType)
		end
	end

	objects[unit] = object

	return object
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
		object:RegisterEvent("UNIT_HEALTH", "UpdateHealth")
		object:RegisterEvent("UNIT_MAXHEALTH", "UpdateHealth")
	elseif(subType == "Power") then
		object:RegisterEvent("UNIT_MANA", "UpdatePower")
		object:RegisterEvent("UNIT_RAGE", "UpdatePower")
		object:RegisterEvent("UNIT_FOCUS", "UpdatePower")
		object:RegisterEvent("UNIT_ENERGY", "UpdatePower")
		object:RegisterEvent("UNIT_MAXMANA", "UpdatePower")
		object:RegisterEvent("UNIT_MAXRAGE", "UpdatePower")
		object:RegisterEvent("UNIT_MAXFOCUS", "UpdatePower")
		object:RegisterEvent("UNIT_MAXENERGY", "UpdatePower")
		object:RegisterEvent("UNIT_DISPLAYPOWER", "UpdatePower")
	elseif(subType == "Name") then
		object:RegisterEvent("UNIT_NAME_UPDATE", "UpdateName")
	elseif(subType == "CPoints" and unit == "target") then
		object:RegisterEvent("PLAYER_COMBO_POINTS", "UpdateCPoints")
	elseif(subType == "RaidIcon") then
		object:RegisterEvent("RAID_TARGET_UPDATE", "UpdateRaidIcon")
	else
		error("Typo? - '%s' is not a valid subType.", subType)
	end
end

--[[ Health - Updating ]]

local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

-- My 8-ball tells me we'll need this one later on.
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
end

local min, max, bar, func, color
--[[
--:UpdateHealth(event, unit)
--	Notes:
--		- Internal function, but externally avaible as someone might want to call it.
--		- It will call .func if it's defined.
--]]
function oUF:UpdateHealth(event, unit)
	if(self.unit ~= unit) then return end

	min, max = UnitHealth(unit), UnitHealthMax(unit)
	bar = self.Health

	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	color = colors.health[0]
	bar:SetStatusBarColor(color.r, color.g, color.b)

	if(bar.bg) then
		bar.bg:SetVertexColor(color.r*.5, color.g*.5, color.b*.5)
	end

	func = bar.func
	if(type(func) == "function") then func(bar, unit, min, max) end
end

--[[ Power - Updating ]]

local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType

local min, max, bar, color, func
--[[
--:UpdatePower(event, unit)
--	Notes:
--		- Internal function, but externally avaible as someone might want to call it.
--		- It will call .func if it's defined.
--]]
function oUF:UpdatePower(event, unit)
	if(self.unit ~= unit) then return end

	min, max = UnitMana(unit), UnitManaMax(unit)
	bar = self.Power

	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	color = colors.power[UnitPowerType(unit)]
	bar:SetStatusBarColor(color.r, color.g, color.b)
	
	if(bar.bg) then
		bar.bg:SetVertexColor(color.r*.5, color.g*.5, color.b*.5)
	end

	func = bar.func
	if(type(func) == "function") then func(bar, unit, min, max) end
end

--[[ Name ]]

local UnitName = UnitName

function oUF:UpdateName(event, unit)
	local name = UnitName(unit)

	-- This is really really temporary, at least until someone writes a tag
	-- library that doesn't eat babies and spew poison (or any other common
	-- solution to this problem).
	self.Name:SetText(name)
end

--[[ CPoints ]]

local MAX_COMBO_POINTS
local GetComboPoints = GetComboPoints

function oUF:UpdateCPoints()
	local cp = GetComboPoints()
	local cpoints = self.CPoints

	if(#cpoints == 0) then
		cpoints:SetText(cp)
	else
		for i=1, MAX_COMBO_POINTS do
			if(i <= cp) then
				cpoints[i]:Show()
			else
				cpoints[i]:Hide()
			end
		end
	end
end

--[[ RaidIcon ]]

local GetRaidTargetIndex = GetRaidTargetIndex

function oUF:UpdateRaidIcon()
	local index = GetRaidTargetIndex(self.unit)
	local icon = self.RaidIcon

	if(index) then
		SetRaidTargetIconTexture(icon, index)
		self.RaidIcon:Show()
	else
		self.RaidIcon:Hide()
	end
end

oUF.log = log
_G.oUF = oUF
