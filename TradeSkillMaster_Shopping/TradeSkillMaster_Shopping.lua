local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster_Shopping", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0")

local savedDBDefaults = {
	global = {
		previousSearches = {},
		automaticDestroyingModes = {mill=true, prospect=true, disenchant=true, transform=true},
		treeGroupStatus = {},
	},
	profile = {
		version = 0,
		fullStacksOnly = true,
		tradeInks = true,
		evenStacks = true,
		dealfinding = {},
		shopping = {},
		postDuration = 1,
		postUndercut = 1,
		postPriceSource = "DBMarket",
		postPriceSourcePercent = 1.5,
		postBidPercent = 0.95,
		searchDefaultSort = 8,
		destroyingDefaultSort = 5,
		autoExpandSingleResult = true,
		dealfindingShowAboveMaxPrice = false,
        searchMarketValue = "DBMarket",
	},
}

TSM.sortTemp = {}

function TSM:OnInitialize()
	TSM.db = LibStub("AceDB-3.0"):New("TradeSkillMaster_ShoppingDB", savedDBDefaults)
	TSM:UpdateDB()
	
	local version = GetAddOnMetadata("TradeSkillMaster_Shopping", "version")
	TSMAPI:RegisterReleasedModule("TradeSkillMaster_Shopping", version, GetAddOnMetadata("TradeSkillMaster_Shopping", "author"), GetAddOnMetadata("TradeSkillMaster_Shopping", "notes"), 1)
	TSMAPI:RegisterIcon(L["Shopping Options"], "Interface\\Icons\\Inv_Misc_Token_ArgentDawn2", function(...) TSM.Config:Load(...) end, "TradeSkillMaster_Shopping", "options")
	TSMAPI:RegisterAuctionSTRightClickFunction(L["Add item to shopping list"], TSM.AuctionSTRightClickCallbackShopping)
	TSMAPI:RegisterAuctionSTRightClickFunction(L["Add item to dealfinding list"], TSM.AuctionSTRightClickCallbackDealfinding)
	TSMAPI:RegisterData("newShoppingList", TSM.NewShoppingList)
	
	for name, module in pairs(TSM.modules) do
		TSM[name] = module
	end
	if TSMAPI.GetItemInfoCache then
		local itemIDs = {}
		for name, data in pairs(TSM.db.profile.shopping) do
			for itemID in pairs(data) do
				if itemID ~= "searchTerms" then
					itemIDs[itemID] = true
				end
			end
		end
		for name, data in pairs(TSM.db.profile.dealfinding) do
			for itemID in pairs(data) do
				itemIDs[itemID] = true
			end
		end
		TSMAPI:GetItemInfoCache(itemIDs, true)
	end
	
	local function FixListNames()
		local numLeft = 0
		for listName, data in pairs(TSM.db.profile.shopping) do
			if listName ~= "searchTerms" then
				for itemID, itemData in pairs(data) do
					if type(itemData.name) == "number" then
						local name = GetItemInfo(itemID)
						if name then
							itemData.name = name
						else
							numLeft = numLeft + 1
						end
					end
				end
			end
		end
		for _, data in pairs(TSM.db.profile.dealfinding) do
			for itemID, itemData in pairs(data) do
				if type(itemData.name) == "number" then
					local name = GetItemInfo(itemID)
					if name then
						itemData.name = name
					else
						numLeft = numLeft + 1
					end
				end
			end
		end
	
		if numLeft == 0 then
			TSMAPI:CancelFrame("shoppingItemIDNames")
		end
	end
	TSMAPI:CreateTimeDelay("shoppingItemIDNames", 5, FixListNames, 5)
end

