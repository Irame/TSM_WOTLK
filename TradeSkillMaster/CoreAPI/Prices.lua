-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains price related TSMAPI functions.

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {context={}, itemValueKeyCache={}, moduleObjects=TSM.moduleObjects, customPriceCache={}, priceCache={}, priceCacheActive=nil, mappedWarning={}}
local ITEM_STRING_PATTERN = "[ip]:[0-9:\-]+"
local MONEY_PATTERNS = {
	"([0-9]+g[ ]*[0-9]+s[ ]*[0-9]+c)", 	-- g/s/c
	"([0-9]+g[ ]*[0-9]+s)", 				-- g/s
	"([0-9]+g[ ]*[0-9]+c)", 				-- g/c
	"([0-9]+s[ ]*[0-9]+c)", 				-- s/c
	"([0-9]+g)", 								-- g
	"([0-9]+s)", 								-- s
	"([0-9]+c)",								-- c
}
local MATH_FUNCTIONS = {
	["avg"] = "self._avg",
	["min"] = "self._min",
	["max"] = "self._max",
	["first"] = "self._first",
	["check"] = "self._check",
}
local NAN = math.huge*0
local NAN_STR = tostring(NAN)
local function isNAN(num) return tostring(num) == NAN_STR end



-- ============================================================================
-- TSM Functions
-- ============================================================================

function TSM:CreateCustomPriceSource(name, value)
	TSMAPI:Assert(name ~= "")
	TSMAPI:Assert(gsub(name, "([a-z]+)", "") == "")
	TSMAPI:Assert(not TSM.db.global.customPriceSources[name])
	TSM.db.global.customPriceSources[name] = value
	wipe(private.customPriceCache)
end

function TSM:RenameCustomPriceSource(oldName, newName)
	TSMAPI:Assert(TSM.db.global.customPriceSources[oldName])
	TSM.db.global.customPriceSources[newName] = TSM.db.global.customPriceSources[oldName]
	TSM.db.global.customPriceSources[oldName] = nil
	wipe(private.customPriceCache)
end

function TSM:DeleteCustomPriceSource(name)
	TSMAPI:Assert(TSM.db.global.customPriceSources[name])
	TSM.db.global.customPriceSources[name] = nil
	wipe(private.customPriceCache)
end



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI:ValidateCustomPrice(customPriceStr, badPriceSource)
	local func, err = private:ParseCustomPrice(customPriceStr, badPriceSource)
	return func and true or false, err
end

function TSMAPI:GetCustomPriceValue(customPriceStr, itemString, badPriceSource)
	local func, err = private:ParseCustomPrice(customPriceStr, badPriceSource)
	if not func then
		return nil, err
	end
	local startTime = debugprofilestop()
	local value = nil
	if not private.priceCacheActive then
		TSMAPI:Assert(not next(private.priceCache))
		private.priceCacheActive = true
		value = func(itemString)
		wipe(private.priceCache)
		private.priceCacheActive = nil
	else
		value = func(itemString)
	end
	if debugprofilestop() > startTime + 500 then
		TSM:LOG_WARN("Slow custom price: %s", customPriceStr)
	end
	return value
end

function TSMAPI:GetItemValue(itemString, key)
	itemString = TSMAPI.Item:ToItemString(itemString)
	if not itemString then return end

	-- look in module objects for this key
	if not private.itemValueKeyCache[key] then
		for _, obj in pairs(private.moduleObjects) do
			if obj.priceSources then
				for _, info in ipairs(obj.priceSources) do
					if info.key == key then
						private.itemValueKeyCache[key] = info
						break
					end
				end
				if private.itemValueKeyCache[key] then break end
			end
		end
	end
	if not private.itemValueKeyCache[key] then return end
	local info = private.itemValueKeyCache[key]
	if not info.takeItemString then
		-- this price source does not take an itemString, so pass it an itemLink instead
		itemString = TSMAPI.Item:GetLink(itemString)
		if not itemString then return end
	end
	local value = info.callback(itemString, info.arg)
	return (type(value) == "number" and value > 0) and value or nil
