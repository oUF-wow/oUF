--[[-------------------------------------------------------------------------
  Copyright (c) 2006-2007, Dongle Development Team
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
      * Neither the name of the Dongle Development Team nor the names of
        its contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.

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
local major = "DongleStub"
local minor = tonumber(string.match("$Revision: 314 $", "(%d+)") or 1)

local g = getfenv(0)

if not g.DongleStub or g.DongleStub:IsNewerVersion(major, minor) then
	local lib = setmetatable({}, {
		__call = function(t,k) 
			if type(t.versions) == "table" and t.versions[k] then 
				return t.versions[k].instance
			else
				error("Cannot find a library with name '"..tostring(k).."'", 2)
			end
		end
	})

	function lib:IsNewerVersion(major, minor)
		local versionData = self.versions and self.versions[major]

		-- If DongleStub versions have differing major version names
		-- such as DongleStub-Beta0 and DongleStub-1.0-RC2 then a second
		-- instance will be loaded, with older logic.  This code attempts
		-- to compensate for that by matching the major version against
		-- "^DongleStub", and handling the version check correctly.

		if major:match("^DongleStub") then
			local oldmajor,oldminor = self:GetVersion()
			if self.versions and self.versions[oldmajor] then
				return minor > oldminor
			else
				return true
			end
		end

		if not versionData then return true end
		local oldmajor,oldminor = versionData.instance:GetVersion()
		return minor > oldminor
	end
	
	local function NilCopyTable(src, dest)
		for k,v in pairs(dest) do dest[k] = nil end
		for k,v in pairs(src) do dest[k] = v end
	end

	function lib:Register(newInstance, activate, deactivate)
		assert(type(newInstance.GetVersion) == "function",
			"Attempt to register a library with DongleStub that does not have a 'GetVersion' method.")

		local major,minor = newInstance:GetVersion()
		assert(type(major) == "string",
			"Attempt to register a library with DongleStub that does not have a proper major version.")
		assert(type(minor) == "number",
			"Attempt to register a library with DongleStub that does not have a proper minor version.")

		-- Generate a log of all library registrations
		if not self.log then self.log = {} end
		table.insert(self.log, string.format("Register: %s, %s", major, minor))

		if not self:IsNewerVersion(major, minor) then return false end
		if not self.versions then self.versions = {} end

		local versionData = self.versions[major]
		if not versionData then
			-- New major version
			versionData = {
				["instance"] = newInstance,
				["deactivate"] = deactivate,
			}
			
			self.versions[major] = versionData
			if type(activate) == "function" then
				table.insert(self.log, string.format("Activate: %s, %s", major, minor))
				activate(newInstance)
			end
			return newInstance
		end
		
		local oldDeactivate = versionData.deactivate
		local oldInstance = versionData.instance
		
		versionData.deactivate = deactivate
		
		local skipCopy
		if type(activate) == "function" then
			table.insert(self.log, string.format("Activate: %s, %s", major, minor))
			skipCopy = activate(newInstance, oldInstance)
		end

		-- Deactivate the old libary if necessary
		if type(oldDeactivate) == "function" then
			local major, minor = oldInstance:GetVersion()
			table.insert(self.log, string.format("Deactivate: %s, %s", major, minor))
			oldDeactivate(oldInstance, newInstance)
		end

		-- Re-use the old table, and discard the new one
		if not skipCopy then
			NilCopyTable(newInstance, oldInstance)
		end
		return oldInstance
	end

	function lib:GetVersion() return major,minor end

	local function Activate(new, old)
		-- This code ensures that we'll move the versions table even
		-- if the major version names are different, in the case of 
		-- DongleStub
		if not old then old = g.DongleStub end

		if old then
			new.versions = old.versions
			new.log = old.log
		end
		g.DongleStub = new
	end
	
	-- Actually trigger libary activation here
	local stub = g.DongleStub or lib
	lib = stub:Register(lib, Activate)
end

--[[-------------------------------------------------------------------------
  Begin Library Implementation
---------------------------------------------------------------------------]]

local major = "Dongle-1.0"
local minor = tonumber(string.match("$Revision: 522 $", "(%d+)") or 1)

assert(DongleStub, string.format("Dongle requires DongleStub.", major))

if not DongleStub:IsNewerVersion(major, minor) then return end

local Dongle = {}
local methods = {
	"RegisterEvent", "UnregisterEvent", "UnregisterAllEvents", "IsEventRegistered",
	"RegisterMessage", "UnregisterMessage", "UnregisterAllMessages", "TriggerMessage", "IsMessageRegistered",
	"EnableDebug", "IsDebugEnabled", "Print", "PrintF", "Debug", "DebugF", "Echo", "EchoF",
	"InitializeDB",
	"InitializeSlashCommand",
	"NewModule", "HasModule", "IterateModules",
}

local registry = {}
local lookup = {}
local loadqueue = {}
local loadorder = {}
local events = {}
local databases = {}
local commands = {}
local messages = {}

local frame

--[[-------------------------------------------------------------------------
  Message Localization
---------------------------------------------------------------------------]]

local L = {
	["ADDMESSAGE_REQUIRED"] = "The frame you specify must have an 'AddMessage' method.",
	["ALREADY_REGISTERED"] = "A Dongle with the name '%s' is already registered.",
	["BAD_ARGUMENT"] = "bad argument #%d to '%s' (%s expected, got %s)",
	["BAD_ARGUMENT_DB"] = "bad argument #%d to '%s' (DongleDB expected)",
	["CANNOT_DELETE_ACTIVE_PROFILE"] = "You cannot delete your active profile.  Change profiles, then attempt to delete.",
	["DELETE_NONEXISTANT_PROFILE"] = "You cannot delete a non-existant profile.",
	["MUST_CALLFROM_DBOBJECT"] = "You must call '%s' from a Dongle database object.",
	["MUST_CALLFROM_REGISTERED"] = "You must call '%s' from a registered Dongle.",
	["MUST_CALLFROM_SLASH"] = "You must call '%s' from a Dongle slash command object.",
	["PROFILE_DOES_NOT_EXIST"] = "Profile '%s' doesn't exist.",
	["REPLACE_DEFAULTS"] = "You are attempting to register defaults with a database that already contains defaults.",
	["SAME_SOURCE_DEST"] = "Source/Destination profile cannot be the same profile.",
	["EVENT_REGISTER_SPECIAL"] = "You cannot register for the '%s' event.  Use the '%s' method instead.",
	["Unknown"] = "Unknown",
	["INJECTDB_USAGE"] = "Usage: DongleCmd:InjectDBCommands(db, ['copy', 'delete', 'list', 'reset', 'set'])",
	["DBSLASH_PROFILE_COPY_DESC"] = "profile copy <name> - Copies profile <name> into your current profile.",
	["DBSLASH_PROFILE_COPY_PATTERN"] = "^profile copy (.+)$",
	["DBSLASH_PROFILE_DELETE_DESC"] = "profile delete <name> - Deletes the profile <name>.",
	["DBSLASH_PROFILE_DELETE_PATTERN"] = "^profile delete (.+)$",
	["DBSLASH_PROFILE_LIST_DESC"] = "profile list - Lists all valid profiles.",
	["DBSLASH_PROFILE_LIST_PATTERN"] = "^profile list$",
	["DBSLASH_PROFILE_RESET_DESC"] = "profile reset - Resets the current profile.",
	["DBSLASH_PROFILE_RESET_PATTERN"] = "^profile reset$",
	["DBSLASH_PROFILE_SET_DESC"] = "profile set <name> - Sets the current profile to <name>.",
	["DBSLASH_PROFILE_SET_PATTERN"] = "^profile set (.+)$",
	["DBSLASH_PROFILE_LIST_OUT"] = "Profile List:",
}

--[[-------------------------------------------------------------------------
  Utility functions for Dongle use
---------------------------------------------------------------------------]]

local function assert(level,condition,message)
	if not condition then
		error(message,level)
	end
end

local function argcheck(value, num, ...)
	if type(num) ~= "number" then
		error(L["BAD_ARGUMENT"]:format(2, "argcheck", "number", type(num)), 1)
	end

	for i=1,select("#", ...) do
		if type(value) == select(i, ...) then return end
	end

	local types = strjoin(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(L["BAD_ARGUMENT"]:format(num, name, types, type(value)), 3)
end

local function safecall(func,...)
	local success,err = pcall(func,...)
	if not success then
		geterrorhandler()(err)
	end
end

--[[-------------------------------------------------------------------------
  Dongle constructor, and DongleModule system
---------------------------------------------------------------------------]]

function Dongle:New(name, obj)
	argcheck(name, 2, "string")
	argcheck(obj, 3, "table", "nil")

	if not obj then
		obj = {}
	end

	if registry[name] then
		error(string.format(L["ALREADY_REGISTERED"], name))
	end

	local reg = {["obj"] = obj, ["name"] = name}

	registry[name] = reg
	lookup[obj] = reg
	lookup[name] = reg

	for k,v in pairs(methods) do
		obj[v] = self[v]
	end

	-- Add this Dongle to the end of the queue
	table.insert(loadqueue, obj)
	return obj,name
end

function Dongle:NewModule(name, obj)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "NewModule"))
	argcheck(name, 2, "string")
	argcheck(obj, 3, "table", "nil")

	obj,name = Dongle:New(name, obj)

	if not reg.modules then reg.modules = {} end
	reg.modules[obj] = obj
	reg.modules[name] = obj

	return obj,name
end

function Dongle:HasModule(module)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "HasModule"))
	argcheck(module, 2, "string", "table")

	return reg.modules and reg.modules[module]
