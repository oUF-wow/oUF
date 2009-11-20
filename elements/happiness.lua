local oUF
local parent
if(...) then
	parent = ...
else
	parent = debugstack():match[[\AddOns\(.-)\]]
end

local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
if(...) then
	local _, ns = ...
	oUF = ns.oUF
else
	oUF = _G[global]
end

local Update = function(self, event, unit)
	if(self.unit ~= unit) then return end

	if(self.Happiness) then
		local happiness = GetPetHappiness()
		local hunterPet = select(2, HasPetUI())

		if(not (happiness or hunterPet)) then
			return self.Happiness:Hide()
		end

		self.Happiness:Show()
		if(happiness == 1) then
			self.Happiness:SetTexCoord(0.375, 0.5625, 0, 0.359375)
		elseif(happiness == 2) then
			self.Happiness:SetTexCoord(0.1875, 0.375, 0, 0.359375)
		elseif(happiness == 3) then
			self.Happiness:SetTexCoord(0, 0.1875, 0, 0.359375)
		end

		if(self.PostUpdateHappiness) then
			return self:PostUpdateHappiness(event, unit, happiness)
		end
	end
end

local Enable = function(self)
	local happiness = self.Happiness
	if(happiness) then
		self:RegisterEvent("UNIT_HAPPINESS", Update)

		if(happiness:IsObjectType"Texture" and not happiness:GetTexture()) then
			happiness:SetTexture[[Interface\PetPaperDollFrame\UI-PetHappiness]]
		end

		return true
	end
end

local Disable = function(self)
	local happiness = self.Happiness
	if(happiness) then
		self:UnregisterEvent("UNIT_HAPPINESS", Update)
	end
end

oUF:AddElement('Happiness', Update, Enable, Disable)
