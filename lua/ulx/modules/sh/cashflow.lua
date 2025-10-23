local function getCashType(ply, typeStr)
	if not typeStr then return Cashflow.DEFAULT_TYPE end
	if type(typeStr) == "number" then return typeStr end

	typeStr = string.upper(string.Trim(typeStr))
	if typeStr == "" or typeStr == "TYPE" then return Cashflow.DEFAULT_TYPE end

	local found
	for id, info in pairs(Cashflow.TYPEINFO) do
		if not string.find(string.upper(info.NAME), typeStr) then continue end

		if found then
			ULib.tsayError(ply, "More than one type of currency matches your request!", true)
			return
		end

		found = id
	end

	if not found then
		ULib.tsayError(ply, "No such currency exists!", true)
		return
	end

	return found
end

local function onlineMoneyCheck(ply, target, typeStr)
	if not target.Cashflow_Initialized then
		ULib.tsayError(ply, "This player hasn't initialized yet!", true)
		return
	end

	if not Cashflow.BOTS_CVAR:GetBool() and target:IsBot() then
		ULib.tsayError(ply, "You can't target bots!")
		return
	end

	return getCashType(ply, typeStr)
end

local function offlineMoneyCheck(ply, targetID, typeStr, onlineFunc, ...)
	if ply.Cashflow_OfflineQuery and CurTime() - ply.Cashflow_OfflineQuery < Cashflow.OFFLINE_COMMAND_COOLDOWN then
		ULib.tsayError(ply, "You're executing this command too fast!", true)
		return
	end
	ply.Cashflow_OfflineQuery = CurTime()

	if not Cashflow.IsValidSteamID(targetID) then
		ULib.tsayError(ply, "Invalid steamid.")
		return
	end

	local target = player.GetBySteamID(targetID)
	if IsValid(target) then
		onlineFunc(ply, target, ...)
		return
	end

	return getCashType(ply, typeStr)
end

local function onlineTransaction(ply, target, amount, typeTake, typeGive, _source)
	if not Cashflow.Purchase(ply, typeTake, amount) then
		ULib.tsayError(ply, string.format("You don't have enough %s!", Cashflow.TYPEINFO[typeTake].NAME), true)
		return false
	end

	Cashflow.AddCash(target, typeGive, amount, _source)
	return true
end

local function offlineTransaction(ply, targetID, amount, typeTake, typeGive, _source)
	local newCash = Cashflow.GetCash(ply, typeTake) - amount
	if newCash < 0 then
		ULib.tsayError(ply, string.format("You don't have enough %s!", Cashflow.TYPEINFO[typeTake].NAME), true)
		return false
	end

	local success, err = Cashflow.AddCashOffline(targetID, typeGive, amount, _source)
	if not success then
		ULib.tsayError(ply, err, true)
		return false
	end

	Cashflow.SetCash(ply, typeTake, newCash, "purchase")
	return true
end

local function balanceFunc(ply, target)
	if not onlineMoneyCheck(ply, target) then return end

	local items = {}
	for id, info in SortedPairsByMemberValue(Cashflow.TYPEINFO, "ORDER") do
		if info.HIDE_FROM_BALANCE then continue end

		local amount = Cashflow.GetCash(target, id)
		if amount <= 0 and not info.SHOW_WHEN_ZERO then continue end

		table.insert(items, Cashflow.PrettifyCash(id, amount, true))
	end

	local have = ply == target and "have" or "has"
	local itemCount = #items

	local str
	if itemCount == 0 then
		str = string.format("#T %s nothing.", have)
	elseif itemCount == 1 then
		str = string.format("#T %s #s.", have)
	elseif itemCount == 2 then
		str = string.format("#T %s #s and #s.", have)
	else
		str = string.format("#T %s %sand #s.", have, string.rep("#s, ", itemCount - 1))
	end

	ulx.fancyLogAdmin(ply, { ply }, str, target, unpack(items))
end

local balance = ulx.command("Cashflow", "ulx balance", balanceFunc, "!balance", true)
balance:addParam({ type = ULib.cmds.PlayerArg, ULib.cmds.ignoreCanTarget })
balance:defaultAccess(ULib.ACCESS_ALL)
balance:help("See how much money a player has.")

