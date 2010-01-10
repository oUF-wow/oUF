local parent, ns = ...
local oUF = ns.oUF

local objects = oUF.objects

local updateBlizzardBuffFrames = function(self, unit)
	if(self.realUnit == 'player') then
		PlayerFrame.unit = self.unit
		BuffFrame_Update()
	end
end

local UNIT_ENTERED_VEHICLE = function(self, event, unit)
	if(self.unit ~= unit) then return end

	local modUnit = SecureButton_GetModifiedUnit(self)
	self.realUnit = unit

	-- The reason for this is that vehicle exists _before_ pet contains vehicle
	-- data.
	if(modUnit == 'pet') then
		self.unit = 'vehicle'
	else
		self.unit = modUnit
	end

	-- Now the fun part!
	-- If the frame has children, see if any of them are valid swap targets. If
	-- they aren't.. oh well, no need to swap anything then!
	--
	-- Now, if they don't have any children, then we're kinda screwed. So we
	-- iterate over all the non child/parent objects in oUF and just swap every
	-- single one of them.
	if(self.hasChildren) then
		local i = 1
		local child = self:GetAttribute('child' .. i)

		while(child) do
			if(child:GetAttribute'unitsuffix' == 'pet') then
				child.realUnit = SecureButton_GetModifiedUnit(child)
				child.unit = self.realUnit

				child:PLAYER_ENTERING_WORLD('VehicleSwitch')
				break
			end

			i = i + 1
			child = self:GetAttribute('child' .. i)
		end
	else
		for _, obj in next, objects do
			if(not(obj.hasChildren or obj.isChild) and modUnit == obj.unit) then
				obj.realUnit = obj.unit
				obj.unit = self.realUnit

				obj:PLAYER_ENTERING_WORLD('VehicleSwitch')
			end
		end
	end

	updateBlizzardBuffFrames(self)

	return self:PLAYER_ENTERING_WORLD('VehicleSwitch')
end

local UNIT_EXITED_VEHICLE = function(self, event, unit)
	if(self.realUnit ~= unit) then return end

	self.realUnit = nil
	local modUnit = self.unit

	if(modUnit == 'vehicle') then
		modUnit = 'pet'
	end

	if(self.hasChildren) then
		local i = 1
		local child = self:GetAttribute('child' .. i)

		while(child) do
			if(child:GetAttribute'unitsuffix' == 'pet') then
				child.unit = obj.realUnit
				child.realUnit = nil

				child:PLAYER_ENTERING_WORLD('VehicleSwitch')
				break
			end

			i = i + 1
			child = self:GetAttribute('child' .. i)
		end
	else
		for _, obj in next, objects do
			if(not(obj.hasChildren or obj.isChild) and modUnit == obj.realUnit) then
				obj.unit = obj.realUnit
				obj.realUnit = nil

				obj:PLAYER_ENTERING_WORLD('VehicleSwitch')
			end
		end
	end

	self.unit = SecureButton_GetModifiedUnit(self)
	updateBlizzardBuffFrames(self)

	return self:PLAYER_ENTERING_WORLD('VehicleSwitch')
end

local Enable = function(self, unit)
	if(self.disallowVehicleSwap) then return end

	self:RegisterEvent('UNIT_ENTERED_VEHICLE', UNIT_ENTERED_VEHICLE)
	self:RegisterEvent('UNIT_EXITED_VEHICLE', UNIT_EXITED_VEHICLE)

	self:SetAttribute('toggleForVehicle', true)
end

local Disable = function(self)
	self:UnregisterEvent('UNIT_ENTERED_VEHICLE', UNIT_ENTERED_VEHICLE)
	self:UnregisterEvent('UNIT_EXITED_VEHICLE', UNIT_EXITED_VEHICLE)

	self:SetAttribute('toggleForVehicle', nil)
end

oUF:AddElement("VehicleSwitch", nil, Enable, Disable)
