local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local	UnitExists, UnitIsConnected, UnitIsVisible =
		UnitExists, UnitIsConnected, UnitIsVisible

function oUF:UNIT_PORTRAIT_UPDATE(event, unit)
	if(self.unit ~= unit) then return end

	local portrait = self.Portrait
	if(portrait.type == "3D") then
		if(not UnitExists(unit) or not UnitIsConnected(unit) or not UnitIsVisible(unit)) then
			portrait:SetModelScale(4.25)
			portrait:SetPosition(0, 0, -1.5)
			portrait:SetModel"Interface\\Buttons\\talktomequestionmark.mdx"
		else
			portrait:SetUnit(unit)
			portrait:SetCamera(0)
			portrait:Show()
		end
	else
		SetPortraitTexture(portrait, unit)
	end
end

table.insert(oUF.subTypes, function(self)
	if(self.Portrait) then
		self:RegisterEvent"UNIT_PORTRAIT_UPDATE"
	end
end)
oUF:RegisterSubTypeMapping"UNIT_PORTRAIT_UPDATE"
