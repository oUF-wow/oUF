local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')

local _VERSION = GetAddOnMetadata(parent, 'version')

local function argcheck(value, num, ...)
	assert(type(num) == 'number', "Bad argument #2 to 'argcheck' (number expected, got "..type(num)..")")

	for i=1,select("#", ...) do
		if type(value) == select(i, ...) then return end
	end

	local types = strjoin(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s' (%s expected, got %s"):format(num, name, types, type(value)), 3)
end

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
if(IsAddOnLoaded'!ClassColors' and CUSTOM_CLASS_COLORS) then
	local updateColors = function()
		for eclass, color in next, CUSTOM_CLASS_COLORS do
			colors.class[eclass] = {color.r, color.g, color.b}
		end

		if(oUF) then
			for _, obj in next, oUF.objects do
				obj:PLAYER_ENTERING_WORLD()
			end
		end
	end

	updateColors()
	CUSTOM_CLASS_COLORS:RegisterCallback(updateColors)
else
	for eclass, color in next, RAID_CLASS_COLORS do
		colors.class[eclass] = {color.r, color.g, color.b}
	end
end

for power, color in next, PowerBarColor do
	if(type(power) == 'string') then
		colors.power[power] = {color.r, color.g, color.b}
	end
end

for eclass, color in next, FACTION_BAR_COLORS do
	colors.reaction[eclass] = {color.r, color.g, color.b}
end

-- add-on object
local oUF = CreateFrame"Button"
local frame_metatable = {__index = oUF}
local event_metatable = {
	__call = function(funcs, self, ...)
		for _, func in ipairs(funcs) do
			func(self, ...)
		end
	end,
}

local styles, style = {}
local callback, units, objects = {}, {}, {}

local	_G, select, type, tostring, math_modf =
		_G, select, type, tostring, math.modf
local	UnitExists, UnitName =
		UnitExists, UnitName

local conv = {
	['playerpet'] = 'pet',
	['playertarget'] = 'target',
}
local elements = {}

local enableTargetUpdate = function(object)
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
end

-- Events
local OnEvent = function(self, event, ...)
	if(not self:IsShown() and not self.vehicleUnit) then return end
	return self[event](self, event, ...)
end

local OnAttributeChanged = function(self, name, value)
	if(name == "unit" and value) then
		units[value] = self

		if(self.unit and self.unit == value) then
			return
		else
			if(self.hasChildren) then
				for _, object in next, objects do
					local unit = SecureButton_GetModifiedUnit(object)
					object.unit = conv[unit] or unit
					object:PLAYER_ENTERING_WORLD()
				end
			end

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
		object:RegisterEvent("PLAYER_TARGET_CHANGED", 'PLAYER_ENTERING_WORLD')
	elseif(unit == "focus") then
		FocusFrame:UnregisterAllEvents()
		FocusFrame.Show = dummy
		FocusFrame:Hide()

		FocusFrameHealthBar:UnregisterAllEvents()
		FocusFrameManaBar:UnregisterAllEvents()
		FocusFrameSpellBar:UnregisterAllEvents()

		object:RegisterEvent("PLAYER_FOCUS_CHANGED", 'PLAYER_ENTERING_WORLD')
	elseif(unit == "mouseover") then
		object:RegisterEvent("UPDATE_MOUSEOVER_UNIT", 'PLAYER_ENTERING_WORLD')
	elseif(unit:match"target") then
		-- Hide the blizzard stuff
		if(unit == "targettarget") then
			TargetofTargetFrame:UnregisterAllEvents()
			TargetofTargetFrame.Show = dummy
			TargetofTargetFrame:Hide()

			TargetofTargetHealthBar:UnregisterAllEvents()
			TargetofTargetManaBar:UnregisterAllEvents()
		end

		enableTargetUpdate(object)
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

local initObject = function(unit, style, ...)
	local num = select('#', ...)
	for i=1, num do
		local object = select(i, ...)

		object.__elements = {}

		object = setmetatable(object, frame_metatable)
		style(object, unit)

		local mt = type(style) == 'table'
		local height = object:GetAttribute'initial-height' or (mt and style['initial-height'])
		local width = object:GetAttribute'initial-width' or (mt and style['initial-width'])
		local scale = object:GetAttribute'initial-scale' or (mt and style['initial-scale'])
		local suffix = object:GetAttribute'unitsuffix'

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

		if(suffix == 'target') then
			enableTargetUpdate(object)
		end

		if(num > 1 and i == 1) then
			object.hasChildren = true
		end

		object:SetAttribute("*type1", "target")
		object:SetScript("OnEvent", OnEvent)
		object:SetScript("OnAttributeChanged", OnAttributeChanged)
		object:SetScript("OnShow", object.PLAYER_ENTERING_WORLD)

		object:RegisterEvent"PLAYER_ENTERING_WORLD"

		for element in next, elements do
			object:EnableElement(element, unit)
		end

		for _, func in next, callback do
			func(object)
		end

		-- We could use ClickCastFrames only, but it will probably contain frames that
		-- we don't care about.
		table.insert(objects, object)
		_G.ClickCastFrames = ClickCastFrames or {}
		ClickCastFrames[object] = true
	end
end

local walkObject = function(object, unit)
	local style = styles[object:GetParent().style] or styles[style]

	initObject(unit, style, object, object:GetChildren())
end

function oUF:RegisterInitCallback(func)
	table.insert(callback, func)
end

function oUF:RegisterStyle(name, func)
	argcheck(name, 2, 'string')
	argcheck(func, 3, 'function', 'table')

	if(styles[name]) then return error("Style [%s] already registered.", name) end
	if(not style) then style = name end

	styles[name] = func
end

function oUF:SetActiveStyle(name)
	argcheck(name, 2, 'string')
	if(not styles[name]) then return error("Style [%s] does not exist.", name) end

	style = name
end

function oUF:Spawn(unit, name, template, disableBlizz)
	argcheck(unit, 2, 'string')
	if(not style) then return error("Unable to create frame. No styles have been registered.") end

	local object
	if(unit == "header") then
		if(not template) then
			template = "SecureGroupHeaderTemplate"
		end

		HandleUnit(disableBlizz or 'party')

		local header = CreateFrame("Frame", name, UIParent, template)
		header:SetAttribute("template", "SecureUnitButtonTemplate")
		header.initialConfigFunction = walkObject
		header.style = style
		header.SetManyAttributes = SetManyAttributes

		return header
	else
		object = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
		object:SetAttribute("unit", unit)
		object.unit = unit
		object.id = unit:match"^.-(%d+)"

		units[unit] = object
		walkObject(object, unit)
		HandleUnit(unit, object)
		RegisterUnitWatch(object)
	end

	return object
end

local RegisterEvent = oUF.RegisterEvent
function oUF:RegisterEvent(event, func)
	argcheck(event, 2, 'string')

	if(type(func) == 'string' and type(self[func]) == 'function') then
		func = self[func]
	end

	local curev = self[event]
	if(curev and func) then
		if(type(curev) == 'function') then
			self[event] = setmetatable({curev, func}, event_metatable)
		else
			for _, infunc in ipairs(curev) do
				if(infunc == func) then return end
			end

			table.insert(curev, func)
		end
	elseif(self:IsEventRegistered(event)) then
		return
	else
		if(func) then
			self[event] = func
		elseif(not self[event]) then
			return error("Handler for event [%s] on unit [%s] does not exist.", event, self.unit or 'unknown')
		end

		RegisterEvent(self, event)
	end
end

local UnregisterEvent = oUF.UnregisterEvent
function oUF:UnregisterEvent(event, func)
	argcheck(event, 2, 'string')

	local curev = self[event]
	if(type(curev) == 'table' and func) then
		for k, infunc in ipairs(curev) do
			if(infunc == func) then
				curev[k] = nil

				if(#curev == 0) then
					table.remove(curev, k)
					UnregisterEvent(self, event)
				end
			end
		end
	else
		self[event] = nil
		UnregisterEvent(self, event)
	end
end

function oUF:AddElement(name, update, enable, disable)
	argcheck(name, 2, 'string')
	argcheck(update, 3, 'function', 'nil')
	argcheck(enable, 4, 'function', 'nil')
	argcheck(disable, 5, 'function', 'nil')

	if(elements[name]) then return error('Element [%s] is already registered.', name) end
	elements[name] = {
		update = update;
		enable = enable;
		disable = disable;
	}
end

function oUF:EnableElement(name, unit)
	if(self == oUF) then return nil, 'Invalid oUF object.' end

	argcheck(name, 2, 'string')
	argcheck(unit, 3, 'string', 'nil')

	local element = elements[name]
	if(not element) then return end

	if(element.enable(self, unit or self.unit)) then
		table.insert(self.__elements, element.update)
	end
end

function oUF:DisableElement(name)
	if(self == oUF) then return nil, 'Invalid oUF object.' end

	argcheck(name, 2, 'string')
	local element = elements[name]
	if(not element) then return end

	for k, update in ipairs(self.__elements) do
		if(update == element.update) then
			table.remove(self.__elements, k)
			element.disable(self)

			-- We need to run a new update cycle incase we knocked ourself out of sync.
			-- The main reason we do this is to make sure the full update is completed
			-- if an element for some reason removes itself _during_ the update
			-- progress.
			self:PLAYER_ENTERING_WORLD('DisableElement', name)
			break
		end
	end
end

function oUF:UpdateElement(name)
	if(self == oUF) then return nil, 'Invalid oUF object.' end

	argcheck(name, 2, 'string')
	local element = elements[name]
	if(not element) then return end

	element.update(self, 'UpdateElement', self.unit)
end

oUF.Enable = RegisterUnitWatch
function oUF:Disable()
	UnregisterUnitWatch(self)
	self:Hide()
end

--[[
--:PLAYER_ENTERING_WORLD()
--	Notes:
--		- Does a full update of all elements on the object.
--]]
function oUF:PLAYER_ENTERING_WORLD(event)
	local unit = self.unit
	if(not UnitExists(unit)) then return end

	for _, func in next, self.__elements do
		func(self, event, unit)
	end
end

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

oUF.version = _VERSION
oUF.units = units
oUF.objects = objects
oUF.colors = colors
_G[global] = oUF
