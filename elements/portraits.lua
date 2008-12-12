local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local Update = function(self, event, unit)
	if(self.unit ~= unit) then return end

	local portrait = self.Portrait
	if(portrait:IsObjectType'Model') then
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

local Enable = function(self)
	if(self.Portrait) then
		self:RegisterEvent("UNIT_PORTRAIT_UPDATE", Update)

		return true
	end
end

local Disable = function(self)
	if(self.Portrait) then
		self:UnregisterEvent("UNIT_PORTRAIT_UPDATE", Update)
	end
end

oUF:AddElement('Portrait', Update, Enable, Disable)
