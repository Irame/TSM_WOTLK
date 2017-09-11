-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Queue = TSM:NewModule("Queue")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table

Queue.queueInTotal = 0
Queue.queueList = {}
Queue.matList = {}

local inventoryCache = {}
local function FillSubCrafts(mode, mats, numQueued, level)
	if level > 10 then return {} end
	
	local result = {}
	for itemID, quantity in pairs(mats) do
		local subCraft = TSM.Data[mode].crafts[itemID]
		local matPriceSource = TSM.Data[mode].mats[itemID].source
		if subCraft and subCraft.enabled and not subCraft.hasCD and (matPriceSource == "craft") then
			local numHave = TSM.Data:GetTotalQuantity(itemID) - (inventoryCache[itemID] or (TSM.Data[mode].crafts[itemID] and TSM.Data[mode].crafts[itemID].queued) or 0)
			local numNeeded = numQueued * quantity
			
			if numHave > 0 then
				if numHave > numNeeded then
					inventoryCache[itemID] = (inventoryCache[itemID] or 0) + numNeeded
					numNeeded = 0
				else
					numNeeded = numNeeded - numHave
					inventoryCache[itemID] = numHave
				end
			end
			
			local numToCraft = ceil(numNeeded / subCraft.numMade)
			if numToCraft > 0 then
				subCraft.name = subCraft.name or GetSpellInfo(subCraft.spellID)
				local temp = {name=subCraft.name, quantity=numToCraft, spellID=subCraft.spellID, itemID=itemID}
				temp.subCrafts = FillSubCrafts(mode, subCraft.mats, numToCraft, level + 1)
				tinsert(result, temp)
			end
		end
	end
	
	return result
end

local function FillSubStages(resultTable, level, subCrafts)
	if #subCrafts == 0 then return end
	
	for _, craft in ipairs(subCrafts) do
		local temp = CopyTable(craft)
		temp.subCrafts = nil
		if not resultTable[temp.itemID] then
			resultTable[temp.itemID] = temp
			resultTable[temp.itemID].level = level
		else
			resultTable[temp.itemID].quantity = resultTable[temp.itemID].quantity + temp.quantity
			resultTable[temp.itemID].level = max(resultTable[temp.itemID].level, level)
		end
		resultTable.maxLevel = max(resultTable.maxLevel, level)
		FillSubStages(resultTable, level + 1, craft.subCrafts)
	end
end

local function FillMatList(mode, craft)
	if not craft then return end
	
	local isSubCrafting = {}
	for _, subCraft in ipairs(craft.subCrafts) do
		isSubCrafting[subCraft.itemID] = true
	end
	
	for itemID, quantity in pairs(TSM.Data[mode].crafts[craft.itemID].mats) do
		if not isSubCrafting[itemID] then
			Queue.matList[mode][itemID] = (Queue.matList[mode][itemID] or 0) + (quantity * craft.quantity)
		end
	end
	
	for _, subCraft in ipairs(craft.subCrafts) do
		FillMatList(mode, subCraft)
	end
end

local orderCache = {}
local function QueueSortFunction(a, b)
	local orderA = orderCache[a.spellID] or 0
	local orderB = orderCache[b.spellID] or 0
	if Queue.lastCraft == a.spellID then
		return true
	elseif Queue.lastCraft == b.spellID then
		return false
	else
		if orderA == orderB then
			if a.quantity == b.quantity then
				return a.spellID > b.spellID
			else
				return a.quantity > b.quantity
			end
		else
			return orderA > orderB
		end
	end
end

