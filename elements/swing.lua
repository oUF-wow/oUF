--[[
# Element: Swing

Handles creation, visibility and updating of swing timer status bars.

## Widget

Swing - A `StatusBar` to represent swing timer.

## Sub-Widgets

.Time - A `FontString` to represent swing duration.

## Notes

This is not a traditional element; like Auras it only exposes meta functions.

The element only functions in Forever.

## Options

.showCombat - Keep element shown during combat even when swing duration is depleted (bool?)
.showAlways - Always keep element shown (bool?)
.checkRange - Only show element when in the correct range (bool?)
.smoothing  - Which status bar smoothing method to use, defaults to `Enum.StatusBarInterpolation.Immediate` (number)

## Sub-Widget options

.Time.binding   - A [`DurationTextBinding`](https://warcraft.wiki.gg/wiki/ScriptObject_DurationTextBinding) object to override the default
.Time.formatter - A [`NumericFormatter`](https://warcraft.wiki.gg/wiki/ScriptObject_NumericFormatter) to override the default

## Examples

  -- Initialize
  local Swing = self:CreateSwingElement(Enum.PlayerSwingType.Ranged)

  -- Position
  Swing:SetPoint('TOP', self, 'BOTTOM')
  Swing:SetSize(200, 30)

  -- Enable options
  Swing.showCombat = true
  Swing.checkRange = true

--]]
local _, ns = ...
local oUF = ns.oUF

local Private = oUF.Private

local argcheck = Private.argcheck
local nierror = Private.nierror
local GameVersion = Private.GameVersion

local STATE = {}

local defaultFormatter = C_StringUtil.CreateSecondsFormatter()
defaultFormatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
defaultFormatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
defaultFormatter:SetMillisecondsThreshold(60)

local function reset(state)
	local element = state.element

	state.isSwinging = false
	state.timer = nil

	element:SetValue(0)

	if(element.Time) then
		element.Time:SetText('')
	end

	local shouldHide
	if(element.showAlways) then
		shouldHide = false
	else
		shouldHide = not (element.showCombat and state.inCombat)
	end

	if(shouldHide) then
		element:Hide()
	end
end

local function Update(self, event, swingType, ...)
	local state = STATE[self][swingType]
	local element = state.element

	--[[ Callback: Swing:PreUpdate()
	Called before the element has been updated.

	* self - the Swing element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	if(event == 'PLAYER_SWING_RANGE_UPDATE') then
		local isInRange, checksRange = ...
		state.inRange = not checksRange or isInRange
	elseif(event == 'PLAYER_SWING') then
		local swingDuration = ...
		if(swingDuration and swingDuration > 0) then
			local duration = state.duration
			duration:SetTimeFromStart(GetTime(), swingDuration)

			element:SetTimerDuration(duration, element.smoothing, Enum.StatusBarTimerDirection.RemainingTime)

			if(element.Time) then
				element.Time.binding:SetDuration(duration)
			end

			if(state.timer) then
				state.timer:Cancel()
			end

			state.isSwinging = true
			state.timer = C_Timer.NewTimer(swingDuration, GenerateClosure(reset, state))
		end
	elseif(event == 'PLAYER_IN_COMBAT_CHANGED') then
		state.inCombat = not not (...)
	else -- ForceUpdate
		state.inCombat = UnitAffectingCombat('player')
	end

	local shouldShow
	if(not state.inRange) then
		shouldShow = false
	elseif(state.isSwinging or element.showAlways) then
		shouldShow = true
	else
		shouldShow = element.showCombat and state.inCombat
	end

	if(not state.isSwinging) then
		element:SetValue(0)

		if(element.Time) then
			element.Time:SetText('')
		end
	end

	element:SetShown(not not shouldShow)

	--[[ Callback: Swing:PostUpdate()
	Called after the element has been updated.

	* self      - the Swing element
	* event     - the callback event
	* swingType - the swing type for the element
	* ...       - the remaining payload for the callback
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(event, swingType, ...)
	end
end

local function Path(self, event, ...)
	if(event == 'PLAYER_SWING_RANGE_UPDATE') then
		local swingType, isInRange, checksRange = ...

		local state = STATE[self][swingType]
		if(state) then
			--[[ Override: Swing.Override(self, event, swingType, ...)
			Used to completely override the internal update function.

			* self      - the parent object
			* event     - the event triggering the update (string)
			* swingType - the swing type for the element (number)
			* ...       - the remaining payload for the event
			--]]
			(state.element.Override or Update)(self, event, swingType, isInRange, checksRange)
		end
	elseif(event == 'PLAYER_SWING') then
		local swingDuration, swingType = ...

		local state = STATE[self][swingType]
		if(state) then
			(state.element.Override or Update)(self, event, swingType, swingDuration)
		end
	else
		for swingType, state in next, STATE[self] do
			(state.element.Override or Update)(self, event, swingType, ...)
		end
	end
end

local function Disable(self)
	if(STATE[self]) then
		for _, state in next, STATE[self] do
			if(state.timer) then
				state.timer:Cancel()
				state.timer = nil
			end

			local Time = state.element.Time
			if(Time and Time.binding) then
				Time.binding:SetEnabled(false)
			end

			state.isSwinging = nil
			state.element:Hide()
		end

		self:UnregisterEvent('PLAYER_SWING', Path)
		self:UnregisterEvent('PLAYER_SWING_RANGE_UPDATE', Path)
		self:UnregisterEvent('PLAYER_IN_COMBAT_CHANGED', Path)
	end
end

--[[ Swing: frame:CreateSwingElement(swingType[, templates])
Create and return a swing element.

* self      - The unit frame on which to create the element
* swingType - Swing type (see [Enum.PlayerSwingType](https://warcraft.wiki.gg/wiki/Enum.PlayerSwingType))
* templates - Extra templates to use for the swing element (string?)

## Returns

* Swing - the element used to represent the swing bars
--]]
local function Create(self, swingType, templates)
	argcheck(swingType, 1, 'number')
	argcheck(templates, 2, 'string', 'nil')

	if(GameVersion.Forever and not table.contains(Enum.PlayerSwingType, swingType)) then
		nierror(string.format('Invalid swing type %d passed to CreateSwingElement', swingType))
	end

	if(STATE[self] and STATE[self][swingType]) then
		return STATE[self][swingType].element
	end

	local element = CreateFrame('StatusBar', '$parentSwing' .. swingType, self, templates)
	element.__owner = self

	-- keep a local state of elements created for each frame
	if(not STATE[self]) then
		STATE[self] = {}
	end

	STATE[self][swingType] = {
		element = element,
	}

	if(self.__unit ~= 'player' or not GameVersion.Forever) then
		Disable(self)
	end

	return element
end

local function Enable(self, unit)
	if(STATE[self] and unit == 'player' and GameVersion.Forever) then
		local shouldCheckRange
		for swingType, state in next, STATE[self] do
			local element = state.element

			state.duration = state.duration or C_DurationUtil.CreateDuration()
			state.inRange = true -- in case we're not checking range

			C_SwingTimer.EnableRangeCheck(swingType, not not element.checkRange)

			local Time = element.Time
			if(Time) then
				if(not Time.binding) then
					Time.binding = C_DurationUtil.CreateDurationTextBinding()
					Time.binding:SetFormatter(Time.formatter or defaultFormatter)
				end

				Time.binding:SetFontString(Time)
				Time.binding:SetEnabled(true)
			end

			if(element.checkRange) then
				shouldCheckRange = true
			end

			element:Hide()
		end

		self:RegisterEvent('PLAYER_SWING', Path, true)
		self:RegisterEvent('PLAYER_IN_COMBAT_CHANGED', Path, true)

		if(shouldCheckRange) then
			self:RegisterEvent('PLAYER_SWING_RANGE_UPDATE', Path, true)
		end

		C_CVar.SetCVar('showSwingTimer', 0)

		return true
	end
end

oUF:AddMetaElement('Swing', Create, nil, Enable, Disable)
