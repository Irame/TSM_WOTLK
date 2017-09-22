-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local AuctionTabUtil = TSM:NewModule("AuctionTabUtil", "AceHook-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table
local private = {rateCache={}}


-- ============================================================================
-- General Helper Functions
-- ============================================================================

function AuctionTabUtil:GetNumInBags(itemString)
	local num = 0
	local targetBaseItemString = TSMAPI.Item:ToBaseItemString(itemString)
	for _, _, itemString, quantity in TSMAPI.Inventory:BagIterator() do
		if TSMAPI.Item:ToBaseItemString(itemString) == targetBaseItemString then
			num = num + quantity
		end
	end
	return num
end

function AuctionTabUtil:GetItemLocation(targetItemString)
	local targetBaseItemString = TSMAPI.Item:ToBaseItemString(targetItemString)
	local baseItemBag, baseItemSlot, baseItemString = nil, nil, nil
	for bag, slot, itemString in TSMAPI.Inventory:BagIterator() do
		if TSMAPI.Item:ToBaseItemString(itemString) == targetBaseItemString then
			baseItemBag, baseItemSlot, baseItemString = bag, slot, itemString
		elseif itemString == targetItemString then
			return bag, slot, itemString, GetContainerItemLink(bag, slot)
		end
	end
	if not baseItemBag or not baseItemSlot then return end
	return baseItemBag, baseItemSlot, baseItemString, GetContainerItemLink(baseItemBag, baseItemSlot)
end

function AuctionTabUtil:GetCraftingFilterString(targetItem, ignoreDisenchant)
	if not targetItem then return end
	local convertData = TSMAPI.Conversions:GetSourceItems(targetItem)
	if not convertData then return end
	local filters = {TSMAPI.Item:GetName(targetItem).."/exact"}
	if convertData.convert then
		for itemString in pairs(convertData.convert) do
			tinsert(filters, TSMAPI.Item:GetName(itemString).."/exact")
		end
	end
	if convertData.disenchant and not ignoreDisenchant then
		local minRarities = {}
		for _, info in ipairs(convertData.disenchant.sourceInfo) do
			minRarities[info.itemType] = min(minRarities[info.itemType] or info.rarity, info.rarity)
		end
		for itemType, minRarity in pairs(minRarities) do
			tinsert(filters, "/" .. strjoin("/", itemType, _G["ITEM_QUALITY"..minRarity.."_DESC"], convertData.disenchant.minLevel, convertData.disenchant.maxLevel))
		end
	end
	return table.concat(filters, ";")
end

function AuctionTabUtil:GetConvertRate(targetItem, sourceItem, record)
	if targetItem == sourceItem then return 1 end
	if private.rateCache[targetItem.."-"..sourceItem] then return private.rateCache[targetItem.."-"..sourceItem] end
	local sourceItems = TSMAPI.Conversions:GetSourceItems(targetItem)
	if not sourceItems then return end
	if sourceItems.convert and sourceItems.convert[sourceItem] then
		return sourceItems.convert[sourceItem].rate, sourceItems.convert[sourceItem].requiresFive
	elseif sourceItems and sourceItems.disenchant then
		if not TSMAPI.Item:IsDisenchantable(sourceItem) then return end
		local quality = record and record.quality or TSMAPI.Item:GetQuality(sourceItem)
		local ilvl = record and record.itemLevel or TSMAPI.Item:GetItemLevel(sourceItem)
		local iType = GetItemClassInfo(TSMAPI.Item:GetClassId(sourceItem))
		for _, deData in ipairs(sourceItems.disenchant.sourceInfo) do
			if deData.itemType == iType and deData.rarity == quality and ilvl >= deData.minItemLevel and ilvl <= deData.maxItemLevel then
				private.rateCache[targetItem.."-"..sourceItem] = deData.amountOfMats
				return private.rateCache[targetItem.."-"..sourceItem]
			end
		end
	end
end



-- ============================================================================
-- Search Filter Helper Functions
-- ============================================================================

local function GetMaxQuantity(str)
	if #str > 1 and strsub(str, 1, 1) == "x" then
		return tonumber(strsub(str, 2))
	end
end

local function GetItemLevel(str)
	if #str > 1 and strsub(str, 1, 1) == "i" then
		return tonumber(strsub(str, 2))
	end
end

local function GetItemInventoryType(str)
	if not str then return end
	return TSMAPI.Item:GetInventorySlotIdFromInventorySlotString(str)
end

local function GetItemRarity(str)
	for i=0, 4 do
		local text =  _G["ITEM_QUALITY"..i.."_DESC"]
		if strlower(str) == strlower(text) then
			return i
		end
	end
end

local function GetSearchFilterOptions(searchTerm)
	local parts = {("/"):split(searchTerm)}
	local queryString, class, subClass, invType, minLevel, maxLevel, minILevel, maxILevel, rarity, usableOnly, exactOnly, evenOnly, maxQuantity, maxPrice

	if #parts == 0 then
		return false, L["Invalid Filter"]
	end

	-- deal with item strings
	if strmatch(parts[1], "^item:%d+$") then
		parts[1] = gsub(parts[1], "item:", "i:")
	elseif strmatch(parts[1], "^battlepet:%d+$") then
		parts[1] = gsub(parts[1], "battlepet:", "p:")
	end
	if strmatch(parts[1], "^[ip]:%d+$") then
		parts[1] = TSMAPI.Item:GetName(parts[1])
		if not parts[1] then
			return false, L["Invalid Filter"]
		end
	end

	for i, str in ipairs(parts) do
		str = str:trim()

		if i == 1 then
			queryString = str
		elseif tonumber(str) then
			if not minLevel then
				minLevel = tonumber(str)
			elseif not maxLevel then
				maxLevel = tonumber(str)
			else
				return false, L["Invalid Min Level"]
			end
		elseif GetMaxQuantity(str) then
			if not maxQuantity then
				maxQuantity = GetMaxQuantity(str)
			else
				return false, L["Invalid Max Quantity"]
			end
		elseif GetItemLevel(str) then
			if not minILevel then
				minILevel = GetItemLevel(str)
			elseif not maxILevel then
				maxILevel = GetItemLevel(str)
			else
				return false, L["Invalid Item Level"]
			end
		elseif not class and TSMAPI.Item:GetClassIdFromClassString(str) then
			if not class then
				class = TSMAPI.Item:GetClassIdFromClassString(str)
			else
				return false, L["Invalid Item Type"]
			end
		elseif class and TSMAPI.Item:GetSubClassIdFromSubClassString(str, class) then
			if not subClass then
				subClass = TSMAPI.Item:GetSubClassIdFromSubClassString(str, class)
			else
				return false, L["Invalid Item SubType"]
			end
		elseif GetItemInventoryType(str) then
			if not invType then
				invType = GetItemInventoryType(str)
			else
				return false, L["Invalid Item Inventory Type"]
			end
		elseif GetItemRarity(str) then
			if not rarity then
				rarity = GetItemRarity(str)
			else
				return false, L["Invalid Item Rarity"]
			end
		elseif strlower(str) == "usable" then
			if not usableOnly then
				usableOnly = true
			else
				return false, L["Invalid Usable Only Filter"]
			end
		elseif strlower(str) == "exact" then
			if not exactOnly then
				exactOnly = true
			else
				return false, L["Invalid Exact Only Filter"]
			end
		elseif strlower(str) == "even" then
			if not evenOnly then
				evenOnly = true
			else
				return false, L["Invalid Even Only Filter"]
			end
		elseif TSMAPI:MoneyFromString(str) then
			maxPrice = TSMAPI:MoneyFromString(str)
		else
			return false, L["Unknown Filter"]
		end
	end

	if maxLevel and minLevel and maxLevel < minLevel then
		local oldMaxLevel = maxLevel
		maxLevel = minLevel
		minLevel = oldMaxLevel
	end

	if maxILevel and minILevel and maxILevel < minILevel then
		local oldMaxILevel = maxILevel
		maxILevel = minILevel
		minILevel = oldMaxILevel
	end

	return true, queryString or "", class or nil, subClass or nil, invType or nil, minLevel or 0, maxLevel or 0, minILevel or 0, maxILevel or 0, rarity or 0, usableOnly or nil, exactOnly or nil, evenOnly or nil, maxQuantity or math.huge, maxPrice
end

-- gets all the filters for a given search term (possibly semicolon-deliminated list of search terms)
function AuctionTabUtil:ParseFilterString(searchQuery)
	local filters = {}
	local searchTerms = {(";"):split(searchQuery)}

	for i=1, #searchTerms do
		local searchTerm = searchTerms[i]:trim()
		if tonumber(searchTerm) then
			local filter = TSMAPI.Auction:GetItemQueryInfo(TSMAPI.Item:ToItemString(searchTerm))
			if filter then
				tinsert(filters, filter)
			end
		else
			local isValid, queryString, class, subClass, invType, minLevel, maxLevel, minILevel, maxILevel, rarity, usableOnly, exactOnly, evenOnly, maxQuantity, maxPrice = GetSearchFilterOptions(searchTerm)

			if not isValid then
				TSM:Print(L["Skipped the following search term because it's invalid."])
				TSM:Print("\""..searchTerm.."\": "..queryString)
			elseif strlenutf8(queryString) > 63 then
				TSM:Print(L["Skipped the following search term because it's too long. Blizzard does not allow search terms over 63 characters."])
				TSM:Print("\""..searchTerm.."\"")
				isValid = nil
			end

			if isValid then
				tinsert(filters, {name=queryString, usable=usableOnly, minLevel=minLevel, maxLevel=maxLevel, quality=rarity, class=class, subClass=subClass, invType=invType, minILevel=minILevel, maxILevel=maxILevel, exact=exactOnly, evenOnly=evenOnly, maxQuantity=maxQuantity, maxPrice=maxPrice})
			end
		end
	end

	return filters
end

function AuctionTabUtil:GetMatchingFilter(queries, auctionRecord)
	-- figure out which query this item matches
	local name = auctionRecord.name
	if not name then return end
	name = strlower(name)
	local quality = auctionRecord.quality
	local level = auctionRecord.minLevel
	local classId = TSMAPI.Item:GetClassId(auctionRecord.itemString)
	local subClassId = TSMAPI.Item:GetSubClassId(auctionRecord.itemString)
	local invType = GetItemInventoryType(_G[TSMAPI.Item:GetEquipSlot(auctionRecord.itemString)])
	for _, query in ipairs(queries) do
		local isValid = strfind(name, TSMAPI.Util:StrEscape(strlower(query.name))) and true or false
		isValid = isValid and (not query.quality or query.quality == 0 or quality >= query.quality)
		isValid = isValid and (not query.minLevel or query.minLevel == 0 or level >= query.minLevel)
		isValid = isValid and (not query.maxLevel or query.maxLevel == 0 or level <= query.maxLevel)
		isValid = isValid and (query.class == nil or classId == query.class)
		isValid = isValid and (query.subClass == nil or subClassId == query.subClass)
		isValid = isValid and (query.invType == nil or invType == query.invType)
		if isValid then
			return query
		end
	end
end
