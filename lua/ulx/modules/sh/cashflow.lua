local balance = ulx.command("Cashflow", "ulx balance", function(ply, target)
	local items = ply == target and {} or { target }
	for id, info in SortedPairsByMemberValue(Cashflow.TYPEINFO, "ORDER") do
		if info.HIDE_FROM_BALANCE then continue end

		local amount = Cashflow.GetCash(target, id)
		if amount <= 0 and not info.SHOW_WHEN_ZERO then continue end

		table.insert(items, Cashflow.PrettifyCash(id, amount, true))
	end

	local you = ply == target and "You have" or "#T has"
	local itemCount = ply == target and #items or #items - 1

	if itemCount == 1 then
		ulx.fancyLogAdmin(ply, { ply }, string.format("%s #s.", you), unpack(items))
	elseif itemCount == 2 then
		ulx.fancyLogAdmin(ply, { ply }, string.format("%s #s and #s.", you), unpack(items))
	else
		ulx.fancyLogAdmin(ply, { ply }, string.format("%s %sand #s.", you, string.rep("#s, ", itemCount - 1)), unpack(items))
	end
end, "!balance", true)
balance:addParam({ type = ULib.cmds.PlayerArg, ULib.cmds.ignoreCanTarget })
balance:defaultAccess(ULib.ACCESS_ALL)
balance:help("See how much money you have.")

local function findType(typeStr)
	local toFind = string.upper(string.Trim(typeStr))
	if toFind == "TYPE" then return Cashflow.DEFAULT_TYPE end

	local found = "No such currency exists!"
	for id, info in pairs(Cashflow.TYPEINFO) do
		if not string.find(string.upper(info.NAME), toFind) then continue end
		if type(found) == "number" then return "More than one type of currency matches your request!" end
		found = id
	end

	return found
end

local function givemoneyFunc(ply, target, amount, typeStr)
	if not target.Cashflow_Initialized then
		ULib.tsayError(ply, "This player hasn't initialized yet!", true)
		return
	end

	local cashType = Cashflow.DEFAULT_TYPE
	if typeStr and string.Trim(typeStr) ~= "" then
		cashType = findType(typeStr)

		if type(cashType) == "string" then
			ULib.tsayError(ply, cashType, true)
			return
		end
	end

	if Cashflow.TYPEINFO[cashType].CANNOT_BE_GIVEN then
		ULib.tsayError(ply, "You can't give this!", true)
		return
	end

	if not Cashflow.Purchase(ply, cashType, amount) then
		ULib.tsayError(ply, string.format("You don't have enough %s!", Cashflow.TYPEINFO[cashType].NAME), true)
		return
	end

	Cashflow.AddCash(target, cashType, amount, "givemoney")

	local amtStr = Cashflow.PrettifyCash(cashType, amount, true)
	ulx.fancyLogAdmin(target, { target }, "You received #s from #T.", amtStr, ply)
	ulx.fancyLogAdmin(ply, { ply }, "You gave #s to #T.", amtStr, target)
end

local givemoney = ulx.command("Cashflow", "ulx givemoney", givemoneyFunc, "!givemoney", true)
givemoney:addParam({ type = ULib.cmds.PlayerArg, target = "!^", ULib.cmds.ignoreCanTarget })
givemoney:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount" })
givemoney:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
givemoney:defaultAccess(ULib.ACCESS_ALL)
givemoney:help("Give money to another player.")

local givemoneyid = ulx.command("Cashflow", "ulx givemoneyid", function(ply, targetID, amount, typeStr)
	if targetID == ply:SteamID() then
		ULib.tsayError(ply, "You can't target yourself!", true)
		return
	end

	if ply.Cashflow_OfflineQuery and CurTime() - ply.Cashflow_OfflineQuery < 5 then
		ULib.tsayError(ply, "You're executing this command too fast!", true)
		return
	end
	ply.Cashflow_OfflineQuery = CurTime()

	local target = player.GetBySteamID(targetID)
	if IsValid(target) then
		givemoneyFunc(ply, target, amount, typeStr)
		return
	end

	local cashType = Cashflow.DEFAULT_TYPE
	if typeStr and string.Trim(typeStr) ~= "" then
		cashType = findType(typeStr)

		if type(cashType) == "string" then
			ULib.tsayError(ply, cashType, true)
			return
		end
	end

	if Cashflow.TYPEINFO[cashType].CANNOT_BE_GIVEN then
		ULib.tsayError(ply, "You can't give this!", true)
		return
	end

	local newCash = Cashflow.GetCash(ply, cashType) - amount
	if newCash < 0 then
		ULib.tsayError(ply, string.format("You don't have enough %s!", Cashflow.TYPEINFO[cashType].NAME), true)
		return
	end

	local success, err = Cashflow.AddCashOffline(targetID, cashType, amount, "givemoney")
	if not success then
		ULib.tsayError(ply, err, true)
		return
	end

	Cashflow.SetCash(ply, cashType, newCash, "purchase")

	local amtStr = Cashflow.PrettifyCash(cashType, amount, true)
	ulx.fancyLogAdmin(ply, { ply }, "You gave #s to #s.", amtStr, targetID)
end, "!givemoneyid", true)
givemoneyid:addParam({ type = ULib.cmds.StringArg, hint = "steamID" })
givemoneyid:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount" })
givemoneyid:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
givemoneyid:defaultAccess(ULib.ACCESS_ALL)
givemoneyid:help("Give money to another player who may be offline.")

