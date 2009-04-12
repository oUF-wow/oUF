local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local objects = oUF.objects

local VehicleDriverFrame

local UpdateVehicleSwitch = function(self, attr, value)
	if attr == "unit" then
		self.unit = value

		if self:GetAttribute("normalUnit") == "player" then
			PlayerFrame.unit = self.unit
			BuffFrame_Update()
		end
	end
end

local Enable = function(self, unit)
	if self.disallowVehicleSwap or (unit ~= "player" and unit ~= "pet") then return end

	if not VehicleDriverFrame then
		VehicleDriverFrame = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
		RegisterStateDriver(VehicleDriverFrame, "vehicle", "[target=vehicle,exists,bonusbar:5]vehicle;novehicle")
		VehicleDriverFrame:SetAttribute("_onstate-vehicle", [[
			if newstate == "vehicle" then
				for idx, frame in pairs(VEHICLE_FRAMES) do
					frame:SetAttribute("unit", frame:GetAttribute("vehicleUnit"))
				end
			else
				for idx, frame in pairs(VEHICLE_FRAMES) do
					frame:SetAttribute("unit", frame:GetAttribute("normalUnit"))
				end
			end
		]])
		VehicleDriverFrame:Execute([[
			VEHICLE_FRAMES = newtable()
		]])
	end

	self:SetAttribute("normalUnit", unit)

	if unit == "player" then
		self:SetAttribute("vehicleUnit", "pet")
	elseif unit == "pet" then
		self:SetAttribute("vehicleUnit", "player")
	end

	VehicleDriverFrame:SetFrameRef("vehicleFrame", self)
	VehicleDriverFrame:Execute([[
		local frame = self:GetFrameRef("vehicleFrame")
		table.insert(VEHICLE_FRAMES, frame)
	]])

	self:HookScript("OnAttributeChanged", UpdateVehicleSwitch)
end

local Disable = function(self)
	self:SetAttribute("unit", self:GetAttribute("normalUnit"))
	VehicleDriverFrame:SetFrameRef("vehicleFrame", self)
	VehicleDriverFrame:Execute([[
		local frame = self:GetFrameRef("vehicleFrame")
		for idx, value in pairs(VEHICLE_FRAMES) do
			if value == frame then
				table.remove(VEHICLE_FRAMES, idx)
				return
			end
		end
	]])
end

oUF:AddElement("VehicleSwitch", nil, Enable, Disable)