end

local function ModuleIterator(t, name)
	if not t then return end
	local obj
	repeat
		name,obj = next(t, name)
	until type(name) == "string" or not name

	return name,obj
end

function Dongle:IterateModules()
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "IterateModules"))

	return ModuleIterator, reg.modules
end

--[[-------------------------------------------------------------------------
  Event registration system
---------------------------------------------------------------------------]]

local function OnEvent(frame, event, ...)
	local eventTbl = events[event]
	if eventTbl then
		for obj,func in pairs(eventTbl) do
			if type(func) == "string" then
				if type(obj[func]) == "function" then
					safecall(obj[func], obj, event, ...)
				end
			else
				safecall(func, event, ...)
			end
		end
	end
end

local specialEvents = {
	["PLAYER_LOGIN"] = "Enable",
	["PLAYER_LOGOUT"] = "Disable",
}

function Dongle:RegisterEvent(event, func)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "RegisterEvent"))
	argcheck(event, 2, "string")
	argcheck(func, 3, "string", "function", "nil")

	local special = (self ~= Dongle) and specialEvents[event]
	if special then
		error(string.format(L["EVENT_REGISTER_SPECIAL"], event, special), 3)
	end

	-- Name the method the same as the event if necessary
	if not func then func = event end

	if not events[event] then
		events[event] = {}
		frame:RegisterEvent(event)
	end
	events[event][self] = func
