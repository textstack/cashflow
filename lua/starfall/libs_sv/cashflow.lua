--- Called when a player's cash is changed.
-- @server
-- @name cashflow_setcash
-- @class hook
-- @param Player ply The player whose cash is being changed
-- @param number cashType A number representing what type of cash is being changed
-- @param number amount The player's new cash amount after this change
-- @param string source A string representing the context for the change
SF.hookAdd("Cashflow_SetCash", "cashflow_setcash")

--- Called when a player's cash is changed while they are offline.
-- @server
-- @name cashflow_offlinesetcash
-- @class hook
-- @param string steamID The steamID of the player whose cash is being changed
-- @param number cashType A number representing what type of cash is being changed
-- @param number amount The player's new cash amount after this change
-- @param string source A string representing the context for the change
SF.hookAdd("Cashflow_OfflineSetCash", "cashflow_offlinesetcash")

--- Called when a player gives cash to another player.
-- @server
-- @name cashflow_transaction
-- @class hook
-- @param Player giver The player giving cash
-- @param Player receiver The player receiving cash
-- @param number amount The player's new cash amount after this change
-- @param number typeTake A number representing what type of cash the giver is losing
-- @param number typeGive A number representing what type of cash the receiver is gaining
-- @param string source A string representing the context for the change
SF.hookAdd("Cashflow_Transaction", "cashflow_transaction")

--- Called when a player gives cash to an offline player.
-- @server
-- @name cashflow_offlinetransaction
-- @class hook
-- @param Player giver The player giving cash
-- @param string receiverID The steamID of the player receiving cash
-- @param number amount The player's new cash amount after this change
-- @param number typeTake A number representing what type of cash the giver is losing
-- @param number typeGive A number representing what type of cash the receiver is gaining
-- @param string source A string representing the context for the change
SF.hookAdd("Cashflow_OfflineTransaction", "cashflow_offlinetransaction")