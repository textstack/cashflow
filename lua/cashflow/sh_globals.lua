Cashflow.TYPES = {
	CASH = 0,
	BOUNTY = 1,
	STARS = 2
}

Cashflow.DEFAULT_TYPE = 0

-- also available:
-- HIDE_FROM_HUD = true
-- HIDE_FROM_BALANCE = true
Cashflow.TYPEINFO = {
	[0] = {
		NAME = "coins",
		ORDER = 0,
		PREFIX = "∇",
		COLOR = color_white,
		SHOW_WHEN_ZERO = true,
	},
	[1] = {
		NAME = "bounty",
		ORDER = 1000,
		PREFIX = "∇",
		POSTFIX = " bounty",
		POSTFIX_SINGULAR = " bounty",
		SUBJECT_PREFIX = "a ",
		COLOR = Color(255, 64, 64),
		CANNOT_BE_GIVEN = true,
		SHOW_ON_TARGETID = true
	},
	[2] = {
		NAME = "stars",
		ORDER = 1,
		PREFIX = "☆",
		COLOR = Color(255, 192, 0)
	},
}

Cashflow.MAX_AMOUNT = 4000000000
Cashflow.NET_TYPE = 4
Cashflow.NET_AMOUNT = 32

Cashflow.TYPESLOOKUP = {}
for k, v in pairs(Cashflow.TYPES) do
	Cashflow.TYPESLOOKUP[v] = k
end