end

function TSMAPI:GetPriceSources()
	local sources, modules = {}, {}
	for _, obj in pairs(private.moduleObjects) do
		if obj.priceSources then
			for _, info in ipairs(obj.priceSources) do
				sources[info.key] = info.label
				modules[info.key] = obj.name
			end
		end
	end
	return sources, modules
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

private.customPriceFunctions = {
	NAN = NAN,
	NAN_STR = NAN_STR,
	isNAN = isNAN,
	loopError = function(str)
		TSM:Print(L["Loop detected in the following custom price:"].." "..TSMAPI.Design:GetInlineColor("link")..str.."|r")
	end,
	_avg = function(...)
		local total, count = 0, 0
		for i=1, select('#', ...) do
			local num = select(i, ...)
			if type(num) == "number" and not isNAN(num) then
				total = total + num
				count = count + 1
			end
		end
		if count == 0 then return NAN end
		return floor(total / count + 0.5)
	end,
	_min = function(...)
		local minVal
		for i=1, select('#', ...) do
			local num = select(i, ...)
			if type(num) == "number" and not isNAN(num) and (not minVal or num < minVal) then
				minVal = num
			end
		end
		return minVal or NAN
	end,
	_max = function(...)
		local maxVal
		for i=1, select('#', ...) do
			local num = select(i, ...)
			if type(num) == "number" and not isNAN(num) and (not maxVal or num > maxVal) then
				maxVal = num
			end
		end
		return maxVal or NAN
	end,
	_first = function(...)
		for i=1, select('#', ...) do
			local num = select(i, ...)
			if type(num) == "number" and not isNAN(num) then
				return num
			end
		end
		return NAN
	end,
	_check = function(...)
		if select('#', ...) > 3 then return NAN end
		local check, ifValue, elseValue = ...
		check = check or NAN
		ifValue = ifValue or NAN
		elseValue = elseValue or NAN
		return check > 0 and ifValue or elseValue
	end,
	_priceHelper = function(itemString, key, extraParam)
		itemString = TSMAPI.Item:ToItemString(itemString)
		if not itemString then return NAN end
		local cacheKey = itemString..key..tostring(extraParam)
		if not private.priceCache[cacheKey] then
			if key == "convert" then
				private.priceCache[cacheKey] = TSM.Conversions:GetConvertCost(itemString, extraParam) or NAN
			elseif extraParam == "custom" then
				private.priceCache[cacheKey] = TSMAPI:GetCustomPriceValue(TSM.db.global.customPriceSources[key], itemString) or NAN
			else
				private.priceCache[cacheKey] = TSMAPI:GetItemValue(itemString, key) or NAN
			end
		end
		return private.priceCache[cacheKey] or NAN
	end,
}

function private:CreateCustomPriceObj(func, origStr)
	local data = {isUnlocked=nil, globalContext=private.context, origStr=origStr}
	local proxy = newproxy(true)
	local mt = getmetatable(proxy)
	mt.__index = function(self, index)
		if private.customPriceFunctions[index] then
			return private.customPriceFunctions[index]
		elseif index == "globalContext" or index == "origStr" then
			return data[index]
		end
		if not data.isUnlocked then error("Attempt to access a hidden table", 2) end
		return data[index]
	end
	mt.__newindex = function(self, index, value)
		if not data.isUnlocked then error("Attempt to modify a hidden table", 2) end
		data[index] = value
	end
	mt.__call = function(self, item)
		data.isUnlocked = true
		local result = self.func(self, item)
		data.isUnlocked = false
		return result
	end
	mt.__metatable = false
	data.isUnlocked = true
	proxy.func = func
	data.isUnlocked = false
	return proxy
end