local balanceid = ulx.command("Cashflow", "ulx balanceid", function(ply, targetID)
	if not offlineMoneyCheck(ply, targetID, nil, balanceFunc) then return end

	Cashflow._FetchAllCash(targetID, function(data)
		Cashflow.SortFetchResults(data)

		local items = {}
		for _, row in ipairs(data) do
			local amount = tonumber(row.amount)
			local cashtype = tonumber(row.cashType)
			local info = Cashflow.TYPEINFO[cashtype]

			if not info then continue end
			if info.HIDE_FROM_BALANCE then continue end
			if amount <= 0 and not info.SHOW_WHEN_ZERO then continue end

			table.insert(items, Cashflow.PrettifyCash(cashtype, amount, true))
		end

		local itemCount = #items

		local str
		if itemCount == 0 then
			str = "#s has nothing."
		elseif itemCount == 1 then
			str = "#s has #s."
		elseif itemCount == 2 then
			str = "#s has #s and #s."
		else
			str = string.format("#s has %sand #s.", string.rep("#s, ", itemCount - 1))
		end

		ulx.fancyLogAdmin(ply, { ply }, str, targetID, unpack(items))
	end)
end, "!balanceid", true)
balanceid:addParam({ type = ULib.cmds.StringArg, hint = "steamid" })
balanceid:defaultAccess(ULib.ACCESS_ALL)
balanceid:help("See how much money a potentially offline player has.")

local function givemoneyFunc(ply, target, amount, typeStr)
	local cashType = onlineMoneyCheck(ply, target, typeStr)
	if not cashType then return end

	if Cashflow.TYPEINFO[cashType].CANNOT_BE_GIVEN then
		ULib.tsayError(ply, "You can't give this!", true)
		return
	end

	if not onlineTransaction(ply, target, amount, cashType, cashType, "givemoney") then return end

	local amtStr = Cashflow.PrettifyCash(cashType, amount, true)
	ulx.fancyLogAdmin(target, { target }, "#A received #s from #T.", amtStr, ply)
	ulx.fancyLogAdmin(ply, { ply }, "#A gave #s to #T.", amtStr, target)
end

local givemoney = ulx.command("Cashflow", "ulx givemoney", givemoneyFunc, "!givemoney", true)
givemoney:addParam({ type = ULib.cmds.PlayerArg, target = "!^", ULib.cmds.ignoreCanTarget })
givemoney:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount", ULib.cmds.round })
givemoney:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
givemoney:defaultAccess(ULib.ACCESS_ALL)
givemoney:help("Give money to another player.")

local givemoneyid = ulx.command("Cashflow", "ulx givemoneyid", function(ply, targetID, amount, typeStr)
	if targetID == ply:SteamID() then
		ULib.tsayError(ply, "You can't target yourself!", true)
		return
	end

	local cashType = offlineMoneyCheck(ply, targetID, typeStr, givemoneyFunc, amount, typeStr)
	if not cashType then return end

	if Cashflow.TYPEINFO[cashType].CANNOT_BE_GIVEN then
		ULib.tsayError(ply, "You can't give this!", true)
		return
	end

	if not offlineTransaction(ply, targetID, amount, cashType, cashType, "givemoney") then return end

	local amtStr = Cashflow.PrettifyCash(cashType, amount, true)
	ulx.fancyLogAdmin(ply, { ply }, "You gave #s to #s.", amtStr, targetID)
end, "!givemoneyid", true)
givemoneyid:addParam({ type = ULib.cmds.StringArg, hint = "steamid" })
givemoneyid:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount", ULib.cmds.round })
givemoneyid:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
givemoneyid:defaultAccess(ULib.ACCESS_ALL)
givemoneyid:help("Give money to another player who may be offline.")

local function bountyFunc(ply, target, amount)
	local cashType = onlineMoneyCheck(ply, target, Cashflow.DEFAULT_TYPE)
	if not cashType then return end

	if not onlineTransaction(ply, target, amount, cashType, Cashflow.TYPES.BOUNTY, "bounty") then return end

	ulx.fancyLogAdmin(ply, player.GetAll(), "#A placed #s on #T.", Cashflow.PrettifyCash(Cashflow.TYPES.BOUNTY, amount, true), target)
