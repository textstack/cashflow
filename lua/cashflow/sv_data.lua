util.AddNetworkString("cashflow")

sql.Query("CREATE TABLE IF NOT EXISTS cashflow ( id TEXT PRIMARY KEY ON CONFLICT REPLACE, steamID TEXT, cashType INTEGER, amount INTEGER );")

--- set how much cash a player has
function Cashflow.SetCash(ply, cashType, amount, _source, noPush)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not Cashflow.TYPESLOOKUP[cashType] then return end
	if not noPush and not ply.Cashflow_Initialized then return end

	_source = _source or "direct"

	local result = hook.Run("Cashflow_SetCash", ply, cashType, amount, _source)
	if type(result) == "number" then
		amount = result
	end

	amount = math.floor(math.Clamp(amount, 0, Cashflow.MAX_AMOUNT))

	ply.Cash = ply.Cash or {}
	if ply.Cash[cashType] == amount then return end
	ply.Cash[cashType] = amount

	net.Start("cashflow")
	net.WriteEntity(ply)
	net.WriteUInt(cashType, Cashflow.NET_TYPE)
	net.WriteUInt(amount, Cashflow.NET_AMOUNT)
	net.Broadcast()

	if noPush then return end

	Cashflow._PushCash(ply:SteamID(), cashType, amount)
end

--- set the cash of an offline player
-- warning! requires an sql query every time you use it
-- returns whether operation was successful and a potential error message
function Cashflow.SetCashOffline(steamID, cashType, amount, _source)
	local ply = player.GetBySteamID(steamID)
	if IsValid(ply) then
		Cashflow.SetCash(ply, cashType, amount, _source)
		return true
	end

	if not Cashflow.TYPESLOOKUP[cashType] then return false, "Not a valid currency type!" end

	local q = sql.QueryValue(string.format("SELECT amount FROM cashflow WHERE steamID = %s LIMIT 1;", sql.SQLStr(steamID)))
	if not q then return false, "This player needs to be on our database first!" end

	_source = _source or "direct"

	local result = hook.Run("Cashflow_SetCashOffline", steamID, cashType, amount, _source)
	if type(result) == "number" then
		amount = result
	end

	amount = math.floor(math.Clamp(amount, 0, Cashflow.MAX_AMOUNT))

	Cashflow._PushCash(steamID, cashType, amount)

	return true
end

--- add cash to a player
function Cashflow.AddCash(ply, cashType, amount, _source)
	_source = _source or "direct_add"
	Cashflow.SetCash(ply, cashType, Cashflow.GetCash(ply, cashType) + amount, _source)
end

--- add cash to an offline player
-- warning! requires an sql query every time you use it
-- returns whether operation was successful and a potential error message
function Cashflow.AddCashOffline(steamID, cashType, amount, _source)
	local ply = player.GetBySteamID(steamID)
	if IsValid(ply) then
		Cashflow.AddCash(ply, cashType, amount, _source)
		return true
	end

	if not Cashflow.TYPESLOOKUP[cashType] then return false, "Not a valid currency type!" end

	local curCash = sql.QueryValue(string.format("SELECT amount FROM cashflow WHERE id = %s LIMIT 1;", sql.SQLStr(steamID .. "_" .. cashType)))
	if not curCash then
		local q = sql.QueryValue(string.format("SELECT amount FROM cashflow WHERE steamID = %s LIMIT 1;", sql.SQLStr(steamID)))
		if not q then return false, "This player needs to be on our database first!" end

		curCash = 0
	end

	amount = curCash + amount
	_source = _source or "direct_add"

	local result = hook.Run("Cashflow_SetCashOffline", steamID, cashType, amount, _source)
	if type(result) == "number" then
		amount = result
	end

	amount = math.floor(math.Clamp(amount, 0, Cashflow.MAX_AMOUNT))

	Cashflow._PushCash(steamID, cashType, amount)
	return true
end

--- make a purchase and return whether the purchase was successful
function Cashflow.Purchase(ply, cashType, price)
	local newCash = Cashflow.GetCash(ply, cashType) - price
	if newCash < 0 then return false end

	Cashflow.SetCash(ply, cashType, newCash, "purchase")
	return true
end

--- get all of a player's cash info from the database
-- internal
function Cashflow._FetchAllCash(steamID, callback)
	local data = sql.Query(string.format("SELECT * FROM cashflow WHERE steamID = %s;", sql.SQLStr(steamID)))

	if callback then
		callback(data or {})
	end
end

local pushCash = {}

--- push cash data into the database
-- internal
function Cashflow._PushCash(steamID, cashType, amount)
	pushCash[steamID .. "_" .. cashType] = { sql.SQLStr(steamID), cashType, amount }

	-- prevent the push from being hung up by spams
	if timer.Exists("cashflow_pushcash") then return end

	timer.Create("cashflow_pushcash", 1, 1, function()
		local data = {}
		for id, row in pairs(pushCash) do
			table.insert(data, string.format("( %s, %s, %s, %s )", sql.SQLStr(id), row[1], row[2], row[3]))
		end

		sql.Query(string.format("INSERT INTO cashflow ( id, steamID, cashType, amount ) VALUES %s;", table.concat(data, ", ")))

		pushCash = {}
	end)
end

gameevent.Listen("player_activate")
hook.Add("player_activate", "Cashflow_Initialize", function(plyData)
	local ply = Player(plyData.userid)

	for _, ply1 in player.Iterator() do
		if ply == ply1 then continue end

		local cash = ply1.Cash
		if not cash then continue end

		for cashType, amount in pairs(cash) do
			net.Start("cashflow")
			net.WriteEntity(ply)
			net.WriteUInt(cashType, Cashflow.NET_TYPE)
			net.WriteUInt(amount, Cashflow.NET_AMOUNT)
			net.Send(ply)
		end
	end

	Cashflow._FetchAllCash(ply:SteamID(), function(data)
		if not ply:IsValid() then return end

		for _, row in ipairs(data) do
			Cashflow.SetCash(ply, tonumber(row.cashType), tonumber(row.amount), "initialize", true)
		end

		ply.Cashflow_Initialized = true
	end)

	-- second chance to network everything
	timer.Simple(15, function()
		if not ply:IsValid() then return end

		for _, ply1 in player.Iterator() do
			local cash = ply1.Cash
			if not cash then continue end

			for cashType, amount in pairs(cash) do
				net.Start("cashflow")
				net.WriteEntity(ply)
				net.WriteUInt(cashType, Cashflow.NET_TYPE)
				net.WriteUInt(amount, Cashflow.NET_AMOUNT)
				net.Send(ply)
			end
		end
	end)
end)
