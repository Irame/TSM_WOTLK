local TSM = select(2, ...)
local Search = TSM:GetModule("Search")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table

local specialSearchMode


-- GUI functions in the SearchGUI.lua file but both files use the same Search object.

-- ------------------------------------------------ --
--				Search Filter Util functions				 --
-- ------------------------------------------------ --

local function GetItemLevel(str)
	if #str > 1 and strsub(str, 1, 1) == "i" then
		return tonumber(strsub(str, 2))
	end
end

local function GetItemClass(str)
	for i, class in ipairs({GetAuctionItemClasses()}) do
		if strlower(str) == strlower(class) then
			return i
		end
	end
end

local function GetItemSubClass(str, class)
	if not class then return end

	for i, subClass in ipairs({GetAuctionItemSubClasses(class)}) do
		if strlower(str) == strlower(subClass) then
			return i
		end
	end
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
	local queryString, class, subClass, minLevel, maxLevel, minILevel, maxILevel, rarity, usableOnly, exactOnly
	
	if #parts == 1 then
		return true, parts[1]
	elseif #parts == 0 then
		return false, L["Invalid Filter"]
	end
	
	for i, str in ipairs(parts) do
		str = str:trim()
		
		if tonumber(str) then
			if not minLevel then
				minLevel = tonumber(str)
			elseif not maxLevel then
				maxLevel = tonumber(str)
			else
				return false, L["Invalid Min Level"]
			end
		elseif GetItemLevel(str) then
			if not minILevel then
				minILevel = GetItemLevel(str)
			elseif not maxILevel then
				maxILevel = GetItemLevel(str)
			else
				return false, L["Invalid Item Level"]
			end
		elseif GetItemClass(str) then
			if not class then
				class = GetItemClass(str)
			else
				return false, L["Invalid Item Type"]
			end
		elseif GetItemSubClass(str, class) then
			if not subClass then
				subClass = GetItemSubClass(str, class)
			else
				return false, L["Invalid Item SubType"]
			end
		elseif GetItemRarity(str) then
			if not rarity then
				rarity = GetItemRarity(str)
			else
				return false, L["Invalid Item Rarity"]
			end
		elseif strlower(str) == "usable" then
			if not usableOnly then
				usableOnly = 1
			else
				return false, L["Invalid Usable Only Filter"]
			end
		elseif strlower(str) == "exact" then
			if not exactOnly then
				exactOnly = 1
			else
				return false, L["Invalid Exact Only Filter"]
			end
		elseif i == 1 then
			queryString = str
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
	
	return true, queryString or "", class, subClass, minLevel, maxLevel, minILevel, maxILevel, rarity, usableOnly, exactOnly
end

-- gets all the filters for a given search term (possibly semicolon-deliminated list of search terms)
function Search:GetFilters(searchQuery)
	local filters = {}
	local searchTerms = {(";"):split(searchQuery)}
	filters.num = 0
	
	for i=1, #searchTerms do
		local searchTerm = searchTerms[i]:trim()
		local isValid, queryString, class, subClass, minLevel, maxLevel, minILevel, maxILevel, rarity, usableOnly, exactOnly = GetSearchFilterOptions(searchTerm)
		
		if not isValid then
			TSM:Print(L["Skipped the following search term because it's invalid."])
			TSM:Print("\""..searchTerm.."\": "..queryString)
		elseif #queryString > 63 then
			TSM:Print(L["Skipped the following search term because it's too long. Blizzard does not allow search terms over 63 characters."])
			TSM:Print("\""..searchTerm.."\"")
			isValid = nil
		end
	
		if isValid then
			filters.num = filters.num + 1
			if filters.currentFilter then
				filters.currentFilter = filters.currentFilter.."; "..queryString
			else
				filters.currentFilter = queryString
			end
			if filters.currentSearchTerm then
				filters.currentSearchTerm = filters.currentSearchTerm .. "; "..searchTerm
			else
				filters.currentSearchTerm = searchTerm
			end
			tinsert(filters, {name=queryString, usable=usableOnly, minLevel=minLevel, maxLevel=maxLevel, quality=rarity, class=class, subClass=subClass, minILevel=minILevel, maxILevel=maxILevel, exactOnly=exactOnly})
		end
	end
	
	return filters