end

local bounty = ulx.command("Cashflow", "ulx bounty", bountyFunc, "!bounty", true)
bounty:addParam({ type = ULib.cmds.PlayerArg, ULib.cmds.ignoreCanTarget })
bounty:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount", ULib.cmds.round })
bounty:defaultAccess(ULib.ACCESS_ALL)
bounty:help("Place a bounty on a player.")

local bountyid = ulx.command("Cashflow", "ulx bountyid", function(ply, targetID, amount)
	local cashType = offlineMoneyCheck(ply, targetID, Cashflow.DEFAULT_TYPE, bountyFunc, amount)
	if not cashType then return end

	if not offlineTransaction(ply, targetID, amount, cashType, Cashflow.TYPES.BOUNTY, "bounty") then return end

	ulx.fancyLogAdmin(ply, player.GetAll(), "#A placed #s on #s.", Cashflow.PrettifyCash(Cashflow.TYPES.BOUNTY, amount, true), targetID)
end, "!bountyid", true)
bountyid:addParam({ type = ULib.cmds.StringArg, hint = "steamid" })
bountyid:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount", ULib.cmds.round })
bountyid:defaultAccess(ULib.ACCESS_ALL)
bountyid:help("Place a bounty on a player who may be offline.")

local function setmoneyFunc(ply, target, amount, typeStr)
	local cashType = onlineMoneyCheck(ply, target, typeStr)
	if not cashType then return end

	Cashflow.SetCash(target, cashType, amount, "setmoney")
	ulx.fancyLogAdmin(ply, "#A set the #s of #T.", Cashflow.TYPEINFO[cashType].NAME, target)
end

local setmoney = ulx.command("Cashflow", "ulx setmoney", setmoneyFunc, "!setmoney", true)
setmoney:addParam({ type = ULib.cmds.PlayerArg })
setmoney:addParam({ type = ULib.cmds.NumArg, min = 0, hint = "amount", ULib.cmds.round })
setmoney:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
setmoney:defaultAccess(ULib.ACCESS_SUPERADMIN)
setmoney:help("Set the money of a player.")

local setmoneyid = ulx.command("Cashflow", "ulx setmoneyid", function(ply, targetID, amount, typeStr)
	local cashType = offlineMoneyCheck(ply, targetID, typeStr, setmoneyFunc, amount, typeStr)
	if not cashType then return end

	local success, err = Cashflow.SetCashOffline(targetID, cashType, amount, "setmoney")
	if not success then
		ULib.tsayError(ply, err, true)
		return false
	end

	ulx.fancyLogAdmin(ply, "#A set the #s of #s.", Cashflow.TYPEINFO[cashType].NAME, targetID)
end, "!setmoneyid", true)
setmoneyid:addParam({ type = ULib.cmds.StringArg, hint = "steamid" })
setmoneyid:addParam({ type = ULib.cmds.NumArg, min = 0, hint = "amount", ULib.cmds.round })
setmoneyid:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
setmoneyid:defaultAccess(ULib.ACCESS_SUPERADMIN)
setmoneyid:help("Set the money of a player who may be offline.")

local function addmoneyFunc(ply, target, amount, typeStr)
	local cashType = onlineMoneyCheck(ply, target, typeStr)
	if not cashType then return end

	Cashflow.AddCash(target, cashType, amount, "addmoney")

	if amount >= 0 then
		ulx.fancyLogAdmin(ply, "#A added #s to #T.", Cashflow.TYPEINFO[cashType].NAME, target)
	else
		ulx.fancyLogAdmin(ply, "#A removed #s from #T.", Cashflow.TYPEINFO[cashType].NAME, target)
	end
end

local addmoney = ulx.command("Cashflow", "ulx addmoney", addmoneyFunc, "!addmoney", true)
addmoney:addParam({ type = ULib.cmds.PlayerArg })
addmoney:addParam({ type = ULib.cmds.NumArg, hint = "amount", ULib.cmds.round })
addmoney:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
addmoney:defaultAccess(ULib.ACCESS_SUPERADMIN)
addmoney:help("Add or subtract money of a player.")

