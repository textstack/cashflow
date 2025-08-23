Cashflow.Util = Cashflow.Util or {}

--- return a string value of a cash amount in a pretty way
-- isSubject is used for grammar purposes
function Cashflow.Util.PrettifyCash(cashType, amount, isSubject)
	local typeinfo = Cashflow.TYPEINFO[cashType]
	local value = string.Comma(amount)
	if not typeinfo then return value end

	local subj = ""
	if isSubject then
		subj = typeinfo.SUBJECT_PREFIX or ""
	end

	local postfix = "POSTFIX"
	if amount == 1 then
		postfix = "POSTFIX_SINGULAR"
	end

	return string.format("%s%s%s%s", subj, typeinfo.PREFIX or "", value, typeinfo[postfix] or "")
end
