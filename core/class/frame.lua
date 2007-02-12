--[[-------------------------------------------------------------------------
  Copyright (c) 2006, Trond A Ekseth
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of Trond A Ekseth nor the names of its
        contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------]]

local G = getfenv(0)
local methods = {"createElements", "applyLayout", "menu", "loadPosition", "savePosition"}
local OnAuraEnter = function()
	if(not this:IsVisible()) then return end
	local unit = this:GetParent():GetParent().unit

	GameTooltip:SetOwner(this, "ANHOR_BOTTOMRIGHT")
	if(this.isdebuff) then
		GameTooltip:SetUnitDebuff(unit, this.id)
	else
		GameTooltip:SetUnitBuff(unit, this.id)
	end
end

local OnShow = function(self)
	self:updateAll()
end

oUF.class.frame = {}

function oUF.class.frame:new(unit, name, id, db, onShow)
	local frame = CreateFrame("Button", name, nil, "SecureUnitButtonTemplate")

	frame.unit = unit
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	frame:SetBackdropBorderColor(.3, .3, .3)
	frame:SetBackdropColor(0, 0, 0)

	frame:SetScript("OnShow", onShow or OnShow)
	frame:SetScript("OnDragStart", function()
		if(IsAltKeyDown()) then
			frame:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		frame:savePosition()
	end)
	frame:SetScript("OnEnter", function()
		UnitFrame_OnEnter()
	end)
	frame:SetScript("OnLeave", function()
		UnitFrame_OnLeave()
	end)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")

	frame:SetID(id or 0)

	frame:SetAttribute("unit", unit)
	frame:SetAttribute("type1", "target")
	frame:SetAttribute("*type2", "menu")

	RegisterUnitWatch(frame, false)

	for _, v in pairs(methods) do
		frame[v] = self[v]
	end

	frame:createElements()
	frame:applyLayout()
	frame:loadPosition()

	return frame
end

function oUF.class.frame:createElements()
	self.Health = CreateFrame("StatusBar", nil, self)
	self.HealthBG = CreateFrame("StatusBar", nil, self)
	self.Health.Name = self.Health:CreateFontString(nil, "OVERLAY")
	self.Health.Points = self.Health:CreateFontString(nil, "OVERLAY")

	self.Power = CreateFrame("StatusBar", nil, self)
	self.PowerBG = CreateFrame("StatusBar", nil, self)
	self.Power.Info = self.Power:CreateFontString(nil, "OVERLAY")
	self.Power.Points = self.Power:CreateFontString(nil, "OVERLAY")

	for type, num in pairs({Buffs = 32, Debuffs = 40}) do
		self[type] = CreateFrame("Frame", nil, self)
		self[type]:SetWidth(260)
		self[type]:SetHeight(14*4)
		for i=1,num do
			self[type][i] = CreateFrame("Button", nil, self[type])
			self[type][i]:SetWidth(14)
			self[type][i]:SetHeight(14)
			self[type][i]:SetScript("OnEnter", OnAuraEnter)
			self[type][i]:SetScript("OnLeave", function() GameTooltip:Hide() end)
			self[type][i].id = i
			self[type][i].isdebuff = (type == "Debuffs" and 1 or nil)

			self[type][i].Icon = self[type][i]:CreateTexture(nil, "BACKGROUND")
			self[type][i].Icon:SetAllPoints(self[type][i])
			self[type][i].Icon:SetAlpha(.6)

			if(type == "Debuffs") then
				self[type][i].Overlay = self[type][i]:CreateTexture(nil, "BACKGROUND")
				self[type][i].Overlay:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
				self[type][i].Overlay:SetAllPoints(self[type][i])
				self[type][i].Overlay:SetTexture(0.296875, 0.5703125, 0, 0.515625)
			end

			self[type][i].Count = self[type][i]:CreateFontString(nil, "OVERLAY")
			self[type][i].Count:SetFontObject(NumberFontNormal)
			self[type][i].Count:SetPoint("BOTTOMRIGHT", self[type][i])
		end
	end
end

