-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Auctioning - AddOn by Sapu94							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_auctioning.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster_Auctioning", "AceEvent-3.0", "AceConsole-3.0")
TSM.status = {}
TSM.version = GetAddOnMetadata("TradeSkillMaster_Auctioning","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster_Auctioning", "Version") -- current version of the addon
local AceGUI = LibStub("AceGUI-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
TSM.itemReverseLookup = {}
TSM.groupReverseLookup = {}
local status = TSM.status
local statusLog, logIDs, lastSeenLogID = {}, {}

-- versionKey is used to ensure inter-module compatibility when new features are added 
local versionKey = 2


local savedDBDefaults = {
	profile = {
		noCancel = {default = false},
		undercut = {default = 1},
		postTime = {default = 12},
		bidPercent = {default = 1.0},
		fallback = {default = 10000000},
		fallbackPercent = {},
		fallbackPriceMethod = {default = "gold"},
		fallbackCap = {default = 5},
		threshold = {default = 10000},
		thresholdPercent = {},
		thresholdPriceMethod = {default = "gold"},
		postCap = {default = 4},
		perAuction = {default = 1},
		perAuctionIsCap = {default = false},
		ignoreStacksOver = {default = 1000},
		ignoreStacksUnder = {default = 1},
		reset = {default = "none"},
		resetPrice = {default = 30000},
		disabled = {default = false},
		minDuration = {default = 0},
		searchTerm = {default = ""},
		resetEnabled = {default = false},
		resetMaxCost = {default = 50000},
		resetMaxCostPercent = {},
		resetMaxCostPriceMethod = {default = "gold"},
		resetMinProfit = {default = 100000},
		resetMinProfitPercent = {},
		resetMinProfitPriceMethod = {default = "gold"},
		resetMaxQuantity = {default = 10},
		resetResolution = {default = 1000},
		resetMaxPricePer = {default = 10000000},
		resetResolutionPercent = {default = 5},
		itemIDGroups = {},
		groups = {},
		categories = {},
	},
	global = {
		smartCancel = true,
		repostCancel = true,
		cancelWithBid = false,
		hideHelp = false,
		hideGray = false,
		hideAdvanced = nil,
		enableSounds = false,
		tabOrder = 1,
		treeGroupStatus = {treewidth = 200, groups={[2]=true}},
		showTooltip = true,
		smartGroupCreation = true,
		makeAnother = false,
		matchWhitelist = true,
		lowDuration = 1,
		maxRetries = 5,
	},
	factionrealm = {
		player = {},
		whitelist = {},
		blacklist = {},
	},
}

-- Addon loaded
function TSM:OnInitialize()
	-- load the savedDB into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMaster_AuctioningDB", savedDBDefaults, true)
	
	for name, module in pairs(TSM.modules) do
		TSM[name] = module
	end
	
	-- Add this character to the alt list so it's not undercut by the player
	TSM.db.factionrealm.player[UnitName("player")] = true
	TSM:DoDBCleanUp()
	
	TSMAPI:RegisterReleasedModule("TradeSkillMaster_Auctioning", TSM.version, GetAddOnMetadata("TradeSkillMaster_Auctioning", "Author"),
		GetAddOnMetadata("TradeSkillMaster_Auctioning", "Notes"), versionKey)
	TSMAPI:RegisterIcon(L["Auctioning Groups/Options"], "Interface\\Icons\\Racial_Dwarf_FindTreasure", function(...) TSM.Config:LoadOptions(...) end, "TradeSkillMaster_Auctioning", "options")
	TSM:RegisterMessage("TSMAUC_NEW_GROUP_ITEM")
	TSMAPI:RegisterData("auctioningGroups", TSM.GetGroups)
	TSMAPI:RegisterData("auctioningCategories", TSM.GetCategories)
	TSMAPI:RegisterData("auctioningGroupItems", TSM.GetGroupItems)
	TSMAPI:RegisterData("auctioningThreshold", TSM.GetThresholdPrice)
	TSMAPI:RegisterData("auctioningFallback", TSM.GetFallbackPrice)
	TSMAPI:RegisterData("auctioningPostCount", TSM.GetPostCount)
	TSMAPI:RegisterAuctionSTRightClickFunction("Add item to Auctioning group", TSM.AuctionSTRightClickCallback)
	
	if TSM.db.global.showTooltip then
		TSMAPI:RegisterTooltip("TradeSkillMaster_Auctioning", function(...) return TSM:LoadTooltip(...) end)
	end
	
	-- cache the item info for all the items in groups
	local itemsToCache = {}
	for groupName, items in pairs(TSM.db.profile.groups) do
		for itemString in pairs(items) do
			itemsToCache[itemString] = true
		end
	end
	TSMAPI:GetItemInfoCache(itemsToCache, true)
end

-- any code to update the db to account for changes will be put in here and won't be removed for a while after they are added
function TSM:DoDBCleanUp()
	-- Added in r353
	if TSM.db.profile.smartScanning then
		TSM.db.profile.smartScanning = nil
	end
	
	--Added in new AH tab initial release
	TSM.db.global.bInfo = nil
	TSM.db.global.infoID = nil
	TSM.db.global.msgID = nil
	
	-- needs to wait for more stuff to load before it'll work
	TSMAPI:CreateTimeDelay("aucMacroChange", 3, function()
			if (GetMacroBody("TSMAucBClick") or ""):trim() == "/click TSMAucCancelButton\n/click TSMAucPostButton" then
				EditMacro("TSMAucBClick", nil, nil, "/click TSMAuctioningCancelButton\n/click TSMAuctioningPostButton")
			end
		end)
end

local GOLD_TEXT = "|cffc29918g|r"
local SILVER_TEXT = "|cff868688s|r"
local COPPER_TEXT = "|cffaf6136c|r"

-- Truncate tries to save space, after 300g stop showing copper, after 3000g stop showing silver
function TSM:FormatTextMoney(money, truncate, noColor)
	if not money then return end
	local gold = floor(money / COPPER_PER_GOLD)
	local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = floor(math.fmod(money, COPPER_PER_SILVER))
	local text = ""
	
	-- Add gold
	if gold > 0 then
		text = format("%d%s ", gold, (not noColor and GOLD_TEXT or "g"))
	end
	
	-- Add silver
	if silver > 0 and (not truncate or gold < 1000) then
		text = format("%s%d%s ", text, silver, (not noColor and SILVER_TEXT or "s"))
	end
	
	-- Add copper if we have no silver/gold found, or if we actually have copper
	if text == "" or (copper > 0 and (not truncate or gold < 100)) then
		text = format("%s%d%s ", text, copper, (not noColor and COPPER_TEXT or "c"))
	end
	
	return string.trim(text)
end

function TSM:UpdateItemReverseLookup()
	wipe(TSM.itemReverseLookup)
	
	for group, items in pairs(TSM.db.profile.groups) do
		for itemString in pairs(items) do
			TSM.itemReverseLookup[itemString] = group
		end
	end
end

function TSM:UpdateGroupReverseLookup()
	wipe(TSM.groupReverseLookup)
	
	for category, groups in pairs(TSM.db.profile.categories) do
		for groupName in pairs(groups) do
			TSM.groupReverseLookup[groupName] = category
		end
	end
end

-- returns a table of all Auctioning categories
function TSM:GetCategories()
	return CopyTable(TSM.db.profile.categories)
end

-- returns a nicely formatted table of all Auctioning groups
function TSM:GetGroups()
	local groups = CopyTable(TSM.db.profile.groups)
	local temp = {}
	for groupName, items in pairs(groups) do
		for itemString, value in pairs(items) do
			local s1 = gsub(gsub(itemString, "item:", ""), "enchant:", "")
			local pos = strfind(s1, ":")
			if pos then
				local itemID = tonumber(strsub(s1, 1, pos-1))
				if itemID then
					tinsert(temp, {groupName, itemString, itemID, value})
				end
			end
		end
	end
	
	for _, data in ipairs(temp) do
		groups[data[1]][data[2]] = nil
		groups[data[1]][data[3]] = data[4]
	end
	
	return groups
end

-- returns the items in the passed group
function TSM:GetGroupItems(name)
	local groups = TSM:GetGroups()
	if not groups[name] then return end
	local temp = {}
	for itemID in pairs(groups[name]) do
		tinsert(temp, itemID)
	end
	return temp
end

-- message handler that fires when Crafting creates a new group (or adds an item to one)
function TSM:TSMAUC_NEW_GROUP_ITEM(_, groupName, itemID, isNewGroup, category)
	itemID = itemID and select(2, GetItemInfo(itemID)) or itemID
	groupName = strlower(groupName or "")
	if not groupName or groupName == "" then return end
	if isNewGroup then
		if not TSM.db.profile.groups[groupName] then
			TSM.db.profile.groups[groupName] = {}
			if category then
				TSM.db.profile.categories[category][groupName] = true
			end
		else
			TSM:Printf(L["Group named \"%s\" already exists! Item not added."], groupName)
			return
		end
	else
		if not TSM.db.profile.groups[groupName] then
			TSM:Printf(L["Group named \"%s\" does not exist! Item not added."], groupName)
			return
		end
	end
	if itemID then
		local itemString = TSMAPI:GetItemString(itemID)
		if itemString then
			TSM:UpdateItemReverseLookup()
			local existingGroupName = TSM.itemReverseLookup[itemString] or TSM.itemReverseLookup[itemID]
			if existingGroupName then
				TSM.db.profile.groups[existingGroupName][itemString] = nil
				TSM.db.profile.groups[existingGroupName][itemID] = nil
			end
			if TSM.db.profile.itemIDGroups[groupName] then
				TSM.db.profile.groups[groupName][itemID] = true
			else
				TSM.db.profile.groups[groupName][itemString] = true
			end
		else
			TSM:Print(L["Item failed to add to group."])
		end
	end
end

local function GetItemCost(source, itemString)
	for methodName in pairs(TSMAPI:GetPriceSources()) do
		if strlower(methodName) == source then
			source = methodName
		end
	end

	return TSMAPI:GetItemValue(itemString, source)
end

function TSM:GetMarketValue(group, percent, method)
	local cost = 0
	
	if TSM.db.profile.groups[group] then
		for itemString in pairs(TSM.db.profile.groups[group]) do
			local newCost = GetItemCost(method, itemString)
			if newCost and newCost > cost then
				cost = newCost
			end
		end
	end
	
	return cost*(percent or 1)
end

-- checks to make sure they aren't using % of crafting cost / auctiondb incorrectly
function TSM:ValidateGroups(nextFunc)
	local invalidGroups = {}
	for groupName, data in pairs(TSM.db.profile.groups) do
		local thresholdMethod = TSM.Config:GetConfigValue(groupName, "thresholdPriceMethod")
		local fallbackMethod = TSM.Config:GetConfigValue(groupName, "fallbackPriceMethod")
		local isValid = true
		if thresholdMethod ~= "gold" or fallbackMethod ~= "gold" then
			local items = {}
			for itemString in pairs(data) do
				tinsert(items, itemString)
			end
			if #items > 1 then
				local groupPrice
				if thresholdMethod ~= "gold" then
					for _, itemString in ipairs(items) do
						local cost = GetItemCost(thresholdMethod, itemString) or 0
						groupPrice = groupPrice or cost
						if abs(groupPrice-cost) > 1 then
							isValid = false
						end
					end
				end
				groupPrice = nil
				if fallbackMethod ~= "gold" then
					for _, itemString in ipairs(items) do
						local cost = GetItemCost(fallbackMethod, itemString) or 0
						groupPrice = groupPrice or cost
						if abs(groupPrice-cost) > 1 then
							isValid = false
						end
					end
				end
			end
		end
		
		if not isValid then
			tinsert(invalidGroups, groupName)
		end
	end
	
	local function FixGroups()
		TSM:UpdateGroupReverseLookup()
		for _, groupName in ipairs(invalidGroups) do
			local thresholdMethod = TSM.Config:GetConfigValue(groupName, "thresholdPriceMethod")
			local fallbackMethod = TSM.Config:GetConfigValue(groupName, "fallbackPriceMethod")
			local items = CopyTable(TSM.db.profile.groups[groupName])
			TSM.db.profile.groups[groupName] = nil
			local categoryName = TSM.groupReverseLookup[groupName]
			if categoryName then
				for setting, data in pairs(TSM.db.profile) do
					if type(data) == "table" and data[categoryName] ~= nil and data[groupName] == nil then
						data[groupName] = data[categoryName]
					end
				end
			end
			
			TSM.db.profile.categories[groupName] = {}
			local newGroups = {}
			for itemString in pairs(items) do
				local threshold = GetItemCost(thresholdMethod, itemString) or 0
				local fallback = GetItemCost(fallbackMethod, itemString) or 0
				local key = threshold.."$"..fallback
				newGroups[key] = newGroups[key] or {}
				newGroups[key][itemString] = true
			end
			
			for _, data in pairs(newGroups) do
				local newGroupName = groupName.."subgroup"
				local num = 1
				while(true) do
					if not TSM.db.profile.groups[newGroupName..num] and not TSM.db.profile.categories[newGroupName..num] then
						newGroupName = newGroupName..num
						break
					end
					num = num + 1
				end
				
				TSM.db.profile.groups[newGroupName] = CopyTable(data)
				TSM.db.profile.categories[groupName][newGroupName] = true
			end
		end
		TSM:Print(L["Fixed invalid groups."])
		nextFunc()
	end
	
	if #invalidGroups > 0 then
		TSM:Print(L["If you are using a % of something for threshold / fallback, every item in a group must evalute to the exact same amount. For example, if you are using % of crafting cost, every item in the group must have the same mats. If you are using % of auctiondb value, no items will ever have the same market price or min buyout. So, these items must be split into separate groups."])
		TSM:Print(L["Click on the \"Fix\" button to have Auctioning turn this group into a category and create appropriate groups inside the category to fix this issue. This is recommended unless you'd like to fix the group yourself. You will only be prompted with this popup once per session."])
		
		StaticPopupDialogs["TSMAucValidateGroups"] = {
			text = format(L["Auctioning has found %s group(s) with an invalid threshold/fallback. Check your chat log for more info. Would you like Auctioning to fix these groups for you?"], #invalidGroups),
			button1 = L["Fix (Recommended)"],
			button2 = L["Ignore"],
			timeout = 0,
			whileDead = true,
			hideOnEscape = false,
			OnAccept = FixGroups,
			OnCancel = nextFunc,
		}
		TSMAPI:ShowStaticPopupDialog("TSMAucValidateGroups")
	else
		nextFunc()
	end
end

local function GetGroupMoney(groupName, key)
	local group = TSM.Config:GetConfigObject(groupName)
	local groupValue = group[key]
	local defaultValue = TSM.db.profile[key].default

	if group[key.."PriceMethod"] ~= "gold" then
		local percent = group[key.."Percent"]
		if not percent then
			percent = floor(((groupValue or 0)/TSM:GetMarketValue(groupName, nil, group[key.."PriceMethod"]))*1000 + 0.5)/10
			TSM.db.profile[key.."Percent"][groupName] = percent/100
		end
	end
	
	return tonumber(groupValue or defaultValue)
end

function TSM:GetThresholdPrice(itemID)
	if not itemID then return end
	TSM:UpdateItemReverseLookup()
	TSM:UpdateGroupReverseLookup()
	local itemString = TSMAPI:GetItemString(itemID)
	local group = TSM.itemReverseLookup[itemString] or TSM.itemReverseLookup[itemID]
	if not group then return end
	return GetGroupMoney(group, "threshold")
end

function TSM:GetFallbackPrice(itemID)
	if not itemID then return end
	TSM:UpdateItemReverseLookup()
	TSM:UpdateGroupReverseLookup()
	local itemString = TSMAPI:GetItemString(itemID)
	local group = TSM.itemReverseLookup[itemString] or TSM.itemReverseLookup[itemID]
	if not group then return end
	return GetGroupMoney(group, "fallback")
end

function TSM:GetPostCount(itemID)
	if not itemID then return end
	TSM:UpdateItemReverseLookup()
	TSM:UpdateGroupReverseLookup()
	local itemString = TSMAPI:GetItemString(itemID)
	local group = TSM.itemReverseLookup[itemString] or TSM.itemReverseLookup[itemID]
	if not group then return end
	return TSM.Config:GetConfigValue(group, "postCap", true) * TSM.Config:GetConfigValue(group, "perAuction", true)
end

function TSM:LoadTooltip(itemID)
	local itemString = TSMAPI:GetItemString(itemID)
	if not itemString then return end
	
	local groupName = TSM.itemReverseLookup[itemString] or TSM.itemReverseLookup[itemID]
	if not groupName then
		TSM:UpdateItemReverseLookup()
		groupName = TSM.itemReverseLookup[itemString] or TSM.itemReverseLookup[itemID]
	end
	local thresholdValue = TSM:GetThresholdPrice(itemID)
	local fallbackValue = TSM:GetFallbackPrice(itemID)
	if groupName then
		return {L["Auctioning Group:"].." |cffffffff"..groupName, L["Threshold/Fallback:"]..TSMAPI:FormatTextMoney(thresholdValue, "|cffffffff", nil, true).."/"..TSMAPI:FormatTextMoney(fallbackValue, "|cffffffff", nil, true)}
	end
end

-- Makes sure this bag is an actual bag and not an ammo, soul shard, etc bag
function TSM:IsValidBag(bag)
	if bag == 0 then return true end
	
	-- family 0 = bag with no type, family 1/2/4 are special bags that can only hold certain types of items
	local itemFamily = GetItemFamily(GetInventoryItemLink("player", ContainerIDToInventoryID(bag)))
	return itemFamily and ( itemFamily == 0 or itemFamily > 4 )
end

function TSM:GetBagIterator(reverse)
	local bags, b, s = {}, 1, 0
	if reverse then
		for bag=4, 0, -1 do
			if TSM:IsValidBag(bag) then
				tinsert(bags, bag)
			end
		end
	else
		for bag=0, 4 do
			if TSM:IsValidBag(bag) then
				tinsert(bags, bag)
			end
		end
	end

	return function()
			if bags[b] then
				if s < GetContainerNumSlots(bags[b]) then
					s = s + 1
				else
					s = 1
					b = b + 1
					if not bags[b] then return end
				end
				
				return bags[b], s, TSMAPI:GetItemString(GetContainerItemLink(bags[b], s))
			end
		end
end

local function getIndex(t, value)
	for i, v in pairs(t) do
		if v == value then
			return i
		end
	end
end

local OpenRightClickWindow
function TSM.AuctionSTRightClickCallback(parent, itemLink)
	if OpenRightClickWindow then OpenRightClickWindow:Hide() end
	
	local itemID = TSMAPI:GetItemID(itemLink)
	local itemString = TSMAPI:GetItemString(itemLink)
	local x, y = GetCursorPosition()
	x = x / UIParent:GetEffectiveScale()
	y = y / UIParent:GetEffectiveScale()

	local window = AceGUI:Create("TSMWindow")
	window.frame:SetParent(parent)
	window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	window:SetWidth(500)
	window:SetHeight(200)
	window:SetTitle(L["Add Item to TSM_Auctioning"])
	window:SetLayout("Flow")
	window.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	window:SetCallback("OnClose", function(self)
			self:ReleaseChildren()
			OpenRightClickWindow = nil
			window.frame:Hide()
		end)
	OpenRightClickWindow = window

	local groupSelection, newGroupName, inAuctioningGroup
	local auctioningGroupList = {}
	TSM:UpdateItemReverseLookup()
	for groupName, items in pairs(TSM.db.profile.groups) do
		auctioningGroupList[groupName] = groupName
		if items[itemString] or items[TSMAPI:GetItemID(itemString)] then
			inAuctioningGroup = groupName
		end
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
			label = L["TSM_Auctioning Group to Add Item to:"],
			list = auctioningGroupList,
			value = 1,
			relativeWidth = 0.49,
			callback = function(self, _, value)
					value = value:trim()
					groupSelection = value
					local i = getIndex(self.parent.children, self)
					self.parent.children[i+2]:SetDisabled(not value or value == "")
				end,
			tooltip = L["Which group in TSM_Auctioning to add this item to."],
		},
		{
			type = "Label",
			text = "",
			relativeWidth = 0.02,
		},
		{
			type = "Button",
			text = L["Add Item to Selected Group"],
			relativeWidth = 0.49,
			disabled = true,
			callback = function(self)
					if groupSelection then
						TSM:SendMessage("TSMAUC_NEW_GROUP_ITEM", groupSelection, itemID)
						window.frame:Hide()
					end
				end,
		},
		{
			type = "Spacer"
		},
		{
			type = "EditBox",
			label = L["Name of New Group to Add Item to:"],
			relativeWidth = 0.49,
			callback = function(self, _, value)
					value = value:trim()
					local i = getIndex(self.parent.children, self)
					self.parent.children[i+2]:SetDisabled(not value or value == "")
					newGroupName = value
				end,
		},
		{
			type = "Label",
			text = "",
			relativeWidth = 0.02,
		},
		{
			type = "Button",
			text = L["Add Item to New Group"],
			relativeWidth = 0.49,
			disabled = true,
			callback = function(self)
					if newGroupName then
						TSM:SendMessage("TSMAUC_NEW_GROUP_ITEM", newGroupName, itemID, true)
						window.frame:Hide()
					end
				end,
		},
	}

	if inAuctioningGroup then
		for i=1, 7 do
			tremove(page, 3)
		end
		tinsert(page, 3, {
				type = "Label",
				text = format(L["This item is already in the \"%s\" Auctioning group."], inAuctioningGroup),
				relativeWidth = 1,
			})
	end

	TSMAPI:BuildPage(window, page)
end