local function bountyFunc(ply, target, amount)
	if not target.Cashflow_Initialized then
		ULib.tsayError(ply, "This player hasn't initialized yet!", true)
		return
	end

	if not Cashflow.Purchase(ply, Cashflow.DEFAULT_TYPE, amount) then
		ULib.tsayError(ply, string.format("You don't have enough %s!", Cashflow.TYPEINFO[Cashflow.DEFAULT_TYPE].NAME), true)
		return
	end

	Cashflow.AddCash(target, Cashflow.TYPES.BOUNTY, amount, "bounty")

	ulx.fancyLogAdmin(ply, "#A placed #s on #T.", Cashflow.PrettifyCash(Cashflow.TYPES.BOUNTY, amount, true), target)
end

local bounty = ulx.command("Cashflow", "ulx bounty", bountyFunc, "!bounty", true)
bounty:addParam({ type = ULib.cmds.PlayerArg, ULib.cmds.ignoreCanTarget })
bounty:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount" })
bounty:defaultAccess(ULib.ACCESS_ALL)
bounty:help("Place a bounty on a player.")

local bountyid = ulx.command("Cashflow", "ulx bountyid", function(ply, targetID, amount)
	if ply.Cashflow_OfflineQuery and CurTime() - ply.Cashflow_OfflineQuery < 5 then
		ULib.tsayError(ply, "You're executing this command too fast!", true)
		return
	end
	ply.Cashflow_OfflineQuery = CurTime()

	local target = player.GetBySteamID(targetID)
	if IsValid(target) then
		bountyFunc(ply, target, amount)
		return
	end

	local newCash = Cashflow.GetCash(ply, Cashflow.DEFAULT_TYPE) - amount
	if newCash < 0 then
		ULib.tsayError(ply, string.format("You don't have enough %s!", Cashflow.TYPEINFO[Cashflow.DEFAULT_TYPE].NAME), true)
		return
	end

	local success, err = Cashflow.AddCashOffline(targetID, Cashflow.TYPES.BOUNTY, amount, "bounty")
	if not success then
		ULib.tsayError(ply, err, true)
		return
	end

	Cashflow.SetCash(ply, Cashflow.DEFAULT_TYPE, newCash, "purchase")

	ulx.fancyLogAdmin(ply, "#A placed #s on #s.", Cashflow.PrettifyCash(Cashflow.TYPES.BOUNTY, amount, true), targetID)
end, "!bountyid", true)
bountyid:addParam({ type = ULib.cmds.StringArg, hint = "steamID" })
bountyid:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount" })
bountyid:defaultAccess(ULib.ACCESS_ALL)
bountyid:help("Place a bounty on a player who may be offline.")

local setmoney = ulx.command("Cashflow", "ulx setmoney", function(ply, target, amount, typeStr)
	if not target.Cashflow_Initialized then
		ULib.tsayError(ply, "This player hasn't initialized yet!", true)
		return
	end

	local cashType = Cashflow.DEFAULT_TYPE
	if typeStr and string.Trim(typeStr) ~= "" then
		cashType = findType(typeStr)

		if type(cashType) == "string" then
			ULib.tsayError(ply, cashType, true)
			return
		end
	end

	Cashflow.SetCash(target, cashType, amount, "setmoney")
	ulx.fancyLogAdmin(ply, "#A set the #s of #T.", Cashflow.TYPEINFO[cashType].NAME, target)
end, "!setmoney", true)
setmoney:addParam({ type = ULib.cmds.PlayerArg })
setmoney:addParam({ type = ULib.cmds.NumArg, min = 0, hint = "amount" })
setmoney:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
setmoney:defaultAccess(ULib.ACCESS_SUPERADMIN)
setmoney:help("Set the money of a player.")

local addmoney = ulx.command("Cashflow", "ulx addmoney", function(ply, target, amount, typeStr)
	if not target.Cashflow_Initialized then
		ULib.tsayError(ply, "This player hasn't initialized yet!", true)
		return
	end

	local cashType = Cashflow.DEFAULT_TYPE
	if typeStr and string.Trim(typeStr) ~= "" then
		cashType = findType(typeStr)

		if type(cashType) == "string" then
			ULib.tsayError(ply, cashType, true)
			return
		end
	end

	Cashflow.AddCash(target, cashType, amount, "addmoney")

	if amount >= 0 then
		ulx.fancyLogAdmin(ply, "#A added #s to #T.", Cashflow.TYPEINFO[cashType].NAME, target)
	else
		ulx.fancyLogAdmin(ply, "#A removed #s from #T.", Cashflow.TYPEINFO[cashType].NAME, target)
	end
end, "!addmoney", true)
addmoney:addParam({ type = ULib.cmds.PlayerArg })
addmoney:addParam({ type = ULib.cmds.NumArg, hint = "amount" })
addmoney:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
addmoney:defaultAccess(ULib.ACCESS_SUPERADMIN)
addmoney:help("Add or subtract money of a player.")