local addmoneyid = ulx.command("Cashflow", "ulx addmoneyid", function(ply, targetID, amount, typeStr)
	local cashType = offlineMoneyCheck(ply, targetID, typeStr, setmoneyFunc, amount, typeStr)
	if not cashType then return end

	local success, err = Cashflow.AddCashOffline(targetID, cashType, amount, "addmoney")
	if not success then
		ULib.tsayError(ply, err, true)
		return false
	end

	if amount >= 0 then
		ulx.fancyLogAdmin(ply, "#A added #s to #s.", Cashflow.TYPEINFO[cashType].NAME, targetID)
	else
		ulx.fancyLogAdmin(ply, "#A removed #s from #s.", Cashflow.TYPEINFO[cashType].NAME, targetID)
	end
end, "!addmoneyid", true)
addmoneyid:addParam({ type = ULib.cmds.StringArg, hint = "steamid" })
addmoneyid:addParam({ type = ULib.cmds.NumArg, hint = "amount", ULib.cmds.round })
addmoneyid:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
addmoneyid:defaultAccess(ULib.ACCESS_SUPERADMIN)
addmoneyid:help("Add or subtract money of a player who may be offline.")

local pageAmount = 20

local bountylist = ulx.command("Cashflow", "ulx bountylist", function(ply, page)
	if ply.Cashflow_OfflineQuery and CurTime() - ply.Cashflow_OfflineQuery < Cashflow.OFFLINE_COMMAND_COOLDOWN then
		ULib.tsayError(ply, "You're executing this command too fast!", true)
		return
	end
	ply.Cashflow_OfflineQuery = CurTime()

	local count = sql.QueryValue(string.format("SELECT COUNT() from cashflow WHERE cashType = %s AND amount > 0;", Cashflow.TYPES.BOUNTY))
	if not count or count == "0" then
		ulx.fancyLogAdmin(ply, { ply }, "#sThere are no bounties on the server.", "")
		return
	end

	local pageCount = math.ceil(tonumber(count) / pageAmount)
	page = math.min(page, pageCount)

	local entries = sql.Query(string.format("SELECT * FROM cashflow WHERE cashType = %s AND amount > 0 ORDER BY amount DESC LIMIT %s OFFSET %s;", Cashflow.TYPES.BOUNTY, pageAmount, pageAmount * (page - 1)))
	if not entries or table.IsEmpty(entries) then
		ULib.tsayError(ply, "This page is empty!", true)
		return
	end

	local ulibQuery = {}
	for _, row in ipairs(entries) do
		table.insert(ulibQuery, sql.SQLStr(row.steamID))
	end
	ulibQuery = table.concat(ulibQuery, ", ")

	local names = {}
	local nameEntries = sql.Query(string.format("SELECT * FROM ulib_users WHERE steamid IN ( %s );", ulibQuery))
	if nameEntries then
		for _, row in ipairs(nameEntries) do
			if not row.name then continue end
			names[row.steamid] = row.name
		end
	end

	local msg = { string.format("---------- PAGE %s/%s ----------", page, pageCount) }
	local elems = {}
	for _, row in ipairs(entries) do
		local name = names[row.steamID]
		if name then
			table.insert(msg, string.format("%s (%s): #s", name, row.steamID))
		else
			table.insert(msg, string.format("%s: #s", row.steamID))
		end

		local amount = tonumber(row.amount)
		table.insert(elems, Cashflow.PrettifyCash(Cashflow.TYPES.BOUNTY, amount))
	end

	msg = table.concat(msg, "\n")
	ulx.fancyLogAdmin(ply, { ply }, msg, unpack(elems))
end, "!bountylist", true)
bountylist:addParam({ type = ULib.cmds.NumArg, min = 1, default = 1, hint = "page", ULib.cmds.round, ULib.cmds.optional})
bountylist:defaultAccess(ULib.ACCESS_ALL)
bountylist:help("Get a list of each bounty on record.")