end

function Dongle:UnregisterEvent(event)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "UnregisterEvent"))
	argcheck(event, 2, "string")

	local tbl = events[event]
	if tbl then
		tbl[self] = nil
		if not next(tbl) then
			events[event] = nil
			frame:UnregisterEvent(event)
		end
	end
end

function Dongle:UnregisterAllEvents()
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "UnregisterAllEvents"))

	for event,tbl in pairs(events) do
		tbl[self] = nil
		if not next(tbl) then
			events[event] = nil
			frame:UnregisterEvent(event)
		end
	end
end

function Dongle:IsEventRegistered(event)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "IsEventRegistered"))
	argcheck(event, 2, "string")

	local tbl = events[event]
	return tbl
end

--[[-------------------------------------------------------------------------
  Inter-Addon Messaging System
---------------------------------------------------------------------------]]

function Dongle:RegisterMessage(msg, func)
	argcheck(self, 1, "table")
	argcheck(msg, 2, "string")
	argcheck(func, 3, "string", "function", "nil")

	-- Name the method the same as the message if necessary
	if not func then func = msg end

	if not messages[msg] then
		messages[msg] = {}
	end
	messages[msg][self] = func
end

function Dongle:UnregisterMessage(msg)
	argcheck(self, 1, "table")
	argcheck(msg, 2, "string")

	local tbl = messages[msg]
	if tbl then
		tbl[self] = nil
		if not next(tbl) then
			messages[msg] = nil
		end
	end
end

function Dongle:UnregisterAllMessages()
	argcheck(self, 1, "table")

	for msg,tbl in pairs(messages) do
		tbl[self] = nil
		if not next(tbl) then
			messages[msg] = nil
		end
	end
end

function Dongle:TriggerMessage(msg, ...)
	argcheck(self, 1, "table")
	argcheck(msg, 2, "string")
	local msgTbl = messages[msg]
	if not msgTbl then return end

	for obj,func in pairs(msgTbl) do
		if type(func) == "string" then
			if type(obj[func]) == "function" then
				safecall(obj[func], obj, msg, ...)
			end
		else
			safecall(func, msg, ...)
		end
	end
end

function Dongle:IsMessageRegistered(msg)
	argcheck(self, 1, "table")
	argcheck(msg, 2, "string")

	local tbl = messages[msg]
	return tbl[self]
end

--[[-------------------------------------------------------------------------
  Debug and Print utility functions
---------------------------------------------------------------------------]]

function Dongle:EnableDebug(level, frame)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "EnableDebug"))
	argcheck(level, 2, "number", "nil")
	argcheck(frame, 3, "table", "nil")

	assert(3, type(frame) == "nil" or type(frame.AddMessage) == "function", L["ADDMESSAGE_REQUIRED"])
	reg.debugFrame = frame or ChatFrame1
	reg.debugLevel = level
end

function Dongle:IsDebugEnabled()
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "EnableDebug"))

	return reg.debugLevel, reg.debugFrame
end

