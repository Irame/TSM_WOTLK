-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains APIs related to items (itemLinks/itemStrings/etc)

local TSM = select(2, ...)
local Items = TSM:NewModule("Items", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {itemInfo={}, bonusIdCache={}, bonusIdTemp={}, scanTooltip=nil, newItems={}, numPending=0, itemLevelCache = {}, soulboundCache = {}, minLevelCache = {}, canUseCache = {}}
local STATIC_DATA = {classLookup={}, classIdLookup={}, inventorySlotIdLookup={}}
STATIC_DATA.weaponClassName = GetItemClassInfo(LE_ITEM_CLASS_WEAPON)
STATIC_DATA.armorClassName = GetItemClassInfo(LE_ITEM_CLASS_ARMOR)
-- Needed because NUM_LE_ITEM_CLASSS contains an erroneous value
local ITEM_CLASS_IDS = {
	LE_ITEM_CLASS_WEAPON,
	LE_ITEM_CLASS_ARMOR,
	LE_ITEM_CLASS_CONTAINER,
	LE_ITEM_CLASS_GEM,
	LE_ITEM_CLASS_ITEM_ENHANCEMENT,
	LE_ITEM_CLASS_CONSUMABLE,
	LE_ITEM_CLASS_GLYPH,
	LE_ITEM_CLASS_TRADEGOODS,
	LE_ITEM_CLASS_RECIPE,
	LE_ITEM_CLASS_BATTLEPET,
	LE_ITEM_CLASS_QUESTITEM,
	LE_ITEM_CLASS_MISCELLANEOUS
}

for _, classId in ipairs(ITEM_CLASS_IDS) do
	local class = GetItemClassInfo(classId)
	if class then
		STATIC_DATA.classIdLookup[strlower(class)] = classId
		STATIC_DATA.classLookup[class] = {}
		STATIC_DATA.classLookup[class]._index = classId
		for _, subClassId in pairs({GetAuctionItemSubClasses(classId)}) do
			STATIC_DATA.classLookup[class][GetItemSubClassInfo(classId, subClassId)] = subClassId
		end
	end
end
for i = 0, NUM_LE_INVENTORY_TYPES do
	local invType = GetItemInventorySlotInfo(i)
	if invType then
		STATIC_DATA.inventorySlotIdLookup[strlower(invType)] = i
	end
end
local GET_ITEM_INFO_INSTANT_KEYS = {
	equipSlot = 4,
	texture = 5,
	classId = 6,
	subClassId = 7
}
local GET_ITEM_INFO_KEYS = {
	name = 1,
	link = 2,
	quality = 3,
	itemLevel = 4,
	minLevel = 5,
	maxStack = 8,
	equipSlot = 9,
	texture = 10,
	vendorPrice = 11,
	classId = 12,
	subClassId = 13
}
local GET_PET_INFO_KEYS = {
	name = 1,
	quality = 2,
	itemLevel = 3,
	minLevel = 4,
	maxStack = 5,
	equipSlot = 6,
	texture = 7,
	vendorPrice = 8,
	classId = 9,
	subClassId = 10
}
for key in pairs(GET_ITEM_INFO_INSTANT_KEYS) do
	TSMAPI:Assert(GET_ITEM_INFO_KEYS[key])
end
local MAX_REQUESTS_PENDING = 200
local UPGRADE_VALUE_SHIFT = 1000000


-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Item:ToItemString(item)
	if not item then return end
	TSMAPI:Assert(type(item) == "number" or type(item) == "string", tostring(item))
	local result = nil

	if tonumber(item) then
		-- assume this is an itemId
		return "i:"..item
	else
		item = item:trim()
	end

	-- test if it's already (likely) an item string or battle pet string
	if strmatch(item, "^p:([0-9%-:]+)$") then
		result = strjoin(":", strmatch(item, "^(p):(%d+:%d+:%d+)"))
		if result then
			return result
		end
		return item
	elseif strmatch(item, "^i:([0-9%-:]+)$") then
		return private:FixItemString(item)
	end

	result = strmatch(item, "^\124cff[0-9a-z]+\124[Hh](.+)\124h%[.+%]\124h\124r$")
	if result then
		-- it was a full item link which we've extracted the itemString from
		item = result
	end

	-- test if it's an old style item string
	result = strjoin(":", strmatch(item, "^(i)tem:([0-9%-]+):[0-9%-]+:[0-9%-]+:[0-9%-]+:[0-9%-]+:[0-9%-]+:([0-9%-]+)$"))
	if result then
		return private:FixItemString(result)
	end

	-- test if it's an old style battle pet string (or if it was a link)
	result = strjoin(":", strmatch(item, "^battle(p)et:(%d+:%d+:%d+)"))
	if result then
		return result
	end
	result = strjoin(":", strmatch(item, "^battle(p)et:(%d+)$"))
	if result then
		return result
	end
	result = strjoin(":", strmatch(item, "^(p):(%d+:%d+:%d+)"))
	if result then
		return result
	end

	-- test if it's a long item string
	result = strjoin(":", strmatch(item, "(i)tem:([0-9%-]+):[0-9%-]*:[0-9%-]*:[0-9%-]*:[0-9%-]*:[0-9%-]*:([0-9%-]*):[0-9%-]*:[0-9%-]*:[0-9%-]*:[0-9%-]*:[0-9%-]*:([0-9%-:]+)"))
	if result and result ~= "" then
		return private:FixItemString(result)
	end

	-- test if it's a shorter item string (without bonuses)
	result = strjoin(":", strmatch(item, "(i)tem:([0-9%-]+):[0-9%-]*:[0-9%-]*:[0-9%-]*:[0-9%-]*:[0-9%-]*:([0-9%-]*)"))
	if result and result ~= "" then
		return result
	end
end

function TSMAPI.Item:ToBaseItemString(itemString, doGroupLookup)
	-- make sure it's a valid itemString
	itemString = TSMAPI.Item:ToItemString(itemString)
	if not itemString then return end

	local baseItemString = strmatch(itemString, "([ip]:%d+)")

	if not doGroupLookup or (TSM.db.profile.items[baseItemString] and not TSM.db.profile.items[itemString]) then
		-- either we're not doing a group lookup, or the base item is in a group and the specific item is not, so return the base item
		return baseItemString
	end
	return itemString
end

--- Attempts to get the itemID from a given itemLink/itemString.
-- @param itemLink The link or itemString for the item.
-- @return Returns the itemID as the first parameter. On error, will return nil as the first parameter and an error message as the second.
function TSMAPI.Item:ToItemID(itemString)
	itemString = TSMAPI.Item:ToItemString(itemString)
	if type(itemString) ~= "string" then return end
	return tonumber(strmatch(itemString, "^i:(%d+)"))
end

function TSMAPI.Item:IsSoulbound(...)
	local numArgs = select('#', ...)
	if numArgs == 0 then return end
	local bag, slot, itemString, ignoreBOA
	local firstArg = ...
	if type(firstArg) == "string" then
		TSMAPI:Assert(numArgs <= 2, "Too many arguments provided with itemString")
		itemString, ignoreBOA = ...
		itemString = TSMAPI.Item:ToItemString(itemString)
		if strmatch(itemString, "^p:") then
			-- battle pets are not soulbound
			return
		end
	elseif type(firstArg) == "number" then
		bag, slot, ignoreBOA = ...
		TSMAPI:Assert(slot, "Second argument must be slot within bag")
		TSMAPI:Assert(numArgs <= 3, "Too many arguments provided with bag / slot")
	else
		TSMAPI:Assert(false, "Invalid arguments")
	end
	if itemString then
		if not private.soulboundCache[itemString] then
			private.soulboundCache[itemString] = { result = nil, resultIgnoreBOA = nil }
		end
		if ignoreBOA and private.soulboundCache[itemString].resultIgnoreBOA ~= nil then
			return private.soulboundCache[itemString].resultIgnoreBOA
		elseif not ignoreBOA and private.soulboundCache[itemString].result ~= nil then
			return private.soulboundCache[itemString].result
		end
	end

	local scanTooltip = private.GetScanTooltip()
	local result = false
	if itemString then
		-- it's an itemString
		scanTooltip:SetHyperlink(private.ToWoWItemString(itemString))
	elseif bag and slot then
		local itemID = GetContainerItemID(bag, slot)
		local maxCharges
		if itemID then
			scanTooltip:SetItemByID(itemID)
			maxCharges = private:GetTooltipCharges(scanTooltip)
		end
		if bag == -1 then
			scanTooltip:SetInventoryItem("player", slot + 39)
		else
			scanTooltip:SetBagItem(bag, slot)
		end
		if maxCharges then
			if private:GetTooltipCharges(scanTooltip) ~= maxCharges then
				result = true
			end
		end
	else
		TSMAPI:Assert(false) -- should never get here
	end
	if result then
		return result
	end

	local numLines = scanTooltip:NumLines()
	for id=1, numLines do
		local text = private.GetTooltipText(_G[scanTooltip:GetName().."TextLeft"..id])
		if text then
			if (text == ITEM_BIND_ON_PICKUP and id < 4) or text == ITEM_SOULBOUND or text == ITEM_BIND_QUEST then
				result = true
			elseif not ignoreBOA and (text == ITEM_ACCOUNTBOUND or text == ITEM_BIND_TO_ACCOUNT or text == ITEM_BIND_TO_BNETACCOUNT or text == ITEM_BNETACCOUNTBOUND) then
				result = true
			end
		end
	end

	if not result and numLines <= 1 then
		-- the tooltip didn't fully load
		return nil
	elseif itemString then
		if ignoreBOA then
			private.soulboundCache[itemString].resultIgnoreBOA = result
		elseif not ignoreBOA then
			private.soulboundCache[itemString].result = result
		end
	end

	return result
end

function TSMAPI.Item:IsCraftingReagent(itemLink)
	if strmatch(itemLink, "battlepet:") or strmatch(itemLink, "^p:") then
		-- ignore battle pets
		return false
	end

	-- workaround for recipes having the item info and crafting reagent in the tooltip
	if TSMAPI.Item:GetClassId(itemLink) == LE_ITEM_CLASS_RECIPE then
		return false
	end

	local scanTooltip = private.GetScanTooltip()
	scanTooltip:SetHyperlink(itemLink)

	local result = nil
	for id = 1, scanTooltip:NumLines() do
		local text = private.GetTooltipText(_G[scanTooltip:GetName().."TextLeft"..id])
		if text and (text == PROFESSIONS_USED_IN_COOKING) then
			result = true
			break
		end
	end
	return result
end

function TSMAPI.Item:IsSoulboundMat(itemString)
	return itemString and TSM.STATIC_DATA.soulboundMats[itemString]
end

function TSMAPI.Item:GetVendorCost(itemString)
	return itemString and TSM.db.global.vendorItems[itemString]
end

function TSMAPI.Item:IsDisenchantable(itemString)
	if not itemString or TSM.STATIC_DATA.notDisenchantable[itemString] then return end
	local quality = TSMAPI.Item:GetQuality(itemString) or 0
	local classId = TSMAPI.Item:GetClassId(itemString)
	return quality >= LE_ITEM_QUALITY_UNCOMMON and (classId == LE_ITEM_CLASS_ARMOR or classId == LE_ITEM_CLASS_WEAPON)
end

function TSMAPI.Item:GetItemClasses()
	local result = {}
	for class in pairs(STATIC_DATA.classLookup) do
		tinsert(result, class)
	end
	sort(result, function(a, b) return TSMAPI.Item:GetClassIdFromClassString(a) < TSMAPI.Item:GetClassIdFromClassString(b) end)
	return result
end

function TSMAPI.Item:GetItemSubClasses(classId)
	local class = GetItemClassInfo(classId)
	local result = {}
	for subClass in pairs(STATIC_DATA.classLookup[class]) do
		if subClass ~= "_index" then
			tinsert(result, subClass)
		end
	end
	sort(result, function(a, b) return STATIC_DATA.classLookup[class][a] < STATIC_DATA.classLookup[class][b] end)
	return result
end

function TSMAPI.Item:GetClassIdFromClassString(class)
	return STATIC_DATA.classIdLookup[strlower(class)]
end

function TSMAPI.Item:GetSubClassIdFromSubClassString(subClass, classId)
	if not classId then return end
	local class = GetItemClassInfo(classId)
	if not STATIC_DATA.classLookup[class] then return end
	for str, index in pairs(STATIC_DATA.classLookup[class]) do
		if strlower(str) == strlower(subClass) then
			return index
		end
	end
end

function TSMAPI.Item:GetInventorySlotIdFromInventorySlotString(slot)
	return STATIC_DATA.inventorySlotIdLookup[strlower(slot)]
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Items:OnEnable()
	Items:RegisterEvent("MERCHANT_SHOW", "ScanMerchant")
	local itemString = next(TSM.db.global.vendorItems)
	if itemString and TSMAPI.Item:ToItemString(itemString) ~= itemString then
		-- they just upgraded to TSM3, so wipe the table
		wipe(TSM.db.global.vendorItems)
	end

	for itemString, cost in pairs(TSM.STATIC_DATA.preloadedVendorCosts) do
		TSM.db.global.vendorItems[itemString] = TSM.db.global.vendorItems[itemString] or cost
	end
	TSMAPI.Threading:Start(private.ItemInfoThread, 0.1)
	private.loadedItemInfo = private.LoadItemCache()
end

function Items:OnLogout()
	private.SaveItemCache()
end

function Items:ScanMerchant(event)
	for i=1, GetMerchantNumItems() do
		local itemString = TSMAPI.Item:ToItemString(GetMerchantItemLink(i))
		if itemString then
			local price, quantity, _, _, _, extendedCost = select(3, GetMerchantItemInfo(i))
			if price > 0 and not extendedCost then
				TSM.db.global.vendorItems[itemString] = TSMAPI.Util:Round(price / quantity)
			else
				TSM.db.global.vendorItems[itemString] = nil
			end
		end
	end
	if event then
		TSMAPI.Delay:AfterTime("scanMerchantDelay", 1, Items.ScanMerchant)
	end
end



-- ============================================================================
-- ItemCacheDB Helper Functions
-- ============================================================================

function private.EncodeNumber(value, length)
	if value == nil then
		value = 2 ^ (8 * length) - 1
	end
	if length == 1 then
		return strchar(value)
	elseif length == 2 then
		return strchar(value % 256, value / 256)
	elseif length == 3 then
		return strchar(value % 256, (value % 65536) / 256, value / 65536)
	elseif length == 4 then
		return strchar(value % 256, (value % 65536) / 256, (value % 16777216) / 65536, value / 16777216)
	else
		TSMAPI:Assert(false, "Invalid length: "..tostring(length))
	end
end

function private.SaveItemCache()
	local resultRows = {}
	local resultNames = {}
	for itemString, data in pairs(private.itemInfo) do
		local itemId = strmatch(itemString, "^i:([0-9]+)")
		if itemId and not data._isInvalid then
			local row = nil
			if data._getInfoResult then
				row = strjoin("",
					private.EncodeNumber(tonumber(itemId), 3), -- 3 bytes of itemId
					private.EncodeNumber(data.quality, 1), -- 1 byte of quality
					private.EncodeNumber(data.itemLevel, 2), -- 2 bytes of itemLevel
					private.EncodeNumber(data.minLevel, 1), -- 1 byte of minLevel
					private.EncodeNumber(data.maxStack, 2), -- 2 bytes of maxStack
					private.EncodeNumber(data.vendorPrice, 4) -- 4 bytes of vendorPrice
				)
			elseif data._encodedData then
				row = data._encodedData
			end
			if row then
				tinsert(resultNames, data.name)
				tinsert(resultRows, row)
			end
		end
	end
	local result = table.concat(resultRows)
	TSMAPI:Assert(#result % 13 == 0)
	-- prepend the binary data length and append the names
	result = private.EncodeNumber(#result, 4) .. result .. table.concat(resultNames, "\0")
	-- prepend the hash
	result = private.EncodeNumber(TSMAPI.Util:CalculateHash(result), 4)..result
	-- store the result
	TSMItemCacheDB = result
	TSM.db.global.locale = GetLocale()
	-- store the current interface version to know whether the cache should be reset
	TSM.db.global.clientVersion = GetBuildInfo()
end

function private.DecodeNumber(str, length, offset)
	offset = (offset or 0) + 1
	local value = nil
	if length == 1 then
		value = strbyte(str, offset)
	elseif length == 2 then
		value = strbyte(str, offset) + strbyte(str, offset + 1) * 256
	elseif length == 3 then
		value = strbyte(str, offset) + strbyte(str, offset + 1) * 256 + strbyte(str, offset + 2) * 65536
	elseif length == 4 then
		value = strbyte(str, offset) + strbyte(str, offset + 1) * 256 + strbyte(str, offset + 2) * 65536 + strbyte(str, offset + 3) * 16777216
	else
		TSMAPI:Assert(false, "Invalid length: "..tostring(length))
	end
	-- a mmax value indiciates nil
	if value == 2 ^ (8 * length) - 1 then
		return nil
	end
	return value
end

function private.LoadItemCache()
	-- check if the locale changed, in which case we won't load the cache
	if TSM.db.global.locale ~= "" and TSM.db.global.locale ~= GetLocale() then return end

	-- check if the interface version changed, in which case we won't load the cache
	local clientVersion = GetBuildInfo()
	if TSM.db.global.clientVersion ~= clientVersion then return end

	local str = TSMItemCacheDB
	if type(str) ~= "string" or #str < 4 then return end

	-- check the hash
	local hash = private.DecodeNumber(str, 4)
	str = strsub(str, 5)
	if hash ~= TSMAPI.Util:CalculateHash(str) then
		TSM:LOG_ERR("Invalid hash (%s, %s)", tostring(hash), tostring(TSMAPI.Util:CalculateHash(str)))
		return
	end

	-- calculate and check the length of the binary data section
	local binDataLength = private.DecodeNumber(str, 4)
	str = strsub(str, 5)
	if binDataLength % 13 ~= 0 or binDataLength > #str then
		TSM:LOG_ERR("Invalid bin data length (%s, %s)", tostring(binDataLength), tostring(#str))
		return
	end
	local binDataEntries = binDataLength / 13

	-- load the names
	local names = TSMAPI.Util:SafeStrSplit(strsub(str, 1 + binDataLength), "\0")
	if #names ~= binDataEntries then
		TSM:LOG_ERR("Invalid names (%s, %s)", tostring(#names), tostring(binDataEntries))
		return
	end

	local result = {}
	for i = 0, binDataEntries - 1 do
		local rowData = strsub(str, i * 13 + 1, (i + 1) * 13)
		local itemString = "i:"..private.DecodeNumber(rowData, 3) -- 3 bytes of itemId
		if result[itemString] then
			TSM:LOG_ERR("Duplicate entry (%s)", itemString)
			return
		end
		result[itemString] = {
			name = names[i + 1],
			quality = private.DecodeNumber(rowData, 1, 3),  -- 1 byte of quality
			itemLevel = private.DecodeNumber(rowData, 2, 4),  -- 2 bytes of itemLevel
			minLevel = private.DecodeNumber(rowData, 1, 6),  -- 1 byte of minLevel
			maxStack = private.DecodeNumber(rowData, 2, 7),  -- 2 bytes of maxStack
			vendorPrice = private.DecodeNumber(rowData, 4, 9),  -- 4 bytes of vendorPrice
			_encodedData = rowData
		}
	end

	TSM:LOG_INFO("Loaded item data")
	return result
end

-- ============================================================================
-- Item Info Thread
-- ============================================================================

function private.GetPetInfo(speciesId)
	TSMAPI:Assert(type(speciesId) == "number")
	local name, texture, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesId)
	-- name is equal to the speciesId if it's invalid, so check the texture instead
	if not texture then return end
	-- name, quality, itemLevel, minLevel, maxStack, equipSlot, texture, vendorPrice, classId, subClassId
	return name, 0, 0, 0, 1, "", texture, 0, LE_ITEM_CLASS_BATTLEPET, petType - 1
end

function private.GetCachedItemInfo(itemString)
	if not itemString then return end
	if not private.itemInfo[itemString] then
		private.itemInfo[itemString] = {}
		if strmatch(itemString, "^p:") then
			-- pets don't have a variant of GetItemInfoInstant, so just pretend we already got it
			local speciesId = tonumber(strmatch(itemString, "^p:(%d+)"))
			private.StoreGetPetInfoResult(itemString, private.GetPetInfo(speciesId))
			private.itemInfo[itemString]._getInfoInstantResult = true
		else
			private.newItems[itemString] = 1
		end
	end
	return private.itemInfo[itemString]
end

function private.StoreGetItemInfoResult(itemString, ...)
	TSMAPI:Assert(type(itemString) == "string")
	if select('#', ...) == 0 then return end
	local info = private.GetCachedItemInfo(itemString)
	for key, index in pairs(GET_ITEM_INFO_KEYS) do
		info[key] = select(index, ...)
	end
	private.itemInfo[itemString]._getInfoResult = true
	private.itemInfo[itemString]._getInfoInstantResult = true
	if private.itemInfo[itemString]._isPending then
		private.itemInfo[itemString]._isPending = nil
		private.numPending = private.numPending - 1
	end
end

function private.StoreGetItemInfoInstantResult(itemString, ...)
	local info = private.itemInfo[itemString]
	TSMAPI:Assert(type(itemString) == "string" and info)
	if select('#', ...) == 0 then
		info._isInvalid = true
	end
	local info = private.GetCachedItemInfo(itemString)
	for key, index in pairs(GET_ITEM_INFO_INSTANT_KEYS) do
		info[key] = select(index, ...)
	end
	info._getInfoInstantResult = true

	-- we might be able to deduce the maxStack based on the classId and subClassId
	if info.classId and info.subClassId and not info.maxStack then
		if info.classId == 1 then
			info.maxStack = 1
		elseif info.classId == 2 then
			info.maxStack = 1
		elseif info.classId == 4 then
			if info.subClassId > 0 then
				info.maxStack = 1
			end
		elseif info.classId == 15 then
			if info.subClassId == 5 then
				info.maxStack = 1
			end
		elseif info.classId == 16 then
			info.maxStack = 20
		elseif info.classId == 17 then
			info.maxStack = 1
		elseif info.classId == 18 then
			info.maxStack = 1
		end
	end
end

function private.StoreGetPetInfoResult(itemString, ...)
	TSMAPI:Assert(type(itemString) == "string")
	if select('#', ...) == 0 then
		private.itemInfo[itemString]._isInvalid = true
	end
	local info = private.GetCachedItemInfo(itemString)
	for key, index in pairs(GET_PET_INFO_KEYS) do
		info[key] = select(index, ...)
	end
	private.itemInfo[itemString]._getInfoResult = true
	if private.itemInfo[itemString]._isPending then
		private.itemInfo[itemString]._isPending = nil
		private.numPending = private.numPending - 1
	end
end

function private.ItemInfoThread(self)
	self:SetThreadName("ITEM_INFO")
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED", function(event, itemId)
		private.StoreGetItemInfoResult("i:"..itemId, GetItemInfo(itemId))
	end)

	-- import the loaded item data
	local numImported = 0
	if private.loadedItemInfo then
		for itemString, data in pairs(private.loadedItemInfo) do
			private.itemInfo[itemString] = data
			private.itemInfo[itemString].link = TSMAPI.Item:GetLink(itemString)
			if private.newItems[itemString] == 1 then
				private.newItems[itemString] = nil
			end
			numImported = numImported + 1
			self:Yield()
		end
		-- get the instant item info after we load everything
		local numLoops = 0
		for itemString in pairs(private.loadedItemInfo) do
			local info = private.itemInfo[itemString]
			if not info._getInfoInstantResult then
				private.StoreGetItemInfoInstantResult(itemString, GetItemInfoInstant(TSMAPI.Item:ToItemID(itemString)))
			end
			numLoops = (numLoops + 1) % 100
			self:Yield(numLoops == 0)
		end
	end
	TSM:LOG_INFO("Imported %d items worth of data", numImported)

	local doneStatusMessage = false
	local lastStatusMessage = 0
	local maxPending = 0
	local lastStatusPending = -1
	local toRemove = {}
	while true do
		-- count the number which are pending
		local numRemaining = 0
		for itemString in pairs(private.newItems) do
			local info = private.itemInfo[itemString]
			if not info._getInfoInstantResult then
				private.StoreGetItemInfoInstantResult(itemString, GetItemInfoInstant(TSMAPI.Item:ToItemID(itemString)))
			end
			if private.numPending < maxPending then
				local itemId = TSMAPI.Item:ToItemID(itemString)
				local speciesId = strmatch(itemString, "^p:(%d+)")
				speciesId = tonumber(speciesId)
				if speciesId then
					private.StoreGetPetInfoResult(itemString, private.GetPetInfo(speciesId))
				elseif itemId then
					private.StoreGetItemInfoResult(itemString, GetItemInfo(itemId))
				else
					TSMAPI:Assert(false, "Invalid item: "..tostring(itemString))
				end
				if not info._getInfoResult then
					info._isPending = true
					private.numPending = private.numPending + 1
				end
				tinsert(toRemove, itemString)
			end
			numRemaining = numRemaining + 1
			self:Yield()
		end
		while #toRemove > 0 do
			private.newItems[tremove(toRemove)] = nil
		end
		if numRemaining ~= lastStatusPending and GetTime() - lastStatusMessage > 2 then
			if numRemaining > 0 then
				TSM:LOG_INFO("%d items pending info", numRemaining)
				doneStatusMessage = false
				lastStatusMessage = GetTime()
				lastStatusPending = numRemaining
			elseif not doneStatusMessage then
				TSM:LOG_INFO("done fetching info")
				doneStatusMessage = true
				lastStatusMessage = GetTime()
				lastStatusPending = numRemaining
			end
		end
		maxPending = min(maxPending + 1, MAX_REQUESTS_PENDING)
		self:Sleep(0.1)
	end
end

function private.GetItemInfoKey(itemString, key)
	TSMAPI:Assert(GET_ITEM_INFO_KEYS[key])
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	if not itemString then return end

	local info = private.GetCachedItemInfo(itemString)
	if info then
		if info._isInvalid then return end
		if not info[key] and not info._getInfoInstantResult and GET_ITEM_INFO_INSTANT_KEYS[key] then
			-- we can look up this key via GetItemInfoInstant
			private.StoreGetItemInfoInstantResult(itemString, GetItemInfoInstant(TSMAPI.Item:ToItemID(itemString)))
			TSMAPI:Assert(info._isInvalid or info[key], format("Failed to get instant info! (%s, %s)", itemString, key))
		end
		return info[key]
	end
end

function TSMAPI.Item:FetchInfo(itemString)
	private.GetCachedItemInfo(TSMAPI.Item:ToBaseItemString(itemString))
end

function TSMAPI.Item:GetName(itemString)
	local origItemString = itemString
	itemString = TSMAPI.Item:ToItemString(itemString)
	if not itemString then return end
	local baseItemString = TSMAPI.Item:ToBaseItemString(itemString)
	local info = private.GetCachedItemInfo(baseItemString)
	if info and itemString ~= baseItemString and not info._getInfoResult then
		private.newItems[baseItemString] = true
	end
	local name = nil
	if strmatch(itemString, "^p:") or (info and itemString == baseItemString) then
		-- This is either a pet or base item, just return what we have.
		name = info.name
	elseif info and info._getInfoResult then
		-- we have the base item info, so should be able to call GetItemInfo() for this version of the item
		name = GetItemInfo(private.ToWoWItemString(itemString))
	end
	if not name then
		-- if we got passed an item link or this is a base item and we have the item link, we can maybe extract the name from it
		name = strmatch(origItemString, "^\124cff[0-9a-z]+\124[Hh].+\124h%[(.+)%]\124h\124r$")
		if name == "" then
			name = nil
		end
		if not name and itemString == baseItemString and info and info.link then
			name = strmatch(info.link, "^\124cff[0-9a-z]+\124[Hh].+\124h%[(.+)%]\124h\124r$")
			if name == "" then
				name = nil
			end
		end
		if name == "Unknown Item" then
			name = nil
		end
	end
	return name
end

function TSMAPI.Item:GeneralizeLink(itemLink)
	local itemString = TSMAPI.Item:ToItemString(itemLink)
	if not itemString then return end
	if not strmatch(itemString, "p:") and not strmatch(itemString, "i:[0-9]+:[0-9%-]*:[0-9]*") then
		-- swap out the itemString part of the link
		local leader, quality, _, name, trailer, trailer2, extra = ("\124"):split(itemLink)
		if trailer2 and not extra then
			return strjoin("\124", leader, quality, "H"..private.ToWoWItemString(itemString), name, trailer, trailer2)
		end
	end
	return TSMAPI.Item:GetLink(itemString)
end

function TSMAPI.Item:GetLink(itemString)
	itemString = TSMAPI.Item:ToItemString(itemString)
	if not itemString then return "?" end
	local baseItemString = TSMAPI.Item:ToBaseItemString(itemString)
	local info = private.GetCachedItemInfo(baseItemString)
	if info and itemString ~= baseItemString and not info._getInfoResult then
		private.newItems[baseItemString] = true
	end
	local name, link = nil, nil
	if info then
		if itemString == baseItemString then
			link = info.link
			name = info.name
		elseif info._getInfoResult and strmatch(itemString, "^i:") then
			link = select(2, GetItemInfo(private.ToWoWItemString(itemString)))
		end
	end
	if link then
		return link
	elseif strmatch(itemString, "p:") then
		local _, speciesId, level, quality, health, power, speed, petId = strsplit(":", itemString)
		name = private.GetPetInfo(tonumber(speciesId)) or "Unknown Pet"
		local fullItemString = strjoin(":", speciesId, level or "", quality or "", health or "", power or "", speed or "", petId or "")
		return ITEM_QUALITY_COLORS[tonumber(quality) or 0].hex .. "|Hbattlepet:" .. fullItemString .. "|h[" .. name .. "]|h|r"
	elseif strmatch(itemString, "i:") then
		name = name or "Unknown Item"
		local color = "|cffff0000"
		if info and info.quality and info.quality >= 0 and ITEM_QUALITY_COLORS[info.quality] and (itemString == baseItemString or not strmatch(itemString, "i:[0-9]+:[0-9%-]*:[0-9]*")) then
			color = ITEM_QUALITY_COLORS[info.quality].hex
		end
		itemString = private.ToWoWItemString(itemString)
		return color.."|H"..itemString.."|h["..name.."]|h|r"
	end
	return "?"
end

function TSMAPI.Item:GetQuality(itemString)
	itemString = TSMAPI.Item:ToItemString(itemString)
	if not itemString then return end
	local baseItemString = TSMAPI.Item:ToBaseItemString(itemString)
	local info = private.GetCachedItemInfo(baseItemString)
	if strmatch(itemString, "^p:") then
		-- we can get the quality directly from the itemString
		local quality = select(4, strsplit(":", itemString))
		return tonumber(quality) or 0
	elseif itemString ~= baseItemString and info and info._getInfoResult then
		-- we have the base item info, so should be able to call GetItemInfo() for this version of the item
		return select(3, GetItemInfo(private.ToWoWItemString(itemString))) or info.quality
	end
	return info and info.quality
end

function TSMAPI.Item:GetItemLevel(itemString)
	itemString = TSMAPI.Item:ToItemString(itemString)
	if not itemString then return end
	local baseItemString = TSMAPI.Item:ToBaseItemString(itemString)
	local info = private.GetCachedItemInfo(baseItemString)
	if strmatch(itemString, "^p:") then
		-- we can get the level directly from the itemString
		local itemLevel = select(3, strsplit(":", itemString))
		return tonumber(itemLevel) or 0
	elseif itemString ~= baseItemString and info and info._getInfoResult then
		if private.GetUpgradeValue(itemString) then
			if private.itemLevelCache[itemString] then
				return private.itemLevelCache[itemString]
			end
			-- we need to do tooltip scanning to get the correct item level
			local scanTooltip = private.GetScanTooltip()
			scanTooltip:SetHyperlink(private.ToWoWItemString(itemString))
			for id = 1, scanTooltip:NumLines() do
				local text = private.GetTooltipText(_G[scanTooltip:GetName().."TextLeft"..id])
				local itemLevel = text and strmatch(text, gsub(ITEM_LEVEL, "%%d", "([0-9]+)"))
				if itemLevel then
					private.itemLevelCache[itemString] = tonumber(itemLevel)
					return private.itemLevelCache[itemString]
				end
			end
			-- failed to get the item level from the tooltip
			return
		else
			-- we have the base item info, so should be able to call GetItemInfo() for this version of the item
			return select(4, GetItemInfo(private.ToWoWItemString(itemString))) or info.itemLevel
		end
	end
	return info and info.itemLevel
end

function TSMAPI.Item:GetMinLevel(itemString)
	itemString = TSMAPI.Item:ToItemString(itemString)
	if not itemString then return end
	if private.minLevelCache[itemString] then
		return private.minLevelCache[itemString]
	end
	if strmatch(itemString, "^p:") then
		return private.GetItemInfoKey(itemString, "minLevel")
	end
	local baseItemString = TSMAPI.Item:ToBaseItemString(itemString)
	local info = private.GetCachedItemInfo(baseItemString)
	if itemString ~= baseItemString and info and info._getInfoResult then
		-- we have the base item info, so should be able to call GetItemInfo() for this version of the item
		local minLevel = select(5, GetItemInfo(private.ToWoWItemString(itemString)))
		if minLevel then
			private.minLevelCache[itemString] = minLevel
		end
		return private.minLevelCache[itemString] or info.minLevel
	end
	return info and info.minLevel
end

function TSMAPI.Item:GetMaxStack(itemString)
	return private.GetItemInfoKey(itemString, "maxStack")
end

function TSMAPI.Item:GetEquipSlot(itemString)
	return private.GetItemInfoKey(itemString, "equipSlot")
end

function TSMAPI.Item:GetTexture(itemString)
	return private.GetItemInfoKey(itemString, "texture")
end

function TSMAPI.Item:GetVendorPrice(itemString)
	return private.GetItemInfoKey(itemString, "vendorPrice")
end

function TSMAPI.Item:GetClassId(itemString)
	return private.GetItemInfoKey(itemString, "classId")
end

function TSMAPI.Item:GetSubClassId(itemString)
	return private.GetItemInfoKey(itemString, "subClassId")
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private.GetScanTooltip()
	if not TSMScanTooltip then
		CreateFrame("GameTooltip", "TSMScanTooltip", UIParent, "GameTooltipTemplate")
	end
	TSMScanTooltip:Show()
	TSMScanTooltip:SetClampedToScreen(false)
	TSMScanTooltip:SetOwner(UIParent, "ANCHOR_BOTTOMRIGHT", 1000000, 100000)
	return TSMScanTooltip
end

function private:GetTooltipCharges(scanTooltip)
	for id = 1, scanTooltip:NumLines() do
		local text = private.GetTooltipText(_G[scanTooltip:GetName().."TextLeft"..id])
		local maxCharges = text and strmatch(text, "^([0-9]+) Charges?$")
		if maxCharges then
			return maxCharges
		end
	end
end

function private.GetTooltipText(text)
	local textStr = (text and text:GetText() or ""):trim()
	if textStr == "" then return end

	local r, g, b = text:GetTextColor()
	return textStr, floor(r * 256), floor(g * 256), floor(b * 256)
end

function private.ToWoWItemString(itemString)
	local _, itemId, rand, numBonus = (":"):split(itemString)
	local level = UnitLevel("player")
	local spec = GetSpecialization()
	spec = spec and GetSpecializationInfo(spec) or ""
	local upgradeValue = private.GetUpgradeValue(itemString)
	if upgradeValue and numBonus then
		local bonusIds = strmatch(itemString, "i:[0-9]+:[0-9%-]*:[0-9]+:(.+):"..upgradeValue.."$")
		return "item:"..itemId.."::::::"..(rand or "").."::"..level..":"..spec..":512::"..numBonus..":"..bonusIds..":"..(upgradeValue-UPGRADE_VALUE_SHIFT)..":::"
	end
	return "item:"..itemId.."::::::"..(rand or "").."::"..level..":"..spec..":::"..(numBonus and strmatch(itemString, "i:[0-9]+:[0-9%-]*:(.*)") or "")..":::"
end

function private.RemoveExtra(itemString)
	local num = 1
	while num > 0 do
		itemString, num = gsub(itemString, ":0?$", "")
	end
	return itemString
end

function private:FixItemString(itemString)
	itemString = gsub(itemString, ":0:", "::")-- remove 0s which are in the middle
	itemString = private.RemoveExtra(itemString)
	-- make sure we have the correct number of bonusIds
	-- get the number of bonusIds (plus one for the count)
	local numParts = select("#", (":"):split(itemString)) - 3
	if numParts > 0 then
		-- get the number of extra parts we have
		local count = select(4, (":"):split(itemString))
		count = tonumber(count) or 0
		local numExtraParts = numParts - 1 - count
		local lastExtraPart = tonumber(strmatch(itemString, ":([0-9]+)$"))
		for i=1, numExtraParts do
			itemString = gsub(itemString, ":[0-9]*$", "")
		end
		-- we might have already applied the upgrade value shift
		if numExtraParts == 1 and (lastExtraPart >= 98 and lastExtraPart <= 110) or (lastExtraPart - UPGRADE_VALUE_SHIFT >= 90 and lastExtraPart - UPGRADE_VALUE_SHIFT <= 110) then
			-- this extra part is likely the upgradeValue which we want to keep so increase it by UPGRADE_VALUE_SHIFT
			if lastExtraPart < UPGRADE_VALUE_SHIFT then
				lastExtraPart = lastExtraPart + UPGRADE_VALUE_SHIFT
			end
			itemString = itemString..":"..lastExtraPart
		end
		itemString = private.RemoveExtra(itemString)
		-- filter out bonusIds we don't care about
		return private:FilterImportantBonsuIds(itemString)
	end
	return itemString
end

function private.GetUpgradeValue(itemString)
	local bonusIds = strmatch(itemString, "i:[0-9]+:[0-9%-]*:[0-9]*:(.+)$")
	if not bonusIds then return end
	for id in gmatch(bonusIds, "[0-9]+") do
		id = tonumber(id)
		if id > UPGRADE_VALUE_SHIFT then
			return id
		end
	end
end

function private:FilterImportantBonsuIds(itemString)
	local itemId, rand, bonusIds = strmatch(itemString, "i:([0-9]+):([0-9%-]*):[0-9]*:(.+)$")
	if not bonusIds then return itemString end
	if not private.bonusIdCache[bonusIds] then
		wipe(private.bonusIdTemp)
		local adjust = 0
		for id in gmatch(bonusIds, "[0-9]+") do
			id = tonumber(id)
			if id > UPGRADE_VALUE_SHIFT then
				if not tContains(private.bonusIdTemp, id) then
					tinsert(private.bonusIdTemp, id)
					adjust = adjust + 1
				end
			else
				id = TSM.STATIC_DATA.importantBonusIdMap[id]
				if id and not tContains(private.bonusIdTemp, id) then
					tinsert(private.bonusIdTemp, id)
				end
			end
		end
		sort(private.bonusIdTemp)
		private.bonusIdCache[bonusIds] = { num = #private.bonusIdTemp - adjust, value = strjoin(":", unpack(private.bonusIdTemp)) }
	end
	if private.bonusIdCache[bonusIds].num == 0 then
		if rand == "" or tonumber(rand) == 0 then
			return strjoin(":", "i", itemId)
		else
			return strjoin(":", "i", itemId, rand)
		end
	else
		return strjoin(":", "i", itemId, rand, private.bonusIdCache[bonusIds].num, private.bonusIdCache[bonusIds].value)
	end
end
