--[[
# Element: Castbar

Handles the visibility and updating of spell castbars.
Based upon oUF_Castbar by starlon.

## Widget

Castbar - A `StatusBar` to represent spell cast/channel progress.

## Sub-Widgets

.Text     - A `FontString` to represent spell name.
.Icon     - A `Texture` to represent spell icon.
.Time     - A `FontString` to represent spell duration.
.Shield   - A `Texture` to represent if it's possible to interrupt or spell steal.
.SafeZone - A `Texture` to represent latency.

## Notes

A default texture will be applied to the StatusBar and Texture widgets if they don't have a texture or a color set.

## Options

.timeToHold - indicates for how many seconds the castbar should be visible after a _FAILED or _INTERRUPTED
              event. Defaults to 0 (number)

## Attributes

.castID           - a globally unique identifier of the currently cast spell (string?)
.casting          - indicates whether the current spell is an ordinary cast (boolean)
.channeling       - indicates whether the current spell is a channeled cast (boolean)
.notInterruptible - indicates whether the current spell is interruptible (boolean)
.spellID          - the spell identifier of the currently cast/channeled spell (number)

## Examples

    -- Position and size
    local Castbar = CreateFrame('StatusBar', nil, self)
    Castbar:SetSize(20, 20)
    Castbar:SetPoint('TOP')
    Castbar:SetPoint('LEFT')
    Castbar:SetPoint('RIGHT')

    -- Add a background
    local Background = Castbar:CreateTexture(nil, 'BACKGROUND')
    Background:SetAllPoints(Castbar)
    Background:SetTexture(1, 1, 1, .5)

    -- Add a spark
    local Spark = Castbar:CreateTexture(nil, 'OVERLAY')
    Spark:SetSize(20, 20)
    Spark:SetBlendMode('ADD')

    -- Add a timer
    local Time = Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    Time:SetPoint('RIGHT', Castbar)

    -- Add spell text
    local Text = Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    Text:SetPoint('LEFT', Castbar)

    -- Add spell icon
    local Icon = Castbar:CreateTexture(nil, 'OVERLAY')
    Icon:SetSize(20, 20)
    Icon:SetPoint('TOPLEFT', Castbar, 'TOPLEFT')

    -- Add Shield
    local Shield = Castbar:CreateTexture(nil, 'OVERLAY')
    Shield:SetSize(20, 20)
    Shield:SetPoint('CENTER', Castbar)

    -- Add safezone
    local SafeZone = Castbar:CreateTexture(nil, 'OVERLAY')

    -- Register it with oUF
    Castbar.bg = Background
    Castbar.Spark = Spark
    Castbar.Time = Time
    Castbar.Text = Text
    Castbar.Icon = Icon
    Castbar.Shield = Shield
    Castbar.SafeZone = SafeZone
    self.Castbar = Castbar
--]]
local _, ns = ...
local oUF = ns.oUF

local GetNetStats = GetNetStats
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo

local function CastStart(self, event, unit)
	if(self.unit ~= unit and self.realUnit ~= unit) then return end

	local element = self.Castbar

	--[[ REVAMP NOTES:
		- It's possible not to display the castbar for trade skills in the default UI
		  via the .showTradeSkills attribute
		- The pet castbar should be hidden while the player is possessing something,
		  and the player is shown in the pet frame, see PetCastingBarFrame_OnEvent
	]]

	local name, _, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
	event = 'UNIT_SPELLCAST_START'

	if(not name) then
		name, _, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
		event = 'UNIT_SPELLCAST_CHANNEL_START'

		if(not name) then return end
	end

	endTime = endTime / 1e3
	startTime = startTime / 1e3

	element.max = endTime - startTime
	element.startTime = startTime
	element.delay = 0
	element.casting = event == 'UNIT_SPELLCAST_START'
	element.channeling = event == 'UNIT_SPELLCAST_CHANNEL_START'
	element.notInterruptible = notInterruptible
	element.holdTime = 0
	element.castID = castID
	element.spellID = spellID
	element.isHorizontal = element:GetOrientation() == 'HORIZONTAL'
	element.isReversed = element:GetReverseFill()

	if(element.casting) then
		element.duration = GetTime() - startTime
	else
		element.duration = endTime - GetTime()
	end

	element:SetMinMaxValues(0, element.max)
	element:SetValue(0)

	if(element.Icon) then element.Icon:SetTexture(texture or [[Interface\ICONS\INV_Misc_QuestionMark]]) end
	if(element.Shield) then element.Shield:SetShown(notInterruptible) end
	if(element.Spark) then element.Spark:Show() end
	if(element.Text) then element.Text:SetText(name) end
	if(element.Time) then element.Time:SetText() end

	local safeZone = element.SafeZone
	if(safeZone) then
		local isHoriz = element.isHorizontal

		safeZone:ClearAllPoints()
		safeZone:SetPoint(isHoriz and 'TOP' or 'LEFT')
		safeZone:SetPoint(isHoriz and 'BOTTOM' or 'RIGHT')

		if(element.casting) then
			safeZone:SetPoint(element.isReversed and (isHoriz and 'LEFT' or 'BOTTOM') or (isHoriz and 'RIGHT' or 'TOP'))
		else
			safeZone:SetPoint(element.isReversed and (isHoriz and 'RIGHT' or 'TOP') or (isHoriz and 'LEFT' or 'BOTTOM'))
		end

		local ratio = (select(4, GetNetStats()) / 1e3) / element.max
		if(ratio > 1) then
			ratio = 1
		end

		safeZone:SetWidth(element[isHoriz and 'GetWidth' or 'GetHeight'](element) * ratio)
	end

	--[[ Callback: Castbar:PostCastStart(unit, name)
	Called after the element has been updated upon a spell cast start.

	* self - the Castbar widget
	* unit - unit for which the update has been triggered (string)
	* name - name of the spell being cast (string)
	--]]
	if(element.PostCastStart) then
		element:PostCastStart(unit, name)
	end

	element:Show()