local function argsToStrings(a1, ...)
	if select("#", ...) > 0 then
		return tostring(a1), argsToStrings(...)
	else
		return tostring(a1)
	end
end

local function printHelp(obj, method, header, frame, msg, ...)
	local reg = lookup[obj]
	assert(4, reg, string.format(L["MUST_CALLFROM_REGISTERED"], method))

	local name = reg.name

	if header then
		msg = "|cFF33FF99"..name.."|r: "..tostring(msg)
	end

	if select("#", ...) > 0 then
		msg = string.join(", ", msg, argsToStrings(...))
	end

	frame:AddMessage(msg)
end

local function printFHelp(obj, method, header, frame, msg, ...)
	local reg = lookup[obj]
	assert(4, reg, string.format(L["MUST_CALLFROM_REGISTERED"], method))

	local name = reg.name
	local success,txt

	if header then
		msg = "|cFF33FF99%s|r: " .. msg
		success,txt = pcall(string.format, msg, name, ...)
	else
		success,txt = pcall(string.format, msg, ...)
	end

	if success then
		frame:AddMessage(txt)
	else
		error(string.gsub(txt, "'%?'", string.format("'%s'", method)), 3)
	end
end

function Dongle:Print(msg, ...)
	local reg = lookup[self]
	assert(1, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "Print"))
	argcheck(msg, 2, "number", "string", "boolean", "table", "function", "thread", "userdata")
	return printHelp(self, "Print", true, DEFAULT_CHAT_FRAME, msg, ...)
end

function Dongle:PrintF(msg, ...)
	local reg = lookup[self]
	assert(1, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "PrintF"))
	argcheck(msg, 2, "number", "string", "boolean", "table", "function", "thread", "userdata")
	return printFHelp(self, "PrintF", true, DEFAULT_CHAT_FRAME, msg, ...)
end

function Dongle:Echo(msg, ...)
	local reg = lookup[self]
	assert(1, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "Echo"))
	argcheck(msg, 2, "number", "string", "boolean", "table", "function", "thread", "userdata")
	return printHelp(self, "Echo", false, DEFAULT_CHAT_FRAME, msg, ...)
end

function Dongle:EchoF(msg, ...)
	local reg = lookup[self]
	assert(1, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "EchoF"))
	argcheck(msg, 2, "number", "string", "boolean", "table", "function", "thread", "userdata")
	return printFHelp(self, "EchoF", false, DEFAULT_CHAT_FRAME, msg, ...)
end

function Dongle:Debug(level, ...)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "Debug"))
	argcheck(level, 2, "number")

	if reg.debugLevel and level <= reg.debugLevel then
		printHelp(self, "Debug", true, reg.debugFrame, ...)
	end
end

function Dongle:DebugF(level, ...)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "DebugF"))
	argcheck(level, 2, "number")

	if reg.debugLevel and level <= reg.debugLevel then
		printFHelp(self, "DebugF", true, reg.debugFrame, ...)
	end
end

--[[-------------------------------------------------------------------------
  Database System
---------------------------------------------------------------------------]]

local dbMethods = {
	"RegisterDefaults", "SetProfile", "GetProfiles", "DeleteProfile", "CopyProfile",
	"ResetProfile", "ResetDB",
	"RegisterNamespace",
}

local function copyTable(src)
	local dest = {}
	for k,v in pairs(src) do
		if type(k) == "table" then
			k = copyTable(k)
		end
		if type(v) == "table" then
			v = copyTable(v)
		end
		dest[k] = v
	end
	return dest
end

local function copyDefaults(dest, src, force)
	for k,v in pairs(src) do
		if k == "*" then
			if type(v) == "table" then
				-- Values are tables, need some magic here
				local mt = {
					__cache = {},
					__index = function(t,k)
						local mt = getmetatable(dest)
						local cache = rawget(mt, "__cache")
						local tbl = rawget(cache, k)
						if not tbl then
							local parent = t
							local parentkey = k
							tbl = copyTable(v)
							rawset(cache, k, tbl)
							local mt = getmetatable(tbl)
							if not mt then
								mt = {}
								setmetatable(tbl, mt)
							end
							local newindex = function(t,k,v)
								rawset(parent, parentkey, t)
								rawset(t, k, v)
							end
							rawset(mt, "__newindex", newindex)
						end
						return tbl
					end,
				}
				setmetatable(dest, mt)
				-- Now need to set the metatable on any child tables
				for dkey,dval in pairs(dest) do
					copyDefaults(dval, v)
				end
			else
				-- Values are not tables, so this is just a simple return
				local mt = {__index = function() return v end}
				setmetatable(dest, mt)
			end
		elseif type(v) == "table" then
			if not dest[k] then dest[k] = {} end
			copyDefaults(dest[k], v, force)
		else
			if (dest[k] == nil) or force then
				dest[k] = v
			end
		end
	end