-- updates the craft queue
function Queue:UpdateQueue(mode)
	if not mode then return end
	
	Queue.queueInTotal = 0
	Queue.queueList[mode] = {}
	Queue.matList[mode] = {}
	
	if not TSM.Data[mode] then return end
	
	orderCache = {}
	inventoryCache = {}
	
	local temp = {}
	for itemID, data in pairs(TSM.Data[mode].crafts) do
		if data.queued > 0 then
			data.name = data.name or GetSpellInfo(data.spellID)
			local subCrafts = FillSubCrafts(mode, data.mats, data.queued, 1)
			tinsert(temp, {name=data.name, quantity=data.queued, spellID=data.spellID, itemID=itemID, subCrafts=subCrafts})
		end
	end
	
	local items = {maxLevel = 0}
	for _, craft in ipairs(temp) do
		FillMatList(mode, craft)
		FillSubStages(items, 1, craft.subCrafts)
	end
	
	local maxStage = items.maxLevel
	items.maxLevel = nil
	local stages = {}
	for _, data in pairs(items) do
		local order, _, _, partial = TSM.Crafting:GetOrderIndex(mode, data)
		if partial and order ~= 3 then
			orderCache[data.spellID] = 2.5
		else
			orderCache[data.spellID] = order
		end
	
		local index = maxStage - data.level + 1
		stages[index] = stages[index] or {}
		data.subCrafts = nil
		tinsert(stages[index], data)
		Queue.queueInTotal = Queue.queueInTotal + 1
	end
	
	for _, data in ipairs(temp) do
		local order, _, _, partial = TSM.Crafting:GetOrderIndex(mode, data)
		if partial and order ~= 3 then
			orderCache[data.spellID] = 2.5
		else
			orderCache[data.spellID] = order
		end
	
		data.subCrafts = nil
		stages[maxStage+1] = stages[maxStage+1] or {}
		tinsert(stages[maxStage+1], data)
		Queue.queueInTotal = Queue.queueInTotal + 1
	end
	
	for i=1, #stages do
		sort(stages[i], QueueSortFunction)
	end
	Queue.queueList[mode] = stages
end

function Queue:ClearQueue()
	for _, data in pairs(TSM.Data[TSM.Crafting.mode].crafts) do
		data.queued = 0
	end

	Queue.queueList[TSM.Crafting.mode] = {} -- clear the craft queue so we start fresh
	Queue.queueInTotal = 0 -- integer representing the number of different items in the craft queueend
end


local function GetProfessionMats(mode, total, need, countNoneNeeded)
	if not Queue.matList[mode] then
		Queue:UpdateQueue(mode)
	end

	for itemID, quantity in pairs(Queue.matList[mode]) do
		tinsert(total, {itemID, quantity})
		local needed = max(quantity - TSM.Data:GetTotalQuantity(itemID), 0)
		if needed > 0 or countNoneNeeded then
			local inkID, pigPerInk
			if mode == "Inscription" then
				inkID, pigPerInk = TSM.Inscription:GetInk(itemID)
			end
			tinsert(need, {itemID, needed, TSM.Vendor:GetVendorPrice(itemID) and true, inkID, pigPerInk})
		end
	end
end

function Queue:GetMatsForQueue(modes, countNoneNeeded)
	local total, need = {}, {}
	
	if type(modes) == "table" then -- specific modes
		for _, mode in ipairs(modes) do
			GetProfessionMats(mode, total, need, countNoneNeeded)
		end
	elseif modes == "shopping" or not modes then -- all modes
		for _, profession in ipairs(TSM.tradeSkills) do
			GetProfessionMats(profession.name, total, need, countNoneNeeded)
		end
	elseif modes then -- single mode
		GetProfessionMats(modes, total, need, countNoneNeeded)
	end
	
	return total, need
end


-- returns the max number of an item that can be queued
function Queue:GetMaxQueueCount(mode, itemID)
	local maxQueueCount = TSM:GetDBValue("maxRestockQuantity", mode, itemID) - TSM.Data:GetTotalQuantity(itemID)
	local link, _, ilvl = select(2, GetItemInfo(itemID))
	local seenCount = TSM:GetSeenCount(itemID)
	
	if TSM.db.profile.dontQueue[itemID] or (seenCount and not TSM.db.profile.ignoreSeenCountFilter[itemID] and seenCount < TSM.db.profile.seenCountFilter) then
		maxQueueCount = 0
	end
	
	if TSM.db.profile.limitIlvl[mode] then
		if TSM.db.profile.minilvlToCraft[mode] and (ilvl < TSM.db.profile.minilvlToCraft[mode]) then
			maxQueueCount = 0
		end
	end
	
	return maxQueueCount
end