function TSM:UpdateDB()
	-- for new shopping functions in new AH tab
	TSM.db.global.itemNames = nil
	
	-- to adjust for change to "Dealfinding Lists"
	if not TSM.db.profile.version or TSM.db.profile.version < 1 then
		-- for changes to how dealfinding things are stored
		local toRemove = {}
		for itemID, data in pairs(TSM.db.profile.dealfinding) do
			if not data.maxPrice or data.maxPrice <= 0 then
				tinsert(toRemove, itemID)
			end
		end
		for _, itemID in ipairs(toRemove) do
			TSM.db.profile.dealfinding[itemID] = nil
			for name, items in pairs(TSM.db.profile.folders or {}) do
				items[itemID] = nil
			end
		end
		toRemove = {}
		for folderName, items in pairs(TSM.db.profile.folders or {}) do
			local isValid = false
			for _ in pairs(items) do
				isValid = true
				break
			end
			if not isValid then
				tinsert(toRemove, folderName)
			end
		end
		for _, name in ipairs(toRemove) do
			TSM.db.profile.folders[name] = nil
		end
	
		TSM.db.profile.version = 1
		local dealfinding, allItems = {}, {}
		for itemID in pairs(TSM.db.profile.dealfinding) do
			allItems[itemID] = true
		end
		
		for folderName, items in pairs(TSM.db.profile.folders or {}) do
			dealfinding[folderName] = {}
			for itemID in pairs(items) do
				allItems[itemID] = nil
				if TSM.db.profile.dealfinding[itemID] then
					dealfinding[folderName][itemID] = CopyTable(TSM.db.profile.dealfinding[itemID])
				end
			end
		end
		
		local name = "DealfindingList"
		for i = 1, 1000 do
			if not dealfinding[name] then break end
			name = "DealfindingList"..i
		end
		
		dealfinding[name] = {}
		for itemID in pairs(allItems) do
			dealfinding[name][itemID] = CopyTable(TSM.db.profile.dealfinding[itemID])
		end
		
		TSM.db.profile.dealfinding = dealfinding
		TSM.db.profile.folders = nil
	end
	
	-- for new shopping lists
	if TSM.db.global.favoriteSearches then
		for _, searchTerm in ipairs(TSM.db.global.favoriteSearches) do
			local name
			for i = 1, 1000 do
				name = "Favorite Search "..i
				if not TSM.db.profile.shopping[name] and not TSM.db.profile.dealfinding[name] then break end
			end
			
			TSM.db.profile.shopping[name] = {searchTerms={}}
			local newTerms = {}
			
			for _, term in ipairs({(";"):split(searchTerm)}) do
				term = strlower(term:trim())
				if term and term ~= "" then
					tinsert(TSM.db.profile.shopping[name].searchTerms, term)
				end
			end
			
			if #TSM.db.profile.shopping[name].searchTerms == 0 then
				TSM.db.profile.shopping[name] = nil
			end
		end
		
		TSM.db.global.favoriteSearches = nil
	end
end

function TSM:UnformatTextMoney(value)
	value = gsub(value, "|cffffd700g|r", "g")
	value = gsub(value, "|cffc7c7cfs|r", "s")
	value = gsub(value, "|cffeda55fc|r", "c")
	local gold = tonumber(string.match(value, "([0-9]+)g"))
	local silver = tonumber(string.match(value, "([0-9]+)s"))
	local copper = tonumber(string.match(value, "([0-9]+)c"))
	
	if not gold and not silver and not copper then
		return
	else
		-- Convert it all into copper
		return (copper or 0) + ((gold or 0) * COPPER_PER_GOLD) + ((silver or 0) * COPPER_PER_SILVER)
	end
end

function TSM:StartScan(filters, obj, ShouldStop)
	obj.searchST:SetData({})
	obj.isScanning = #filters or true
	
	TSM.AuctionControl:SetCurrentAuction()
	TSMAPI:StartScan(filters, function(...) obj:OnScanCallback(...) end, {sellerResolution=true, useItemStrings=true, missingSellerName="---", maxRetries=2, ShouldStop=ShouldStop})
end

local function getIndex(t, value)
	for i, v in pairs(t) do
		if v == value then
			return i
		end
	end
end

local OpenRightClickWindow
function TSM:GetAuctionSTRightClickWindow(parent, title)
	if OpenRightClickWindow then OpenRightClickWindow:Hide() end
	
	local x, y = GetCursorPosition()
	x = x / UIParent:GetEffectiveScale()
	y = y / UIParent:GetEffectiveScale()
	
	local window = AceGUI:Create("TSMWindow")
	window.frame:SetParent(parent)
	window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	window:SetWidth(500)
	window:SetHeight(200)
	window:SetTitle(title)
	window:SetLayout("Flow")
	window.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	window:SetCallback("OnClose", function(self)
			self:ReleaseChildren()
			OpenRightClickWindow = nil
			window.frame:Hide()
		end)
	OpenRightClickWindow = window
	return window
end

function TSM.AuctionSTRightClickCallbackShopping(parent, itemLink)
	if OpenRightClickWindow then OpenRightClickWindow:Hide() end
	
	local listSelection, newListName
	local itemID = TSMAPI:GetItemID(itemLink)
	local window = TSM:GetAuctionSTRightClickWindow(parent, L["Add Item to Shopping List"])
	
	local shoppingLists = {}
	for listName in pairs(TSM.db.profile.shopping) do
		shoppingLists[listName] = listName
	end

	local page = {
		{
			type = "InteractiveLabel",
			text = itemLink,
			fontObject = GameFontHighlight,
			relativeWidth = 1,
			callback = function() SetItemRef("item:".. itemID, itemID) end,
			tooltip = itemID,
		},
		{
			type = "HeadingLine"
		},
		{
			type = "Dropdown",
			label = L["List to Add Item to:"],
			list = shoppingLists,
			value = 1,
			relativeWidth = 0.49,
			callback = function(self, _, value)
					value = value:trim()
					listSelection = value
					local i = getIndex(self.parent.children, self)
					self.parent.children[i+2]:SetDisabled(not value or value == "")
				end,
			tooltip = L["Which list to add this item to."],
		},
		{
			type = "Label",
			text = "",
			relativeWidth = 0.02,
		},
		{
			type = "Button",
			text = L["Add Item to Selected List"],
			relativeWidth = 0.49,
			disabled = true,
			callback = function(self)
					if listSelection then
						TSM.db.profile.shopping[listSelection][itemID] = {name=(GetItemInfo(itemID) or itemID)}
						window.frame:Hide()
					end
				end,
		},
		{
			type = "Spacer"
		},
		{
			type = "EditBox",
			label = L["Name of New List to Add Item to:"],
			relativeWidth = 0.49,
			callback = function(self, _, value)
					value = value:trim()
					if TSM.db.profile.shopping[value] then return end
					local i = getIndex(self.parent.children, self)
					self.parent.children[i+2]:SetDisabled(not value or value == "")
					newListName = value
				end,
		},
		{
			type = "Label",
			text = "",
			relativeWidth = 0.02,
		},
		{
			type = "Button",
			text = L["Add Item to New List"],
			relativeWidth = 0.49,
			disabled = true,
			callback = function(self)
					if newListName then
						TSM.db.profile.shopping[newListName] = {searchTerms={}, [itemID]={name=(GetItemInfo(itemID) or itemID)}}
						window.frame:Hide()
					end
				end,
		},
	}

	TSMAPI:BuildPage(window, page)
