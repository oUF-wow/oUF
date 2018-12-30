local parent, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local argcheck = Private.argcheck
local error = Private.error
local frame_metatable = Private.frame_metatable

-- Original event methods
local registerEvent = frame_metatable.__index.RegisterEvent
local registerUnitEvent = frame_metatable.__index.RegisterUnitEvent
local unregisterEvent = frame_metatable.__index.UnregisterEvent
local isEventRegistered = frame_metatable.__index.IsEventRegistered

function Private.UpdateUnits(frame, unit, realUnit)
	if(unit == realUnit) then
		realUnit = nil
	end

	if(frame.unit ~= unit or frame.realUnit ~= realUnit) then
		if(frame.unitEvents) then
			for event in next, frame.unitEvents do
				-- IsEventRegistered returns the units in case of an event
				-- registered with RegisterUnitEvent
				local registered, unit1 = isEventRegistered(frame, event)
				if(registered and unit1 and unit1 ~= unit) then
					-- RegisterUnitEvent erases previously registered units so
					-- do not bother to unregister it
					-- BUG: passing explicit nil units to RegisterUnitEvent
					-- makes it silently fall back to RegisterEvent
					registerUnitEvent(frame, event, unit, realUnit or '')
				end
			end
		end

		frame.unit = unit
		frame.realUnit = realUnit
		frame.id = unit:match('^.-(%d+)')
		return true
	end
end

local function onEvent(self, event, ...)
	if(self:IsVisible()) then
		return self[event](self, event, ...)
	end
end

local event_metatable = {
	__call = function(funcs, self, ...)
		for _, func in next, funcs do
			func(self, ...)
		end
	end,
}

--[[ Events: frame:RegisterEvent(event, func, unitless)
Used to register a frame for a game event and add an event handler. OnUpdate polled frames are prevented from
registering events.

* self     - frame that will be registered for the given event.
* event    - name of the event to register (string)
* func     - a function that will be executed when the event fires. Multiple functions can be added for the same frame
             and event (function)
* unitless - indicates that the event does not fire for a specific unit, so the event arguments won't be
             matched to the frame unit(s). Obligatory for unitless event (boolean)
--]]
function frame_metatable.__index:RegisterEvent(event, func, unitless)
	-- Block OnUpdate polled frames from registering events except for
	-- UNIT_PORTRAIT_UPDATE and UNIT_MODEL_CHANGED which are used for
	-- portrait updates.
	if(self.__eventless and event ~= 'UNIT_PORTRAIT_UPDATE' and event ~= 'UNIT_MODEL_CHANGED') then return end

	argcheck(event, 2, 'string')
	argcheck(func, 3, 'function')

	local curev = self[event]
	local kind = type(curev)
	if(curev) then
		if(kind == 'function' and curev ~= func) then
			self[event] = setmetatable({curev, func}, event_metatable)
		elseif(kind == 'table') then
			for _, infunc in next, curev do
				if(infunc == func) then return end
			end

			table.insert(curev, func)
		end

		if unitless then
			-- re-register the event in case we have mixed registration
			-- this will remove previously registered units
			registerEvent(self, event)
			if(self.unitEvents) then
				self.unitEvents[event] = nil
			end
		end
	else
		self[event] = func

		if(not self:GetScript('OnEvent')) then
			self:SetScript('OnEvent', onEvent)
		end

		if(unitless) then
			registerEvent(self, event)
		else
			self.unitEvents = self.unitEvents or {}
			self.unitEvents[event] = true
			registerUnitEvent(self, event, self.unit)
		end
	end
end

--[[ Events: frame:UnregisterEvent(event, func)
Used to remove a function from the event handler list for a game event.

* self  - the frame registered for the event
* event - name of the registered event (string)
* func  - function to be removed from the list of event handlers. If this is the only handler for the given event, then
          the frame will be unregistered for the event (function)
--]]
function frame_metatable.__index:UnregisterEvent(event, func)
	argcheck(event, 2, 'string')

	local curev = self[event]
	if(type(curev) == 'table' and func) then
		for k, infunc in next, curev do
			if(infunc == func) then
				table.remove(curev, k)

				local n = #curev
				if(n == 1) then
					local _, handler = next(curev)
					self[event] = handler
				elseif(n == 0) then
					-- This should not happen
					unregisterEvent(self, event)
				end

				break
			end
		end
	elseif(curev == func) then
		self[event] = nil
		if(self.unitEvents) then
			self.unitEvents[event] = nil
		end
		unregisterEvent(self, event)
	end
end
