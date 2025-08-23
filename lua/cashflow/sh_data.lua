Cashflow.Data = Cashflow.Data or {}

--- get how much cash a player has
function Cashflow.Data.GetCash(ply, cashType)
	if not IsValid(ply) or not ply:IsPlayer() then return 0 end
	if not Cashflow.TYPESLOOKUP[cashType] then return 0 end
	if not ply.Cash then return 0 end

	return ply.Cash[cashType] or 0
end

--- get how much cash a player has, then give a prettystring of it
function Cashflow.Data.GetCashStr(ply, cashType, isSubject)
	return Cashflow.Util.PrettifyCash(cashType, Cashflow.Data.GetCash(ply, cashType), isSubject)
end
