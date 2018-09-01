--[[
# Element: PlayerBuffTimers

Handles the visibility and updating of player buff timers.

## Widget

PlayerBuffTimers - A `table` to hold player buff timers.

## Sub-Widgets

A timer can be any UI widget and must be accessible through the array part of the PlayerBuffTimers table.
If the sub-widgets are StatusBars, a default texture and an `OnUpdate` handler will be set if not provided by the layout.

## Notes

If mouse interactivity is enabled for the sub-widgets, `OnEnter` and/or `OnLeave` handlers will be set to display a
timer duration and a tooltip

## Sub-Widget Options

.Time - used to represent the remaining timer duration (FontString)

## Sub-Widget Attributes

.duration   - the total timer duration in seconds (number)
.expiration - the time at which the timer expires. Can be compared to `GetTime()` (number)
.auraID     - the spellid of the timer aura (number)
.name       - the alternate power name of the timer buff (string)
.tooltip    - the alternate power description of the timer buff (string)

## Examples

    -- Position and size
    local timers = {}
    for i = 1, 2 do
        local timer = CreateFrame('StatusBar', nil, self)
        timer:SetSize(120, 20)
        timer:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, i * 20)
        timer:EnableMouse(true)
        timers[i] = timer
    end

    -- Register with oUF
    self.PlayerBuffTimers = timers

    -- Using cooldown buttons instead of status bars
    -- custom UpdateTimer is mandatory!
    local function UpdateTimer(timer, duration, expiration, barID, auraID)
        local _, _, texture = GetSpellInfo(auraID)
        timer.cd:SetCooldown(expiration - duration, duration)
        timer.icon:SetTexture(texture)
	end

    -- Position and size
    local timers = {}
    for i = 1, 2 do
        -- a Button to hold a cooldown spiral and a texture
        local timer = CreateFrame('Button', nil, self)
        timer:SetSize(32, 32)
        timer:SetPoint("BOTTOMLEFT", self, "TOPLEFT", (i - 1) * (32 + 5), 65)

        -- the cooldown spiral
        local cd = CreateFrame('Cooldown', nil, timer, 'CooldownFrameTemplate')
        cd:SetAllPoints()
        cd:SetReverse(true)
        timer.cd = cd

        -- the icon texture
        local icon = timer:CreateTexture(nil, 'BORDER')
        icon:SetAllPoints()
        timer.icon = icon

        timer.UpdateTimer = UpdateTimer

        timers[i] = timer
    end

    -- Register with oUF
    self.PlayerBuffTimers = timers
--]]

local _, ns = ...
local oUF = ns.oUF

local function UpdateTooltip(timer)
	GameTooltip:SetOwner(timer, 'ANCHOR_BOTTOMRIGHT')
	GameTooltip:SetText(timer.name, 1, 1, 1)
	GameTooltip:AddLine(timer.tooltip, nil, nil, nil, true)
	GameTooltip:Show()
end

local function OnEnter(timer)
	if(not timer:IsVisible()) then return end

	if(timer.Time) then
		timer.Time:Show()
	end

	--[[ Override: timer:UpdateTooltip()
	Called when the mouse is over the widget. Used to populate its tooltip.

	self - the timer sub-widget
	--]]
	timer:UpdateTooltip()
end

local function OnLeave(timer)
	if(timer.Time) then
		timer.Time:Hide()
	end
	GameTooltip:Hide()
end

local function OnUpdate(timer)
	local timeLeft = timer.expiration - GetTime()

	if(timeLeft > 0) then
		timer:SetValue(timeLeft)

		if(timer.Time and timer.Time:IsVisible()) then
			--[[ Callback: timer:CustomTime(timeLeft)
			Called after the timer's remaining time changed. Used together with the `.Time` sub-widget option.

			* self     - the timer widget
			* timeLeft - the remaining timer duration in seconds (number)
			--]]
			if(timer.CustomTime) then
				timer:CustomTime(timeLeft)
			else
				timer.Time:SetFormattedText('%d / %d', timeLeft, timer.duration)
			end
		end
	else
		timer:Hide()
	end
