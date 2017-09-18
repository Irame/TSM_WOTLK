-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Accounting - AddOn by Sapu94							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_accounting.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- create a local reference to the TradeSkillMaster_Accounting table and register a new module
local TSM = select(2, ...)
local Data = TSM:NewModule("Data", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Accounting") -- loads the localization table

local SECONDS_PER_DAY = 24*60*60

function Data:Initialize()
	local adjustedTime = false
	for itemString in pairs(TSM.soldData) do
		TSM.Util:UpdateLink("sold", itemString)
	end
	for itemString in pairs(TSM.buyData) do
		TSM.Util:UpdateLink("buy", itemString)
	end
	
	Data:RawHook("TakeInboxItem", function(...) Data:ScanCollectedMail("TakeInboxItem", 1, ...) end, true)
	Data:RawHook("TakeInboxMoney", function(...) Data:ScanCollectedMail("TakeInboxMoney", 1, ...) end, true)
	Data:RawHook("AutoLootMailItem", function(...) Data:ScanCollectedMail("AutoLootMailItem", 1, ...) end, true)
	Data:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", "ScanAuctionItems")
	Data:RegisterEvent("BAG_UPDATE", "ScanBagItems")
	TSMAPI:RegisterData("avgsellprice", function(_, itemID, maxTime) return Data:GetAverageSellPrice(TSM:GetItemString(itemID), maxTime) end)
	TSMAPI:RegisterData("avgbuyprice", function(_, itemID, maxTime) return Data:GetAverageBuyPrice(TSM:GetItemString(itemID), maxTime) end)
end

-- scans the mail that the player just attempted to collected (Pre-Hook)
function Data:ScanCollectedMail(oFunc, attempt, index, subIndex)
	local invoiceType, itemName, buyer, bid, _, _, ahcut = GetInboxInvoiceInfo(index)
	local _, _, quantity = GetInboxItem(index)
	local success = true
	if invoiceType == "seller" and buyer and buyer ~= "" then
		local itemString = TSM.db.global.itemStrings[itemName] or TSM:GetItemString(itemName)
		if itemString then
			quantity = quantity > 0 and quantity or 1;	-- HACK: in wotlk you cant get the quantitiy of the items sold so we use 1
			local sellPrice = floor(TSMAPI:SafeDivide(bid - ahcut, quantity) + 0.5)
			local daysLeft = select(7, GetInboxHeaderInfo(index))
			local saleTime = (time() + (daysLeft-30)*SECONDS_PER_DAY)
			Data:AddRecord("sold", itemString, sellPrice, quantity, buyer, saleTime)
		end
	elseif invoiceType == "buyer" and buyer and buyer ~= "" then
		local link = GetInboxItemLink(index, subIndex or 1)
		local itemString = TSM:GetItemString(link)
		if itemString then
			--mine as well grab the name for future lookups
			local name = GetItemInfo(link)
			TSM.db.global.itemStrings[name] = itemString
			
			local buyPrice = floor(TSMAPI:SafeDivide(bid, quantity) + 0.5)
			local daysLeft = select(7, GetInboxHeaderInfo(index))
			local buyTime = (time() + (daysLeft-30)*SECONDS_PER_DAY)
			Data:AddRecord("buy", itemString, buyPrice, quantity, buyer, buyTime)
		end
	else
		success = false
	end
	
	if success then
		Data.hooks[oFunc](index, subIndex)
	elseif (not select(2, GetInboxHeaderInfo(index)) or (invoiceType and (not buyer or buyer == ""))) and attempt <= 5 then
		TSMAPI:CreateTimeDelay("accountingHookDelay", 0.2, function() Data:ScanCollectedMail(oFunc, attempt+1, index, subIndex) end)
	elseif attempt > 5 then
		Data.hooks[oFunc](index, subIndex)
	else
		Data.hooks[oFunc](index, subIndex)
	end
end

-- adds a new record for something that was sold / bought
function Data:AddRecord(dataType, itemString, price, stackSize, otherPerson, time)
	local currentPlayer = UnitName("player")
	local records, link
	if TSM[dataType.."Data"][itemString] then
		records, link = select(2, TSM.Util:DecodeItemData(dataType, itemString))
	end
	records = records or {}
	link = link or GetItemInfo(itemString)
	local otherPersonIndex = (dataType == "sold" and "buyer" or "seller")
	
	local foundRecord
	for _, record in ipairs(records) do
		if record.price == price and record.stackSize == stackSize and abs(record.time-time) < 300 and record.player == currentPlayer then
			record.quantity = record.quantity + stackSize
			foundRecord = true
			break
		end
	end
	
	if not foundRecord then
		tinsert(records, {time=time, price=price, quantity=stackSize, stackSize=stackSize, [otherPersonIndex]=otherPerson, player=currentPlayer})
	end
	
	TSM[dataType.."Data"][itemString] = TSM.Util:EncodeItemData(dataType, itemString, {records=records, link=link})
end

-- scan the auctions the user has on the AH for name -> itemString lookup table
function Data:ScanAuctionItems()
	for i=1, GetNumAuctionItems("owner") do
		local name = GetAuctionItemInfo("owner", i)
		if name then
			local itemString = TSM:GetItemString(GetAuctionItemLink("owner", i))
			TSM.db.global.itemStrings[name] = itemString
		end
	end
end

-- scans the bags to help build the name -> itemString lookup table
function Data:ScanBagItems()
	for bag=0, 4 do
		for slot=1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local name = GetItemInfo(link)
				if name then
					local itemString = TSM:GetItemString(link)
					TSM.db.global.itemStrings[name] = itemString
				end
			end
		end
	end
end

function Data:GetAverageSellPrice(itemString, maxTimeDiff)
	local records = TSM.Util:GetRecords("sold", itemString)
	if not records then return end
	maxTimeDiff = maxTimeDiff or time()
	
	local totalNum, totalPrice = 0, 0
	for _, record in ipairs(records) do
		local timeDiff = time() - record.time
		if timeDiff <= maxTimeDiff then
			totalNum = totalNum + record.quantity
			totalPrice = totalPrice + record.price*record.quantity
		end
	end
	
	return floor(TSMAPI:SafeDivide(totalPrice, totalNum) + 0.5)
end

function Data:GetAverageBuyPrice(itemString, maxTimeDiff)
	local records = TSM.Util:GetRecords("buy", itemString)
	if not records then return end
	maxTimeDiff = maxTimeDiff or time()
	
	local totalNum, totalPrice = 0, 0
	for _, record in ipairs(records) do
		local timeDiff = time() - record.time
		if timeDiff <= maxTimeDiff then
			totalNum = totalNum + record.quantity
			totalPrice = totalPrice + record.price*record.quantity
		end
	end
	
	return floor(TSMAPI:SafeDivide(totalPrice, totalNum) + 0.5)
end




-- ************************************************ --
--				GUI Helper Functions							 --
-- ************************************************ --

-- returns a formatted time in the format that the user has selected
function Data:GetFormattedTime(rTime)
	if TSM.db.factionrealm.timeFormat == "ago" then
		return format(L["%s ago"], SecondsToTime(time()-rTime) or "?")
	elseif TSM.db.factionrealm.timeFormat == "usdate" then
		return date("%m/%d/%y %H:%M", rTime)
	elseif TSM.db.factionrealm.timeFormat == "eudate" then
		return date("%d/%m/%y %H:%M", rTime)
	elseif TSM.db.factionrealm.timeFormat == "aidate" then
		return date("%y/%m/%d %H:%M", rTime)
	end
end

-- gets the market value from the set source for an item
function Data:GetMarketValue(itemString)
	local itemID = TSM:ItemStringToID(itemString)
	local link = select(2, GetItemInfo(itemString)) or itemString
	local source = TSM.db.factionrealm.mvSource
	
	return TSMAPI:GetItemValue(link,source)
end

local buyDataCache, soldDataCache = {}, {}
function Data:PopulateDataCaches()
	local temp = {}
	Data.playerDataCache = {}

	for itemString in pairs(TSM.soldData) do
		TSM.Util:UpdateLink("sold", itemString)
		local _, records, link = TSM.Util:DecodeItemData("sold", itemString)
		if records then
			soldDataCache[itemString] = {records=records, link=link}
			for itemString, data in pairs(soldDataCache) do
				for _, record in ipairs(data.records) do
					if not temp[record.player] then
						temp[record.player] = true
						tinsert(Data.playerDataCache, record.player)
					end
				end
			end
		end
	end
	
	for itemString in pairs(TSM.buyData) do
		TSM.Util:UpdateLink("buy", itemString)
		local _, records, link = TSM.Util:DecodeItemData("buy", itemString)
		if records then
			buyDataCache[itemString] = {records=records, link=link}
			for itemString, data in pairs(buyDataCache) do
				for _, record in ipairs(data.records) do
					if not temp[record.player] then
						temp[record.player] = true
						tinsert(Data.playerDataCache, record.player)
					end
				end
			end
		end
	end
end

function Data:ClearDataCaches()
	soldDataCache = {}
	buyDataCache = {}
end

function Data:RemoveOldData(daysOld)
	local cutoffTime = time() - daysOld*SECONDS_PER_DAY
	local numRecords, numItems = 0, 0
	
	local itemsToRemove = {}
	for itemString, data in pairs(soldDataCache) do
		local toRemove = {}
		for i, record in ipairs(data.records) do
			if record.time < cutoffTime then
				tinsert(toRemove, i)
			end
		end
		
		if #toRemove > 0 then
			numRecords = numRecords + #toRemove
			for i=#toRemove, 1, -1 do
				tremove(data.records, toRemove[i])
			end
			
			if #data.records == 0 then
				tinsert(itemsToRemove, itemString)
			else
				TSM.soldData[itemString] = TSM.Util:EncodeItemData("sold", itemString, data)
				soldDataCache[itemString] = data
			end
		end
	end
	for _, itemString in ipairs(itemsToRemove) do
		TSM.soldData[itemString] = nil
		soldDataCache[itemString] = nil
	end
	numItems = numItems + #itemsToRemove
	
	itemsToRemove = {}
	for itemString, data in pairs(buyDataCache) do
		local toRemove = {}
		for i, record in ipairs(data.records) do
			if record.time < cutoffTime then
				tinsert(toRemove, i)
			end
		end
		
		if #toRemove > 0 then
			numRecords = numRecords + #toRemove
			for i=#toRemove, 1, -1 do
				tremove(data.records, toRemove[i])
			end
			
			if #data.records == 0 then
				tinsert(itemsToRemove, itemString)
			else
				TSM.buyData[itemString] = TSM.Util:EncodeItemData("buy", itemString, data)
				buyDataCache[itemString] = data
			end
		end
	end
	for _, itemString in ipairs(itemsToRemove) do
		TSM.buyData[itemString] = nil
		buyDataCache[itemString] = nil
	end
	numItems = numItems + #itemsToRemove
	
	TSM:Printf(L["Removed a total of %s old records and %s items with no remaining records."], numRecords, numItems)
end

-- formats the sales data into a table that the ST can use
function Data:GetSalesData(filterFunc)
	local salesData = {}
	for itemString, data in pairs(soldDataCache) do
		local name, itemLink = GetItemInfo(itemString)
		name = name or data.link
		if not filterFunc or filterFunc(name, data.link) then
			for _, record in ipairs(data.records) do
				if not filterFunc or filterFunc(name, data.link, record.player) then
				tinsert(salesData, {
						cols = {
							{
								value = itemLink or data.link,
								args = {name},
							},
							{
								value = record.player
							},
							{
								value = record.stackSize,
							},
							{
								value = record.quantity/record.stackSize,
							},
							{
								value = function(price) return TSM:FormatTextMoney(price) end,
								args = {record.price}
							},
							{
								value = function(price) return TSM:FormatTextMoney(price) end,
								args = {record.price*record.quantity}
							},
							{
								value = function(rTime) return Data:GetFormattedTime(rTime) end,
								args = {record.time},
							},
						},
						itemString = itemString,
					})
				end
			end
		end
	end
	
	sort(salesData, function(a, b) return a.cols[#a.cols].args[1] > b.cols[#a.cols].args[1] end)
	
	return salesData
end

-- formats the buy data into a table that the ST can use
function Data:GetBuyData(filterFunc)
	local buyData = {}
	for itemString, data in pairs(buyDataCache) do
		local name, itemLink = GetItemInfo(itemString)
		name = name or data.link
		if not filterFunc or filterFunc(name, data.link, player) then
			for _, record in ipairs(data.records) do
				if not filterFunc or filterFunc(name, data.link, record.player) then
				tinsert(buyData, {
						cols = {
							{
								value = itemLink or data.link,
								args = {name}
							},
							{
								value = record.player
							},
							{
								value = record.stackSize,
							},
							{
								value = record.quantity/record.stackSize,
							},
							{
								value = function(price) return TSM:FormatTextMoney(price) end,
								args = {record.price},
							},
							{
								value = function(price) return TSM:FormatTextMoney(price) end,
								args = {record.price*record.quantity},
							},
							{
								value = function(rTime) return Data:GetFormattedTime(rTime) end,
								args = {record.time},
							},
						},
						itemString = itemString,
					})
				end
			end
		end
	end
	
	sort(buyData, function(a, b) return a.cols[#a.cols].args[1] > b.cols[#a.cols].args[1] end)
	
	return buyData
end

-- formats the item summary data into a table that the ST can use
function Data:GetItemSummaryData(filterFunc)
	local data = {}
	for itemString in pairs(TSM.buyData) do
		local _, records, link = TSM.Util:DecodeItemData("buy", itemString)
		if records then
			local totalPrice, totalNum = 0, 0
			for _, record in ipairs(records) do
				totalPrice = totalPrice + record.price*record.quantity
				totalNum = totalNum + record.quantity
			end
			local average = floor(TSMAPI:SafeDivide(totalPrice, totalNum) + 0.5)
			local marketValue = Data:GetMarketValue(itemString)
		
			data[itemString] = {link=link, buyAverage=average, buyNum=totalNum, marketValue=marketValue}
			if TSM.db.factionrealm.priceFormat == "total" then
				data[itemString].buyAverage = totalPrice
			end
		end
	end
	
	for itemString in pairs(TSM.soldData) do
		local totalPrice, totalNum = 0, 0
		local _, records, link = TSM.Util:DecodeItemData("sold", itemString)
		if records then
			for _, record in ipairs(records) do
				totalPrice = totalPrice + record.price*record.quantity
				totalNum = totalNum + record.quantity
			end
			local average = floor(TSMAPI:SafeDivide(totalPrice, totalNum) + 0.5)
		
			if data[itemString] then
				data[itemString].sellAverage = average
				data[itemString].sellNum = totalNum
			else
				local marketValue = Data:GetMarketValue(itemString)
				data[itemString] = {link=link, sellAverage=average, sellNum=totalNum, marketValue=marketValue}
			end
			
			if TSM.db.factionrealm.priceFormat == "total" then
				data[itemString].sellAverage = totalPrice
			end
		end
	end
	
	local stData = {}
	for itemString, iData in pairs(data) do
		local name, itemLink = GetItemInfo(itemString)
		name = name or iData.link
		if not filterFunc or filterFunc(name, data.link) then
			tinsert(stData, {
					cols = {
						{
							value = itemLink or iData.link,
							args = {name},
						},
						{
							value = function(price) return TSM:FormatTextMoney(price) or "|cff999999---|r" end,
							args = {iData.marketValue or 0},
						},
						{
							value = function(num) return num or "|cff3333330|r" end,
							args = {iData.sellNum or 0},
						},
						{
							value = function(price) return TSM:FormatTextMoney(price) or "|cff999999---|r" end,
							args = {iData.sellAverage or 0},
						},
						{
							value = function(num) return num or "|cff3333330|r" end,
							args = {iData.buyNum or 0},
						},
						{
							value = function(price) return TSM:FormatTextMoney(price) or "|cff999999---|r" end,
							args = {iData.buyAverage or 0},
						},
					},
					itemString = itemString,
					totalNum = (iData.sellNum or 0) + (iData.buyNum or 0),
				})
		end
	end
	
	sort(stData, function(a, b) return a.totalNum > b.totalNum end)
	
	return stData
end

-- formats the resale summary data into a table that the ST can use
function Data:GetResaleSummaryData(filterFunc)
	local data = {}
	for itemString in pairs(TSM.buyData) do
		local _, buyRecords, link = TSM.Util:DecodeItemData("buy", itemString)
		local soldRecords = TSM.Util:GetRecords("sold", itemString)
		if buyRecords and soldRecords then
			local totalBuyPrice, totalBuyNum = 0, 0
			for _, record in ipairs(buyRecords) do
				totalBuyPrice = totalBuyPrice + record.price*record.quantity
				totalBuyNum = totalBuyNum + record.quantity
			end
			local avgBuy = floor(TSMAPI:SafeDivide(totalBuyPrice, totalBuyNum) + 0.5)
			
			local totalSellPrice, totalSellNum = 0, 0
			for _, record in ipairs(soldRecords) do
				totalSellPrice = totalSellPrice + record.price*record.quantity
				totalSellNum = totalSellNum + record.quantity
			end
			local avgSell = floor(TSMAPI:SafeDivide(totalSellPrice, totalSellNum) + 0.5)
			
			local profit = avgSell - avgBuy
			local profitPercent = floor(TSMAPI:SafeDivide(profit, avgBuy)*100+0.5)
			local color = profit > 0 and "|cff00ff00" or "|cffff0000"
			local profitText = TSM:FormatTextMoney(profit, color).." ("..color..profitPercent.."%|r)"
		
			data[itemString] = {link=link, avgBuy=avgBuy, buyNum=totalBuyNum, avgSell=avgSell, sellNum=totalSellNum, profit=profit, profitText=profitText}
			
			if TSM.db.factionrealm.priceFormat == "total" then
				data[itemString].avgSell = totalSellPrice
				data[itemString].avgBuy = totalBuyPrice
			end
		end
	end
	
	local stData = {}
	for itemString, iData in pairs(data) do
		local name, itemLink = GetItemInfo(itemString)
		name = name or iData.link
		if not filterFunc or filterFunc(name, data.link) then
			tinsert(stData, {
					cols = {
						{
							value = itemLink or iData.link,
							args = {name},
						},
						{
							value = function(num) return num or "|cff3333330|r" end,
							args = {iData.sellNum or 0},
						},
						{
							value = function(price) return TSM:FormatTextMoney(price) or "|cff999999---|r" end,
							args = {iData.avgSell or 0},
						},
						{
							value = function(num) return num or "|cff3333330|r" end,
							args = {iData.buyNum or 0},
						},
						{
							value = function(price) return TSM:FormatTextMoney(price) or "|cff999999---|r" end,
							args = {iData.avgBuy or 0},
						},
						{
							value = iData.profitText,
							args = {iData.profit}
						},
					},
					itemString = itemString,
					totalNum = (iData.sellNum or 0) + (iData.buyNum or 0),
				})
		end
	end
	
	sort(stData, function(a, b) return a.totalNum > b.totalNum end)
	
	return stData
end

-- gets data for the gold summary page
function Data:GetGoldData(filterFunc)
	local goldData = {totalSale=0, monthSale=0, weekSale=0, topSellGold={}, topSellQuantity={},
		totalBuy=0, monthBuy=0, weekBuy=0, topBuyGold={}, topBuyQuantity={},
		totalTime=0, monthTime=0, weekTime=0}
	
	for itemString in pairs(TSM.soldData) do
		local _, records, link = TSM.Util:DecodeItemData("sold", itemString)
		if records then
			link = select(2, GetItemInfo(itemString)) or link
			TSM.Util:UpdateLink("sold", itemString)
			local itemTotalGold, itemTotalNum = 0, 0
			for _, record in ipairs(records) do
				itemTotalNum = itemTotalNum + record.quantity
				itemTotalGold = itemTotalGold + record.price*record.quantity
				goldData.totalSale = goldData.totalSale + record.price*record.quantity
				local timeDiff = time() - record.time
				if timeDiff < (SECONDS_PER_DAY*30) then
					if timeDiff > goldData.monthTime then
						goldData.monthTime = timeDiff
					end
					goldData.monthSale = goldData.monthSale + record.price*record.quantity
					if timeDiff < (SECONDS_PER_DAY*7) then
						if timeDiff > goldData.weekTime then
							goldData.weekTime = timeDiff
						end
						goldData.weekSale = goldData.weekSale + record.price*record.quantity
					end
				end
				if timeDiff > goldData.totalTime then
					goldData.totalTime = timeDiff
				end
			end
			if itemTotalGold > (goldData.topSellGold.price or 0) then
				goldData.topSellGold = {link=link, price=itemTotalGold, itemID=TSM:ItemStringToID(itemString)}
			end
			if itemTotalNum > (goldData.topSellQuantity.num or 0) then
				goldData.topSellQuantity = {link=link, num=itemTotalNum, itemID=TSM:ItemStringToID(itemString)}
			end
		end
	end
	
	for itemString in pairs(TSM.buyData) do
		local _, records, link = TSM.Util:DecodeItemData("buy", itemString)
		if records then
			link = select(2, GetItemInfo(itemString)) or link
			TSM.Util:UpdateLink("buy", itemString)
			local itemTotalGold, itemTotalNum = 0, 0
			for _, record in ipairs(records) do
				itemTotalNum = itemTotalNum + record.quantity
				itemTotalGold = itemTotalGold + record.price*record.quantity
				goldData.totalBuy = goldData.totalBuy + record.price*record.quantity
				local timeDiff = time() - record.time
				if timeDiff < (SECONDS_PER_DAY*30) then
					if timeDiff > goldData.monthTime then
						goldData.monthTime = timeDiff
					end
					goldData.monthBuy = goldData.monthBuy + record.price*record.quantity
					if timeDiff < (SECONDS_PER_DAY*7) then
						if timeDiff > goldData.weekTime then
							goldData.weekTime = timeDiff
						end
						goldData.weekBuy = goldData.weekBuy + record.price*record.quantity
					end
				end
				if timeDiff > goldData.totalTime then
					goldData.totalTime = timeDiff
				end
			end
			if itemTotalGold > (goldData.topBuyGold.price or 0) then
				goldData.topBuyGold = {link=(link or itemString), price=itemTotalGold, itemID=TSM:ItemStringToID(itemString)}
			end
			if itemTotalNum > (goldData.topBuyQuantity.num or 0) then
				goldData.topBuyQuantity = {link=(link or itemString), num=itemTotalNum, itemID=TSM:ItemStringToID(itemString)}
			end
		end
	end
	
	if goldData.totalTime > (SECONDS_PER_DAY*7) then
		goldData.weekTime = SECONDS_PER_DAY*7
		if goldData.totalTime > (SECONDS_PER_DAY*30) then
			goldData.monthTime = SECONDS_PER_DAY*30
		end
	end
	goldData.totalTime = ceil(goldData.totalTime/SECONDS_PER_DAY)
	goldData.monthTime = ceil(goldData.monthTime/SECONDS_PER_DAY)
	goldData.weekTime = ceil(goldData.weekTime/SECONDS_PER_DAY)
	
	return goldData
end

-- get the data for the item specifics page
function Data:GetItemData(itemString)
	local _, sellRecords, sellLink = TSM.Util:DecodeItemData("sold", itemString)
	local _, buyRecords, buyLink = TSM.Util:DecodeItemData("buy", itemString)
	if not buyRecords and not sellRecords then return end
	
	local data = {activity={}, sellers={}, buyers={}, link=(sellLink or buyLink)}
	
	if buyRecords then
		TSM.Util:UpdateLink("buy", itemString)
		local totalBuyPrice, totalBuyNum = 0, 0
		local monthBuyPrice, monthBuyNum = 0, 0
		local weekBuyPrice, weekBuyNum = 0, 0
		
		for _, record in ipairs(buyRecords) do
			data.sellers[record.seller] = (data.sellers[record.seller] or 0) + record.quantity
			tinsert(data.activity, {type=L["Purchase"], price=record.price, quantity=record.quantity, who=record.seller, time=record.time})
			
			totalBuyPrice = totalBuyPrice + record.price*record.quantity
			totalBuyNum = totalBuyNum + record.quantity
			local timeDiff = time() - record.time
			if timeDiff < (SECONDS_PER_DAY*30) then
				monthBuyPrice = monthBuyPrice + record.price*record.quantity
				monthBuyNum = monthBuyNum + record.quantity
				if timeDiff < (SECONDS_PER_DAY*7) then
					weekBuyPrice = weekBuyPrice + record.price*record.quantity
					weekBuyNum = weekBuyNum + record.quantity
				end
			end
		end
		
		data.totalBuyPrice = totalBuyPrice
		data.totalBuyNum = totalBuyNum
		data.avgTotalBuy = floor(TSMAPI:SafeDivide(totalBuyPrice, totalBuyNum) + 0.5)
		
		data.monthBuyPrice = monthBuyPrice
		data.monthBuyNum = monthBuyNum
		data.avgMonthBuy = floor(TSMAPI:SafeDivide(monthBuyPrice, monthBuyNum) + 0.5)
		
		data.weekBuyPrice = weekBuyPrice
		data.weekBuyNum = weekBuyNum
		data.avgWeekBuy = floor(TSMAPI:SafeDivide(weekBuyPrice, weekBuyNum) + 0.5)
	end
	
	if sellRecords then
		TSM.Util:UpdateLink("sell", itemString)
		local totalSellPrice, totalSellNum = 0, 0
		local monthSellPrice, monthSellNum = 0, 0
		local weekSellPrice, weekSellNum = 0, 0
		
		for _, record in ipairs(sellRecords) do
			data.buyers[record.buyer] = (data.buyers[record.buyer] or 0) + record.quantity
			tinsert(data.activity, {type=L["Sale"], price=record.price, quantity=record.quantity, who=record.buyer, time=record.time})
			
			totalSellPrice = totalSellPrice + record.price*record.quantity
			totalSellNum = totalSellNum + record.quantity
			local timeDiff = time() - record.time
			if timeDiff < (SECONDS_PER_DAY*30) then
				monthSellPrice = monthSellPrice + record.price*record.quantity
				monthSellNum = monthSellNum + record.quantity
				if timeDiff < (SECONDS_PER_DAY*7) then
					weekSellPrice = weekSellPrice + record.price*record.quantity
					weekSellNum = weekSellNum + record.quantity
				end
			end
		end
		
		data.totalSellPrice = totalSellPrice
		data.totalSellNum = totalSellNum
		data.avgTotalSell = floor(TSMAPI:SafeDivide(totalSellPrice, totalSellNum) + 0.5)
		
		data.monthSellPrice = monthSellPrice
		data.monthSellNum = monthSellNum
		data.avgMonthSell = floor(TSMAPI:SafeDivide(monthSellPrice, monthSellNum) + 0.5)
		
		data.weekSellPrice = weekSellPrice
		data.weekSellNum = weekSellNum
		data.avgWeekSell = floor(TSMAPI:SafeDivide(weekSellPrice, weekSellNum) + 0.5)
	end
	
	sort(data.activity, function(a, b) return a.time > b.time end)
	data.stData = {}
	for _, record in pairs(data.activity) do
		tinsert(data.stData, {
				cols = {
					{
						value = record.type,
					},
					{
						value = record.who,
					},
					{
						value = record.quantity,
					},
					{
						value = function(price) return TSM:FormatTextMoney(price) end,
						args = {record.price},
					},
					{
						value = function(price) return TSM:FormatTextMoney(price) end,
						args = {record.price*record.quantity},
					},
					{
						value = function(rTime) return Data:GetFormattedTime(rTime) end,
						args = {record.time},
					},
				},
			})
	end
	
	return data
end