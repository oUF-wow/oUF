local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local objects = oUF.objects
local units = oUF.units

local toUnit = function(...)
	for i=1, select('#', ...) do
		local unit = select(i, ...)

		for k, object in ipairs(objects) do
			if(object.__unit == unit) then
				object.__unit = nil
				object:SetAttribute('unit', unit)
			end
		end
	end
end

local toVehicle = function(aUnit, bUnit, override)
	local aFrame = units[override or aUnit]
	local bFrame = units[bUnit]

	aFrame.__unit = aFrame.unit
	bFrame.__unit = bFrame.unit

	aFrame:SetAttribute('unit', bUnit)
	bFrame:SetAttribute('unit', override or aUnit)
end

local UNIT_ENTERED_VEHICLE = function(self, event, unit)
	if(unit ~= self.unit) then return end

	if(unit == 'player' and units.pet) then
		toVehicle('vehicle', 'pet', 'player')
	elseif(self.id) then
		if(unit == 'party'..self.id and units['partypet'..self.id]) then
			toVehicle(unit, 'partypet'..self.id)
		elseif(unit == 'raid'..self.id and units['raidpet'..self.id]) then
			toVehicle(unit, 'raidpet'..self.id)
		end
	end
end

local UNIT_EXITED_VEHICLE = function(self, event, unit)
	if(unit ~= self.__unit) then return end

	if(unit == 'player' and units.pet) then
		toUnit('player', 'pet')
	elseif(self.id) then
		if(unit == 'party'..self.id and units['partypet'..self.id]) then
			toUnit(unit, 'partypet'..self.id)
		elseif(unit == 'raid'..self.id and units['raidpet'..self.id]) then
			toUnit(unit, 'raidpet'..self.id)
		end
	end
end

oUF:AddElement(
	'VehicleSwitch',

	-- Update
	function(...)
		UNIT_ENTERED_VEHICLE(...)
		UNIT_EXITED_VEHICLE(...)
	end,

	-- Enable
	function(self, unit)
		if(self.disallowVehicleSwap or unit == 'pet') then return end

		self:RegisterEvent('UNIT_ENTERED_VEHICLE', UNIT_ENTERED_VEHICLE)
		self:RegisterEvent('UNIT_EXITED_VEHICLE', UNIT_EXITED_VEHICLE)
	end,

	-- Disable
	function(self)
		self:UnregisterEvent('UNIT_ENTERED_VEHICLE', UNIT_ENTERED_VEHICLE)
		self:UnregisterEvent('UNIT_EXITED_VEHICLE', UNIT_EXITED_VEHICLE)
	end
)
