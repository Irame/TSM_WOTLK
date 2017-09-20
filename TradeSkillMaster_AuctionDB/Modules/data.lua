-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_AuctionDB - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_auctiondb.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Data = TSM:NewModule("Data")

-- weight for the market value from X days ago (where X is the index of the table)
local WEIGHTS = {[0] = 132, [1] = 125, [2] = 100, [3] = 75, [4] = 45, [5] = 34, [6] = 33,
	[7] = 38, [8] = 28, [9] = 21, [10] = 15, [11] = 10, [12] = 7, [13] = 5, [14] = 4}

function Data:GetDay(t)
	t = t or time()
	return floor(t / (60*60*24))
end

-- Updates all the market values
function Data:UpdateMarketValue(itemData)
	local day = Data:GetDay()

	local scans = CopyTable(itemData.scans)
	itemData.scans = {}
	itemData.scans[day] = scans[day] and CopyTable(scans[day])
	for i=1, 14 do
		local dayScans = scans[day-i]
		if type(dayScans) == "table" then
			itemData.scans[day-i] = Data:GetAverage(dayScans)
		elseif dayScans then
			itemData.scans[day-i] = dayScans
		end
	end
	itemData.marketValue = Data:GetMarketValue(itemData.scans)
end

-- gets the average of a list of numbers
function Data:GetAverage(data)
	local total, num = 0, 0
	for _, marketValue in ipairs(data) do
		total = total + marketValue
		num = num + 1
	end
	
	return num > 0 and floor((total / num) + 0.5)
end

-- gets the market value given a set of scans
function Data:GetMarketValue(scans)
	local day = Data:GetDay()
	local totalAmount, totalWeight = 0, 0
	
	for i=0, 14 do
		local data = scans[day-i]
		if data then
			local dayMarketValue
			if type(data) == "table" then
				dayMarketValue = Data:GetAverage(data)
			else
				dayMarketValue = data
			end
			if dayMarketValue then
				totalAmount = totalAmount + (WEIGHTS[i] * dayMarketValue)
				totalWeight = totalWeight + WEIGHTS[i]
			end
		end
	end
	for i in ipairs(scans) do
		if i < day - 14 then
			scans[i] = nil
		end
	end
	
	return totalWeight > 0 and floor(TSMAPI:SafeDivide(totalAmount, totalWeight) + 0.5) or 0
end


function Data:CleanMinBuyouts(queue)
	if queue and #queue > 1 then -- they did a category scan
		local scannedInfo = {}
		for i=1, #queue do
			scannedInfo[tostring(queue[i].class).."@"..tostring(queue[i].subClass)] = true
		end
	
		local classLookup = {}
		local subClassLookup = {}
		for i, class in pairs({GetAuctionItemClasses()}) do
			for j, subClass in pairs({GetAuctionItemSubClasses(i)}) do
				subClassLookup[subClass] = j
			end
			classLookup[class] = i
		end
		
		-- wipe all the minBuyout data of items that should have been scanned
		for itemID, data in pairs(TSM.data) do
			local className, subClassName = select(6, GetItemInfo(itemID))
			if not className or scannedInfo[(classLookup[className] or "0").."@"..(subClassLookup[subClassName] or "0")] then
				data.minBuyout = nil
				data.currentQuantity = 0
			end
		end
	else
		-- wipe all the minBuyout data
		for itemID, data in pairs(TSM.data) do
			data.minBuyout = nil
			data.currentQuantity = 0
		end
	end
end

function Data:ProcessData(scanData, queue)
	local day = Data:GetDay()
	Data:CleanMinBuyouts(queue)
	
	-- go through each item and figure out the market value / update the data table
	for itemID, data in pairs(scanData) do
		TSM.data[itemID] = TSM.data[itemID] or {scans={}, seen=0}
		local marketValue = Data:CalculateMarketValue(data.records, data.recordsQuantity)
		
		if type(TSM.data[itemID].scans[day]) == "number" then
			TSM.data[itemID].scans[day] = {TSM.data[itemID].scans[day]}
		end
		TSM.data[itemID].scans[day] = TSM.data[itemID].scans[day] or {}
		tinsert(TSM.data[itemID].scans[day], marketValue)
		
		TSM.data[itemID].seen = ((TSM.data[itemID].seen or 0) + data.quantity)
		TSM.data[itemID].currentQuantity = data.quantity
		TSM.data[itemID].lastScan = time()
		TSM.data[itemID].minBuyout = data.minBuyout > 0 and data.minBuyout or nil
		Data:UpdateMarketValue(TSM.data[itemID])
	end
end

function Data:CalculateMarketValue(records, quantity)
	local totalNum, totalBuyout = 0, 0
	
	for i=1, #records do
		for j=1, records[i].count do
			local gi = totalNum + 1
			if not (gi == 1 or gi < (quantity)*0.3 or (gi < (quantity)*0.5 and records[i].buyout < 1.2*records[max(i-1, 1)].buyout)) then
				break
			end

			totalBuyout = totalBuyout + records[i].buyout
			totalNum = totalNum + 1;
		end
	end
	
	local uncorrectedMean = TSMAPI:SafeDivide(totalBuyout, totalNum)
	local varience = 0
	
	for i=1, #records do
		varience = varience + records[i].count * (records[i].buyout-uncorrectedMean)^2
	end
	
	local stdDev = sqrt(TSMAPI:SafeDivide(varience, totalNum))
	local correctedTotalNum, correctedTotalBuyout = 1, uncorrectedMean

	local totalLeft = totalNum;
	for i = 1, #records do
		local count = min(records[i].count, totalLeft)
		if abs(uncorrectedMean - records[i].buyout) < 1.5*stdDev then
			correctedTotalNum = correctedTotalNum + count
			correctedTotalBuyout = correctedTotalBuyout + records[i].buyout * count
		end
		totalLeft = totalLeft - records[i].count
		if totalLeft <= 0 then break end
	end
	
	local correctedMean = floor(TSMAPI:SafeDivide(correctedTotalBuyout, correctedTotalNum) + 0.5)
	
	return correctedMean
end