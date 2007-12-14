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

local function _tostring(v, ...) if select('#', ...) == 0 then return tostring(v) end return tostring(v).." ".._tostring(...) end
local print = function(...) ChatFrame1:AddMessage("|cff33ff99oUF:|r ".._tostring(...)) end
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

local style, cache
local styles = {}
local furui = {}

local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType
local UnitName = UnitName
local GetComboPoints = GetComboPoints
local GetRaidTargetIndex = GetRaidTargetIndex
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff

local min, max, bar, color, func
local r, g, b
local MAX_COMBO_POINTS
local blimit, dlimit, row, button, r, icons
local nb, nd, buff, debuff
local name, rank, texture, count, color, dtype

local objects = {}
local subTypes = {
	["Health"] = "UpdateHealth",
	["Power"] = "UpdatePower",
	["Name"] = "UpdateName",
	["CPoints"] = "UpdateCPoints",
	["RaidIcon"] = "UpdateRaidIcon",
	["Aura"] = "UpdateAura",
}

local settings = {
	["showBuffs"] = true,
	["showDebuffs"] = true,
	["buffLimit"] = 16,
	["debuffLimit"] = 18,
	["numBuffs"] = 32,
	["numDebuffs"] = 40,
}

local dummy = function() end

-- Events
local events = {}
local OnEvent = function(self, event, ...)
	local func = self.events[event]

	if(type(func) == "string") then
		self[func](self, ...)
	elseif(type(func) == "function") then
		func(self, ...)
	end
end

-- Updates
local time = 0
local OnUpdate = function(self, a1)
	time = time + a1
	
	if(time > .5) then
		self:UpdateAll()
		time = 0
	end
end

-- Gigantic function of doom
local RegisterUnitEvents = function(object)
	local unit = object.unit

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
		object:RegisterEvent("UNIT_HAPPINESS", "UpdateHealth")
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
		object:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateAll")
	elseif(unit == "targettarget") then
		-- Hide the blizzard stuff
		TargetofTargetFrame:UnregisterAllEvents()
		TargetofTargetFrame.Show = dummy
		TargetofTargetFrame:Hide()

		TargetofTargetHealthBar:UnregisterAllEvents()
		TargetofTargetManaBar:UnregisterAllEvents()

		object:SetScript("OnUpdate", OnUpdate)
	end

	object:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAll")
end

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

function oUF:RegisterStyle(name, func)
	if(type(name) ~= "string") then return error("Bad argument #1 to 'RegisterStyle' (string expected, got %s)", type(name)) end
	if(type(func) ~= "function") then return error("Bad argument #2 to 'RegisterStyle' (function expected, got %s)", type(func)) end
	if(styles[name]) then return error("Style [%s] already registered.", name) end
	if(not style) then style = name end

	styles[name] = style
end

function oUF:SetActiveStyle(name)
	if(type(name) ~= "string") then return error("Bad argument #1 to 'SetActiveStyle' (string expected, got %s)", type(name)) end
	if(not styles[name]) then return error("Style [%s] does not exist.", name) end

	furui[style] = cache
	cache = furui[name] or {}

	style = name
end

function oUF:Spawn(name, unit, template)
	if(not unit) then return error("Bad argument #2 to 'Spawn' (string expected, got %s)", type(unit)) end
	if(not style) then return error("Unable to create frame. No styles have been registered.") end

	if(unit:sub(1,8) == "partypet") then
		template = "SecurePartyPetHeaderTemplate, "..template
	elseif(unit:sub(1,5) == "party") then
		template = "SecurePartyHeaderTemplate, "..template
	elseif(unit:sub(1,4) == "raid") then
		template = "SecureRaidGroupHeaderTemplate, "..template
	else
		template = "SecureUnitButtonTemplate, "..template
	end

	local object = setmetatable(styles[style](CreateFrame("Button", name, UIParent, template)), metatable)
	object.events = {}
	object:SetScript("OnEvent", OnEvent)
	object:SetScript("OnShow", self.UpdateAll)
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

	RegisterUnitEvents(object)
	RegisterUnitWatch(object)

	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[object] = true

	if(UnitExists(unit)) then
		object:UpdateAll()
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
	elseif(subType == "Aura") then
		object:RegisterEvent("UNIT_AURA", "UpdateAura")
	end
end


--[[
--:UpdateAll()
--	Notes:
--		- Does a full update of all elements on the object.
--]]
function oUF:UpdateAll()
	local unit = self.unit
	if(not UnitExists(unit)) then return end

	for key, func in pairs(subTypes) do
		if(self[key]) then
			self[func](self, unit)
		end
	end
end

--[[ Health - Updating ]]

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

--[[
--:UpdateHealth(event, unit)
--	Notes:
--		- Internal function, but externally avaible as someone might want to call it.
--		- It will call .func if it's defined.
--]]
function oUF:UpdateHealth(unit)
	if(self.unit ~= unit) then return end

	min, max = UnitHealth(unit), UnitHealthMax(unit)
	bar = self.Health

	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	-- Discuss...
	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		color = colors.health[1]
	elseif(unit == "pet" and GetPetHappiness()) then
		color = colors.happiness[GetPetHappiness()]
	else
		color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or UnitReactionColor[UnitReaction(unit, "player")]
	end

	if(color) then
		bar:SetStatusBarColor(color.r, color.g, color.b)

		if(bar.bg) then
			bar.bg:SetVertexColor(color.r*.5, color.g*.5, color.b*.5)
		end
	end

	func = bar.func
	if(type(func) == "function") then func(bar, unit, min, max) end
end

--[[ Power - Updating ]]

