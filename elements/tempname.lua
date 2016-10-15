local _, ns = ...
local oUF = ns.oUF

local function ResetStatusBar(bar)
	bar.elapsed = 0
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar:Hide()
end

local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed

	if(self.elapsed >= self.updateDelay) then
		ResetStatusBar(self)
	end
end

local function Update(self, event, unit, powerType)
	if(self.unit ~= unit) then return end

	local element = self.TempName

	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local cur = UnitPower(unit, powerType)
	local max = UnitPowerMax(unit, powerType)
	local _, powerToken = UnitPowerType(unit)
	local diff = 0

	if(max ~= 0 and element.old and powerType == powerToken) then
		diff = cur - element.old

		if(math.abs(diff) / max < element.diffThreshold) then
			diff = 0
		end
	end

	element.old = cur

	if(diff ~= 0 or GetTime() - (element.lastUpdate or 0) > element.updateDelay) then
		if(diff > 0) then
			if(element.gainBar) then
				ResetStatusBar(element.gainBar)

				element.gainBar:SetScript('OnUpdate', OnUpdate)
				element.gainBar:SetMinMaxValues(0, max)
				element.gainBar:SetValue(diff)
				element.gainBar:Show()
			end
		elseif(diff < 0) then
			if(element.gainBar) then
				element.gainBar:SetScript('OnUpdate', nil)

				ResetStatusBar(element.gainBar)
			end

			if(element.lossBar) then
				ResetStatusBar(element.lossBar)

				element.lossBar:SetScript('OnUpdate', OnUpdate)
				element.lossBar:SetMinMaxValues(0, max)
				element.lossBar:SetValue(math.abs(diff))
				element.lossBar:Show()
			end
		else
			if(element.gainBar) then
				element.gainBar:SetScript('OnUpdate', nil)

				ResetStatusBar(element.gainBar)
			end

			if(element.lossBar) then
				element.lossBar:SetScript('OnUpdate', nil)

				ResetStatusBar(element.lossBar)
			end
		end

		element.lastUpdate = GetTime()

		if(element.PostUpdate) then
			return element:PostUpdate(unit, diff)
		end
	end
end

local function Path(self, ...)
	return (self.TempName.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.TempName

	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element.updateDelay = element.updateDelay or 0.4
		element.diffThreshold = element.diffThreshold or 0.1

		self:RegisterEvent('UNIT_POWER_FREQUENT', Path)

		if(element.gainBar) then
			element.gainBar.updateDelay = element.updateDelay

			if(element.gainBar:IsObjectType('StatusBar') and not element.gainBar:GetStatusBarTexture()) then
				element.gainBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.lossBar) then
			element.lossBar.updateDelay = element.updateDelay

			if(element.lossBar:IsObjectType('StatusBar') and not element.lossBar:GetStatusBarTexture()) then
				element.lossBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		return true
	end
end

local function Disable(self)
	local element = self.TempName

	if(element) then
		if(element.gainBar) then
			element.gainBar:Hide()
		end

		if(element.lossBar) then
			element.lossBar:Hide()
		end

		self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
	end
end

oUF:AddElement('TempName', Path, Enable, Disable)