end

local function UpdateTimer(timer, duration, expiration, barID, auraID)
	timer:SetMinMaxValues(0, duration)
end

-- TODO: remove before merge
-- Use for testing outside of Darkmoon Fair
-- local function UnitPowerBarTimerInfo(unit, index)
-- 	local duration = math.random(20, 60)
-- 	return duration, GetTime() + duration, 84, 101871
-- end

local function Update(self, event)
	local element = self.PlayerBuffTimers

	--[[ Callback: PlayerBuffTimers:PreUpdate()
	Called before the element has been updated.

	* self  - the PlayerBuffTimers element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	for i = 1, #element do
		local timer = element[i]
		if(not timer) then
			break
		end

		local duration, expiration, barID, auraID = UnitPowerBarTimerInfo('player', i)

		if(barID) then
			timer.duration = duration
			timer.expiration = expiration
			timer.auraID = auraID
			timer.name, timer.tooltip = select(11, GetAlternatePowerInfoByID(barID))

			--[[ Override: timer:UpdateTimer(duration, expiration, barID, auraID)
			Used to update the timer attributes. You have to override this if your sub-widgets are not StatusBars.

			* self       - the timer sub-widget
			* duration   - the total timer duration in seconds (number)
			* expiration - the time at which the timer expires. Can be compared to `GetTime()` (number)
			* barID      - the alternate power id of the timer (number)
			* auraID     - the spellid of the timer aura (number)
			--]]
			timer:UpdateTimer(duration, expiration, barID, auraID)
			timer:Show()
		else
			timer:Hide()
		end
	end

	--[[ Callback: PlayerBuffTimers:PostUpdate()
	Called after all timers have been updated.

	* self - the PlayerBuffTimers element
	--]]
	if(element.PostUpdate) then
		element:PostUpdate()
	end
end

local function Path(self, ...)
	--[[ Override: PlayerBuffTimers.Override(self, event, unit)
	Used to completely override the element's update function.

	* self   - the parent object
	* event  - the event triggering the update (string)
	* unit   - the unit accompanying the event (string)
	--]]
	return (self.PlayerBuffTimers.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', 'player')
end

local function Enable(self, unit)
	local element = self.PlayerBuffTimers
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		for i = 1, #element do
			local timer = element[i]

			if(timer:IsObjectType('StatusBar')) then
				timer.UpdateTimer = timer.UpdateTimer or UpdateTimer

				if(not timer:GetStatusBarTexture()) then
					timer:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
				end

				if(not timer:GetScript('OnUpdate')) then
					timer:SetScript('OnUpdate', OnUpdate)
				end
			end

			if(timer:IsMouseEnabled()) then
				timer.UpdateTooltip = timer.UpdateTooltip or UpdateTooltip

				if(not timer:GetScript('OnEnter')) then
					timer:SetScript('OnEnter', OnEnter)
				end

				if(not timer:GetScript('OnLeave')) then
					timer:SetScript('OnLeave', OnLeave)
				end
			end
		end

		self:RegisterEvent('UNIT_POWER_BAR_TIMER_UPDATE', Path)

		PlayerBuffTimerManager:UnregisterEvent('UNIT_POWER_BAR_TIMER_UPDATE')
		PlayerBuffTimerManager:UnregisterEvent('PLAYER_ENTERING_WORLD')

		return true
	end
end

local function Disable(self)
	local element = self.PlayerBuffTimers
	if(element) then
		self:UnregisterEvent('UNIT_POWER_BAR_TIMER_UPDATE', Path)

		for i = 1, #element do
			element[i]:Hide()
		end

		PlayerBuffTimerManager:RegisterEvent('UNIT_POWER_BAR_TIMER_UPDATE')
		PlayerBuffTimerManager:RegisterEvent('PLAYER_ENTERING_WORLD')
	end
end

oUF:AddElement('PlayerBuffTimers', Path, Enable, Disable)
