--- return a string value of a cash amount in a pretty way
-- isSubject is used for grammar purposes
function Cashflow.PrettifyCash(cashType, amount, isSubject)
	local typeinfo = Cashflow.TYPEINFO[cashType]
	local value = string.Comma(amount)
	if not typeinfo then return value end

	local subj = ""
	if isSubject then
		subj = typeinfo.SUBJECT_PREFIX or ""
	end

	local postfix = "POSTFIX"
	if amount == 1 then
		postfix = "POSTFIX_SINGULAR"
	end

	return string.format("%s%s%s%s", subj, typeinfo.PREFIX or "", value, typeinfo[postfix] or "")
end

--- get how much cash a player has, then give a prettystring of it
function Cashflow.GetCashStr(ply, cashType, isSubject)
	return Cashflow.PrettifyCash(cashType, Cashflow.GetCash(ply, cashType), isSubject)
end

--- returns if a steamid is valid or not
function Cashflow.IsValidSteamID(steamID)
	return (Cashflow.BOTS_CVAR:GetBool() and steamID == "BOT") or string.match(steamID, "^STEAM_%d:%d:%d+$") ~= nil
end

--- sorts database fetch results by typeinfo order
function Cashflow.SortFetchResults(data)
	table.sort(data, function(a, b)
		if not a.cashType or not b.cashType then return true end

		local aType = Cashflow.TYPEINFO[tonumber(a.cashType)]
		local bType = Cashflow.TYPEINFO[tonumber(b.cashType)]

		if not aType or not bType then return true end

		local aOrder = aType.ORDER or 0
		local bOrder = bType.ORDER or 0

		return aOrder < bOrder
	end)
end

