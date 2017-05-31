local parent, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

function Private.UpdateArenaPreperation(self, event)
	if(event == 'ARENA_OPPONENT_UPDATE' and not self:IsEnabled()) then
		self:Enable()
		self:UnregisterEvent(event, Private.UpdateArenaPreperation)
	elseif(event == 'PLAYER_ENTERING_WORLD' and not UnitExists(self.unit)) then
		Private.UpdateArenaPreperation(self, 'ARENA_PREP_OPPONENT_SPECIALIZATIONS')
	elseif(event == 'ARENA_PREP_OPPONENT_SPECIALIZATIONS') then
		local specID = GetArenaOpponentSpec(tonumber(id))
		if(specID) then
			if(self:IsEnabled()) then
				self:Disable()
				self:RegisterEvent('ARENA_OPPONENT_UPDATE', Private.UpdateArenaPreperation)
			end

			self:Show()
		end
	end
end
