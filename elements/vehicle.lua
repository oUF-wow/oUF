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

				if(not InCombatLockdown()) then
					object.__unit = nil
					object:SetAttribute('unit', unit)
				else
					object.unit = unit
					object:PLAYER_ENTERING_WORLD()
				end
			end
		end
	end
end

local toVehicle = function(aUnit, bUnit, override)
	local aFrame = units[override or aUnit]
	local bFrame = units[bUnit]

	aFrame.__unit = aFrame.unit
	bFrame.__unit = bFrame.unit

	if(not InCombatLockdown()) then
		aFrame:SetAttribute('unit', bUnit)
		bFrame:SetAttribute('unit', override or aUnit)
	else
		-- We manually change the unit here, so we can check if it's correct when
		-- we drop combat.
		aFrame.unit = bUnit
		bFrame.unit = override or aUnit

		-- Force an update to all the information is correct. This is usually done
		-- by OnAttributeChanged.
		aFrame:PLAYER_ENTERING_WORLD()
		bFrame:PLAYER_ENTERING_WORLD()
	end
end

local UNIT_ENTERED_VEHICLE = function(self, event, unit)
	if(unit ~= self.unit) then return end

	if(unit == 'player' and units.pet) then
		-- Required for BuffFrame.lua
		PlayerFrame.unit = 'vehicle'
		BuffFrame_Update()

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
		-- Required for BuffFrame.lua
		PlayerFrame.unit = 'player'

		toUnit('player', 'pet')
	elseif(self.id) then
		if(unit == 'party'..self.id and units['partypet'..self.id]) then
			toUnit(unit, 'partypet'..self.id)
		elseif(unit == 'raid'..self.id and units['raidpet'..self.id]) then
			toUnit(unit, 'raidpet'..self.id)
		end
	end
end

-- Swap the unit - I hate this solution and hope it's me whose stupid.
local PLAYER_REGEN_ENABLED = function(self)
	local unit = self.unit
	if(self:GetAttribute'unit' ~= unit) then
		self.__unit = nil
		self:SetAttribute('unit', unit)
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
		if(self.disallowVehicleSwap) then return end

		if(unit ~= 'pet') then
			self:RegisterEvent('UNIT_ENTERED_VEHICLE', UNIT_ENTERED_VEHICLE)
			self:RegisterEvent('UNIT_EXITED_VEHICLE', UNIT_EXITED_VEHICLE)
		end

		self:RegisterEvent('PLAYER_REGEN_ENABLED', PLAYER_REGEN_ENABLED)
	end,

	-- Disable
	function(self)
		self:UnregisterEvent('UNIT_ENTERED_VEHICLE', UNIT_ENTERED_VEHICLE)
		self:UnregisterEvent('UNIT_EXITED_VEHICLE', UNIT_EXITED_VEHICLE)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED', PLAYER_REGEN_ENABLED)
	end
)