end

local function CastStop(self, event, unit, castID, spellID)
	if(self.unit ~= unit and self.realUnit ~= unit) then return end

	local element = self.Castbar

	-- Channeled spells for some reason don't have castIDs
	if(element.castID ~= castID or element.spellID ~= spellID) then return end

	if(element.Spark) then element.Spark:Hide() end

	element.casting = nil
	element.channeling = nil
	element.notInterruptible = nil

	element:SetValue(element.max)

	--[[ Callback: Castbar:PostCastStop(unit)
	Called after the element has been updated when a spell cast has finished.

	* self - the Castbar widget
	* unit - unit for which the update has been triggered (string)
	--]]
	if(element.PostCastStop) then
		return element:PostCastStop(unit)
	end
end

local function CastDelay(self, event, unit, castID, spellID)
	if(self.unit ~= unit and self.realUnit ~= unit) then return end

	local element = self.Castbar
	if(not element:IsShown() or element.castID ~= castID or element.spellID ~= spellID) then
		return
	end

	local name, startTime, endTime, _
	if(event == 'UNIT_SPELLCAST_DELAYED') then
		name, _, _, startTime, endTime = UnitCastingInfo(unit)
	else
		name, _, _, startTime, endTime = UnitChannelInfo(unit)
	end

	if(not name) then return end

	endTime = endTime / 1e3
	startTime = startTime / 1e3

	local delta
	if(element.casting) then
		delta = startTime - element.startTime

		element.duration = GetTime() - startTime
	else
		delta = element.startTime - startTime

		element.duration = endTime - GetTime()
	end

	if(delta < 0) then
		delta = 0
	end

	element.max = endTime - startTime
	element.startTime = startTime
	element.delay = element.delay + delta

	element:SetMinMaxValues(0, element.max)
	element:SetValue(element.duration)

	--[[ Callback: Castbar:PostCastDelayed(unit, name)
	Called after the element has been updated when a spell cast has been delayed.

	* self - the Castbar widget
	* unit - unit that the update has been triggered (string)
	* name - name of the delayed spell (string)
	--]]
	if(element.PostCastDelayed) then
		return element:PostCastDelayed(unit, name)
	end
end

local function CastFail(self, event, unit, castID, spellID)
	if(self.unit ~= unit and self.realUnit ~= unit) then return end

	local element = self.Castbar
	if(not element:IsShown() or element.castID ~= castID or element.spellID ~= spellID) then
		return
	end

	if(element.Text) then
		element.Text:SetText(event == 'UNIT_SPELLCAST_FAILED' and FAILED or INTERRUPTED)
	end

	if(element.Spark) then element.Spark:Hide() end

	element.casting = nil
	element.channeling = nil
	element.notInterruptible = nil
	element.holdTime = element.timeToHold or 0

	element:SetValue(element.max)

	--[[ Callback: Castbar:PostCastFailed(unit)
	Called after the element has been updated upon a failed spell cast.

	* self - the Castbar widget
	* unit - unit for which the update has been triggered (string)
	--]]
	if(element.PostCastFailed) then
		return element:PostCastFailed(unit)
	end
end

local function CastInterruptible(self, event, unit)
	if(self.unit ~= unit and self.realUnit ~= unit) then return end

	local element = self.Castbar
	if(not element:IsShown()) then return end

	element.notInterruptible = event == 'UNIT_SPELLCAST_NOT_INTERRUPTIBLE'

	if(element.Shield) then element.Shield:SetShown(element.notInterruptible) end

	--[[ Callback: Castbar:PostCastInterruptible(unit)
	Called after the element has been updated when a spell cast has become interruptible.

	* self - the Castbar widget
	* unit - unit for which the update has been triggered (string)
	--]]
	if(element.PostCastInterruptible) then
		return element:PostCastInterruptible(unit)
	end
end

