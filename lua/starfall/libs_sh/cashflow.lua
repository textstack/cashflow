--- Cashflow library
-- @name cashflow
-- @class library
-- @libtbl cashflow_library
SF.RegisterLibrary("cashflow")

return function(instance)
	local cashflow_library = instance.Libraries.cashflow
	local entUnwrap = instance.Types.Entity.Unwrap
	local env = instance.env

	--- Get the cash of an online player.
	-- @shared
	-- @param Player ply The player to get the amount of cash from
	-- @param number cashType A number representing what type of cash to get
	-- @return number The amount of cash the player has
	cashflow_library.getCash = function(ply, cashType)
		return Cashflow.GetCash(entUnwrap(ply), cashType)
	end

	--- Available currency types for Cashflow.
	-- @shared
	-- @name builtins_library.CASHFLOW_TYPE
	-- @class table
	-- @field CASH Generic money
	-- @field BOUNTY Money to be awarded a player's killer, shows on targetID
	-- @field STARS Secondary money, shows on targetID
	-- @field DEFAULT The default cash type
	env.CASHFLOW_TYPE = {
		CASH = Cashflow.TYPES.CASH,
		BOUNTY = Cashflow.TYPES.BOUNTY,
		STARS = Cashflow.TYPES.STARS,
		DEFAULT = Cashflow.DEFAULT_TYPE
	}
end