util.AddNetworkString("cashflow")

sql.Query("CREATE TABLE IF NOT EXISTS cashflow ( id TEXT PRIMARY KEY ON CONFLICT REPLACE, steamID TEXT, cashType INTEGER, amount INTEGER );")

Cashflow.Data = Cashflow.Data or {}

--- set how much cash a player has
function Cashflow.Data.SetCash(ply, cashType, amount, _source, noPush)
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

	Cashflow.Data.PushCash(ply, cashType, amount)
end

function Cashflow.Data.SetCashOffline(steamID, cashType, amount, _source)
	local ply = player.GetBySteamID(steamID)
	if ply then
		Cashflow.Data.SetCash(ply, cashType, amount, _source)
		return
	end

	if not Cashflow.TYPESLOOKUP[cashType] then return end

	_source = _source or "direct"

	local result = hook.Run("Cashflow_SetCashOffline", steamID, cashType, amount, _source)
	if type(result) == "number" then
		amount = result
	end

	amount = math.floor(math.Clamp(amount, 0, Cashflow.MAX_AMOUNT))

	Cashflow.Data.PushCash(steamID, cashType, amount)
end

--- add cash to a player
function Cashflow.Data.AddCash(ply, cashType, amount, _source)
	_source = _source or "direct_add"
	Cashflow.Data.SetCash(ply, cashType, Cashflow.Data.GetCash(ply, cashType) + amount, _source)
end

--- make a purchase and return whether the purchase was successful
function Cashflow.Data.Purchase(ply, cashType, price)
	local newCash = Cashflow.Data.GetCash(ply, cashType) - price
	if newCash < 0 then return false end

	Cashflow.Data.SetCash(ply, cashType, newCash, "purchase")
	return true
end

--- get all of a player's cash info from the database
function Cashflow.Data.FetchAllCash(ply, callback)
	if not IsValid(ply) then return end

	local data = sql.Query(string.format("SELECT * FROM cashflow WHERE steamID = %s;", sql.SQLStr(ply:SteamID())))

	if callback then
		callback(data or {})
	end
end

local pushCash = {}

--- push cash data into the database
-- amount is only needed if supplying a steamid
function Cashflow.Data.PushCash(plyOrSteamID, cashType, amount)
	if type(plyOrSteamID) == "string" then
		pushCash[plyOrSteamID .. "_" .. cashType] = {
			sql.SQLStr(plyOrSteamID),
			cashType,
			amount
		}
	else
		if not IsValid(plyOrSteamID) then return end

		pushCash[plyOrSteamID:SteamID() .. "_" .. cashType] = {
			sql.SQLStr(plyOrSteamID:SteamID()),
			cashType,
			amount or Cashflow.Data.GetCash(plyOrSteamID, cashType)
		}
	end

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

	Cashflow.Data.FetchAllCash(ply, function(data)
		if not ply:IsValid() then return end

		for _, row in ipairs(data) do
			Cashflow.Data.SetCash(ply, tonumber(row.cashType), tonumber(row.amount), "initialize", true)
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
