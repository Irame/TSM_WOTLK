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
local Data = TSM:NewModule("Data", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table


-- initialize all the data tables
function Data:Initialize()
	local shouldClear = false
	if select(4, GetBuildInfo()) >= 50000 and not TSM.db.profile.updatedForMoP then
		TSM.db.profile.updatedForMoP = true
		shouldClear = true
	end
	
	

	for _, data in ipairs(TSM.tradeSkills) do
		if shouldClear then
			if TSM.db.profile[data.name] then
				wipe(TSM.db.profile[data.name])
				TSM.db.profile[data.name] = {}
			end
		end
	
		-- load all the crafts into Data.crafts
		TSM.db.profile[data.name] = TSM.db.profile[data.name] or {}
		Data[data.name] = TSM.db.profile[data.name]
		Data[data.name].mats = Data[data.name].mats or {}
		Data[data.name].crafts = Data[data.name].crafts or {}
		
		local usedMats = {}
		for _, craft in pairs(Data[data.name].crafts) do
			for itemID in pairs(craft.mats) do
				usedMats[itemID] = true
			end
		end
		
		local unusedMats = {}
		-- add any materials that aren't in the default table to the data table
		for itemID, mat in pairs(Data[data.name].mats) do
			-- remove the mat from the savedDB if it is unused
			if usedMats[itemID] then
				if mat.cost then
					if mat.source == "custom" and not mat.customValue then
						mat.customValue = mat.cost
					elseif strfind(mat.source or "", "#") and not (mat.customID and mat.customMultiplier) then
						local customID, customMultiplier = ("#"):split(mat.source)
						mat.customID = tonumber(customID)
						mat.customMultiplier = tonumber(customMultiplier)
						mat.source = "customitem"
					end
					mat.cost = nil
				end
				if (mat.source ~= "custom" and mat.source ~= "customitem") or not mat.override then
					mat.customID = nil
					mat.customMultiplier = nil
					mat.customValue = nil
				end
			else
				tinsert(unusedMats, itemID)
			end
		end
		
		for _, itemID in ipairs(unusedMats) do
			Data[data.name].mats[itemID] = nil
		end
	end
end



-- **************************************************************************
--										Material Price Functions
-- **************************************************************************

function Data:GetMatSourcePrice(mode, itemID, source, visitedList)
	local cost
	local mat = Data[mode].mats[itemID]

	if source == "auction" then -- value based on auction data
		cost = TSM:GetItemMarketPrice(itemID, "mat")
	elseif source == "vendor" then -- value based on how much a vendor sells it for
		cost = TSM.Vendor:GetVendorPrice(itemID)
	elseif source == "vendortrade" then -- value based on the value of an item that can be traded for this mat
		local tradeItemID, tradeQuantity = TSM.Vendor:GetItemVendorTrade(itemID)
		if tradeItemID then
			cost = (Data[mode].mats[tradeItemID] and Data:GetMatCost(mode, tradeItemID, visitedList) or TSM:GetItemMarketPrice(tradeItemID, "mat") or 0)*tradeQuantity
		end
	elseif source == "craft" then -- value based on crafting this mat
		cost = Data:GetCraftCost(itemID, mode, visitedList)
	elseif source == "mill" then -- value based on milling for this mat (pigments)
		local pigmentID, pigmentData = TSM.Inscription:GetInkFromPigment(itemID)
		if pigmentID then
			local prices = {}
			local pigmentPrice = TSM:GetItemMarketPrice(pigmentID, "mat")
			if pigmentPrice and pigmentPrice ~= 0 then
				tinsert(prices, pigmentPrice)
			end
			for i=1, #pigmentData.herbs do
				local herbID = pigmentData.herbs[i].itemID
				local pigmentPerMill = pigmentData.herbs[i].pigmentPerMill
				local marketPrice = TSM:GetItemMarketPrice(herbID, "mat")
				if marketPrice and marketPrice ~= 0 then
					tinsert(prices, floor(marketPrice*5/pigmentPerMill + 0.5))
				end
			end
			-- set the cost to the 2nd lowest price if there are atleast 2
			sort(prices, function(a, b) return a < b end)
			cost = prices[min(#prices, 2)]
		end
	elseif source == "customitem" then -- value based on another item
		local mat = Data[mode].mats[itemID]
		if mat.customID and mat.customMultiplier then
			if Data[mode].crafts[mat.customID] then
				-- this item is based on an item that is a craft
				cost = (Data:GetCraftCost(mat.customID, mode, visitedList) or 0)*mat.customMultiplier
			elseif Data[mode].mats[mat.customID] then
				-- this item is based on an item that is a mat
				cost = (Data:GetMatCost(mode, mat.customID, visitedList) or 0)*mat.customMultiplier
			else
				cost = (TSM:GetItemMarketPrice(mat.customID, "mat") or 0)*mat.customMultiplier
			end
		end
	elseif source == "custom" then
		cost = Data[mode].mats[itemID].customValue or 0
	end
	
	if cost == 0 then
		cost = nil
	end
	
	return cost
end

local matCache = {}
function Data:GetMatCost(mode, itemID, visitedList)
	visitedList = CopyTable(visitedList or {})
	if visitedList[itemID] then
		return -- we went in a circle!
	end
	visitedList[itemID] = true
	
	local mat = Data[mode].mats[itemID]
	if not mat then return end
	
	if matCache[itemID] and matCache[itemID].cost and (time() - matCache[itemID].cTime) < 1 then
		return matCache[itemID].cost
	end
	
	local cost
	if mat.override then
		cost = Data:GetMatSourcePrice(mode, itemID, mat.source, visitedList)
	else
		mat.customValue = nil
		mat.customID = nil
		mat.customMultiplier = nil
		local matSources = {"auction", "vendor", "vendortrade", "craft", "mill"}
		local cheapestCost, cheapestSource
		for i=1, #matSources do
			local sourcePrice = Data:GetMatSourcePrice(mode, itemID, matSources[i], visitedList)
			if sourcePrice and (not cheapestCost or sourcePrice < cheapestCost) then
				cheapestCost = sourcePrice
				cheapestSource = matSources[i]
			end
		end
		
		mat.source = cheapestSource or mat.source
		cost = cheapestCost
	end
	
	if cost then
		matCache[itemID] = matCache[itemID] or {}
		matCache[itemID].cTime = time()
		matCache[itemID].cost = cost
	end
	return cost
end



-- **************************************************************************
--										Inventory Count Functions
-- **************************************************************************

-- gets the number of an item they have on their alts
function Data:GetAltNum(itemID)
	local count = 0
	if TSM.db.profile.altAddon == "ItemTracker" and select(4, GetAddOnInfo("TradeSkillMaster_ItemTracker")) == 1 then
		for _, player in pairs(TSMAPI:GetData("playerlist") or {}) do
			if player ~= UnitName("player") and TSM.db.profile.altCharacters[player] then
				local bags = TSMAPI:GetData("playerbags", player)
				local bank = TSMAPI:GetData("playerbank", player)
				count = count + (bags[itemID] or 0)
				count = count + (bank[itemID] or 0)
			end
		end
		for _, guild in pairs(TSMAPI:GetData("guildlist") or {}) do
			if TSM.db.profile.altGuilds[guild] then
				local bank = TSMAPI:GetData("guildbank", guild)
				count = count + (bank[itemID] or 0)
			end
		end
	elseif TSM.db.profile.altAddon == "DataStore" and select(4, GetAddOnInfo("DataStore_Containers")) == 1 and DataStore then
		for account in pairs(DataStore:GetAccounts()) do
			for characterName, character in pairs(DataStore:GetCharacters(nil, account)) do
				if characterName ~= UnitName("Player") and TSM.db.profile.altCharacters[characterName] then
					local bagCount, bankCount = DataStore:GetContainerItemCount(character, itemID)
					count = count + (bagCount or 0)
					count = count + (bankCount or 0)
				end
			end
			for guildName, guild in pairs(DataStore:GetGuilds(nil, account)) do
				if TSM.db.profile.altGuilds[guildName] then
					local itemCount = DataStore:GetGuildBankItemCount(guild, itemID)
					count = count + (itemCount or 0)
				end
			end
			if select(4, GetAddOnInfo("DataStore_Mails")) == 1 then
				for characterName, character in pairs(DataStore:GetCharacters(nil, account)) do
					if characterName == UnitName("Player") or TSM.db.profile.altCharacters[characterName] then
						local mailCount = DataStore:GetMailItemCount(character, itemID)
						count = count + (mailCount or 0)
					end
				end
			end
		end
	end
	
	if TSM.db.profile.altAddon == "ItemTracker" and select(4, GetAddOnInfo("TradeSkillMaster_ItemTracker")) == 1 then
		for _, player in pairs(TSMAPI:GetData("playerlist") or {}) do
			if player ~= UnitName("player") and TSM.db.profile.altCharacters[player] then
				local auctions = TSMAPI:GetData("playerauctions", player) or {}
				count = count + (auctions[itemID] or 0)
			end
		end
	elseif TSM.db.profile.altAddon == "DataStore" and select(4, GetAddOnInfo("DataStore_Auctions")) == 1 and DataStore then
		for account in pairs(DataStore:GetAccounts()) do
			for characterName, character in pairs(DataStore:GetCharacters(nil, account)) do
				if TSM.db.profile.altCharacters[characterName] and characterName ~= UnitName("player") then
					local lastVisit = (DataStore:GetAuctionHouseLastVisit(character) or math.huge) - time()
					if lastVisit < 48*60*60 then
						count = count + (DataStore:GetAuctionHouseItemCount(character, itemID) or 0)
					end
				end
			end
		end
	end
	
	return count
end

-- gets the number of an item they have on this player
function Data:GetPlayerNum(itemID)
	local auctions = 0
	
	if TSM.db.profile.altAddon == "ItemTracker" and select(4, GetAddOnInfo("TradeSkillMaster_ItemTracker")) == 1 then
		if TSM.db.profile.restockAH then
			auctions = (TSMAPI:GetData("playerauctions", UnitName("player")) or {})[itemID] or 0
		end
		bags = (TSMAPI:GetData("playerbags", UnitName("player")) or {})[itemID] or 0
		bank = (TSMAPI:GetData("playerbank", UnitName("player")) or {})[itemID] or 0
		local iType = select(6, GetItemInfo(itemID))
		if iType and iType ~= "Container" and bags == 0 then bags = bags + GetItemCount(itemID) end
		if iType and iType ~= "Container" and bank == 0 then bank = bank + (GetItemCount(itemID, true) - GetItemCount(itemID)) end
		return bags, bank, auctions
	elseif TSM.db.profile.altAddon == "DataStore" and select(4, GetAddOnInfo("DataStore_Containers")) == 1 and DataStore then
		if TSM.db.profile.restockAH and select(4, GetAddOnInfo("DataStore_Auctions")) == 1 then
			auctions = DataStore:GetAuctionHouseItemCount(DataStore:GetCharacter(), itemID) or 0
		end
		for account in pairs(DataStore:GetAccounts()) do
			for characterName, character in pairs(DataStore:GetCharacters(nil, account)) do
				if characterName == UnitName("player") then
					local bags, bank = DataStore:GetContainerItemCount(character, itemID)
					return bags or 0, bank or 0, auctions
				end
			end
		end
	else
		-- if they don't have datastore or ItemTracker...they get the very inaccurate GetItemCount result for bags/bank
		local bags = GetItemCount(itemID)
		local bank = GetItemCount(itemID, true) - bags
		return bags, bank, auctions
	end
end

-- gets the total number of some item that they have
function Data:GetTotalQuantity(itemID)
	local bags, bank, auctions = Data:GetPlayerNum(itemID)
	local alts = Data:GetAltNum(itemID)
	
	return bags + bank + auctions + alts
end



-- **************************************************************************
--										Misc Data Functions
-- **************************************************************************

-- gets the cost to create this craft
function Data:GetCraftCost(itemID, mode, extraArg)
	if not itemID then return end
	mode = mode or TSM.mode
	local craft = Data[mode].crafts[itemID]
	if not craft then return end
	
	-- first, we calculate the cost of crafting that crafted item based off the cost of the individual materials
	local cost, costIsValid = 0, true
	for matID, matQuantity in pairs(craft.mats) do
		local matCost = Data:GetMatCost(mode, matID, extraArg)
		if not matCost or matCost == 0 then
			costIsValid = false
			break
		end
		cost = cost + matQuantity*matCost
	end
	cost = floor(cost/(craft.numMade or 1) + 0.5) --rounds to nearest gold
	
	if costIsValid then
		return cost
	end
end

-- gets the profit of this craft
function Data:GetCraftProfit(itemID, mode)
	local cost = Data:GetCraftCost(itemID, mode)
	local buyout = TSM:GetItemMarketPrice(itemID, "craft")
	
	if cost and buyout then
		return floor(buyout - buyout*TSM.db.profile.profitPercent - cost + 0.5)
	end
end

-- calulates the cost, buyout, and profit for a crafted item
function Data:GetCraftPrices(itemID, mode)
	if not itemID then return end
	mode = mode or TSM.mode

	local cost, buyout, profit
	cost = Data:GetCraftCost(itemID, mode)
	buyout = TSM:GetItemMarketPrice(itemID, "craft")
	
	if cost and buyout then
		profit = floor(buyout - buyout*TSM.db.profile.profitPercent - cost + 0.5)
	end
	
	return cost, buyout, profit
end
