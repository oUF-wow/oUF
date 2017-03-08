--[[
# Element: PlayerBuffTimers

Handles creation and updating of player buff timers.

## Widget

PlayerBuffTimers - A frame to hold player buff timers.

## Options

.width         - Timer width. Defaults to the width of the PlayerBuffTimers widget.
.height        - Timer height. Defaults to 16.
.anchor        - Anchor point for the timers. Must be one of 'BOTTOMLEFT', 'BOTTOMRIGHT', 'TOPLEFT' or 'TOPRIGHT'.
                 Timer growth direction will be then choosen so that timers grow away from the anchor point and into the
                 PlayerBuffTimers widget. Defaults to `'TOPLEFT'`.
.primaryAxis   - Axis for the primary growth direction. Defaults to `'x'`.
.spacing       - Spacing between timers. Defaults to 0.
.['spacing-x'] - Horizontal spacing between timers. Takes priority over `.spacing`.
.['spacing-y'] - Vertical spacing between timers. Takes priority over `.spacing`.

## Sub-Widget

Timers are created on demand and could be represented by any UI widget. They can be accessed through the array part of
the PlayerBuffTimers widget. StatusBar is used by default, but the layout could alter this by overriding
`CreateTimer`.

## Notes

If the layout provides its own `CreateTimer`, it also has to specify `timer.UpdateTimer`, which is then used to update
the timer.

## Attributes

.powerName    - Name of the timer buff. Applied to the timer widget before it has been updated.
.powerTooltip - Description of the timer buff. Applied to the timer widget before it has been updated.

## Examples

    -- Position and size
    local pbt = CreateFrame('Frame', nil, self)
    pbt:SetPoint('BOTTOM', self, 'TOP')
    pbt:SetSize(230, 20 * 4)

    -- Register with oUF
    self.PlayerBuffTimers = pbt
--]]

local _, ns = ...
local oUF = ns.oUF or oUF

local growthDirection = {
	TOPLEFT     = { 1, -1},
	TOPRIGHT    = {-1, -1},
	BOTTOMLEFT  = { 1,  1},
	BOTTOMRIGHT = {-1,  1},
}

local function SetPosition(element)
	local width = (element.width or element:GetWidth()) + (element['spacing-x'] or element.spacing or 0)
	local height = (element.height or 16) + (element['spacing-y'] or element.spacing or 0)
	local anchor = element.anchor or 'TOPLEFT'
	local direction = growthDirection[anchor]
	if(not direction) then
		local anchors
		for key in next, growthDirection do
			if(not anchors) then
				anchors = key
			else
				anchors = string.format('%s, %s', anchors, key)
			end
		end
		error(string.format('Invalid anchor %s. Should be one of %s', anchor, anchors))
	end
	local x = direction[1]
	local y = direction[2]
	local cols = math.floor(element:GetWidth() / width + .5)
	local rows = math.floor(element:GetHeight() / height + .5)

	local hidden = 0
	for i = 1, #element do
		local timer = element[i]
		if(timer:IsShown()) then
			local col, row
			if(element.primaryAxis == 'x') then
				col = (i - 1 - hidden) % cols
				row = math.floor((i - 1 - hidden) / cols)
			else
				col = math.floor((i - 1 - hidden) / rows)
				row = (i - 1 - hidden) % rows
			end
			timer:ClearAllPoints()
			timer:SetPoint(anchor, element, anchor, col * width * x, row * height * y)
		else
			hidden = hidden + 1
		end
	end
end

local function OnEnter(timer)
	if(not timer:IsVisible()) then return end

	GameTooltip:SetOwner(timer, 'ANCHOR_BOTTOMRIGHT')
	GameTooltip:SetText(timer.powerName, 1, 1, 1)
	GameTooltip:AddLine(timer.powerTooltip, nil, nil, nil, true)
	GameTooltip:Show()
end

local function OnLeave(timer)
	GameTooltip:Hide()
end

local function OnUpdate(timer)
	local timeLeft = timer.expiration - GetTime()

	if(timeLeft > 0) then
		timer:SetValue(timeLeft)
	else
		timer:Hide()
		--SetPosition(timer:GetParent()) -- TODO: remove after testing
	end
end

