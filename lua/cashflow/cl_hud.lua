surface.CreateFont("CashflowHUD", {
	font = "Arial",
	size = 32
})

local dark1 = Color(0, 0, 0, 120)
local dark2 = Color(0, 0, 0, 50)

hook.Add("HUDPaint", "Cashflow_HUD", function()
	local ply = LocalPlayer()

	local y = 0
	for id, info in SortedPairsByMemberValue(Cashflow.TYPEINFO, "ORDER") do
		if info.HIDE_FROM_HUD then continue end

		local amount = Cashflow.GetCash(ply, id)
		if amount <= 0 and not info.SHOW_WHEN_ZERO then continue end

		draw.TextShadow({
			text = Cashflow.PrettifyCash(id, amount),
			font = "CashflowHUD",
			pos = { 0, y },
			color = info.COLOR or color_white
		}, 2)

		y = y + 32
	end

	local trace = ply:GetEyeTrace()
	if not trace.Hit then return end
	if not trace.HitNonWorld then return end
	if trace.Entity == NULL or not trace.Entity:IsPlayer() then return end
	if not Cashflow.BOTS_CVAR:GetBool() and trace.Entity:IsBot() then return end

	local text = trace.Entity:Nick()
	local font = "TargetIDSmall"

	surface.SetFont(font)
	local _, h = surface.GetTextSize(text)

	local MouseX, MouseY = input.GetCursorPos()

	if MouseX == 0 and MouseY == 0 or not vgui.CursorVisible() then
		MouseX = ScrW() / 2
		MouseY = ScrH() / 2
	end

	local x = MouseX
	y = MouseY

	y = y + 30
	y = y + 2 * h + 12

	-- not the best to do sortedpairs twice for the same table...
	for id, info in SortedPairsByMemberValue(Cashflow.TYPEINFO, "ORDER") do
		if not info.SHOW_ON_TARGETID then continue end

		local amount = Cashflow.GetCash(trace.Entity, id)
		if amount <= 0 and not info.SHOW_WHEN_ZERO then continue end

		local str = Cashflow.PrettifyCash(id, amount)

		draw.SimpleText(str, font, x + 1, y + 1, dark1, TEXT_ALIGN_CENTER)
		draw.SimpleText(str, font, x + 2, y + 2, dark2, TEXT_ALIGN_CENTER)
		draw.SimpleText(str, font, x, y, info.COLOR or color_white, TEXT_ALIGN_CENTER)

		y = y + h + 5
	end
end)