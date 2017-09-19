-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Conversions = TSM:NewModule("Conversions")
local private = {data={}, targetItemNameLookup=nil, sourceItemCache=nil, skippedConversions={}}
local MAX_CONVERSION_DEPTH = 3



-- ============================================================================
-- TSMAPI Functions - Conversions
-- ============================================================================

function TSMAPI.Conversions:Add(targetItem, sourceItem, rate, method)
	local origTargetItem, origSourceItem = targetItem, sourceItem
	targetItem = TSMAPI.Item:ToBaseItemString(targetItem)
	sourceItem = TSMAPI.Item:ToBaseItemString(sourceItem)
	TSMAPI:Assert(targetItem, format("Invalid targetItem %s.", origTargetItem))
	TSMAPI:Assert(sourceItem, format("Invalid sourceItem %s.", origSourceItem))
	private.data[targetItem] = private.data[targetItem] or {}
	if private.data[targetItem][sourceItem] then
		-- if there is more than one way to go from source to target, then just skip all conversions between these items
		private.skippedConversions[targetItem..sourceItem] = true
		private.data[targetItem][sourceItem] = nil
	end
	if private.skippedConversions[targetItem..sourceItem] then return end
	private.data[targetItem][sourceItem] = {rate=rate, method=method, hasItemInfo=nil}
	TSMAPI.Item:FetchInfo(targetItem)
	TSMAPI.Item:FetchInfo(sourceItem)
	private.targetItemNameLookup = nil
	private.sourceItemCache = nil
end

function TSMAPI.Conversions:GetData(targetItem)
	return private.data[targetItem]
end

function TSMAPI.Conversions:GetTargetItemByName(targetItemName)
	targetItemName = strlower(targetItemName)
	for itemString, data in pairs(private.data) do
		local name = TSMAPI.Item:GetName(itemString)
		if name and strlower(name) == targetItemName then
			return TSMAPI.Item:ToItemString(itemString)
		end
	end
	for _, data in pairs(TSM.STATIC_DATA.disenchantInfo) do
		for itemString in pairs(data) do
			if itemString ~= "desc" then
				local name = TSMAPI.Item:GetName(itemString)
				if name and strlower(name) == targetItemName then
					return TSMAPI.Item:ToItemString(itemString)
				end
			end
		end
	end
end

function TSMAPI.Conversions:GetTargetItemNames()
	if private.targetItemNameLookup then return private.targetItemNameLookup, true end
	local result = {}
	local completeResult = true
	for itemString in pairs(private.data) do
		local name = TSMAPI.Item:GetName(itemString)
		if name then
			tinsert(result, strlower(name))
		else
			completeResult = false
		end
	end
	for _, data in pairs(TSM.STATIC_DATA.disenchantInfo) do
		for itemString in pairs(data) do
			if itemString ~= "desc" then
				local name = TSMAPI.Item:GetName(itemString)
				if name then
					tinsert(result, strlower(name))
				else
					completeResult = false
				end
			end
		end
	end
	sort(result)
	if completeResult then
		-- remote duplicates
		for i=#result, 2, -1 do
			if result[i] == result[i-1] then
				tremove(result, i)
			end
		end
		private.targetItemNameLookup = result
	end
	return result, completeResult
end

function TSMAPI.Conversions:GetSourceItems(targetItem)
	if not targetItem then return end
	private.sourceItemCache = private.sourceItemCache or {}
	if not private.sourceItemCache[targetItem] then
		private.sourceItemCache[targetItem] = {}
		if private.data[targetItem] then
			private.sourceItemCache[targetItem].convert = {}
			private.sourceItemCache[targetItem].convert[targetItem] = {depth=-1} -- temporarily set this so we don't loop back through the target item
			private:GetSourceItemsHelper(targetItem, private.sourceItemCache[targetItem].convert, 0, 1)
			private.sourceItemCache[targetItem].convert[targetItem] = nil
		end
		-- add disenchant info
		for _, data in ipairs(TSM.STATIC_DATA.disenchantInfo) do
			if data[targetItem] then
				private.sourceItemCache[targetItem].disenchant = data[targetItem]
				break
			end
		end
		if not next(private.sourceItemCache[targetItem]) then
			private.sourceItemCache[targetItem] = nil
		end
	end
	return private.sourceItemCache[targetItem]