end

local function removeDefaults(db, defaults)
	if not db then return end
	for k,v in pairs(defaults) do
		if k == "*" and type(v) == "table" then
			-- check for any defaults that have been changed
			local mt = getmetatable(db)
			local cache = rawget(mt, "__cache")

			for cacheKey,cacheValue in pairs(cache) do
				removeDefaults(cacheValue, v)
				if next(cacheValue) ~= nil then
					-- Something's changed
					rawset(db, cacheKey, cacheValue)
				end
			end
			-- Now loop through all the actual k,v pairs and remove
			for key,value in pairs(db) do
				removeDefaults(value, v)
			end
		elseif type(v) == "table" and db[k] then
			removeDefaults(db[k], v)
			if not next(db[k]) then
				db[k] = nil
			end
		else
			if db[k] == defaults[k] then
				db[k] = nil
			end
		end
	end
end

local function initSection(db, section, svstore, key, defaults)
	local sv = rawget(db, "sv")

	local tableCreated
	if not sv[svstore] then sv[svstore] = {} end
	if not sv[svstore][key] then
		sv[svstore][key] = {}
		tableCreated = true
	end

	local tbl = sv[svstore][key]

	if defaults then
		copyDefaults(tbl, defaults)
	end
	rawset(db, section, tbl)

	return tableCreated, tbl
end

local dbmt = {
	__index = function(t, section)
		local keys = rawget(t, "keys")
		local key = keys[section]
		if key then
			local defaultTbl = rawget(t, "defaults")
			local defaults = defaultTbl and defaultTbl[section]

			if section == "profile" then
				local new = initSection(t, section, "profiles", key, defaults)
				if new then
					Dongle:TriggerMessage("DONGLE_PROFILE_CREATED", t, rawget(t, "parent"), rawget(t, "sv_name"), key)
				end
			elseif section == "profiles" then
				local sv = rawget(t, "sv")
				if not sv.profiles then sv.profiles = {} end
				rawset(t, "profiles", sv.profiles)
			elseif section == "global" then
				local sv = rawget(t, "sv")
				if not sv.global then sv.global = {} end
				if defaults then
					copyDefaults(sv.global, defaults)
				end
				rawset(t, section, sv.global)
			else
				initSection(t, section, section, key, defaults)
			end
		end

		return rawget(t, section)
	end
}

local function initdb(parent, name, defaults, defaultProfile, olddb)
	-- This allows us to use an arbitrary table as base instead of saved variable name
	local sv
	if type(name) == "string" then
		sv = getglobal(name)
		if not sv then
			sv = {}
			setglobal(name, sv)
		end
	elseif type(name) == "table" then
		sv = name
	end

	-- Generate the database keys for each section
	local char = string.format("%s - %s", UnitName("player"), GetRealmName())
	local realm = GetRealmName()
	local class = select(2, UnitClass("player"))
	local race = select(2, UnitRace("player"))
	local faction = UnitFactionGroup("player")
	local factionrealm = string.format("%s - %s", faction, realm)

	-- Make a container for profile keys
	if not sv.profileKeys then sv.profileKeys = {} end

	-- Try to get the profile selected from the char db
	local profileKey = sv.profileKeys[char] or defaultProfile or char
	sv.profileKeys[char] = profileKey

	local keyTbl= {
		["char"] = char,
		["realm"] = realm,
		["class"] = class,
		["race"] = race,
		["faction"] = faction,
		["factionrealm"] = factionrealm,
		["global"] = true,
		["profile"] = profileKey,
		["profiles"] = true, -- Don't create until we need
	}

	-- If we've been passed an old database, clear it out
	if olddb then
		for k,v in pairs(olddb) do olddb[k] = nil end
	end

	-- Give this database the metatable so it initializes dynamically
	local db = setmetatable(olddb or {}, dbmt)

	-- Copy methods locally
	for idx,method in pairs(dbMethods) do
		db[method] = Dongle[method]
	end

	-- Set some properties in the object we're returning
	db.profiles = sv.profiles
	db.keys = keyTbl
	db.sv = sv
	db.sv_name = name
	db.defaults = defaults
	db.parent = parent

	databases[db] = true

	return db
end

function Dongle:InitializeDB(name, defaults, defaultProfile)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "InitializeDB"))
	argcheck(name, 2, "string", "table")
	argcheck(defaults, 3, "table", "nil")
	argcheck(defaultProfile, 4, "string", "nil")

	return initdb(self, name, defaults, defaultProfile)
end

