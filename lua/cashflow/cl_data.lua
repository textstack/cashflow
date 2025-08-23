net.Receive("cashflow", function()
	local ply = net.ReadEntity()
	if not IsValid(ply) then return end

	local cashType = net.ReadUInt(Cashflow.NET_TYPE)
	local amount = net.ReadUInt(Cashflow.NET_AMOUNT)

	ply.Cash = ply.Cash or {}
	ply.Cash[cashType] = amount
end)
