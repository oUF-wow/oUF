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
	health = {49/255, 207/255, 37/255}, -- Health
	happiness = {
		[1] = {1, 0, 0}, -- need.... | unhappy
		[2] = {1, 1, 0}, -- new..... | content
		[3] = {0, 1, 0}, -- colors.. | happy
	},
	smooth = {
		1, 0, 0,
		1, 1, 0,
		0, 1, 0
	},
	disconnected = {.6, .6, .6},
	tapped = {.6,.6,.6},
	class = {},
	reaction = {},
	power = {},
}

-- We do this because people edit the vars directly, and changing the default
-- globals makes SPICE FLOW!
for eclass, color in pairs(RAID_CLASS_COLORS) do
	colors.class[eclass] = {color.r, color.g, color.b}
end

for eclass, color in ipairs(UnitReactionColor) do
	colors.reaction[eclass] = {color.r, color.g, color.b}
end

if(select(4, GetBuildInfo()) < 3e4) then
	colors.power = {
		[0] = { 48/255, 113/255, 191/255}, -- Mana
		[1] = { 226/255, 45/255, 75/255}, -- Rage
		[2] = { 255/255, 178/255, 0}, -- Focus
		[3] = { 1, 1, 34/255}, -- Energy
		[4] = { 0, 1, 1} -- Happiness
	}
else
	for power, color in pairs(PowerBarColor) do
		if(type(power) == 'string') then
			colors.power[power] = {color.r, color.g, color.b}
		end
	end
end

-- add-on object
local oUF = CreateFrame"Button"
local RegisterEvent = oUF.RegisterEvent
local metatable = {__index = oUF}

local styles, style = {}
local callback, units, objects = {}, {}, {}

local	_G, select, type, tostring, math_modf =
		_G, select, type, tostring, math.modf
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

		-- updating of "invalid" units.
		local OnTargetUpdate
		do
			local timer = 0
			OnTargetUpdate = function(self, elapsed)
				if(not self.unit) then
					return
				elseif(timer >= .5) then
					self:PLAYER_ENTERING_WORLD'OnTargetUpdate'
					timer = 0
				end

				timer = timer + elapsed
			end
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
	local style = object:GetParent().style or styles[style]

	object = setmetatable(object, metatable)
	style(object, unit)

	local mt = type(style) == 'table'
	local height = object:GetAttribute'initial-height' or (mt and style['initial-height'])
	local width = object:GetAttribute'initial-width' or (mt and style['initial-width'])
	local scale = object:GetAttribute'initial-scale' or (mt and style['initial-scale'])

	if(height) then
		object:SetAttribute('initial-height', height)
		if(unit) then object:SetHeight(height) end
	end

	if(width) then
		object:SetAttribute("initial-width", width)
		if(unit) then object:SetWidth(width) end
	end

	if(scale) then
		object:SetAttribute("initial-scale", scale)
		if(unit) then object:SetScale(scale) end
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
	table.insert(objects, object)
	_G.ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[object] = true
end

function oUF:RegisterInitCallback(func)
	table.insert(callback, func)
end

function oUF:RegisterStyle(name, func)
	if(type(name) ~= "string") then return error("Bad argument #1 to 'RegisterStyle' (string expected, got %s)", type(name)) end
	if(type(func) == 'function' or (type(func) == 'table' and type(getmetatable(func).__call))) then
		if(styles[name]) then return error("Style [%s] already registered.", name) end
		if(not style) then style = name end

		styles[name] = func
	else
		error("Bad argument #2 to 'RegisterStyle' (table/function expected, got %s)", type(func))
	end
end

function oUF:SetActiveStyle(name)
	if(type(name) ~= "string") then return error("Bad argument #1 to 'SetActiveStyle' (string expected, got %s)", type(name)) end
	if(not styles[name]) then return error("Style [%s] does not exist.", name) end

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

-- http://www.wowwiki.com/ColorGradient
function oUF.ColorGradient(perc, ...)
	if perc >= 1 then
		local r, g, b = select(select('#', ...) - 2, ...)
		return r, g, b
	elseif perc <= 0 then
		local r, g, b = ...
		return r, g, b
	end

	local num = select('#', ...) / 3

	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

function oUF:PARTY_MEMBERS_CHANGED(event)
	if(self:IsEventRegistered"PARTY_LEADER_CHANGED") then self:PARTY_LEADER_CHANGED() end
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

oUF.version = GetAddOnMetadata('oUF', 'version')
oUF.units = units
oUF.objects = objects
oUF.subTypes = subTypes
oUF.subTypesMapping = subTypesMapping
oUF.colors = colors
_G.oUF = oUF
