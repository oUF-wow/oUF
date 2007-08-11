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
}

local events = {}
local OnEvent = function(self, event, ...)
	local regs = events[event]

	if(regs) then
		for obj, func in pairs(regs) do
			if(type(func) == "string") then
				if(obj[func]) == "function") then
					obj[func](obj, event, ...)
				end
			else
				func(obj, event, ...)
			end
		end
	end
end

-- For debugging
local log = {}

-- add-on object
local oUF = CreateFrame"Frame"

--[[
--:RegisterEvent(event, func)
--	Notes:
--		- Internal function, but externaly avaible as someone might want to call it.
--]]
function oUF:RegisterEvent(event, func)
	if(not events[event]) then
		events[event] = {}
		self:RegisterEvent(event)
	end

	events[event][self] = func or event
end

--[[
--:RegisterFrameObject(object, unit)
--	Arguments:
--		- object: WoW frame table
--		- unit: Valid WoW unit
--	Returns:
--		- oUF frame object
--]]
function oUF:RegisterFrameObject(objectunit)
	if(type(object) ~= "table") then return end
	if(type(object.unit) ~= "string") then return end
	if(objects[unit]) then return error("Unit '%s' is already registered.", unit) end

	local unit = object.unit

	table.insert(log, string.format("[%s]: Parsing frame table.", unit))

	-- We might want to go deeper then the first level of the table, but there is honestly
	-- nothing preventing us from just placing all the interesting vars at the first level
	-- of it.
	for subType, subObject in pairs(object) do
		if(subTypes[subType]) then
			table.insert(log, string.format("[%s] Valid key '%s' found.", unit, key))

			self:RegisterObject(object, subType)
		end
	end

	objects[unit] = object
end

--[[
--:RegisterObject(object, subType)
--	Notes:
--		- Internal function, but externaly avaible as someone might want to call it.
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
	end
end

oUF.log = log
_G.oUF = oUF