end


-- ------------------------------------------------ --
--					Scanning Util functions					 --
-- ------------------------------------------------ --

function Search:UpdateRecentSearches(searchTerm)
	-- make sure it's a valid search term
	if not searchTerm or searchTerm == "" then
		return
	end

	-- insert the new one at the start
	tinsert(TSM.db.global.previousSearches, 1, searchTerm)
	
	-- remove any previous searches that were the same
	for i=2, #TSM.db.global.previousSearches do
		if strlower(TSM.db.global.previousSearches[i]) == strlower(searchTerm) then
			tremove(TSM.db.global.previousSearches, i)
			break
		end
	end
	
	-- store at most 100 previous searches
	while(#TSM.db.global.previousSearches > 100) do
		tremove(TSM.db.global.previousSearches, 101)
	end
end

-- start the scan
function Search:StartScan(filters, lists, ShouldStop)
	if not Search:IsAutomaticMode() then Search.searchBar:Disable() end
	Search.currentSearch = {filter=filters.currentFilter, num=(filters.num or #filters), lists=lists, filters=CopyTable(filters)}
	TSM:StartScan(filters, Search, ShouldStop)
end

-- gets the price that the percent column is based off of ("market price")
function Search:SetMarketPrice(item)
	if specialSearchMode == "Dealfinding" then
		item:SetMarketValue(TSM.Config:GetDealfindingData(item:GetItemID()).maxPrice)
	elseif specialSearchMode == "Vendor" then
		item:SetMarketValue(select(11, GetItemInfo(item:GetItemID())))
	elseif specialSearchMode == "Disenchant" then
		item:SetMarketValue(TSMAPI:GetData("deValue", item:GetItemID()))
	elseif Search:IsAutomaticMode() then
		item:SetMarketValue(TSM.Automatic.currItem.cost)
	else
        item:SetMarketValue(TSMAPI:GetItemValue(item:GetItemString(), TSM.db.profile.searchMarketValue))
	end
end

function Search:IsAutomaticMode()
	return specialSearchMode and not Search:IsSpecialSearch()
end

function Search:IsSpecialSearch()
	local specialSearchModes = {Vendor=true, Disenchant=true, Dealfinding=true}
	return specialSearchModes[specialSearchMode]
end


-- ------------------------------------------------ --
--					Scanning Start functions				 --
-- ------------------------------------------------ --

-- starts a regular search which is started by entering something in the search bar or clicking on a recent search
function Search:StartRegularSearch(searchTerm)
	TSM.AuctionControl:HideAuctionConfirmation()
	
	local filters = Search:GetFilters(searchTerm)
	if #filters == 0 then
		return TSM:Print(L["No valid search terms. Aborting search."])
	end
	
	specialSearchMode = nil
	Search.searchST:SetPctColText(L["% Market Value"])
	Search:UpdateRecentSearches(filters.currentSearchTerm)
	Search:StartScan(filters)
end

-- starts a shopping list search - started by clicking on a shopping list
function Search:StartShoppingListSearch(shoppingList)
	TSM.AuctionControl:HideAuctionConfirmation()
	
	local filterStrings = {}
	local filters = {}
	for itemID, data in pairs(TSM.db.profile.shopping[shoppingList] or {}) do
		if itemID == "searchTerms" then
			for _, searchTerm in ipairs(data) do
				for _, filter in ipairs(Search:GetFilters(searchTerm)) do
					tinsert(filters, filter)
					tinsert(filterStrings, filter.name)
				end
			end
		else
			local filterData = TSMAPI:GetAuctionQueryInfo(itemID)
			if filterData then
				tinsert(filters, filterData)
				tinsert(filterStrings, filterData.name)
			end
		end
	end
	if #filters == 0 then
		return TSM:Print(L["No valid search terms. Aborting search."])
	end
	
	filters.num = #filters
	filters.currentFilter = table.concat(filterStrings, "; ")
	
	specialSearchMode = nil
	Search.searchST:SetPctColText(L["% Market Value"])
	Search:StartScan(filters, {shoppingList})
end

-- starts a dealfinding search - started by clicking on a dealfinding list or clicking on the "Dealfinding Search" button
function Search:StartDealfindingListSearch(dealfindingLists)
	TSM.AuctionControl:HideAuctionConfirmation()
	
	local filters, filterStrings = {}, {}
	if type(dealfindingLists) == "table" then
		for _, listName in ipairs(dealfindingLists) do
			for itemID in pairs(TSM.db.profile.dealfinding[listName]) do
				local filterData = TSMAPI:GetAuctionQueryInfo(itemID)
				if filterData then
					tinsert(filters, filterData)
					tinsert(filterStrings, filterData.name)
				end
			end
		end
	else
		for itemID in pairs(TSM.db.profile.dealfinding[dealfindingLists]) do
			local filterData = TSMAPI:GetAuctionQueryInfo(itemID)
			if filterData then
				tinsert(filters, filterData)
				tinsert(filterStrings, filterData.name)
			end
		end
	end
	
	filters.num = #filters
	filters.currentFilter = table.concat(filterStrings, "; ")
	if #filters == 0 then
		return TSM:Print(L["Nothing to search for."])
	end
	
	specialSearchMode = "Dealfinding"
	Search.searchST:SetPctColText(L["% Max Price"])
	Search:StartScan(filters, type(dealfindingLists) == "table" and dealfindingLists or {dealfindingLists})
end

-- starts a search inside the crafting mats search (automatic mode)
function Search:StartAutomaticSearch(itemLink, automaticFrame)
	TSM.AuctionControl:HideAuctionConfirmation()
	
	local filters = {currentFilter=(GetItemInfo(itemLink) or itemLink)}
	local filterData = TSMAPI:GetAuctionQueryInfo(itemLink)
	if filterData then
		tinsert(filters, filterData)
	end
	
	Search:ShowAutomaticFrames(automaticFrame)
	specialSearchMode = TSMAPI:GetItemString(itemLink)
	Search.searchST:SetPctColText(L["% Expected Cost"])
	Search:StartScan(filters)
end

function Search:StartVendorSearch(useScanData)
	if not useScanData then
		TSM:Print(L["Performing a full scan due to no recent scan data being available. This may take several minutes."])
	end

	TSM.AuctionControl:HideAuctionConfirmation()
	
	local filters, filterStrings = {}, {}
	
	if useScanData then
		for itemID, data in pairs(TSMAPI:GetData("lastCompleteScan") or {}) do
			local vendorPrice = select(11, GetItemInfo(itemID))
			if vendorPrice and data.minBuyout and vendorPrice > data.minBuyout then
				local filterData = TSMAPI:GetAuctionQueryInfo(itemID)
				if filterData then
					tinsert(filters, filterData)
					tinsert(filterStrings, filterData.name)
				end
			end
		end
	else
		filters = {{name=""}}
		filterStrings = {L["Vendor Search"]}
	end
		
	filters.num = #filters
	filters.currentFilter = table.concat(filterStrings, "; ")
	if #filters == 0 then
		return TSM:Print(L["Nothing below vendor price from last scan."])
	end
	
	local function ShouldStop(link, buyout)
		local vendorPrice = select(11, GetItemInfo(link))
		if vendorPrice then
			return buyout > vendorPrice
		end
	end
	
	specialSearchMode = "Vendor"
	Search.searchST:SetPctColText(L["% Vendor Price"])
	Search:StartScan(filters, {L["Vendor Search"]}, useScanData and ShouldStop)
end

function Search:StartDisenchantSearch(useScanData)
	if not useScanData then
		TSM:Print(L["Performing a full scan due to no recent scan data being available. This may take several minutes."])
	end

	TSM.AuctionControl:HideAuctionConfirmation()
	
	local filters, filterStrings = {}, {}
	
	if useScanData then
		local scanData
		if useScanData == "TSM_WoWuction" then
			scanData = TSMAPI:GetData("wowuctionLastScan") or {}
		else
			scanData = TSMAPI:GetData("lastCompleteScan") or {}
		end
	
		for itemID, data in pairs(scanData) do
			local deValue = TSMAPI:GetData("deValue", itemID)
			if deValue > 0 and data.minBuyout and deValue > data.minBuyout then
				local filterData = TSMAPI:GetAuctionQueryInfo(itemID)
				if filterData then
					tinsert(filters, filterData)
					tinsert(filterStrings, filterData.name)
				end
			end
		end
	else
		filters = {{name="", quality=2, class=1}, {name="", quality=2, class=2}}
		filterStrings = {L["Disenchantable Weapons"], L["Disenchantable Armor"]}
	end
		
	filters.num = #filters
	filters.currentFilter = table.concat(filterStrings, "; ")
	if #filters == 0 then
		return TSM:Print(L["Nothing worth disechanting from last scan."])
	end
	
	local function ShouldStop(link, buyout)
		return buyout > TSMAPI:GetData("deValue", TSMAPI:GetItemID(link))
	end
	
	specialSearchMode = "Disenchant"
	Search.searchST:SetPctColText(L["% Disenchant Value"])
	Search:StartScan(filters, {L["Disenchant Search"]}, useScanData and ShouldStop)
end

function Search:StartDealfindingSearch(useScanData)
	local lists = {}
	for listName in pairs(TSM.db.profile.dealfinding) do
		tinsert(lists, listName)
	end
	
	if not useScanData then
		TSM:Print(L["Performing a full scan due to no recent scan data being available. This may take several minutes."])
		return Search:StartDealfindingListSearch(lists)
	end

	TSM.AuctionControl:HideAuctionConfirmation()
	
	local filters, filterStrings = {}, {}
	
	for itemID, data in pairs(TSMAPI:GetData("lastCompleteScan") or {}) do
		local dealfindingData = TSM.Config:GetDealfindingData(itemID)
		if dealfindingData and dealfindingData.maxPrice and data.minBuyout and dealfindingData.maxPrice >= data.minBuyout then
			local filterData = TSMAPI:GetAuctionQueryInfo(itemID)
			if filterData then
				tinsert(filters, filterData)
				tinsert(filterStrings, filterData.name)
			end
		end
	end
		
	filters.num = #filters
	filters.currentFilter = table.concat(filterStrings, "; ")
	if #filters == 0 then
		return TSM:Print(L["Nothing below dealfinding price from last scan."])
	end
	
	local function ShouldStop(link, buyout)
		local tmp = TSM.Config:GetDealfindingData(TSMAPI:GetItemID(link))
		local maxPrice = tmp and tmp.maxPrice
		if maxPrice then
			return buyout > maxPrice
		end
	end
	
	specialSearchMode = "Dealfinding"
	Search.searchST:SetPctColText(L["% Max Price"])
	Search:StartScan(filters, {L["Dealfinding Search"]}, ShouldStop)
end


-- ------------------------------------------------ --
--				Scanning Processing functions				 --
-- ------------------------------------------------ --

-- Function for handling LibAuctionScan's callbacks
function Search:OnScanCallback(event, ...)
	if event == "QUERY_FINISHED" then
		local data = ...
		Search:ProcessScan(data.data, Search.currentSearch.num - data.left + 1)
	elseif event == "SCAN_STATUS_UPDATE" then
		Search:UpdateTopLabel(...)
	elseif event == "SCAN_COMPLETE" or event == "SCAN_INTERRUPTED" then
		local data = select(1, ...)
		Search:ProcessScan(data, true)
	end
end

-- processes scan data
function Search:ProcessScan(scanData, isComplete)
	if not scanData then return end
	
	local filterNum = Search.currentSearch.num
	if type(isComplete) == "number" then
		filterNum = isComplete
		isComplete = nil
	end
	
	local numAuctions = 0
	local toRemove = {}
	for itemString, obj in pairs(scanData) do
		local badRecords = {}
		for i, record in ipairs(obj.records) do
			if not record.buyout or record.buyout == 0 then
				tinsert(badRecords, i)
			end
		end
		for i=#badRecords, 1, -1 do
			obj:RemoveRecord(badRecords[i])
		end
		
		if #obj.records == 0 then
			tinsert(toRemove, itemString)
		elseif not obj.searchFlag then
			local validItem = true
			local filter = Search.currentSearch.filters[filterNum]
			if type(filter) == "table" and not Search:IsSpecialSearch() then
				local name, _, rarity, iLevel = GetItemInfo(itemString)
				if filter.exactOnly and filter.exactOnly ~= 0 then
					validItem = name and strlower(name) == strlower(filter.name)
				end
				if (filter.minILevel and filter.minILevel ~= 0) or (filter.maxILevel and filter.maxILevel ~= 0) then
					if iLevel then
						filter.minILevel = filter.minILevel or 0
						if not filter.maxILevel or filter.maxILevel == 0 then
							filter.maxILevel = math.huge
						end
						
						validItem = validItem and iLevel >= filter.minILevel and iLevel <= filter.maxILevel
					end
				end
				if filter.quality and filter.quality ~= 0 then
					validItem = validItem and rarity and rarity == filter.quality
				end
			elseif specialSearchMode == "Dealfinding" then
				local data = TSM.Config:GetDealfindingData(obj:GetItemID())
				if data then
					obj:FilterRecords(function(record)
							if data.evenStacks and record.count % 5 ~= 0 then
								return true
							end
							
							if TSM.db.profile.dealfindingShowAboveMaxPrice then
								return (record:GetItemBuyout() or 0) > data.maxPrice
							end
						end)
					validItem = #obj.records > 0
				else
					validItem = false
				end
			elseif specialSearchMode == "Vendor" then
				local vendorPrice = select(11, GetItemInfo(itemString))
				if vendorPrice and vendorPrice > 0 then
					obj:FilterRecords(function(record) return (record:GetItemBuyout() or 0) >= vendorPrice end)
					validItem = #obj.records > 0
				else
					validItem = false
				end
			elseif specialSearchMode == "Disenchant" then
				local deValue = TSMAPI:GetData("deValue", itemString)
				if deValue > 0 then
					obj:FilterRecords(function(record) return (record:GetItemBuyout() or 0) >= deValue end)
					validItem = #obj.records > 0
				else
					validItem = false
				end
			end
			
			if Search:IsAutomaticMode() then
				validItem = specialSearchMode == itemString
			end
			
			-- delete if it's not an item we want
			-- set up the market value and add up the auctions
			if validItem then
				Search:SetMarketPrice(obj)
				obj.searchFlag = true
				numAuctions = numAuctions + #obj.records
			else
				tinsert(toRemove, itemString)
			end
		else
			numAuctions = numAuctions + #obj.records
		end
	end
	
	for _, itemString in ipairs(toRemove) do
		scanData[itemString] = nil
	end
	
	if isComplete then
		-- set topLabel text
		if numAuctions == 0 then
			Search.topLabel.text:SetText(BROWSE_NO_RESULTS)
			TSM.AuctionControl:SetCurrentAuction(Search.currentSearch.filter)
		elseif Search.currentSearch.lists then
			if #Search.currentSearch.lists == 1 then
				Search.topLabel.text:SetFormattedText(L["Showing summary of all %s auctions for list \"%s\""], TSMAPI.Design:GetInlineColor("link")..numAuctions.."|r", TSMAPI.Design:GetInlineColor("link")..Search.currentSearch.lists[1].."|r")
			else
				Search.topLabel.text:SetFormattedText(L["Showing summary of all %s auctions for \"%sDealfinding Search|r\""], TSMAPI.Design:GetInlineColor("link")..numAuctions.."|r", TSMAPI.Design:GetInlineColor("link"))
			end
		else
			Search.topLabel.text:SetFormattedText(L["Showing summary of all %s auctions that match filter \"%s\""], TSMAPI.Design:GetInlineColor("link")..numAuctions.."|r", TSMAPI.Design:GetInlineColor("link")..Search.currentSearch.filter.."|r")
		end
		
		-- let the Automatic code know we are done
		if Search:IsAutomaticMode() then
			Search:SendMessage("TSM_AUTOMATIC_SCAN_COMPLETE")
		else
			Search.searchBar:Enable()
		end
		Search.isScanning = nil
	end
	
	Search.auctions = scanData
	Search:UpdateSearchSTData()

	if isComplete and Search.searchST.rows[1] then
		local rowFrame = Search.searchST.rows[1]
		local colFrame = rowFrame.cols[1]
		
		-- click the first row (need to click the column)
		colFrame:Click()
		
		if TSM.db.profile.autoExpandSingleResult and #Search.searchST.data == 1 then
			-- expand the item
			local handler = colFrame:GetScript("OnDoubleClick")
			handler(rowFrame, colFrame, Search.searchST.data, _, _, 1, _, Search.searchST)
		end
	else
		-- more visually appealing if nothing is selected while we search
		Search.searchST:ClearSelection()
	end
end

function Search:GetAuctionData(itemString)
	return Search.auctions[itemString].records
end

function Search:TSM_SHOPPING_AH_EVENT(_, mode, postInfo)
	local stSelection = Search.searchST:GetSelection()
	local itemString, bid, buyout, count
	if stSelection and Search.searchST.data[stSelection] then
		itemString, bid, buyout, count = unpack(Search.searchST.data[stSelection].args)
	elseif mode == "Post" and postInfo then
		itemString, bid, buyout, count = postInfo.itemString, postInfo.bid, postInfo.buyout, postInfo.count
	else
		return
	end
	
	-- If we are in Automatic mode and this was the last one we needed to buy, don't bother updating anything.
	if Search:IsAutomaticMode() then
		if mode == "Buyout" then
			local isDone = TSM.Automatic:ProcessPurchase(itemString, count)
			if isDone then	return end
		end
	end
	
	if mode == "Buyout" or mode == "Cancel" then
		local auctionItem = Search.auctions[itemString]
		if auctionItem then
			for i, record in ipairs(auctionItem.records) do
				if record:GetDisplayedBid() == bid and record.buyout == buyout and record.count == count then
					auctionItem:RemoveRecord(i)
					break
				end
			end
			
			if #auctionItem.records == 0 then
				Search.auctions[itemString] = nil
			end
		end
	elseif mode == "Post" then
		if not Search.auctions[itemString] then
			local aucItem = TSMAPI:NewAuctionItem()
			aucItem:SetItemLink(postInfo.link)
			Search:SetMarketPrice(aucItem)
			Search.auctions[itemString] = aucItem
		end
		for i=1, postInfo.numStacks do
			Search.auctions[itemString]:AddAuctionRecord(unpack(postInfo))
		end
	end
	
	-- get the next row to click on and then update the ST
	local rowButton
	for i=1, #Search.searchST.filtered do
		if Search.searchST.filtered[i] == stSelection then
			rowButton = Search.searchST.rows[i-Search.searchST.offset] and Search.searchST.rows[i-Search.searchST.offset].cols[1]
			break
		end
	end
	Search:UpdateSearchSTData()
	
	
	if not TSM.AuctionControl:IsConfirmationVisible() then
		if stSelection and Search.searchST.data[stSelection] and rowButton then
			rowButton:Click()
		else
			Search.searchST:SetSelection()
			TSM.AuctionControl:SetCurrentAuction()
		end
	end
end