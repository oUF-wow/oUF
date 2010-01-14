local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event, unit)
	-- Calculate units to work with
	local realUnit, modUnit = SecureButton_GetUnit(self), SecureButton_GetModifiedUnit(self)
	if(modUnit == "pet" and realUnit ~= "pet") then
		modUnit = "vehicle"
	end

	-- Avoid unnecessary changes
	if(modUnit == self.unit) then return end
	
	-- Update the frame unit properties
	self.unit = modUnit
	if(modUnit ~= realUnit) then
		self.realUnit = realUnit
	else
		self.realUnit = nil
	end
	
	-- Refresh the frame
	self:PLAYER_ENTERING_WORLD('VehicleSwitch')

	-- Update player buff frames
	if(realUnit == "player") then
		PlayerFrame.unit = modUnit
		BuffFrame_Update()
	end
end

local Enable = function(self, unit)
	if(self.disallowVehicleSwap) then return end

	self:RegisterEvent('UNIT_ENTERED_VEHICLE', Update)
	self:RegisterEvent('UNIT_EXITED_VEHICLE', Update)

	self:SetAttribute('toggleForVehicle', true)

	return true
end

local Disable = function(self)
	self:UnregisterEvent('UNIT_ENTERED_VEHICLE', Update)
	self:UnregisterEvent('UNIT_EXITED_VEHICLE', Update)

	self:SetAttribute('toggleForVehicle', nil)
end

oUF:AddElement("VehicleSwitch", Update, Enable, Disable)