-- This function operates on a Dongle DB object
function Dongle.RegisterDefaults(db, defaults)
	assert(3, databases[db], string.format(L["MUST_CALLFROM_DBOBJECT"], "RegisterDefaults"))
	assert(3, db.defaults == nil, L["REPLACE_DEFAUTS"])
	argcheck(defaults, 2, "table")

	for section,key in pairs(db.keys) do
		if defaults[section] and rawget(db, section) then
			copyDefaults(db[section], defaults[section])
		end
	end

	db.defaults = defaults
end

function Dongle:ClearDBDefaults()
	for db in pairs(databases) do
		local defaults = db.defaults
		local sv = db.sv

		if db and defaults then
			for section,key in pairs(db.keys) do
				if defaults[section] and rawget(db, section) then
					removeDefaults(db[section], defaults[section])
				end
			end

			for section,key in pairs(db.keys) do
				local tbl = rawget(db, section)
				if tbl and not next(tbl) then
					if sv[section] then
						if type(key) == "string" then
							sv[section][key] = nil
						else
							sv[section] = nil
						end
					end
				end
			end
		end
	end
end

function Dongle.SetProfile(db, name)
	assert(3, databases[db], string.format(L["MUST_CALLFROM_DBOBJECT"], "SetProfile"))
	argcheck(name, 2, "string")

	local old = db.profile
	local defaults = db.defaults and db.defaults.profile

	if defaults then
		-- Remove the defaults from the old profile
		removeDefaults(old, defaults)
	end

	db.profile = nil
	db.keys["profile"] = name

	Dongle:TriggerMessage("DONGLE_PROFILE_CHANGED", db, db.parent, db.sv_name, db.keys.profile)
end

function Dongle.GetProfiles(db, t)
	assert(3, databases[db], string.format(L["MUST_CALLFROM_DBOBJECT"], "GetProfiles"))
	argcheck(t, 2, "table", "nil")

	t = t or {}
	local i = 1
	for profileKey in pairs(db.sv.profiles) do
		t[i] = profileKey
		i = i + 1
	end
	return t, i - 1
end

function Dongle.DeleteProfile(db, name)
	assert(3, databases[db], string.format(L["MUST_CALLFROM_DBOBJECT"], "DeleteProfile"))
	argcheck(name, 2, "string")

	if db.keys.profile == name then
		error(L["CANNOT_DELETE_ACTIVE_PROFILE"], 2)
	end

	assert(type(db.sv.profiles[name]) == "table", L["DELETE_NONEXISTANT_PROFILE"])

	db.sv.profiles[name] = nil
	Dongle:TriggerMessage("DONGLE_PROFILE_DELETED", db, db.parent, db.sv_name, name)
end

function Dongle.CopyProfile(db, name)
	assert(3, databases[db], string.format(L["MUST_CALLFROM_DBOBJECT"], "CopyProfile"))
	argcheck(name, 2, "string")

	assert(3, db.keys.profile ~= name, L["SAME_SOURCE_DEST"])
	assert(3, type(db.sv.profiles[name]) == "table", string.format(L["PROFILE_DOES_NOT_EXIST"], name))

	local profile = db.profile
	local source = db.sv.profiles[name]

	copyDefaults(profile, source, true)
	Dongle:TriggerMessage("DONGLE_PROFILE_COPIED", db, db.parent, db.sv_name, name, db.keys.profile)
end

function Dongle.ResetProfile(db)
	assert(3, databases[db], string.format(L["MUST_CALLFROM_DBOBJECT"], "ResetProfile"))

	local profile = db.profile

	for k,v in pairs(profile) do
		profile[k] = nil
	end

	local defaults = db.defaults and db.defaults.profile
	if defaults then
		copyDefaults(profile, defaults)
	end
	Dongle:TriggerMessage("DONGLE_PROFILE_RESET", db, db.parent, db.sv_name, db.keys.profile)
end


function Dongle.ResetDB(db, defaultProfile)
	assert(3, databases[db], string.format(L["MUST_CALLFROM_DBOBJECT"], "ResetDB"))
    argcheck(defaultProfile, 2, "nil", "string")

	local sv = db.sv
	for k,v in pairs(sv) do
		sv[k] = nil
	end

	local parent = db.parent

	initdb(parent, db.sv_name, db.defaults, defaultProfile, db)
	Dongle:TriggerMessage("DONGLE_DATABASE_RESET", db, parent, db.sv_name, db.keys.profile)
	Dongle:TriggerMessage("DONGLE_PROFILE_CHANGED", db, db.parent, db.sv_name, db.keys.profile)
	return db
end

