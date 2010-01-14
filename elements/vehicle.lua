local parent, ns = ...
local oUF = ns.oUF

-- Rough optimization
local petUnits = { player = "pet" }
for i = 1, 4 do petUnits['party'..i] = 'partypet'..i end
for i = 1, 40 do petUnits['raid'..i] = 'raidpet'..i end

local Update = function(self, event, unit)
	local realUnit = SecureButton_GetUnit(self)
	-- Smart filter to update both master and pet/vehicle frames with a single event
	if not (unit == realUnit or petUnits[unit] == realUnit) then return end
	
	-- Evaluate the unit to display
	local	modUnit = SecureButton_GetModifiedUnit(self)
	if modUnit == "pet" and realUnit ~= "pet" then 
		modUnit = "vehicle" 
	end

	-- Avoid unnecessary changes
	if modUnit == self.unit then return end
	
	-- Update the frame unit properties
	self.unit = modUnit
	if modUnit ~= realUnit then
		self.realUnit = realUnit
	else
		self.realUnit = nil
	end
	
	-- Refresh the frame
	self:PLAYER_ENTERING_WORLD('VehicleSwitch')

	-- Update player buff frames
	if realUnit == "player" then
		PlayerFrame.unit = modUnit
		BuffFrame_Update()	
	end
end

local Enable = function(self, unit)
	if(self.disallowVehicleSwap) then return end

	self:RegisterEvent('UNIT_ENTERED_VEHICLE', Update)
	self:RegisterEvent('UNIT_EXITED_VEHICLE', Update)

	self:SetAttribute('toggleForVehicle', true)
end

local Disable = function(self)
	self:UnregisterEvent('UNIT_ENTERED_VEHICLE', Update)
	self:UnregisterEvent('UNIT_EXITED_VEHICLE', Update)

	self:SetAttribute('toggleForVehicle', nil)
end

oUF:AddElement("VehicleSwitch", nil, Enable, Disable)
