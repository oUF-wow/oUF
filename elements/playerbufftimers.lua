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
	-- TODO: let the layout deside?
	timer:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
	timer:SetHeight(10)
	timer:SetPoint('LEFT')
	timer:SetPoint('RIGHT')
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

local function Update(self, event, unit)
	local element = self.PlayerBuffTimers
	local timers = element.timers

	if(element.PreUpdate) then element:PreUpdate() end

	local index = 1
	local anchorFrame = self -- TODO: let the layout deside
	local duration, expiration, barID, auraID = UnitPowerBarTimerInfo(unit, index)
	while(barID) do
		if(not timers[auraID]) then
			local timer = GetTimer(self, duration, expiration, auraID)
			timer.auraID = auraID
			timers[auraID] = timer
		end

		local timer = timers[auraID]
		timer.expiration = expiration
		timer.show = true
		timer:SetPoint('BOTTOM', anchorFrame, 'TOP', 0, 10) -- TODO: let the layout deside
		anchorFrame = timer

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
