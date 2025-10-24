local cvarIncomeAmount = CreateConVar("cashflow_income_amount", 1, FCVAR_ARCHIVE, "Set how much money people get every pay period.")
local cvarIncomeTime = CreateConVar("cashflow_income_time", 900, FCVAR_ARCHIVE, "Set the time between pay periods in seconds.")

local function bountyFunc(ply, attacker)
	local bounty = Cashflow.GetCash(ply, Cashflow.TYPES.BOUNTY)
	if bounty <= 0 then return end

	Cashflow.AddCash(attacker, Cashflow.DEFAULT_TYPE, bounty, "bounty_claim")
	Cashflow.SetCash(ply, Cashflow.TYPES.BOUNTY, 0, "bounty_claim")

	if ulx then
		ulx.fancyLogAdmin(attacker, player.GetAll(), "#A received #s for killing #T.", Cashflow.PrettifyCash(Cashflow.DEFAULT_TYPE, bounty, true), ply)
	end
end

local function starFunc(ply, attacker)
	local stars = Cashflow.GetCash(attacker, Cashflow.TYPES.STARS)
	if stars <= 0 then return end

	Cashflow.AddCash(attacker, Cashflow.TYPES.STARS, -1, "star_transfer")
	Cashflow.AddCash(ply, Cashflow.TYPES.STARS, 1, "star_transfer")
end

hook.Add("PlayerDeath", "Cashflow_Kiling", function(ply, _, attacker)
	if ply == attacker then return end
	if not IsValid(attacker) or not attacker:IsPlayer() then return end

	starFunc(ply, attacker)
	bountyFunc(ply, attacker)
end)

local giveIncome
function giveIncome()
	local amount = cvarIncomeAmount:GetInt()

	for _, ply in player.Iterator() do
		Cashflow.AddCash(ply, Cashflow.DEFAULT_TYPE, amount, "income")
	end

	timer.Create("cashflow_income", cvarIncomeTime:GetInt(), 1, giveIncome)
end

timer.Create("cashflow_income", 1, 1, giveIncome)
