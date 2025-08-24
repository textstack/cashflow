--- get how much cash a player has
function Cashflow.GetCash(ply, cashType)
	if not IsValid(ply) or not ply:IsPlayer() then return 0 end
	if not Cashflow.TYPESLOOKUP[cashType] then return 0 end
	if not Cashflow.BOTS_CVAR:GetBool() and ply:IsBot() then return 0 end
	if not ply.Cash then return 0 end

	return ply.Cash[cashType] or 0
end
