local balance = ulx.command("Cashflow", "ulx balance", function(ply, target)
	local items = ply == target and {} or { target }
	for id, info in SortedPairsByMemberValue(Cashflow.TYPEINFO, "ORDER") do
		if info.HIDE_FROM_BALANCE then continue end

		local amount = Cashflow.Data.GetCash(target, id)
		if amount <= 0 and not info.SHOW_WHEN_ZERO then continue end

		table.insert(items, Cashflow.Util.PrettifyCash(id, amount, true))
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
balance:addParam({ type = ULib.cmds.PlayerArg })
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

local givemoney = ulx.command("Cashflow", "ulx givemoney", function(ply, target, amount, typeStr)
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

	if not Cashflow.Data.Purchase(ply, cashType, amount) then
		ULib.tsayError(ply, string.format("You don't have enough %s!", Cashflow.TYPEINFO[cashType].NAME), true)
		return
	end

	Cashflow.Data.AddCash(target, cashType, amount, "givemoney")

	local amtStr = Cashflow.Util.PrettifyCash(cashType, amount, true)
	ulx.fancyLogAdmin(target, { target }, "You received #s from #T.", amtStr, ply)
	ulx.fancyLogAdmin(ply, { ply }, "You gave #s to #T.", amtStr, target)
end, "!givemoney", true)
givemoney:addParam({ type = ULib.cmds.PlayerArg, target = "!^" })
givemoney:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount" })
givemoney:addParam({ type = ULib.cmds.StringArg, hint = "type", ULib.cmds.optional, ULib.cmds.takeRestOfLine })
givemoney:defaultAccess(ULib.ACCESS_ALL)
givemoney:help("Give money to another player.")

local bounty = ulx.command("Cashflow", "ulx bounty", function(ply, target, amount)
	if not target.Cashflow_Initialized then
		ULib.tsayError(ply, "This player hasn't initialized yet!", true)
		return
	end

	if not Cashflow.Data.Purchase(ply, Cashflow.DEFAULT_TYPE, amount) then
		ULib.tsayError(ply, string.format("You don't have enough %s!", Cashflow.TYPEINFO[Cashflow.DEFAULT_TYPE].NAME), true)
		return
	end

	Cashflow.Data.AddCash(target, Cashflow.TYPES.BOUNTY, amount, "bounty")

	ulx.fancyLogAdmin(ply, "#A placed #s on #T.", Cashflow.Util.PrettifyCash(Cashflow.TYPES.BOUNTY, amount, true), target)
end, "!bounty", true)
bounty:addParam({ type = ULib.cmds.PlayerArg })
bounty:addParam({ type = ULib.cmds.NumArg, min = 1, hint = "amount" })
bounty:defaultAccess(ULib.ACCESS_ALL)
bounty:help("Give money to another player.")

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

	Cashflow.Data.SetCash(target, cashType, amount, "setmoney")
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

	Cashflow.Data.AddCash(target, cashType, amount, "addmoney")

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
