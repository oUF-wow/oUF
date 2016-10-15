local _, ns = ...
local oUF = ns.oUF

local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed

	if(self.elapsed >= self.updateDelay) then
		self:Hide()
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
		element:SetMinMaxValues(0, max)
		element:SetValue(math.abs(diff))

		if(diff ~= 0) then
			element.elapsed = 0
			element:SetScript("OnUpdate", OnUpdate)
			element:Show()
		else
			element:SetScript("OnUpdate", nil)
			element:Hide()
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

		if(element:IsObjectType('StatusBar') and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.TempName

	if(element) then
		self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
	end
end

oUF:AddElement('TempName', Path, Enable, Disable)
