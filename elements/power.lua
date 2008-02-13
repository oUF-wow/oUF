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

local type = type
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType

local power = oUF.colors.power
local min, max, bar, color

function oUF:UNIT_MANA(event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdatePower) then self:PreUpdatePower(event, unit) end

	min, max = UnitMana(unit), UnitManaMax(unit)
	bar = self.Power
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	if(not self.OverrideUpdatePower) then
		-- TODO: Rewrite this block.
		color = power[UnitPowerType(unit)]
		bar:SetStatusBarColor(color.r, color.g, color.b)

		if(bar.bg) then
			bar.bg:SetVertexColor(color.r*.5, color.g*.5, color.b*.5)
		end
	else
		self:OverrideUpdatePower(event, bar, unit, min, max)
	end

	if(self.PostUpdatePower) then self:PostUpdatePower(event, bar, unit, min, max) end
end

oUF.UNIT_RAGE = oUF.UNIT_MANA
oUF.UNIT_FOCUS = oUF.UNIT_MANA
oUF.UNIT_ENERGY = oUF.UNIT_MANA
oUF.UNIT_MAXMANA = oUF.UNIT_MANA
oUF.UNIT_MAXRAGE = oUF.UNIT_MANA
oUF.UNIT_MAXFOCUS = oUF.UNIT_MANA
oUF.UNIT_MAXENERGY = oUF.UNIT_MANA
oUF.UNIT_DISPLAYPOWER = oUF.UNIT_MANA