function oUF.class.frame:applyLayout()
	local p = oUF.getPowerColor(self.unit)
	self:SetWidth(260)
	self:SetHeight(46)
	self:SetPoint("CENTER", UIParent, "CENTER")

	self.Health:SetPoint("TOPLEFT", self, "TOPLEFT", 8, -7)
	self.Health:SetWidth(260-90)
	self.Health:SetHeight(14)
	self.Health:SetStatusBarTexture("Interface\\AddOns\\oUF\\textures\\glaze")
	self.Health:SetStatusBarColor(49/255, 227/255, 37/255)

	self.HealthBG:SetPoint("TOP", self.Health, "TOP", 0, 0)
	self.HealthBG:SetWidth(260-90)
	self.HealthBG:SetHeight(14)
	self.HealthBG:SetStatusBarTexture("Interface\\AddOns\\oUF\\textures\\glaze")
	self.HealthBG:SetStatusBarColor(49/255, 227/255, 37/255, .25)

	self.Health.Name:SetPoint("LEFT", self.Health, "LEFT", 2, 0)
	self.Health.Name:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.Health.Name:SetHeight(14)
	self.Health.Name:SetWidth(260-94)
	self.Health.Name:SetTextColor(1, 1, 1)
	self.Health.Name:SetJustifyH("LEFT")
	self.Health.Name:SetShadowOffset(.8, -.8)
	self.Health.Name:SetShadowColor(0, 0, 0, 1)

	self.Health.Points:SetPoint("LEFT", self.Health, "RIGHT", 3, 0)
	self.Health.Points:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.Health.Points:SetHeight(14)
	self.Health.Points:SetWidth(76)
	self.Health.Points:SetTextColor(1, 1, 1)
	self.Health.Points:SetJustifyH("CENTER")
	self.Health.Points:SetShadowOffset(.8, -.8)
	self.Health.Points:SetShadowColor(0, 0, 0, 1)

	self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -3)
	self.Power:SetWidth(260-90)
	self.Power:SetHeight(14)
	self.Power:SetStatusBarTexture("Interface\\AddOns\\oUF\\textures\\glaze")
	self.Power:SetStatusBarColor(p.r1, p.g1, p.b1)
	
	self.PowerBG:SetPoint("TOP", self.Power, "TOP", 0, 0)
	self.PowerBG:SetWidth(260-90)
	self.PowerBG:SetHeight(14)
	self.PowerBG:SetStatusBarTexture("Interface\\AddOns\\oUF\\textures\\glaze")
	self.PowerBG:SetStatusBarColor(p.r1, p.g1, p.b1, .25)
	
	self.Power.Info:SetPoint("LEFT", self.Power, "LEFT", 2, 0)
	self.Power.Info:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.Power.Info:SetHeight(14)
	self.Power.Info:SetWidth(260-94)
	self.Power.Info:SetTextColor(1, 1, 1)
	self.Power.Info:SetJustifyH("LEFT")
	self.Power.Info:SetShadowOffset(.8, -.8)
	self.Power.Info:SetShadowColor(0, 0, 0, 1)

	self.Power.Points:SetPoint("LEFT", self.Power, "RIGHT", 3, 0)
	self.Power.Points:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.Power.Points:SetHeight(14)
	self.Power.Points:SetWidth(76)
	self.Power.Points:SetTextColor(1, 1, 1)
	self.Power.Points:SetJustifyH("CENTER")
	self.Power.Points:SetShadowOffset(.8, -.8)
	self.Power.Points:SetShadowColor(0, 0, 0, 1)

	local rows = 3
	for type, num in pairs({Buffs = 32, Debuffs = 40}) do
		self[type]:ClearAllPoints()
		if(type == "Buffs") then
			self[type]:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 3, 0)
		else
			self[type]:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 3, 0)
		end
		self[type][1]:ClearAllPoints()
		if(type == "Buffs") then
			self[type][1]:SetPoint("BOTTOMLEFT", self[type], "BOTTOMLEFT")
		else
			self[type][1]:SetPoint("TOPLEFT", self[type], "TOPLEFT")
		end

		for i=2,num do
			self[type][i]:ClearAllPoints()
			self[type][i]:SetPoint("LEFT", self[type][i-1], "RIGHT", 2, 0)
		end

		local prev
		for i=1, rows-1 do
			local start = math.ceil((num / rows)*i) + 1
			local point = prev or 1
			self[type][start]:ClearAllPoints()
			if(type == "Buffs") then
				self[type][start]:SetPoint("BOTTOMLEFT", self[type][point], "TOPLEFT", 0, 2)
			else
				self[type][start]:SetPoint("TOPLEFT", self[type][point], "BOTTOMLEFT", 0, -2)
			end
		
			prev = start
		end
	end
end

function oUF.class.frame:savePosition()
	local _, _, _, x, y = self:GetPoint()

	oUF.db.profile.pos[self.unit] = math.ceil(x).."#"..math.ceil(y)
end

function oUF.class.frame:loadPosition()
	local pos = oUF.db.profile.pos[self.unit]
	if(pos) then
		local x,y = strsplit("#", pos)
		self:SetPoint("TOPLEFT", nil, "TOPLEFT", x, y)
	else
		self:SetPoint("CENTER", nil, "CENTER")
	end
end

function oUF.class.frame.menu()
	local s = oUF.getUnitType(this.unit)
	local unit = oUF.getCapitalized(this.unit)
	if s == "party" or s == "partypet" then
		ToggleDropDownMenu(1, nil, G["PartyMemberFrame"..this:GetID().."DropDown"], "cursor", 0, 0)
	else
		ToggleDropDownMenu(1, nil, G[unit.."FrameDropDown"], "cursor", 0, 0)
	end
end