end

function TSM.AuctionSTRightClickCallbackDealfinding(parent, itemLink)
	if OpenRightClickWindow then OpenRightClickWindow:Hide() end
	
	local listSelection, newListName, inDealfindingList
	local itemID = TSMAPI:GetItemID(itemLink)
	local window = TSM:GetAuctionSTRightClickWindow(parent, L["Add Item to Dealfinding List"])
	
	for listName, items in pairs(TSM.db.profile.dealfinding) do
		if items[itemID] then
			inDealfindingList = listName
			break
		end
	end

	local page = {}
	
	if inDealfindingList then
		page = {
			{
				type = "InteractiveLabel",
				text = itemLink,
				fontObject = GameFontHighlight,
				relativeWidth = 1,
				callback = function() SetItemRef("item:".. itemID, itemID) end,
				tooltip = itemID,
			},
			{
				type = "HeadingLine"
			},
			{
				type = "Label",
				text = format(L["This item is already in the \"%s\" Dealfinding List."], inDealfindingList),
				relativeWidth = 1,
			}
		}
	else
		local dealfindingList = {}
		for listName in pairs(TSM.db.profile.dealfinding) do
			dealfindingList[listName] = listName
		end
	
		page = {
			{
				type = "InteractiveLabel",
				text = itemLink,
				fontObject = GameFontHighlight,
				relativeWidth = 1,
				callback = function() SetItemRef("item:".. itemID, itemID) end,
				tooltip = itemID,
			},
			{
				type = "HeadingLine"
			},
			{
				type = "Dropdown",
				label = L["List to Add Item to:"],
				list = dealfindingList,
				value = 1,
				relativeWidth = 0.49,
				callback = function(self, _, value)
						value = value:trim()
						listSelection = value
						local i = getIndex(self.parent.children, self)
						self.parent.children[i+2]:SetDisabled(not value or value == "")
					end,
				tooltip = L["Which list to add this item to."],
			},
			{
				type = "Label",
				text = "",
				relativeWidth = 0.02,
			},
			{
				type = "Button",
				text = L["Add Item to Selected List"],
				relativeWidth = 0.49,
				disabled = true,
				callback = function(self)
					if listSelection then
						TSM.db.profile.dealfinding[listSelection][itemID] = {name=(GetItemInfo(itemID) or itemID), maxPrice=1}
						window.frame:Hide()
					end
				end,
			},
			{
				type = "Spacer"
			},
			{
				type = "EditBox",
				label = L["Name of New List to Add Item to:"],
				relativeWidth = 0.49,
				callback = function(self, _, value)
						value = value:trim()
						if TSM.db.profile.dealfinding[value] then return end
						local i = getIndex(self.parent.children, self)
						self.parent.children[i+2]:SetDisabled(not value or value == "")
						newListName = value
					end,
			},
			{
				type = "Label",
				text = "",
				relativeWidth = 0.02,
			},
			{
				type = "Button",
				text = L["Add Item to New List"],
				relativeWidth = 0.49,
				disabled = true,
				callback = function(self)
						if newListName then
							TSM.db.profile.dealfinding[newListName] = {[itemID]={name=(GetItemInfo(itemID) or itemID), maxPrice=1}}
							window.frame:Hide()
						end
					end,
			},
		}
	end

	TSMAPI:BuildPage(window, page)
end

function TSM:NewShoppingList(name, data)
	local newListName = name
	for i = 1, 1000 do
		if not TSM.db.profile.shopping[newListName] then break end
		newListName = name..i
	end
	
	TSM.db.profile.shopping[newListName] = {searchTerms={}}
	for itemID in pairs(data) do
		TSM.db.profile.shopping[newListName][itemID] = {name=(GetItemInfo(itemID) or itemID)}
	end
	
	return newListName
end