function Dongle.RegisterNamespace(db, name, defaults)
	assert(3, databases[db], string.format(L["MUST_CALLFROM_DBOBJECT"], "RegisterNamespace"))
    argcheck(name, 2, "string")
	argcheck(defaults, 3, "nil", "string")

	local sv = db.sv
	if not sv.namespaces then sv.namespaces = {} end
	if not sv.namespaces[name] then
		sv.namespaces[name] = {}
	end

	local newDB = initdb(db, sv.namespaces[name], defaults, db.keys.profile)
	-- Remove the :SetProfile method from newDB
	newDB.SetProfile = nil

	if not db.children then db.children = {} end
	table.insert(db.children, newDB)
	return newDB
end

--[[-------------------------------------------------------------------------
  Slash Command System
---------------------------------------------------------------------------]]

local slashCmdMethods = {
	"InjectDBCommands",
	"RegisterSlashHandler",
	"PrintUsage",
}

local function OnSlashCommand(cmd, cmd_line)
	if cmd.patterns then
		for idx,tbl in pairs(cmd.patterns) do
			local pattern = tbl.pattern
			if string.match(cmd_line, pattern) then
				local handler = tbl.handler
				if type(tbl.handler) == "string" then
					local obj
					-- Look in the command object before we look at the parent object
					if cmd[handler] then obj = cmd end
					if cmd.parent[handler] then obj = cmd.parent end
					if obj then
						obj[handler](obj, string.match(cmd_line, pattern))
					end
				else
					handler(string.match(cmd_line, pattern))
				end
				return
			end
		end
	end
	cmd:PrintUsage()
end

function Dongle:InitializeSlashCommand(desc, name, ...)
	local reg = lookup[self]
	assert(3, reg, string.format(L["MUST_CALLFROM_REGISTERED"], "InitializeSlashCommand"))
	argcheck(desc, 2, "string")
	argcheck(name, 3, "string")
	argcheck(select(1, ...), 4, "string")
	for i = 2,select("#", ...) do
		argcheck(select(i, ...), i+2, "string")
	end

	local cmd = {}
	cmd.desc = desc
	cmd.name = name
	cmd.parent = self
	cmd.slashes = { ... }
	for idx,method in pairs(slashCmdMethods) do
		cmd[method] = Dongle[method]
	end

	local genv = getfenv(0)

	for i = 1,select("#", ...) do
		genv["SLASH_"..name..tostring(i)] = "/"..select(i, ...)
	end

	genv.SlashCmdList[name] = function(...) OnSlashCommand(cmd, ...) end

	commands[cmd] = true

	return cmd
end

function Dongle.RegisterSlashHandler(cmd, desc, pattern, handler)
	assert(3, commands[cmd], string.format(L["MUST_CALLFROM_SLASH"], "RegisterSlashHandler"))

	argcheck(desc, 2, "string")
	argcheck(pattern, 3, "string")
	argcheck(handler, 4, "function", "string")

	if not cmd.patterns then
		cmd.patterns = {}
	end

	table.insert(cmd.patterns, {
		["desc"] = desc,
		["handler"] = handler,
		["pattern"] = pattern,
	})
end

function Dongle.PrintUsage(cmd)
	assert(3, commands[cmd], string.format(L["MUST_CALLFROM_SLASH"], "PrintUsage"))
	local parent = cmd.parent

	parent:Echo(cmd.desc.."\n".."/"..table.concat(cmd.slashes, ", /")..":\n")
	if cmd.patterns then
		for idx,tbl in ipairs(cmd.patterns) do
			parent:Echo(" - " .. tbl.desc)
		end
	end
end

local dbcommands = {
	["copy"] = {
		L["DBSLASH_PROFILE_COPY_DESC"],
		L["DBSLASH_PROFILE_COPY_PATTERN"],
		"CopyProfile",
	},
	["delete"] = {
		L["DBSLASH_PROFILE_DELETE_DESC"],
		L["DBSLASH_PROFILE_DELETE_PATTERN"],
		"DeleteProfile",
	},
	["list"] = {
		L["DBSLASH_PROFILE_LIST_DESC"],
		L["DBSLASH_PROFILE_LIST_PATTERN"],
	},
	["reset"] = {
		L["DBSLASH_PROFILE_RESET_DESC"],
		L["DBSLASH_PROFILE_RESET_PATTERN"],
		"ResetProfile",
	},
	["set"] = {
		L["DBSLASH_PROFILE_SET_DESC"],
		L["DBSLASH_PROFILE_SET_PATTERN"],
		"SetProfile",
	},
}

