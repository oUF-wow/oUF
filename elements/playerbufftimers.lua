local _, ns = ...
local oUF = ns.oUF or oUF

local function OnUpdate(self)
	local timeLeft = self.expiration - GetTime()

	if(timeLeft > 0) then
		self:SetValue(timeLeft)
	else
		self:Hide()
	end
end

local function CreateTimer(self, duration, expiration, auraID)
	local element = self.PlayerBuffTimers
	local timer = CreateFrame('StatusBar', nil, self)
	timer:SetMinMaxValues(0, duration)
	timer:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]]) -- TODO: let the layout deside
	timer:SetSize(element.width or element:GetWidth(), element.height or 10)
	timer:SetScript('OnUpdate', OnUpdate)

	if(element.PostCreateTimer) then
		element:PostCreateTimer(timer, duration, expiration, auraID)
	end

	return timer
end

local function GetTimer(self, duration, expiration, auraID)
	local timers = self.PlayerBuffTimers.timers
	for id, bar in next, timers do
		if(not bar:IsShown()) then
			timers[id] = nil
			return bar
		end
	end

	return (self.PlayerBuffTimers.CreateTimer or CreateTimer)(self, duration, expiration, auraID)
end

local growthDirection = {
	TOPLEFT     = { 1, -1},
	TOPRIGHT    = {-1, -1},
	BOTTOMLEFT  = { 1,  1},
	BOTTOMRIGHT = {-1,  1},
}

local function SetPosition(element)
	local timers = element.timers

	local width = (element.width or element:GetWidth()) + (element['spacing-x'] or element.spacing or 0)
	local height = (element.height or 10) + (element['spacing-y'] or element.spacing or 0)
	local anchor = element.anchor or 'TOPLEFT'
	local direction = growthDirection[anchor] -- TODO: error on invalid anchor
	local x = direction[1]
	local y = direction[2]
	local cols = math.floor(element:GetWidth() / width + .5)
	local rows = math.floor(element:GetHeight() / height + .5)

	for _, timer in next, timers do
		local i = timer.index
		local col, row
		if(element.primaryAxis == 'x') then
			col = (i - 1) % cols
			row = math.floor((i - 1) / cols)
		else
			col = math.floor((i - 1) / rows)
			row = (i - 1) % rows
		end
		timer:ClearAllPoints()
		timer:SetPoint(anchor, element, anchor, col * width * x, row * height * y)
	end
end

local function Update(self, event, unit)
	local element = self.PlayerBuffTimers
	local timers = element.timers

	if(element.PreUpdate) then element:PreUpdate() end

	local index = 1
	local duration, expiration, barID, auraID = UnitPowerBarTimerInfo(unit, index)
	while(barID) do
		if(not timers[auraID]) then
			local timer = GetTimer(self, duration, expiration, auraID)
			timer.auraID = auraID
			timers[auraID] = timer
		end

		local timer = timers[auraID]
		timer.index = index
		timer.expiration = expiration
		timer.show = true

		index = index + 1
		duration, expiration, barID, auraID = UnitPowerBarTimerInfo(unit, index)
	end

	for _, timer in next, timers do
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
	element.timers = {}
	element.primaryAxis = element.primaryAxis or 'x'

	self:RegisterEvent('UNIT_POWER_BAR_TIMER_UPDATE', Path)

	return true
end

local function Disable(self)
	local element = self.PlayerBuffTimers
	if(element) then
		self:UnregisterEvent('UNIT_POWER_BAR_TIMER_UPDATE')

		for _, timer in next, element.timers do
			timer:Hide()
		end
	end
end

oUF:AddElement('PlayerBuffTimers', Path, Enable, Disable)