local function UpdateTimer(timer, duration, expiration, barID, auraID)
	timer:SetMinMaxValues(0, duration)
	timer.expiration = expiration
	timer.auraID = auraID
end

local function CreateTimer(element, index)
	local timer = CreateFrame('StatusBar', nil, element)
	timer:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]]) -- TODO: let the layout deside
	timer:SetSize(element.width or element:GetWidth(), element.height or 10)
	timer:SetScript('OnUpdate', OnUpdate)
	timer:SetScript('OnEnter', OnEnter)
	timer:SetScript('OnLeave', OnLeave)
	timer.UpdateTimer = UpdateTimer

	--[[ Callback: PlayerBuffTimers:PostCreateTimer(timer, index)
	Called after a timer has been created.

	* self  - the PlayerBuffTimers widget
	* timer - the created timer widget
	* index - index at which the timer was created
	--]]
	if(element.PostCreateTimer) then
		element:PostCreateTimer(timer, index)
	end

	return timer
end

-- local function UnitPowerBarTimerInfo(unit, index)
-- 	if(index > 5) then return end
-- 	local duration = math.random(20, 60)
-- 	return duration, GetTime() + duration, 84, 101871
-- end

local function Update(self, event)
	local element = self.PlayerBuffTimers

	--[[ Callback: PlayerBuffTimers:PreUpdate()
	Called before the element has been updated.

	* self  - the PlayerBuffTimers widget
	--]]
	if(element.PreUpdate) then element:PreUpdate() end

	local index = 1
	local duration, expiration, barID, auraID = UnitPowerBarTimerInfo('player', index)
	while(barID) do
		local timer = element[index]
		if(not timer) then
			--[[ Override: PlayerBuffTimers:CreateTimer(index)
			Used to create and return a new timer widget.

			* self  - the PlayerBuffTimers widget
			* index - index at which the timer should be created
			--]]
			timer = (element.CreateTimer or CreateTimer)(element, index)
			element[#element + 1] = timer
		end

		timer.powerName, timer.powerTooltip = select(11, GetAlternatePowerInfoByID(barID))

		--[[ Override: timer:UpdateTimer(duration, expiration, barID, auraID)
		Used to update the timer attributes.

		* self       - widget holding the timer to be updated
		* duration   - total timer duration
		* expiration - time at which the timer expires. Can be compared to `GetTime()`
		* barID      - alternate power id of the timer
		* auraID     - spellid of the timer aura
		--]]
		timer:UpdateTimer(duration, expiration, barID, auraID)
		timer.show = true

		index = index + 1
		duration, expiration, barID, auraID = UnitPowerBarTimerInfo('player', index)
	end

	for i = 1, #element do
		local timer = element[i]
		if(timer.show) then
			timer.show = nil
			timer:Show()
		else
			timer:Hide()
		end
	end

	--[[ Override: PlayerBuffTimers:SetPosition()
	Used to (re-)anchor the timers.
	Called every time a new timer is shown or an old one expires.

	* self - the PlayerBuffTimers widget
	--]]
	(element.SetPosition or SetPosition)(element)

	--[[ Callback: PlayerBuffTimers:PostUpdate()
	Called after all timers have been updated.

	* self - the PlayerBuffTimers widget
	--]]
	if(element.PostUpdate) then
		element:PostUpdate()
	end
end

local function Path(self, ...)
	--[[ Override: PlayerBuffTimers:Override(...)
	Used to completely override the internal update function.

	* self - the PlayerBuffTimers widget
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.PlayerBuffTimers.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', 'player')
end

local function Enable(self, unit)
	if(unit ~= 'player') then return end
	local element = self.PlayerBuffTimers
	if(not element) then return end

	element.__owner = self
	element.ForceUpdate = ForceUpdate
	element.primaryAxis = element.primaryAxis or 'x'

	self:RegisterEvent('UNIT_POWER_BAR_TIMER_UPDATE', Path)

	return true
end

local function Disable(self)
	local element = self.PlayerBuffTimers
	if(element) then
		self:UnregisterEvent('UNIT_POWER_BAR_TIMER_UPDATE')
		self:Hide()
	end
end

oUF:AddElement('PlayerBuffTimers', Path, Enable, Disable)