function Queue:CreateRestockQueue()
	local mode = TSM.Crafting.mode
	
	for itemID, data in pairs(TSM.Data[mode].crafts) do
		if data.enabled and not data.hasCD then
			local minRestock, maxRestock = TSM:GetDBValue("minRestockQuantity", mode, itemID), TSM:GetDBValue("maxRestockQuantity", mode, itemID)
			local maxQueueCount = Queue:GetMaxQueueCount(mode, itemID)
			local profitMethod = TSM:GetDBValue("queueProfitMethod", mode, itemID)
			data.queued = 0
			
			if minRestock > maxRestock then
				local link = select(2, GetItemInfo(itemID)) or data.name
				TSM:Printf(L["%s not queued! Min restock of %s is higher than max restock of %s"], link, minRestock, maxRestock)
			elseif profitMethod == "none" or TSM.db.profile.alwaysQueue[itemID] then
				data.queued = floor(maxQueueCount / data.numMade)
			else
				local cost, buyout, profit = TSM.Data:GetCraftPrices(itemID, mode)
				local minProfit
				if profitMethod == "percent" then
					minProfit = cost and cost*TSM:GetDBValue("queueMinProfitPercent", mode, itemID)
				elseif profitMethod == "gold" then
					minProfit = (TSM:GetDBValue("queueMinProfitGold", mode, itemID) or 0)*COPPER_PER_GOLD
				elseif profitMethod == "both" then
					minProfit = cost and max((TSM:GetDBValue("queueMinProfitGold", mode, itemID) or 0)*COPPER_PER_GOLD, cost*TSM:GetDBValue("queueMinProfitPercent", mode, itemID))
				end
				
				if minProfit and profit and profit >= minProfit then
					data.queued = floor(maxQueueCount / data.numMade)
				elseif cost and not buyout and TSM:GetDBValue("unknownProfitMethod") == "fallback" and TSMAPI:GetData("auctioningFallback", itemID) then
					profit = TSMAPI:GetData("auctioningFallback", itemID) - cost
					if profit and profit >= minProfit then
						data.queued = floor(maxQueueCount / data.numMade)
					end
				end
			end
			
			if data.queued < 0 or data.queued < minRestock then
				data.queued = 0
			end
		end
	end
end

function Queue:CreateOnHandQueue()
	local mode = TSM.Crafting.mode
	-- get a list of itemIDs of crafts sorted by profit
	local sortedData = {}
	for itemID, craft in pairs(TSM.Data[mode].crafts) do
		local profit = TSM.Data:GetCraftProfit(itemID, mode)
		if not profit then
			profit = TSM:GetDBValue("unknownProfitMethod") == "fallback" and TSMAPI:GetData("auctioningFallback", itemID) or math.huge
		end
		tinsert(sortedData, {itemID=itemID, profit=profit})
	end
	sort(sortedData, function(a, b) return a.profit > b.profit end)
	for i=1, #sortedData do
		sortedData[i] = sortedData[i].itemID
	end
	
	-- queue stuff up until we run out of mats
	local usedMats = {}
	for _, itemID in ipairs(sortedData) do
		local data = TSM.Data[mode].crafts[itemID]
		local profit = data and TSM.Data:GetCraftProfit(itemID, mode)
		
		if profit and profit >= 0 and data.enabled and not data.hasCD then
			local quantity = 0
			local maxQueueCount = Queue:GetMaxQueueCount(mode, itemID)
			data.queued = 0
			
			for matID, mQuantity in pairs(data.mats) do
				if TSM.Data[mode].mats[matID].source == "vendor" and TSM.db.profile.assumeVendorInBags then
					if not TSM.db.profile.limitVendorItemPrice or TSM.Data:GetMatCost(mode, matID) <= TSM.db.profile.maxVendorPrice then
						usedMats[matID] = -1
					end
				end
			end
		
			while(true) do
				local t = TSM.Crafting:GetOrderIndex(mode, {spellID=data.spellID, quantity=quantity+1}, usedMats)
				if t ~= 3 or quantity >= maxQueueCount then
					break
				else
					quantity = quantity + 1
				end
			end
			
			for matID, mQuantity in pairs(data.mats) do
				usedMats[matID] = (usedMats[matID] or 0) + quantity*mQuantity
			end
			
			data.queued = floor(quantity / data.numMade)
		end
	end
end