local function onUpdate(self, elapsed)
	if(self.casting) then
		local duration = self.duration + elapsed
		if(duration >= self.max) then
			self.casting = nil
			self:Hide()

			if(self.PostCastStop) then self:PostCastStop(self.__owner.unit) end
			return
		end

		if(self.Time) then
			if(self.delay ~= 0) then
				if(self.CustomDelayText) then
					self:CustomDelayText(duration)
				else
					self.Time:SetFormattedText('%.1f|cffff0000+%.2f|r', duration, self.delay)
				end
			else
				if(self.CustomTimeText) then
					self:CustomTimeText(duration)
				else
					self.Time:SetFormattedText('%.1f', duration)
				end
			end
		end

		self.duration = duration
		self:SetValue(duration)

		if(self.Spark) then
			local isHoriz = self.isHorizontal
			local size = self[isHoriz and 'GetWidth' or 'GetHeight'](self)
			local offset = (duration / self.max) * size
			if(self.isReversed) then
				offset = size - offset
			end

			self.Spark:SetPoint('CENTER', self, isHoriz and 'LEFT' or 'BOTTOM', isHoriz and offset or 0, isHoriz and 0 or offset)
		end
	elseif(self.channeling) then
		local duration = self.duration - elapsed

		if(duration <= 0) then
			self.channeling = nil
			self:Hide()

			if(self.PostChannelStop) then self:PostChannelStop(self.__owner.unit) end
			return
		end

		if(self.Time) then
			if(self.delay ~= 0) then
				if(self.CustomDelayText) then
					self:CustomDelayText(duration)
				else
					self.Time:SetFormattedText('%.1f|cffff0000-%.2f|r', duration, self.delay)
				end
			else
				if(self.CustomTimeText) then
					self:CustomTimeText(duration)
				else
					self.Time:SetFormattedText('%.1f', duration)
				end
			end
		end

		self.duration = duration
		self:SetValue(duration)
		if(self.Spark) then
			local isHoriz = self.isHorizontal
			local size = self[isHoriz and 'GetWidth' or 'GetHeight'](self)
			local offset = (duration / self.max) * size
			if(self.isReversed) then
				offset = size - offset
			end

			self.Spark:SetPoint('CENTER', self, isHoriz and 'LEFT' or 'BOTTOM', isHoriz and offset or 0, isHoriz and 0 or offset)
		end
	elseif(self.holdTime > 0) then
		self.holdTime = self.holdTime - elapsed
	else
		self.casting = nil
		self.castID = nil
		self.channeling = nil

		self:Hide()
	end
end

local function Update(self, ...)
	CastStart(self, ...)
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.Castbar
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		if(not (unit and unit:match'%wtarget$')) then
			self:RegisterEvent('UNIT_SPELLCAST_START', CastStart)
			self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START', CastStart)
			self:RegisterEvent('UNIT_SPELLCAST_STOP', CastStop)
			self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP', CastStop)
			self:RegisterEvent('UNIT_SPELLCAST_DELAYED', CastDelay)
			self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE', CastDelay)
			self:RegisterEvent('UNIT_SPELLCAST_FAILED', CastFail)
			self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED', CastFail)
			self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTIBLE', CastInterruptible)
			self:RegisterEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE', CastInterruptible)
		end

		element.holdTime = 0
		element:SetScript('OnUpdate', element.OnUpdate or onUpdate)

		if(self.unit == 'player') then
			CastingBarFrame:UnregisterAllEvents()
			CastingBarFrame.Show = CastingBarFrame.Hide
			CastingBarFrame:Hide()

			PetCastingBarFrame:UnregisterAllEvents()
			PetCastingBarFrame.Show = PetCastingBarFrame.Hide
			PetCastingBarFrame:Hide()
		end

		if(element:IsObjectType('StatusBar') and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		local spark = element.Spark
		if(spark and spark:IsObjectType('Texture') and not spark:GetTexture()) then
			spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
		end

		local shield = element.Shield
		if(shield and shield:IsObjectType('Texture') and not shield:GetTexture()) then
			shield:SetTexture([[Interface\CastingBar\UI-CastingBar-Small-Shield]])
		end

		local safeZone = element.SafeZone
		if(safeZone and safeZone:IsObjectType('Texture') and not safeZone:GetTexture()) then
			safeZone:SetColorTexture(1, 0, 0)
		end

		element:Hide()

		return true
	end
end

local function Disable(self)
	local element = self.Castbar
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_SPELLCAST_START', CastStart)
		self:UnregisterEvent('UNIT_SPELLCAST_CHANNEL_START', CastStart)
		self:UnregisterEvent('UNIT_SPELLCAST_STOP', CastStop)
		self:UnregisterEvent('UNIT_SPELLCAST_CHANNEL_STOP', CastStop)
		self:UnregisterEvent('UNIT_SPELLCAST_DELAYED', CastDelay)
		self:UnregisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE', CastDelay)
		self:UnregisterEvent('UNIT_SPELLCAST_FAILED', CastFail)
		self:UnregisterEvent('UNIT_SPELLCAST_INTERRUPTED', CastFail)
		self:UnregisterEvent('UNIT_SPELLCAST_INTERRUPTIBLE', CastInterruptible)
		self:UnregisterEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE', CastInterruptible)

		element:SetScript('OnUpdate', nil)
	end
end

oUF:AddElement('Castbar', Update, Enable, Disable)
