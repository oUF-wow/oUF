local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local objects = oUF.objects

local Update = function()
	local hasVehicle = UnitHasVehicleUI("player")
	for _, object in next, objects do
		if hasVehicle and object.vehicleUnit then
			object.unit = object.vehicleUnit
		elseif object.normalUnit then
			object.unit = object.normalUnit
		end

		if object.unit ~= object:GetAttribute("unit") then
			object:SetAttribute("unit", object.unit)

			if object.normalUnit == "player" then
				PlayerFrame.unit = object.unit
				BuffFrame_Update()
			end
		end
	end
end

local PLAYER_REGEN_ENABLED = function(self, event)
	Update()
end

local UNIT_ENTERED_VEHICLE = function(self, event, unit)
	if not InCombatLockdown() then
		Update()
	end
end

local UNIT_EXITED_VEHICLE = function(self, event, unit)
	if not InCombatLockdown() then
		Update()
	end
end

local Enable = function(self, unit)
	if self.disallowVehicleSwap then return end

	self.normalUnit = unit

	if unit == "player" then
		self.vehicleUnit = "vehicle"

		self:RegisterEvent("UNIT_ENTERED_VEHICLE", UNIT_ENTERED_VEHICLE)
		self:RegisterEvent("UNIT_EXITED_VEHICLE", UNIT_EXITED_VEHICLE)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", PLAYER_REGEN_ENABLED)
	elseif unit == "pet" then
		self.vehicleUnit = "player"
	end
end

local Disable = function(self)
	self:UnregisterEvent("UNIT_ENTERED_VEHICLE", UNIT_ENTERED_VEHICLE)
	self:UnregisterEvent("UNIT_EXITED_VEHICLE", UNIT_EXITED_VEHICLE)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", PLAYER_REGEN_ENABLED)
end

oUF:AddElement("VehicleSwitch", Update, Enable, Disable)
