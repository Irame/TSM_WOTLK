-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Shopping - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_shopping.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


local TSM = select(2, ...)
local Config = TSM:NewModule("Config", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table



-- *************************Helper Functions***********************************

local function SelectTreePath(major, minor)
	if type(major) == "number" then
		Config:UpdateTree()
		if minor then
			Config.treeGroup:SelectByPath(major, minor)
		else
			Config.treeGroup:SelectByPath(major)
		end
	elseif type(major) == "string" then
		local major = (major == "shopping" and 4) or (major == "dealfinding" and 3)
		if major then
			SelectTreePath(major, minor)
		end
	end
end

local function AddWidgets(tbl, widgets)
	for _, widget in ipairs(widgets) do
		tinsert(tbl, widget)
	end
end

local function AddItemToList(eb, item, listType, list, try)
	item = item:trim()
	local itemID = tonumber(item) or TSMAPI:GetItemID(item)
	
	-- check if the item is already in the group
	if itemID and TSM.db.profile[listType][list][itemID] then
		TSM:Print(L["This item is already in this group."])
		return
	end
	
	-- validate the item
	try = try or 0
	if itemID and not GetItemInfo(itemID) and try < 3 then
		return TSMAPI:CreateTimeDelay("shoppingAddItemToList", 0.2, function() AddItemToList(eb, tostring(itemID), listType, list, try+1) end)
	end
	local ok, name, link = pcall(function() return GetItemInfo(itemID or item) end)
	if not (ok and name and link) and not (itemID and itemID < 100000 and itemID > 0) then
		TSM:Printf(L["The item you entered was invalid. See the tooltip for the \"%s\" editbox for info about how to add items."], L["Item to Add"])
		eb:SetFocus()
		return
	end
	
	-- make sure we don't already have this item in dealfinding
	itemID = itemID or TSMAPI:GetItemID(link)
	if listType == "dealfinding" then
		for listName, items in pairs(TSM.db.profile.dealfinding) do
			if items[itemID] then
				TSM:Printf(L["Item is already in dealfinding list: %s"], listName)
				eb:SetFocus()
				return
			end
		end
		TSM.db.profile.dealfinding[list][itemID] = {name=(name or itemID), maxPrice=1}
	else
		TSM.db.profile.shopping[list][itemID] = {name=(name or itemID)}
	end
	
	SelectTreePath(listType, list)
end

local function RemoveItemFromList(itemID, listType, list)
	TSM.db.profile[listType][list][itemID] = nil
	SelectTreePath(listType, list)
end

local function AddList(eb, listName, listType)
	listName = listName:trim()
	if not listName or listName == "" or TSM.db.profile[listType][listName] then
		TSM:Printf(L["Invalid list name. A list with this name may already exist."])
		eb:SetFocus()
		return
	end
	
	if listType == "shopping" then
		TSM.db.profile.shopping[listName] = {searchTerms={}}
	else
		TSM.db.profile.dealfinding[listName] = {}
	end
	Config:UpdateTree()
	SelectTreePath(listType, listName)
end



-- ************************Config Util Functions**********************************

function Config:GetDealfindingData(itemID)
	for _, items in pairs(TSM.db.profile.dealfinding) do
		if items[itemID] then
			return items[itemID]
		end
	end
end

function Config:CreateNewShoppingList(name, nameIsTerm)
	local listName = name
	if TSM.db.profile.shopping[listName] or TSM.db.profile.dealfinding[listName] then
		listName = name
		for i = 1, 1000 do
			listName = name .. i
			if not TSM.db.profile.shopping[listName] and not TSM.db.profile.dealfinding[listName] then break end
		end
		TSM:Printf(L["Shopping/Dealfinding list with name \"%s\" already exists. Creating group under name \"%s\" instead."], name, listName)
	end
	
	TSM.db.profile.shopping[listName] = {searchTerms={}}
	if nameIsTerm then
		tinsert(TSM.db.profile.shopping[listName].searchTerms, name)
	end
end

function Config:SelectTreePath(major, minor)
	SelectTreePath(major, minor)
end



-- *************************Config UI Functions***********************************

function Config:Load(parent)
	local treeGroup = AceGUI:Create("TSMTreeGroup")
	treeGroup:SetLayout("Fill")
	treeGroup:SetCallback("OnGroupSelected", function(...) Config:SelectTree(...) end)
	treeGroup:SetStatusTable(TSM.db.global.treeGroupStatus)
	parent:AddChild(treeGroup)
	
	Config.treeGroup = treeGroup
	SelectTreePath(1)
end

function Config:UpdateTree()
	if not Config.treeGroup then return end
	
	local pageNum
	local dealfindingLists, shoppingLists = {}, {}
	local treeGroups = {{value=1, text=L["Options"]}, {value=2, text=L["Profiles"]},
		{value=3, text=L["Dealfinding Lists"], children=dealfindingLists}, {value=4, text=L["Shopping Lists"], children=shoppingLists}}
	
	-- populate the dealfinding lists
	for listName, items in pairs(TSM.db.profile.dealfinding) do
		tinsert(dealfindingLists, {value=listName, text=TSMAPI.Design:GetInlineColor("category")..listName.."|r"})
	end
	sort(dealfindingLists, function(a, b) return strlower(a.text) < strlower(b.text) end)
	
	-- populate the shopping lists
	for listName, items in pairs(TSM.db.profile.shopping) do
		tinsert(shoppingLists, {value=listName, text=listName})
	end
	sort(shoppingLists, function(a, b) return strlower(a.text) < strlower(b.text) end)
	
	Config.treeGroup:SetTree(treeGroups)
end

function Config:SelectTree(treeFrame, _, selection)
	treeFrame:ReleaseChildren()
	local selectedParent, selectedChild, selectedSubChild = ("\001"):split(selection)
	
	local content = AceGUI:Create("TSMSimpleGroup")
	content:SetLayout("Fill")
	treeFrame:AddChild(content)
	
	if tonumber(selectedParent) == 1 then
		Config:LoadOptionsPage(content)
	elseif tonumber(selectedParent) == 2 then
		Config:LoadProfilesPage(content)
	elseif tonumber(selectedParent) == 3 then
		if not selectedChild then
			Config:LoadDealfindingListOptions(content)
		else
			local tg = AceGUI:Create("TSMTabGroup")
			tg:SetLayout("Fill")
			tg:SetFullHeight(true)
			tg:SetFullWidth(true)
			tg:SetTabs({{value=1, text=L["Items"]}, {value=2, text=L["List Management"]}})
			tg:SetCallback("OnGroupSelected", function(self,_,value)
				tg:ReleaseChildren()
				content:DoLayout()
				
				if value == 1 then
					Config:LoadDealfindingItemOptions(self, selectedChild)
				else
					Config:LoadListManagement(self, "dealfinding", selectedChild)
				end
			end)
			content:AddChild(tg)
			tg:SelectTab(1)
		end
	elseif tonumber(selectedParent) == 4 then
		if not selectedChild then
			Config:LoadShoppingListOptions(content)
		else
			local tg = AceGUI:Create("TSMTabGroup")
			tg:SetLayout("Fill")
			tg:SetFullHeight(true)
			tg:SetFullWidth(true)
			tg:SetTabs({{value=1, text=L["Items"]}, {value=2, text=L["List Management"]}})
			tg:SetCallback("OnGroupSelected", function(self,_,value)
				tg:ReleaseChildren()
				content:DoLayout()
				
				if value == 1 then
					Config:LoadShoppingItemOptions(self, selectedChild)
				else
					Config:LoadListManagement(self, "shopping", selectedChild)
				end
			end)
			content:AddChild(tg)
			tg:SelectTab(1)
		end
	end
end

function Config:LoadOptionsPage(container)
    -- price sources for % of market value
    local mktPriceSrc = CopyTable(TSMAPI:GetPriceSources())
    -- remove irrelevant ones fromm the list
    mktPriceSrc["AucMinBuyout"] = nil
    mktPriceSrc["IACost"] = nil
    mktPriceSrc["Crafting"] = nil
    mktPriceSrc["Vendor"] = nil
    mktPriceSrc["AucMinBuyout"] = nil
    mktPriceSrc["DBMinBuyout"] = nil
    mktPriceSrc["TUJGEMedian"] = nil
    mktPriceSrc["wowuctionMinBuyout"] = nil

	local function UnformatTextMoney(value)
		local gold = tonumber(strmatch(value, "([0-9]+)|c([0-9a-fA-F]+)g|r") or strmatch(value, "([0-9]+)g"))
		local silver = tonumber(strmatch(value, "([0-9]+)|c([0-9a-fA-F]+)s|r") or strmatch(value, "([0-9]+)s"))
		local copper = tonumber(strmatch(value, "([0-9]+)|c([0-9a-fA-F]+)c|r") or strmatch(value, "([0-9]+)c"))
		
		if not copper and not silver and not gold then
			return
		end
		
		return (copper or 0) + (silver or 0) * COPPER_PER_SILVER + (gold or 0) * COPPER_PER_GOLD
	end


	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["General Options"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Below are some general options for the Shopping module."],
						},
						{
							type = "HeadingLine"
						},
						{
							type = "Dropdown",
							label = L["Search Results Default Sort (requires reload)"],
							relativeWidth = 0.5,
							list = {L["Item"], L["Item Level"], L["Auctions"], L["Stack Size"], L["Time Left"], L["Seller"], L["Price Per Item/Stack"], L["% Market Value"]},
							value = TSM.db.profile.searchDefaultSort,
							callback = function(_,_,value) TSM.db.profile.searchDefaultSort = value end,
							tooltip = L["Specifies the default sorting for results in the \"Search\" feature."],
						},
						{
							type = "Dropdown",
							label = L["Search Results Market Value Price Source"],
							relativeWidth = 0.5,
							list = mktPriceSrc,
							value = TSM.db.profile.searchMarketValue,
							callback = function(_,_,value) TSM.db.profile.searchMarketValue = value end,
							tooltip = L["Specifies the market value price source for results in the \"Search\" feature."],
						},
                        {
                            type = "Dropdown",
                            label = L["Destroying Results Default Sort (requires reload)"],
                            relativeWidth = 0.5,
                            list = {L["Item"], L["Auctions"], L["Stack Size"], L["Seller"], L["Price Per Target Item"], L["Price Per Item/Stack"], L["% Market Value"]},
                            value = TSM.db.profile.destroyingDefaultSort,
                            callback = function(_,_,value) TSM.db.profile.destroyingDefaultSort = value end,
                            tooltip = L["Specifies the default sorting for results in the \"Destroying\" feature."],
                        },
                        {
                            type = "Spacer",
                        },
						{
							type = "CheckBox",
							label = L["Automatically Expand Single Result"],
							relativeWidth = 0.5,
							quickCBInfo = {TSM.db.profile, "autoExpandSingleResult"},
							tooltip = L["If the results of a search only contain one unique item, it will be automatically expanded to show all auctions of that item if this option is enabled."],
						},
						{
							type = "CheckBox",
							label = L["Show Results Above Dealfinding Price"],
							relativeWidth = 0.5,
							quickCBInfo = {TSM.db.profile, "dealfindingShowAboveMaxPrice"},
							tooltip = L["If checked, the results of a dealfinding scan will include items above the maximum price. This can be useful if you sometimes want to buy items that are just above your max price."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Posting Options"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["The options below control the \"Post\" button that is shown at the bottom of the auction frame inside the \"Search\" feature."],
						},
						{
							type = "HeadingLine"
						},
						{
							type = "Dropdown",
							label = L["Auction Duration"],
							relativeWidth = 0.5,
							list = {L["12 hours"], L["24 hours"], L["48 hours"]},
							value = TSM.db.profile.postDuration,
							callback = function(_,_,value) TSM.db.profile.postDuration = value end,
							tooltip = L["How long auctions should be posted for."],
						},
						{
							type = "EditBox",
							value = TSMAPI:FormatTextMoney(TSM.db.profile.postUndercut),
							label = L["Default Undercut"],
							relativeWidth = 0.5,
							callback = function(self, _, value)
									local val = UnformatTextMoney(value)
									if val then
										TSM.db.profile.postUndercut = val
										self:ClearFocus()
									else
										TSM:Print(L["Invalid money format entered, should be \"#g#s#c\", \"25g4s50c\" is 25 gold, 4 silver, 50 copper."])
										self:SetFocus()
									end
									self:SetText(TSMAPI:FormatTextMoney(TSM.db.profile.postUndercut))
								end,
							tooltip = L["How much to undercut other auctions by, format is in \"#g#s#c\", \"50g30s\" means 50 gold, 30 silver."],
						},
						{
							type = "Slider",
							label = L["Bid Percent"],
							relativeWidth = 0.5,
							isPercent = true,
							min = 0.01,
							max = 1,
							step = 0.01,
							value = TSM.db.profile.postBidPercent,
							callback = function(_,_,value) TSM.db.profile.postBidPercent = value end,
							tooltip = L["Determines what percent of the buyout price Shopping will use for the starting bid when posting auctions."]
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Dropdown",
							label = L["Fallback Price Source"],
							relativeWidth = 0.5,
							list = TSMAPI:GetPriceSources(),
							value = TSM.db.profile.postPriceSource,
							callback = function(_,_,value) TSM.db.profile.postPriceSource = value end,
							tooltip = L["If there are none of an item on the auction house, Shopping will use this price source for the default post price."],
						},
						{
							type = "Slider",
							label = L["Fallback Price Percent"],
							relativeWidth = 0.5,
							isPercent = true,
							min = 0.1,
							max = 10,
							step = 0.05,
							value = TSM.db.profile.postPriceSourcePercent,
							callback = function(_,_,value) TSM.db.profile.postPriceSourcePercent = value end,
							tooltip = L["If there are none of an item on the auction house, Shopping will use this percentage of the fallback price source for the default post price."]
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:LoadShoppingListOptions(container)
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = "New Shopping List",
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Use the box below to create a new shopping list. A shopping list is a list of items and search terms you frequently search for."],
						},
						{
							type = "HeadingLine"
						},
						{
							type = "EditBox",
							label = L["Shopping List Name"],
							relativeWidth = 0.8,
							callback = function(eb,_,name) AddList(eb, name, "shopping") end,
							tooltip = L["Name of the new shopping list."],
						},
						{
							type = "HeadingLine"
						},
						{
							type = "Button",
							text = L["Import Shopping List"],
							relativeWidth = 1,
							callback = function() Config:OpenImportFrame("shopping") end,
							tooltip = L["Opens a new window that allows you to import a shopping list."]
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:LoadDealfindingListOptions(container)
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["New Dealfinding List"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Use the box below to create a new dealfinding list. A dealfinding list is a list of items along with a max price you'd like to pay for each item. This is the equivalent of a \"snatch list\"."],
						},
						{
							type = "HeadingLine"
						},
						{
							type = "EditBox",
							label = L["Dealfinding List Name"],
							relativeWidth = 0.8,
							callback = function(eb,_,name) AddList(eb, name, "dealfinding") end,
							tooltip = L["Name of the new dealfinding list."],
						},
						{
							type = "HeadingLine"
						},
						{
							type = "Button",
							text = L["Import Dealfinding List"],
							relativeWidth = 1,
							callback = function() Config:OpenImportFrame("dealfinding") end,
							tooltip = L["Opens a new window that allows you to import a dealfinding list."]
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:LoadProfilesPage(container)
	local text = {
		default = L["Default"],
		intro = L["You can change the active database profile, so you can have different settings for every character."],
		reset_desc = L["Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over."],
		reset = L["Reset Profile"],
		choose_desc = L["You can either create a new profile by entering a name in the editbox, or choose one of the already exisiting profiles."],
		new = L["New"],
		new_sub = L["Create a new empty profile."],
		choose = L["Existing Profiles"],
		copy_desc = L["Copy the settings from one existing profile into the currently active profile."],
		copy = L["Copy From"],
		delete_desc = L["Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file."],
		delete = L["Delete a Profile"],
		profiles = L["Profiles"],
		current = L["Current Profile:"] .. " " .. TSMAPI.Design:GetInlineColor("link") .. TSM.db:GetCurrentProfile() .. "|r",
	}
	
	-- Popup Confirmation Window used in this module
	StaticPopupDialogs["TSMShopProfiles.DeleteConfirm"] = StaticPopupDialogs["TSMShopProfiles.DeleteConfirm"] or {
		text = L["Are you sure you want to delete the selected profile?"],
		button1 = L["Accept"],
		button2 = L["Cancel"],
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnCancel = false,
		-- OnAccept defined later
	}
	
	-- Returns a list of all the current profiles with common and nocurrent modifiers.
	-- This code taken from AceDBOptions-3.0.lua
	local function GetProfileList(db, common, nocurrent)
		local profiles = {}
		local tmpprofiles = {}
		local defaultProfiles = {["Default"] = L["Default"]}
		
		-- copy existing profiles into the table
		local currentProfile = db:GetCurrentProfile()
		for i,v in pairs(db:GetProfiles(tmpprofiles)) do 
			if not (nocurrent and v == currentProfile) then 
				profiles[v] = v 
			end 
		end
		
		-- add our default profiles to choose from ( or rename existing profiles)
		for k,v in pairs(defaultProfiles) do
			if (common or profiles[k]) and not (nocurrent and k == currentProfile) then
				profiles[k] = v
			end
		end
		
		return profiles
	end
	
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "Label",
					text = "TradeSkillMaster_Shopping" .. "\n",
					fullWidth = true,
					colorRed = 255,
					colorGreen = 0,
					colorBlue = 0,
				},
				{
					type = "Label",
					text = text["intro"] .. "\n" .. "\n",
					fullWidth = true,
				},
				{
					type = "Label",
					text = text["reset_desc"],
					fullWidth = true,
				},
				{	--simplegroup1 for the reset button / current profile text
					type = "SimpleGroup",
					layout = "flow",
					fullWidth = true,
					children = {
						{
							type = "Button",
							text = text["reset"],
							callback = function()
									TSM.db:ResetProfile()
									SelectTreePath(2)
								end,
						},
						{
							type = "Label",
							text = text["current"],
						},
					},
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Label",
					text = text["choose_desc"],
					fullWidth = true,
				},
				{	--simplegroup2 for the new editbox / existing profiles dropdown
					type = "SimpleGroup",
					layout = "flow",
					fullWidth = true,
					children = {
						{
							type = "EditBox",
							label = text["new"],
							value = "",
							callback = function(_,_,value) 
									TSM.db:SetProfile(value)
									SelectTreePath(2)
								end,
						},
						{
							type = "Dropdown",
							label = text["choose"],
							list = GetProfileList(TSM.db, true, nil),
							value = TSM.db:GetCurrentProfile(),
							callback = function(_,_,value)
									if value ~= TSM.db:GetCurrentProfile() then
										TSM.db:SetProfile(value)
										SelectTreePath(2)
									end
								end,
						},
					},
				},
				{
					type = "Spacer",
					quantity = 1,
				},
				{
					type = "Label",
					text = text["copy_desc"],
					fullWidth = true,
				},
				{
					type = "Dropdown",
					label = text["copy"],
					list = GetProfileList(TSM.db, true, nil),
					value = "",
					disabled = not GetProfileList(TSM.db, true, nil) and true,
					callback = function(_,_,value)
							if value ~= TSM.db:GetCurrentProfile() then
								TSM.db:CopyProfile(value)
								SelectTreePath(2)
							end
						end,
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Label",
					text = text["delete_desc"],
					fullWidth = true,
				},
				{
					type = "Dropdown",
					label = text["delete"],
					list = GetProfileList(TSM.db, true, nil),
					value = "",
					disabled = not GetProfileList(TSM.db, true, nil) and true,
					callback = function(_,_,value)
							StaticPopupDialogs["TSMShopProfiles.DeleteConfirm"].OnAccept = function()
									TSM.db:DeleteProfile(value)
									SelectTreePath(2)
								end
							TSMAPI:ShowStaticPopupDialog("TSMShopProfiles.DeleteConfirm")
						end,
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:LoadDealfindingItemOptions(container, list)
	local itemWidgets = {
		{
			type = "Label",
			relativeWidth = 1,
			text = L["Here, you can set the maximum price you want to pay for each item in this list."], 
		},
		{
			type = "HeadingLine",
		}
	}
	
	for itemID, data in pairs(TSM.db.profile.dealfinding[list]) do
		local widgets = {
			{
				type = "InteractiveLabel",
				text = select(2, GetItemInfo(itemID)) or data.name,
				fontObject = GameFontHighlight,
				relativeWidth = 0.3,
				callback = function() SetItemRef("item:".. itemID, itemID) end,
				tooltip = itemID,
			},
			{
				type = "EditBox",
				label = L["Max Price Per Item"],
				relativeWidth = 0.2,
				value = TSMAPI:FormatTextMoney(TSM.db.profile.dealfinding[list][itemID].maxPrice),
				callback = function(self,_,value)
						local copper = TSM:UnformatTextMoney(value)
						if not copper then
							TSM:Print(L["Invalid money format entered, should be \"#g#s#c\", \"25g4s50c\" is 25 gold, 4 silver, 50 copper."])
							self:SetFocus()
						else
							self:ClearFocus()
							TSM.db.profile.dealfinding[list][itemID].maxPrice = copper
						end
					end,
				tooltip = L["This is the maximum price you want to pay per item (NOT per stack) for this item. You will be prompted to buy all items on the AH that are below this price."],
			},
			{
				type = "Label",
				relativeWidth = 0.01
			},
			{
				type = "CheckBox",
				label = L["Even Stacks Only"],
				relativeWidth = 0.27,
				quickCBInfo = {TSM.db.profile.dealfinding[list][itemID], "evenStacks"},
				tooltip = L["Only even stacks (5/10/15/20) of this item will be purchased. This is useful for buying herbs / ore to mill / prospect."],
			},
			{
				type = "Button",
				text = L["Remove"],
				relativeWidth = 0.19,
				callback = function() RemoveItemFromList(itemID, "dealfinding", list) end,
			},
		}
		
		AddWidgets(itemWidgets, widgets)
	end

	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Add Item"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Here you can add an item to this dealfinding list."],
						},
						{
							type = "HeadingLine"
						},
						{
							type = "EditBox",
							label = L["Item to Add"],
							relativeWidth = 0.8,
							callback = function(eb, _, item) AddItemToList(eb, item, "dealfinding", list) end,
							tooltip = L["You can either drag an item into this box, paste (shift click) an item link into this box, or enter an itemID."],
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Item Settings"],
					children = itemWidgets,
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:LoadShoppingItemOptions(container, list)
	local function AddSearchTermToList(eb, _, line)
		if not line or line:trim() == "" then
			TSM:Print(L["Invalid search term."])
			eb:SetFocus()
			return
		end
	
		local newTerms, currentTerms = {}, {}
		for _, term in ipairs(TSM.db.profile.shopping[list].searchTerms) do
			currentTerms[term] = true
		end
		
		for _, term in ipairs({(";"):split(line)}) do
			term = strlower(term:trim())
			if currentTerms[term] then
				TSM:Printf(L["Did not add search term \"%s\". Already in this list."], term)
			else
				tinsert(TSM.db.profile.shopping[list].searchTerms, term)
			end
		end
		
		SelectTreePath("shopping", list)
	end

	local itemWidgets = {
		{
			type = "Label",
			relativeWidth = 1,
			text = L["Here, you can remove items from this list."], 
		},
		{
			type = "HeadingLine",
		}
	}
	local searchTermWidgets = {
		{
			type = "Label",
			relativeWidth = 1,
			text = L["Here, you can remove search terms from this list."], 
		},
		{
			type = "HeadingLine",
		}
	}
	
	local itemsInList = {}
	for itemID, data in pairs(TSM.db.profile.shopping[list]) do
		if itemID ~= "searchTerms" then
			tinsert(itemsInList, itemID)
		else
			for i, term in ipairs(data) do
				local widgets = {
					{
						type = "Button",
						text = L["Remove"],
						relativeWidth = 0.19,
						callback = function()
								tremove(TSM.db.profile.shopping[list].searchTerms, i)
								SelectTreePath("shopping", list)
							end,
					},
					{
						type = "Label",
						text = "\"" .. term .. "\"",
						relativeWidth = 0.3
					},
				}
				
				AddWidgets(searchTermWidgets, widgets)
			end
		end
	end
	
	sort(itemsInList, function(a, b) return (GetItemInfo(a) or "") < (GetItemInfo(b) or "") end)
	
	for i = 1, #itemsInList do
		local itemID = itemsInList[i]
		local widgets = {
			{
				type = "Button",
				text = L["Remove"],
				relativeWidth = 0.19,
				callback = function() RemoveItemFromList(itemID, "shopping", list) end,
			},
			{
				type = "InteractiveLabel",
				text = select(2, GetItemInfo(itemID)) or TSM.db.profile.shopping[list][itemID].name,
				fontObject = GameFontHighlight,
				relativeWidth = 0.295,
				callback = function() SetItemRef("item:".. itemID, itemID) end,
				tooltip = itemID,
			},
			{
				type = "Label",
				relativeWidth = 0.01
			},
			
		}
		
		AddWidgets(itemWidgets, widgets)
	end

	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Add Item / Search Term"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Here you can add an item or a search term to this shopping list."],
						},
						{
							type = "HeadingLine"
						},
						{
							type = "EditBox",
							label = L["Add Item"],
							relativeWidth = 0.8,
							callback = function(eb, _, item) AddItemToList(eb, item, "shopping", list) end,
							tooltip = L["You can either drag an item into this box, paste (shift click) an item link into this box, or enter an itemID."],
						},
						{
							type = "EditBox",
							label = L["Add Search Term"],
							relativeWidth = 0.8,
							callback = AddSearchTermToList,
							tooltip = L["Enter the search term you would list to add below. You can add multiple search terms at once by separating them with semi-colons. For example, \"elementium ore; volatile\""],
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Remove Item"],
					children = itemWidgets,
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Remove Search Term"],
					children = searchTermWidgets,
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:LoadListManagement(container, listType, listName)
	local otherType = listType == "dealfinding" and "shopping" or "dealfinding"
	
	local function SwitchType()
		TSM.db.profile[otherType][listName] = {}
		
		if otherType == "shopping" then
			for itemID, data in pairs(TSM.db.profile.dealfinding[listName]) do
				TSM.db.profile.shopping[listName].searchTerms = {}
				TSM.db.profile.shopping[listName][itemID] = {name=data.name}
			end
		else
			for itemID, data in pairs(TSM.db.profile.shopping[listName]) do
				if itemID ~= "searchTerms" then
					if not Config:GetDealfindingData(itemID) then
						TSM.db.profile.dealfinding[listName][itemID] = {name=data.name, evenStacks=nil, maxPrice=1}
					else
						local name = select(2, GetItemInfo(itemID)) or data.name
						TSM:Printf(L["%s is already in a dealfinding list and has been removed from this list."], name)
					end
				end
			end
		end
		
		TSM.db.profile[listType][listName] = nil
		SelectTreePath(otherType, listName)
	end

	local function RenameList(eb,_,newName)
		newName = newName:trim()
		-- make sure the list name is valid
		if not newName or newName == "" or TSM.db.profile.dealfinding[newName] or TSM.db.profile.shopping[newName] then
			TSM:Printf(L["Invalid folder name. A folder with this name may already exist."])
			eb:SetFocus()
			return
		end
		
		TSM.db.profile[listType][newName] = CopyTable(TSM.db.profile[listType][listName])
		TSM.db.profile[listType][listName] = nil
		SelectTreePath(listType, newName)
	end
	
	local function DeleteList()
		TSM.db.profile[listType][listName] = nil
		SelectTreePath(listType)
	end
	
	local switchLabelText, infoText
	if otherType == "shopping" then
		switchLabelText = L["Use the button below to convert this list from a Dealfinding list to a Shopping list.\n\nNOTE: Doing so will remove all item settings from the list! This cannot be undone."]
	else
		switchLabelText = L["Use the button below to convert this list from a Shopping list to a Dealfinding list.\n\nNOTE: Doing so will remove all search terms from this list as well as any items that are already in a dealfinding list! This cannot be undone."]
		local count = 0
		for itemID in pairs(TSM.db.profile.shopping[listName]) do
			if itemID ~= "searchTerms" then
				for _, items in pairs(TSM.db.profile.dealfinding) do
					if items[itemID] then
						count = count + 1
						break
					end
				end
			end
		end
		if count > 0 then
			infoText = "|cffff0000" .. format(L["%s item(s) will be removed (already in a dealfinding list)"], count) .. "|r"
		end
	end

	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Rename List"],
					children = {
						{
							type = "EditBox",
							label = L["New List Name"],
							relativeWidth = 0.5,
							callback = RenameList,
						},
					},
				},
				{
					type = "Spacer",
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Switch List Type"],
					children = {
						{
							type = "Label",
							text = switchLabelText,
							relativeWidth = 1,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Button",
							text = L["Switch Type"],
							relativeWidth = 0.5,
							callback = SwitchType,
						},
						{
							type = "Label",
							text = infoText,
							relativeWidth = 0.49
						},
					},
				},
				{
					type = "Spacer",
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Delete / Export List"],
					children = {
						{
							type = "Button",
							text = L["Delete List"],
							relativeWidth = 0.5,
							callback = DeleteList,
						},
						{
							type = "Button",
							text = "Export List",
							relativeWidth = 0.5,
							callback = function() Config:OpenExportFrame(listType, listName) end,
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end