function private:ParsePriceString(str, badPriceSource)
	if tonumber(str) then
		return private:CreateCustomPriceObj(function() return tonumber(str) end, str)
	end

	local origStr = str
	-- make everything lower case and put a space at the start and end
	str = " "..strlower(str).." "
	-- remove any colors around gold/silver/copper
	while true do
		local num1, num2, num3
		str, num1 = gsub(str, "\124cff[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]g\124r", "g")
		str, num2 = gsub(str, "\124cff[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]s\124r", "s")
		str, num3 = gsub(str, "\124cff[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]c\124r", "c")
		if num1 + num2 + num3 == 0 then break end
	end
	-- replace old itemStrings with the new format
	str = gsub(str, "([^h]i)tem:([0-9:\-]+)", "%1:%2")

	-- replace all formatted gold amount with their copper value
	local start = 1
	local goldAmountContinue = true
	while goldAmountContinue do
		goldAmountContinue = false
		local minFind = {}
		for _, pattern in ipairs(MONEY_PATTERNS) do
			local s, e, sub = strfind(str, pattern, start)
			if s and (not minFind.s or minFind.s > s) then
				minFind.s = s
				minFind.e = e
				minFind.sub = sub
			end
		end
		if minFind.s then
			local value = TSMAPI:MoneyFromString(minFind.sub)
			if not value then return nil, L["Invalid function."] end -- sanity check
			local preStr = strsub(str, 1, minFind.s-1)
			local postStr = strsub(str, minFind.e+1)
			str = preStr .. value .. postStr
			start = #str - #postStr + 1
			goldAmountContinue = true
		end
	end

	-- remove up to 1 occurance of convert(priceSource[, item])
	local convertPriceSource, convertItem
	local convertParams = strmatch(str, "[^a-z]convert%((.-)%)")
	if convertParams then
		local convertItemLink = strmatch(convertParams, "\124c.-\124r")
		local convertItemString = strmatch(convertParams, ITEM_STRING_PATTERN)
		if convertItemLink then -- check for itemLink in convert params
			convertItem = TSMAPI.Item:ToItemString(convertItemLink)
			if not convertItem then
				return nil, L["Invalid item link."]  -- there's an invalid item link in the convertParams
			end
			convertPriceSource = strmatch(convertParams, "^ *(.-) *,")
		elseif convertItemString then -- check for itemString in convert params
			convertItem = convertItemString
			convertPriceSource = strmatch(convertParams, "^ *(.-) *,")
		else
			convertPriceSource = gsub(convertParams, ", *$", ""):trim()
		end
		if convertPriceSource and convertPriceSource == badPriceSource or convertPriceSource == "matprice" then
			return nil, format(L["You cannot use %s within convert() as part of this custom price."], convertPriceSource)
		end

		-- can't allow custom price sources in convert, so just check regular ones
		local isValidPriceSource = nil
		for key in pairs(TSMAPI:GetPriceSources()) do
			if strlower(key) == convertPriceSource then
				isValidPriceSource = true
				break
			end
		end
		if not isValidPriceSource then
			return nil, L["Invalid price source in convert."]
		end
		local num = 0
		str, num = gsub(str, "([^a-z])convert%(.-%)", "%1~convert~")
		if num > 1 then
			return nil, L["A maximum of 1 convert() function is allowed."]
		end
	end

	while true do
		local itemLink = strmatch(str, "\124c.*\124r")
		if not itemLink then break end
		local _, endIndex = strfind(itemLink, "\124r")
		itemLink = strsub(itemLink, 1, endIndex)
		local itemString = TSMAPI.Item:ToItemString(itemLink)
		if not itemString then return nil, L["Invalid item link."] end -- there's an invalid item link in the str
		str = gsub(str, TSMAPI.Util:StrEscape(itemLink), itemString)
	end

	-- make sure there's spaces on either side of math operators
	str = gsub(str, "[%-%+%/%*]", " %1 ")
	-- make sure there's a space to the right of % signs
	str = gsub(str, "[%%]", "%1 ")
	-- convert percentages to decimal numbers
	str = gsub(str, "([0-9%.]+)%%", "( %1 / 100 ) *")
	-- ensure a space before items and remove parentheses around items
	str = gsub(str, "%( ?("..ITEM_STRING_PATTERN..") ?%)", " %1")
	-- ensure a space on either side of parentheses and commas
	str = gsub(str, "[%(%),]", " %1 ")
	-- remove any occurances of more than one consecutive space
	str = gsub(str, " [ ]+", " ")

	-- ensure equal number of left/right parenthesis
	if select(2, gsub(str, "%(", "")) ~= select(2, gsub(str, "%)", "")) then return nil, L["Unbalanced parentheses."] end

	-- create array of valid price sources
	local priceSourceKeys = {}
	for key in pairs(TSMAPI:GetPriceSources()) do
		tinsert(priceSourceKeys, strlower(key))
	end
	for key in pairs(TSM.db.global.customPriceSources) do
		tinsert(priceSourceKeys, strlower(key))
	end

	-- validate all words in the string
	local parts = TSMAPI.Util:SafeStrSplit(str:trim(), " ")
	local i = 1
	while i <= #parts do
		local word = parts[i]
		if strmatch(word, "^[%-%+%/%*]$") then
			if i == #parts then
				return nil, L["Invalid operator at end of custom price."]
			end
			-- valid math operator
		elseif badPriceSource == word then
			-- price source that's explicitly invalid
			return nil, format(L["You cannot use %s as part of this custom price."], word)
		elseif tContains(priceSourceKeys, word) then
			-- make sure we're not trying to take the price source of a number
			if parts[i+1] == "(" and type(parts[i+2]) == "string" and not strfind(parts[i+2], "^[ip].*:") then
				return nil, L["Invalid parameter to price source."]
			end
			-- valid price source
		elseif tonumber(word) then
			-- make sure it's not an itemID (incorrect)
			if i > 2 and parts[i-1] == "(" and tContains(priceSourceKeys, parts[i-2]) then
				return nil, L["Invalid parameter to price source."]
			end
			-- valid number
		elseif strmatch(word, "^"..ITEM_STRING_PATTERN.."$") then
			-- make sure previous word was a price source
			if i > 1 and tContains(priceSourceKeys, parts[i-1]) then
				-- valid item parameter
			else
				return nil, L["Item links may only be used as parameters to price sources."]
			end
		elseif word == "(" then
			-- empty parenthesis are not allowed
			if not parts[i+1] or parts[i+1] == ")" then
				return nil, L["Empty parentheses are not allowed"]
			end
		elseif word == ")" then
			-- valid parenthesis
		elseif word == "," then
			if not parts[i+1] or parts[i+1] == ")" then
				return nil, L["Misplaced comma"]
			else
				-- we're hoping this is a valid comma within a function, will be caught by loadstring otherwise
			end
		elseif MATH_FUNCTIONS[word] then
			if not parts[i+1] or parts[i+1] ~= "(" then
				return nil, format(L["Invalid word: '%s'"], word)
			end
			-- valid math function
		elseif word == "~convert~" then
			-- valid convert statement
		elseif word:trim() == "" then
			-- harmless extra spaces
		elseif word == "disenchant" then
			return nil, format(L["The 'disenchant' price source has been replaced by the more general 'destroy' price source. Please update your custom prices."])
		else
			-- check if this is an operation export that they tried to use as a custom price
			if strfind(word, "^%^1%^t%^") then
				return nil, L["This looks like an exported operation and not a custom price."]
			end
			return nil, format(L["Invalid word: '%s'"], word)
		end
		i = i + 1
	end

	for key in pairs(TSMAPI:GetPriceSources()) do
		-- replace all "<priceSource> itemString" occurances with the proper parameters (with the itemString)
		str = gsub(str, format(" %s (%s)", strlower(key), ITEM_STRING_PATTERN), format(" self._priceHelper(\"%%1\", \"%s\")", key))
		-- replace all "<priceSource>" occurances with the proper parameters (with _item for the item)
		str = gsub(str, format(" %s$", strlower(key)), format(" self._priceHelper(_item, \"%s\")", key))
		str = gsub(str, format(" %s([^a-z])", strlower(key)), format(" self._priceHelper(_item, \"%s\")%%1", key))
		if strlower(key) == convertPriceSource then
			convertPriceSource = key
		end
	end

	for key in pairs(TSM.db.global.customPriceSources) do
		-- price sources need to have at least 1 capital letter for this algorithm to work, so temporarily give it one
		local startStr = str
		local tempKey = strupper(strsub(key, 1, 1))..strsub(key, 2)
		-- replace all "<customPriceSource> itemString" occurances with the proper parameters (with the itemString)
		str = gsub(str, format(" %s (%s)", strlower(key), ITEM_STRING_PATTERN), format(" self._priceHelper(\"%%1\", \"%s\", \"custom\")", tempKey))
		-- replace all "<customPriceSource>" occurances with the proper parameters (with _item for the item)
		str = gsub(str, format(" %s$", strlower(key)), format(" self._priceHelper(_item, \"%s\", \"custom\")", tempKey))
		str = gsub(str, format(" %s([^a-z])", strlower(key)), format(" self._priceHelper(_item, \"%s\", \"custom\")%%1", tempKey))
		if startStr ~= str then
			-- change custom price sources to the correct capitalization
			str = gsub(str, tempKey, key)
		end
	end

	-- replace "~convert~" appropriately
	if convertPriceSource then
		convertItem = convertItem and ('"'..convertItem..'"') or "_item"
		str = gsub(str, "~convert~", format("self._priceHelper(%s, \"convert\", \"%s\")", convertItem, convertPriceSource))
	end

	-- replace math functions with special custom function names
	for word, funcName in pairs(MATH_FUNCTIONS) do
		str = gsub(str, " "..word.." ", " "..funcName.." ")
	end

	-- finally, create and return the function
	local funcTemplate = [[
		return function(self, _item)
			local isTop
			local context = self.globalContext
			if not context.num then
				context.num = 0
				isTop = true
			end
			context.num = context.num + 1
			if context.num > 100 then
				if (context.lastPrint or 0) + 1 < time() then
					context.lastPrint = time()
					self.loopError(self.origStr)
				end
				return
			end

			local result = floor((%s) + 0.5)
			if context.num then
				context.num = context.num - 1
			end
			if isTop then
				context.num = nil
			end
			if not result or self.isNAN(result) or result <= 0 then return end
			return result
		end
	]]
	local func, loadErr = loadstring(format(funcTemplate, str), "TSMCustomPrice: "..origStr)
	if loadErr then
		loadErr = gsub(loadErr:trim(), "([^:]+):.", "")
		return nil, L["Invalid function."]..L[" Details: "]..loadErr
	end
	local success, func = pcall(func)
	if not success then return nil, L["Invalid function."] end
	return private:CreateCustomPriceObj(func, origStr)
end

function private:ParseCustomPrice(customPriceStr, badPriceSource)
	if not customPriceStr then return nil, L["Empty price string."] end
	customPriceStr = strlower(tostring(customPriceStr):trim())
	if customPriceStr == "" then return nil, L["Empty price string."] end

	if not private.customPriceCache[customPriceStr] then
		local func, err = private:ParsePriceString(customPriceStr, badPriceSource)
		if func and not err then
			private.customPriceCache[customPriceStr] = {isValid=true, func=func}
		else
			private.customPriceCache[customPriceStr] = {isValid=false, err=err}
		end
	end
	if private.customPriceCache[customPriceStr].isValid then
		return private.customPriceCache[customPriceStr].func
	else
		return nil, private.customPriceCache[customPriceStr].err
	end
end
