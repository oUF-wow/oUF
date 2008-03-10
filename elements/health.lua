--[[-------------------------------------------------------------------------
  Copyright (c) 2006-2008, Trond A Ekseth
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
      * Neither the name of oUF nor the names of its contributors may
        be used to endorse or promote products derived from this
        software without specific prior written permission.

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

local select = select
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsPlayer = UnitIsPlayer
local UnitIsConnected = UnitIsConnected
local GetPetHappiness = GetPetHappiness
local UnitClass = UnitClass
local UnitReactionColor = UnitReactionColor
local UnitReaction = UnitReaction
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local health = oUF.colors.health
local happiness = oUF.colors.happiness
local min, max, bar, color

function oUF:UNIT_HEALTH(event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdateHealth) then self:PreUpdateHealth(event, unit) end

	min, max = UnitHealth(unit), UnitHealthMax(unit)
	bar = self.Health
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	if(not self.OverrideUpdateHealth) then
		-- TODO: Rewrite this block.
		if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
			color = health[1]
		elseif(unit == "pet" and GetPetHappiness()) then
			color = happiness[GetPetHappiness()]
		else
			color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or UnitReactionColor[UnitReaction(unit, "player")]
		end
		if(color) then
			bar:SetStatusBarColor(color.r, color.g, color.b)

			if(bar.bg) then
				bar.bg:SetVertexColor(color.r*.5, color.g*.5, color.b*.5)
			end
		end
	else
		self:OverrideUpdateHealth(event, bar, unit, min, max)
	end

	if(self.PostUpdateHealth) then self:PostUpdateHealth(event, bar, unit, min, max) end
end
oUF.UNIT_MAXHEALTH = oUF.UNIT_HEALTH
