oUF.unit.player = oUF.class.unit:new("player")
oUF:NewModule("oUF_Player", oUF.unit.player)

function oUF.unit.player:Enable()
	self:disableBlizzard()
	self:loadPosition()

    self.energy = UnitMana('player')
    self.ticktime = 2.0

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "updateCombat")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "updateCombat")
	self:RegisterEvent("PLAYER_UPDATE_RESTING", "updateCombat")
	self:RegisterEvent("UNIT_ENERGY", "startTick")
end

function oUF.unit.player:createEnergyTick()
	local c = select(2, UnitClass("player"))

	if(c == "ROGUE" or c == "DRUID") then
		self:SetScript("OnUpdate", self.OnUpdate)
		self.Tick = self.Power:CreateTexture(nil, "OVERLAY")
		self.Tick:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		self.Tick:SetWidth(16)
		self.Tick:SetHeight(30)
		self.Tick:SetBlendMode("ADD")

		self.var = {
		}
	end
end

function oUF.unit.player:updateCombat()
	if(UnitAffectingCombat("player")) then
		self:SetBackdropBorderColor(.8, .3, .22)
	elseif(IsResting()) then
		self:SetBackdropBorderColor(.6, .6, 1)
	else
		self:SetBackdropBorderColor(.3, .3, .3)
	end
end

--[[ Based upon kEnergy by kergoth
	SVN: http://svn.wowace.com/wowace/trunk/kEnergy/
	ZIP: http://wowace.com/files/kEnergy/
]]
local prevtime
function oUF.unit.player:startTick(event, unit)
	if(unit ~= "player") then return end
	local time = GetTime()
	local maxen = UnitManaMax(unit)
	local olden = self.energy

	self.energy = UnitMana(unit)
	if self.energy ~= maxen and (self.energy - olden ~= 20 or self.energy - olden ~= 19 or self.energy - olden ~= 21) then
		return
	end
	
	if(not self.Tick) then self:createEnergyTick() end

	 -- Update our weighted average of energy tick time
	if prevtime and self.energyticking then
		-- there was a previous tick, and it was within this group of ticks
		self.ticktime = ((99.0 * self.ticktime) + (time - prevtime)) / 100.0
	end
	prevtime = time

	self.energyticking = self.energy ~= maxen
	if(UnitMana(unit) == maxen) then self.Tick:Hide() else self.Tick:Show() end
	self.var.maxValue = GetTime() + self.ticktime
	self.var.startTime = time
end

function oUF.unit.player:OnUpdate()
--	local n = this.var.maxValue - GetTime()
	local n = GetTime() - self.var.startTime

	local w = this.Power:GetWidth()
	local sp = ((n) / (this.var.maxValue - this.var.startTime)) * w
	if( sp < 0 ) then sp = 0 end
	if( sp > w ) then sp = w end
	this.Tick:SetPoint("CENTER", this.Power, "LEFT", sp, 0)
end

function oUF.unit.player:disableBlizzard()
	PlayerFrame:UnregisterAllEvents()
	PlayerFrame:Hide()
end
