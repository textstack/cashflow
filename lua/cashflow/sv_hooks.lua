local cvarIncomeAmount = CreateConVar("cashflow_income_amount", 1, FCVAR_ARCHIVE, "Set how much money people get every pay period.")
local cvarIncomeTime = CreateConVar("cashflow_income_time", 900, FCVAR_ARCHIVE, "Set the time between pay periods in seconds.")

hook.Add("PlayerDeath", "Cashflow_Bounty", function(ply, _, attacker)
	if ply == attacker then return end
	if not IsValid(attacker) or not attacker:IsPlayer() then return end

	local bounty = Cashflow.GetCash(ply, Cashflow.TYPES.BOUNTY)
	if bounty <= 0 then return end

	Cashflow.AddCash(attacker, Cashflow.DEFAULT_TYPE, bounty)
	Cashflow.SetCash(ply, Cashflow.TYPES.BOUNTY, 0)

	if ulx then
		ulx.fancyLogAdmin(attacker, "#A received #s for killing #T.", Cashflow.PrettifyCash(Cashflow.DEFAULT_TYPE, bounty, true), ply)
	end
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
