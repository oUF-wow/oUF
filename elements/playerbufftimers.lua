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
	local height = (element.height or 10) + (element['spacing-y'] or element.spacing or 0)
	local anchor = element.anchor or 'TOPLEFT'
	local direction = growthDirection[anchor] -- TODO: error on invalid anchor
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
		SetPosition(timer:GetParent()) -- TODO: remove after testing
	end
end

local function UpdateTimer(timer, duration, expiration, barID, auraID)
	timer:SetMinMaxValues(0, duration)
	timer.expiration = expiration
	timer.auraID = auraID
end

local function CreateTimer(element, duration, expiration, auraID)
	local timer = CreateFrame('StatusBar', nil, element)
	timer:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]]) -- TODO: let the layout deside
	timer:SetSize(element.width or element:GetWidth(), element.height or 10)
	timer:SetScript('OnUpdate', OnUpdate)
	timer:SetScript('OnEnter', OnEnter)
	timer:SetScript('OnLeave', OnLeave)
	timer.UpdateTimer = UpdateTimer

	if(element.PostCreateTimer) then
		element:PostCreateTimer(timer, duration, expiration, auraID)
	end

	return timer
end

local function UnitPowerBarTimerInfo(unit, index)
	if(index > 5) then return end
	local duration = math.random(20, 60)
	return duration, GetTime() + duration, 84, 101871
end

local function Update(self, event, unit)
	local element = self.PlayerBuffTimers

	if(element.PreUpdate) then element:PreUpdate() end

	local index = 1
	local duration, expiration, barID, auraID = UnitPowerBarTimerInfo(unit, index)
	while(barID) do
		local timer = element[index]
		if(not timer) then
			timer = (element.CreateTimer or CreateTimer)(element, index)
			element[#element + 1] = timer
		end

		timer.powerName, timer.powerTooltip = select(11, GetAlternatePowerInfoByID(barID))

		timer:UpdateTimer(duration, expiration, barID, auraID)
		timer.show = true

		index = index + 1
		duration, expiration, barID, auraID = UnitPowerBarTimerInfo(unit, index)
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

	(element.SetPosition or SetPosition)(element)

	if(element.PostUpdate) then
		element:PostUpdate()
	end
end

local function Path(self, ...)
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