end

function TSMAPI.Conversions:GetTargetItemsByMethod(method)
	local result = {}
	for itemString, items in pairs(private.data) do
		for _, info in pairs(items) do
			if info.method == method then
				tinsert(result, TSMAPI.Item:ToItemString(itemString))
				break
			end
		end
	end
	return result
end

function TSMAPI.Conversions:GetValue(sourceItem, customPrice, method)
	if not customPrice then return end

	-- calculate disenchant value first
	if TSMAPI.Item:IsDisenchantable(sourceItem) and (not method or method == "disenchant") then
		local quality = TSMAPI.Item:GetQuality(sourceItem)
		local ilvl = TSMAPI.Item:GetItemLevel(sourceItem) or 0
		local iType = GetItemClassInfo(TSMAPI.Item:GetClassId(sourceItem))
		local value = 0
		for _, data in ipairs(TSM.STATIC_DATA.disenchantInfo) do
			for itemString, itemData in pairs(data) do
				if itemString ~= "desc" then
					for _, deData in ipairs(itemData.sourceInfo) do
						if deData.itemType == iType and deData.rarity == quality and ilvl >= deData.minItemLevel and ilvl <= deData.maxItemLevel then
							local matValue = TSMAPI:GetCustomPriceValue(customPrice, itemString)
							if not matValue or matValue == 0 then return end
							value = value + matValue * deData.amountOfMats
						end
					end
				end
			end
		end

		value = floor(value)
		if value > 0 then
			return value
		end
	end

	-- calculate other conversion values
	local value = 0
	for targetItem, items in pairs(private.data) do
		if items[sourceItem] and ((not method and items[sourceItem].method ~= "craft") or items[sourceItem].method == method) then
			local matValue = TSMAPI:GetCustomPriceValue(customPrice, targetItem)
			value = value + (matValue or 0) * items[sourceItem].rate
		end
	end

	value = TSMAPI.Util:Round(value)
	return value > 0 and value or nil
end



-- ============================================================================
-- Module Code
-- ============================================================================

function Conversions:OnInitialize()
	for targetItem, sourceItems in pairs(TSM.STATIC_DATA.predefinedConversions) do
		for _, info in ipairs(sourceItems) do
			TSMAPI.Conversions:Add(targetItem, unpack(info))
		end
	end
	for _, data in pairs(TSM.STATIC_DATA.disenchantInfo) do
		for itemString in pairs(data) do
			if itemString ~= "desc" then
				TSMAPI.Item:FetchInfo(itemString)
			end
		end
	end
end

function Conversions:GetConvertCost(targetItem, priceSource)
	local conversions = TSMAPI.Conversions:GetSourceItems(targetItem)
	if not conversions or not conversions.convert then return end

	local minPrice = nil
	for itemString, info in pairs(conversions.convert) do
		if info.method ~= "craft" then -- ignore crafting conversions for convert cost
			local price = TSMAPI:GetItemValue(itemString, priceSource)
			if price then
				price = price / info.rate
				minPrice = min(minPrice or price, price)
			end
		end
	end
	return minPrice
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:GetSourceItemsHelper(targetItem, result, depth, currentRate)
	if depth >= MAX_CONVERSION_DEPTH then return end
	if not private.data[targetItem] then return end
	for sourceItem, info in pairs(private.data[targetItem]) do
		if not result[sourceItem] or result[sourceItem].depth > depth then
			result[sourceItem] = result[sourceItem] or {}
			result[sourceItem].rate = info.rate * currentRate
			result[sourceItem].method = (depth == 0) and info.method or "multiple"
			result[sourceItem].depth = depth
			if info.method == "mill" or info.method == "prospect" then
				result[sourceItem].requiresFive = true
			end
			private:GetSourceItemsHelper(sourceItem, result, depth+1, result[sourceItem].rate)
		end
	end
end