function Dongle.InjectDBCommands(cmd, db, ...)
	assert(3, commands[cmd], string.format(L["MUST_CALLFROM_SLASH"], "InjectDBCommands"))
	assert(3, databases[db], string.format(L["BAD_ARGUMENT_DB"], 2, "InjectDBCommands"))
	local argc = select("#", ...)
	assert(3, argc > 0, L["INJECTDB_USAGE"])

	for i=1,argc do
		local cmdname = string.lower(select(i, ...))
		local entry = dbcommands[cmdname]
		assert(entry, L["INJECTDB_USAGE"])
		local func = entry[3]

		local handler
		if cmdname == "list" then
			handler = function(...)
				local profiles = db:GetProfiles()
				db.parent:Print(L["DBSLASH_PROFILE_LIST_OUT"] .. "\n" .. strjoin("\n", unpack(profiles)))
			end
		else
			handler = function(...) db[entry[3]](db, ...) end
		end

		cmd:RegisterSlashHandler(entry[1], entry[2], handler)
	end
end

--[[-------------------------------------------------------------------------
  Internal Message/Event Handlers
---------------------------------------------------------------------------]]

local function PLAYER_LOGOUT(event)
	Dongle:ClearDBDefaults()
	for k,v in pairs(registry) do
		local obj = v.obj
		if type(obj["Disable"]) == "function" then
			safecall(obj["Disable"], obj)
		end
	end
end

local function PLAYER_LOGIN()
	Dongle.initialized = true
	for i=1, #loadorder do
		local obj = loadorder[i]
		if type(obj.Enable) == "function" then
			safecall(obj.Enable, obj)
		end
		loadorder[i] = nil
	end
end

local function ADDON_LOADED(event, ...)
	for i=1, #loadqueue do
		local obj = loadqueue[i]
		table.insert(loadorder, obj)

		if type(obj.Initialize) == "function" then
			safecall(obj.Initialize, obj)
		end
		loadqueue[i] = nil
	end

	if not Dongle.initialized then
		if type(IsLoggedIn) == "function" then
			Dongle.initialized = IsLoggedIn()
		else
			Dongle.initialized = ChatFrame1.defaultLanguage
		end
	end

	if Dongle.initialized then
		for i=1, #loadorder do
			local obj = loadorder[i]
			if type(obj.Enable) == "function" then
				safecall(obj.Enable, obj)
			end
			loadorder[i] = nil
		end
	end
end

local function DONGLE_PROFILE_CHANGED(msg, db, parent, sv_name, profileKey)
	local children = db.children
	if children then
		for i,namespace in ipairs(children) do
			local old = namespace.profile
			local defaults = namespace.defaults and namespace.defaults.profile

			if defaults then
				-- Remove the defaults from the old profile
				removeDefaults(old, defaults)
			end

			namespace.profile = nil
			namespace.keys["profile"] = profileKey
		end
	end
end

--[[-------------------------------------------------------------------------
  DongleStub required functions and registration
---------------------------------------------------------------------------]]

function Dongle:GetVersion() return major,minor end

local function Activate(self, old)
	if old then
		registry = old.registry or registry
		lookup = old.lookup or lookup
		loadqueue = old.loadqueue or loadqueue
		loadorder = old.loadorder or loadorder
		events = old.events or events
		databases = old.databases or databases
		commands = old.commands or commands
		messages = old.messages or messages
		frame = old.frame or CreateFrame("Frame")

		registry[major].obj = self
	else
		frame = CreateFrame("Frame")
		local reg = {obj = self, name = "Dongle"}
		registry[major] = reg
		lookup[self] = reg
		lookup[major] = reg
	end

	self.registry = registry
	self.lookup = lookup
	self.loadqueue = loadqueue
	self.loadorder = loadorder
	self.events = events
	self.databases = databases
	self.commands = commands
	self.messages = messages
	self.frame = frame

	local reg = self.registry[major]
	lookup[self] = reg
	lookup[major] = reg

	frame:SetScript("OnEvent", OnEvent)

	-- Register for events using Dongle itself
	self:RegisterEvent("ADDON_LOADED", ADDON_LOADED)
	self:RegisterEvent("PLAYER_LOGIN", PLAYER_LOGIN)
	self:RegisterEvent("PLAYER_LOGOUT", PLAYER_LOGOUT)
	self:RegisterMessage("DONGLE_PROFILE_CHANGED", DONGLE_PROFILE_CHANGED)

	-- Convert all the modules handles
	for name,obj in pairs(registry) do
		for k,v in ipairs(methods) do
			obj[k] = self[v]
		end
	end

	-- Convert all database methods
	for db in pairs(databases) do
		for idx,method in ipairs(dbMethods) do
			db[method] = self[method]
		end
	end

	-- Convert all slash command methods
	for cmd in pairs(commands) do
		for idx,method in ipairs(slashCmdMethods) do
			cmd[method] = self[method]
		end
	end
end

local function Deactivate(self, new)
	self:UnregisterAllEvents()
	lookup[self] = nil
end

Dongle = DongleStub:Register(Dongle, Activate, Deactivate)
