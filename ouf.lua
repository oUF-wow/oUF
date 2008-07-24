local ver = "$Id$"
local print = function(a) ChatFrame1:AddMessage("|cff33ff99oUF:|r "..tostring(a)) end
local error = function(...) print("|cffff0000Error:|r "..string.format(...)) end
local dummy = function() end
local function SetManyAttributes(self, ...)
	for i=1,select("#", ...),2 do
		local att,val = select(i, ...)
		if not att then return end
		self:SetAttribute(att,val)
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
		[0] = {r = 49/255, g = 207/255, b = 37/255}, -- Health
		[1] = {r = .6, g = .6, b = .6} -- Tapped targets
	},
	happiness = {
		[1] = {r = 1, g = 0, b = 0}, -- need.... | unhappy
		[2] = {r = 1 ,g = 1, b = 0}, -- new..... | content
		[3] = {r = 0, g = 1, b = 0}, -- colors.. | happy
	},
}

-- add-on object
local oUF = CreateFrame"Button"
local RegisterEvent = oUF.RegisterEvent
local metatable = {__index = oUF}

local style, cache
local styles, furui = {}, {}
local callback, units, objects = {}, {}, {}

local	_G, select, type, pairs, tostring, math_modf =
		_G, select, type, pairs, tostring, math.modf
local	UnitExists, UnitName =
		UnitExists, UnitName


local subTypes = {}
local subTypesMapping = {
	"UNIT_NAME_UPDATE",
}

-- Events
local OnEvent = function(self, event, ...)
	if(not self:IsShown()) then return end
	self[event](self, event, ...)
end

local OnAttributeChanged = function(self, name, value)
	if(name == "unit" and value) then
		units[value] = self

		if(self.unit and self.unit == value) then
			return
		else
			self.unit = value
			self.id = value:match"^.-(%d+)"
			self:PLAYER_ENTERING_WORLD()
		end
	end
end

-- updating of "invalid" units.
local OnTargetUpdate = function(self, elapsed)
	if(not self.unit) then
		return
	elseif(not self.timer) then
		self.timer = .5
	elseif(self.timer < 0) then
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

	local style = object:GetParent().style or style

	object:SetAttribute("initial-width", style["initial-width"])
	object:SetAttribute("initial-height", style["initial-height"])
	object:SetAttribute("initial-scale", style["initial-scale"])
	style(object, unit)

	if(not InCombatLockdown()) then
		local width, height, scale = style["initial-width"], style["initial-height"], style["initial-scale"]
		if(width) then object:SetWidth(width) end
		if(height) then object:SetHeight(height) end
		if(scale) then object:SetScale(scale) end
	end

	object:SetAttribute("*type1", "target")
	object:SetScript("OnEvent", OnEvent)
	object:SetScript("OnAttributeChanged", OnAttributeChanged)
	object:SetScript("OnShow", object.PLAYER_ENTERING_WORLD)

	object:RegisterEvent"PLAYER_ENTERING_WORLD"

	for _, func in ipairs(subTypes) do
		func(object, unit)
	end

	for _, func in ipairs(callback) do
		func(object)
	end

	-- We could use ClickCastFrames only, but it will probably contain frames that
	-- we don't care about.
	objects[object] = true
	_G.ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[object] = true
end

function oUF:RegisterInitCallback(func)
	table.insert(callback, func)
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

function oUF:Spawn(unit, name, isPet)
	if(not unit) then return error("Bad argument #1 to 'Spawn' (string expected, got %s)", type(unit)) end
	if(not style) then return error("Unable to create frame. No styles have been registered.") end

	local style = styles[style]
	local object
	if(unit == "header") then
		local template
		if(isPet) then
			template = "SecureGroupPetHeaderTemplate"
		else
			-- Yes, I know.
			HandleUnit"party"
			template = "SecureGroupHeaderTemplate"
		end

		local header = CreateFrame("Frame", name, UIParent, template)
		header:SetAttribute("template", "SecureUnitButtonTemplate")
		header.initialConfigFunction = initObject
		header.style = style
		header.SetManyAttributes = SetManyAttributes

		return header
	else
		object = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
		object:SetAttribute("unit", unit)
		object.unit = unit
		object.id = unit:match"^.-(%d+)"

		units[unit] = object
		initObject(object, unit)
		HandleUnit(unit, object)
		RegisterUnitWatch(object)

		if(UnitExists(unit)) then
			object:PLAYER_ENTERING_WORLD()
		end
	end

	return object
end

function oUF:RegisterSubTypeMapping(event)
	for _, map in ipairs(subTypesMapping) do
		if(map == event) then
			return
		end
	end

	table.insert(subTypesMapping, event)
end

--[[
--:PLAYER_ENTERING_WORLD()
--	Notes:
--		- Does a full update of all elements on the object.
--]]
function oUF:PLAYER_ENTERING_WORLD(event)
	local unit = self.unit
	if(not UnitExists(unit)) then return end

	for _, func in ipairs(subTypesMapping) do
		if(self:IsEventRegistered(func)) then
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
table.insert(subTypes, function(self)
	if(self.Name) then
		self:RegisterEvent"UNIT_NAME_UPDATE"
	end
end)

function oUF:UNIT_HAPPINESS(event, unit)
	if(self.unit ~= unit) then return end

	if(self:IsEventRegistered"UNIT_HEALTH") then self:UNIT_HEALTH(event, unit) end
	if(self:IsEventRegistered"UNIT_MANA") then self:UNIT_MANA(event, unit) end
end

oUF.version = ver
oUF.units = units
oUF.objects = objects
oUF.subTypes = subTypes
oUF.subTypesMapping = subTypesMapping
oUF.colors = colors
_G.oUF = oUF