--[[
--:UpdatePower(event, unit)
--	Notes:
--		- Internal function, but externally avaible as someone might want to call it.
--		- It will call .func if it's defined.
--]]
function oUF:UpdatePower(unit)
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

function oUF:UpdateName(unit)
	if(self.unit ~= unit) then return end
	local name = UnitName(unit)

	-- This is really really temporary, at least until someone writes a tag
	-- library that doesn't eat babies and spew poison (or any other common
	-- solution to this problem).
	self.Name:SetText(name)
end

--[[ CPoints ]]

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

function oUF:UpdateRaidIcon()
	local index = GetRaidTargetIndex(self.unit)
	local icon = self.RaidIcon

	if(index) then
		SetRaidTargetIconTexture(icon, index)
		icon:Show()
	else
		icon:Hide()
	end
end

--[[ Aura ]]

local buffOnEnter = function(self)
	if(not self:IsVisible()) then return end
	local unit = self:GetParent().unit

	GameTooltip:SetOwner(self, "ANHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitBuff(unit, self:GetID())
end
local debuffOnEnter = function(self)
	if(not self:IsVisible()) then return end
	local unit = self:GetParent().unit

	GameTooltip:SetOwner(self, "ANHOR_BOTTOMRIGHT")

	GameTooltip:SetUnitDebuff(unit, self:GetID())
end
local onLeave = function() GameTooltip:Hide() end

local createBuff = function(self, index)
	local buff = CreateFrame("Frame", nil, self)
	buff:EnableMouse(true)
	buff:SetID(index)

	buff:SetWidth(14)
	buff:SetHeight(14)

	local icon = buff:CreateTexture(nil, "BACKGROUND")
	icon:SetAllPoints(buff)

	local count = buff:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(NumberFontNormal)
	count:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", -1, 0)

	buff:SetScript("OnEnter", buffOnEnter)
	buff:SetScript("OnLeave", onLeave)

	table.insert(self.Buffs, buff)

	buff.icon = icon
	buff.count = count

	return buff
end

local createDebuff = function(self, index)
	local debuff = CreateFrame("Frame", nil, self)
	debuff:EnableMouse(true)
	debuff:SetID(index)

	debuff:SetWidth(14)
	debuff:SetHeight(14)

	local icon = debuff:CreateTexture(nil, "BACKGROUND")
	icon:SetAllPoints(debuff)

	local count = debuff:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(NumberFontNormal)
	count:SetPoint("BOTTOMRIGHT", debuff, "BOTTOMRIGHT", -1, 0)

	local overlay = debuff:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture"Interface\\Buttons\\UI-Debuff-Overlays"
	overlay:SetAllPoints(debuff)
	overlay:SetTexCoord(.296875, .5703125, 0, .515625)

	debuff:SetScript("OnEnter", debuffOnEnter)
	debuff:SetScript("OnLeave", onLeave)

	table.insert(self.Debuffs, debuff)

	debuff.icon = icon
	debuff.count = count
	debuff.overlay = overlay

	return debuff
end

-- TODO: Rewrite to use the width of the parent.
function oUF:SetAuraPosition(unit, nb, nd)
	blimit = settings.buffLimit
	dlimit = settings.debuffLimit
	row = 1

	icons = self.Buffs
	for i=1, nb do
		button = icons[i]
		if(i == 1) then
			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
		else
			button:ClearAllPoints()
			button:SetPoint("LEFT", icons[i-1], "RIGHT", 0, 0)

			r = math.fmod(i - 1, blimit)
			if(r == 0) then
				button:ClearAllPoints()
				button:SetPoint("BOTTOMLEFT", icons[row], "TOPLEFT", 0, 2)
				row = i
			end
		end
	end

	icons = self.Debuffs
	for i=1, nd do
		button = icons[i]
		if(i == 1) then
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, -2)
		else
			button:ClearAllPoints()
			button:SetPoint("LEFT", icons[i-1], "RIGHT", 0, 0)

			r = math.fmod(i - 1, dlimit)
			if(r == 0) then
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", icons[row], "BOTTOMLEFT", 0, -2)
				row = i
			end
		end
	end
end

function oUF:UpdateAura(unit)
	if(self.unit ~= unit) then return end

	nb = 0
	if(settings.showBuffs) then
		if(not self.Buffs) then self.Buffs = {} end

		icons = self.Buffs
		for i=1,settings.numBuffs do
			buff = icons[i]
			name, rank, texture, count = UnitBuff(unit, i)

			if(not buff and not name) then
				break
			elseif(name) then
				if(not buff) then buff = createBuff(self, i) end
				buff:Show()
				buff.icon:SetTexture(texture)
				buff.count:SetText((count > 1 and count) or nil)

				nb = nb + 1
			elseif(buff) then
				buff:Hide()
			end
		end
	end

	nd = 0
	if(settings.showDebuffs) then
		if(not self.Debuffs) then self.Debuffs = {} end

		icons = self.Debuffs
		for i=1,settings.numDebuffs do
			debuff = icons[i]
			name, rank, texture, count, dtype, color = UnitDebuff(unit, i)

			if(not debuff and not name) then
				break
			elseif(name) then
				if(not debuff) then debuff = createDebuff(self, i) end
				debuff:Show()
				debuff.icon:SetTexture(texture)

				color = DebuffTypeColor[dtype or "none"]
				debuff.overlay:SetVertexColor(color.r, color.g, color.b)
				debuff.count:SetText((count > 1 and count) or nil)

				nd = nd + 1
			elseif(debuff) then
				debuff:Hide()
			end
		end
	end

	self:SetAuraPosition(unit, nb, nd)
end

oUF.settings = settings
oUF.log = log
_G.oUF = oUF
