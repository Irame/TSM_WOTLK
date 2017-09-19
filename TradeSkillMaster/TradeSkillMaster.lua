-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This is the main TSM file that holds the majority of the APIs that modules will use.

-- register this file with Ace libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster", "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
TSM.NO_SOUND_KEY = "TSM_NO_SOUND" -- this can never change
TSM.moduleObjects = {} -- PRIVATE: reference will be removed once loading completes
TSM.moduleNames = {} -- PRIVATE: reference will be removed once loading completes
TSM.moduleOperationInfo = {} -- PRIVATE: reference will be removed once loading completes
TSM.exportedForTesting = {} -- PRIVATE: reference will be removed once loading completes - used by test infrastructure code
local LibRealmInfo = LibStub("LibRealmInfo")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {cachedConnectedRealms=nil, appInfo=nil}
TSMAPI = {Auction={}, GUI={}, Design={}, Debug={}, Item={}, ItemFilter={}, Conversions={}, Delay={}, Player={}, Inventory={}, Threading={}, Groups={}, Operations={}, Util={}, Settings={}}

TSM.designDefaults = {
	frameColors = {
		frameBG = { backdrop = { 24, 24, 24, .93 }, border = { 30, 30, 30, 1 } },
		frame = { backdrop = { 24, 24, 24, 1 }, border = { 255, 255, 255, 0.03 } },
		content = { backdrop = { 42, 42, 42, 1 }, border = { 0, 0, 0, 0 } },
	},
	textColors = {
		iconRegion = { enabled = { 249, 255, 247, 1 } },
		text = { enabled = { 255, 254, 250, 1 }, disabled = { 147, 151, 139, 1 } },
		label = { enabled = { 216, 225, 211, 1 }, disabled = { 150, 148, 140, 1 } },
		title = { enabled = { 132, 219, 9, 1 } },
		link = { enabled = { 49, 56, 133, 1 } },
	},
	inlineColors = {
		link = { 153, 255, 255, 1 },
		link2 = { 153, 255, 255, 1 },
		category = { 36, 106, 36, 1 },
		category2 = { 85, 180, 8, 1 },
		tooltip = { 130, 130, 250, 1 },
	},
	edgeSize = 1.5,
	fonts = {
		content = "Fonts\\ARIALN.TTF",
		bold = "Interface\\Addons\\TradeSkillMaster\\Media\\DroidSans-Bold.ttf",
	},
	fontSizes = {
		normal = 15,
		medium = 13,
		small = 12,
	},
}

-- Changelog:
-- [6] added 'global.locale' key
-- [7] changed default value of 'tsmItemTweetEnabled' to false
-- [8] added 'global.itemCacheVersion' key
-- [9] removed 'global.itemCacheVersion' key, added 'global.clientVersion' key

local settingsInfo = {
	version = 9,
	global = {
		vendorItems = { type = "table", default = {}, lastModifiedVersion = 1 },
		ignoreRandomEnchants = { type = "boolean", default = false, lastModifiedVersion = 1 },
		globalOperations = { type = "boolean", default = false, lastModifiedVersion = 1 },
		operations = { type = "table", default = {}, lastModifiedVersion = 1 },
		moduleOperationsTreeStatus = { type = "table", default = {}, lastModifiedVersion = 1 },
		moduleOperationTabs = { type = "table", default = {}, lastModifiedVersion = 1 },
		optionsTreeStatus = { type = "table", default = {}, lastModifiedVersion = 1 },
		customPriceSources = { type = "table", default = {}, lastModifiedVersion = 1 },
		bankUITab = { type = "string", default = "Warehousing", lastModifiedVersion = 1 },
		chatFrame = { type = "string", default = "", lastModifiedVersion = 1 },
		infoMessagesShown = { type = "table", default = { resetDesign = nil }, lastModifiedVersion = 1 },
		frameStatus = { type = "table", default = {}, lastModifiedVersion = 1 },
		customPriceTooltips = { type = "table", default = {}, lastModifiedVersion = 1 },
		pendingAddonUpdate = { type = "table", default = {}, lastModifiedVersion = 5 },
		auctionSaleEnabled = { type = "boolean", default = true, lastModifiedVersion = 1 },
		auctionSaleSound = { type = "string", default = TSM.NO_SOUND_KEY, lastModifiedVersion = 1 },
		auctionBuyEnabled = { type = "boolean", default = true, lastModifiedVersion = 1 },
		tsmItemTweetEnabled = { type = "boolean", default = false, lastModifiedVersion = 7 },
		moveDelay = { type = "number", default = 0, lastModifiedVersion = 1 },
		appMessageId = { type = "number", default = 0, lastModifiedVersion = 4 },
		locale = { type = "string", default = "", lastModifiedVersion = 6 },
		clientVersion = { type = "string", default = "", lastModifiedVersion = 9 },
	},
	profile = {
		design = { type = "table", default = nil, lastModifiedVersion = 1 },
		auctionFrameMovable = { type = "boolean", default = true, lastModifiedVersion = 1 },
		auctionFrameScale = { type = "number", default = 1, lastModifiedVersion = 1 },
		protectAH = { type = "boolean", default = false, lastModifiedVersion = 1 },
		openAllBags = { type = "boolean", default = true, lastModifiedVersion = 1 },
		auctionResultRows = { type = "number", default = 16, lastModifiedVersion = 1 },
		groups = { type = "table", default = {}, lastModifiedVersion = 1 },
		items = { type = "table", default = {}, lastModifiedVersion = 1 },
		operations = { type = "table", default = {}, lastModifiedVersion = 1 },
		groupTreeStatus = { type = "table", default = {}, lastModifiedVersion = 1 },
		customPriceSourceTreeStatus = { type = "table", default = {}, lastModifiedVersion = 1 },
		pricePerUnit = { type = "boolean", default = true, lastModifiedVersion = 1 },
		isBankui = { type = "boolean", default = true, lastModifiedVersion = 1 },
		gotoNewGroup = { type = "boolean", default = true, lastModifiedVersion = 1 },
		gotoNewCustomPriceSource = { type = "boolean", default = true, lastModifiedVersion = 1 },
		defaultGroupTab = { type = "number", default = 2, lastModifiedVersion = 1 },
		moveImportedItems = { type = "boolean", default = false, lastModifiedVersion = 1 },
		importParentOnly = { type = "boolean", default = false, lastModifiedVersion = 1 },
		keepInParent = { type = "boolean", default = true, lastModifiedVersion = 1 },
		savedThemes = { type = "table", default = {}, lastModifiedVersion = 1 },
		groupTreeCollapsedStatus = { type = "table", default = {}, lastModifiedVersion = 1 },
		groupTreeSelectedGroupStatus = { type = "table", default = {}, lastModifiedVersion = 1 },
		exportSubGroups = { type = "boolean", default = false, lastModifiedVersion = 1 },
		tooltipOptions = { type = "table", default = {}, lastModifiedVersion = 1 },
		embeddedTooltip = { type = "boolean", default = true, lastModifiedVersion = 1 },
		groupOperationTooltip = { type = "boolean", default = true, lastModifiedVersion = 1 },
		vendorBuyTooltip = { type = "boolean", default = true, lastModifiedVersion = 1 },
		vendorSellTooltip = { type = "boolean", default = true, lastModifiedVersion = 1 },
		detailedDestroyTooltip = { type = "boolean", default = false, lastModifiedVersion = 1 },
		millTooltip = { type = "boolean", default = true, lastModifiedVersion = 1 },
		prospectTooltip = { type = "boolean", default = true, lastModifiedVersion = 1 },
		deTooltip = { type = "boolean", default = true, lastModifiedVersion = 1 },
		transformTooltip = { type = "boolean", default = true, lastModifiedVersion = 1 },
		operationTooltips = { type = "table", default = {}, lastModifiedVersion = 1 },
		cleanBags = { type = "boolean", default = false, lastModifiedVersion = 1 },
		cleanBank = { type = "boolean", default = false, lastModifiedVersion = 1 },
		cleanReagentBank = { type = "boolean", default = false, lastModifiedVersion = 1 },
		minimapIcon = { type = "table", default = { hide = false, minimapPos = 220, radius = 80 }, lastModifiedVersion = 1 },
		destroyValueSource = { type = "string", default = "dbmarket", lastModifiedVersion = 1 },
		tooltipShowModifier = { type = "string", default = "none", lastModifiedVersion = 1 },
		inventoryTooltipFormat = { type = "string", default = "full", lastModifiedVersion = 1 },
		groupFilterPrice = { type = "string", default = "dbmarket", lastModifiedVersion = 1 },
		inventoryViewerPriceSource = { type = "string", default = "dbmarket", lastModifiedVersion = 1 },
		tooltipPriceFormat = { type = "string", default = "text", lastModifiedVersion = 1 },
		defaultAuctionTab = { type = "string", default = "Shopping", lastModifiedVersion = 1 },
		exportOperations = { type = "boolean", default = false, lastModifiedVersion = 3 },
	},
	factionrealm = {
		accountKey = { type = "string", default = nil, lastModifiedVersion = 1 },
		characters = { type = "table", default = {}, lastModifiedVersion = 1 },
		characterGuilds = { type = "table", default = {}, lastModifiedVersion = 1 },
		ignoreGuilds = { type = "table", default = {}, lastModifiedVersion = 1 },
		syncAccounts = { type = "table", default = {}, lastModifiedVersion = 1 },
		syncMetadata = { type = "table", default = {}, lastModifiedVersion = 1 },
		bankUIBankFramePosition = { type = "table", default = { 100, 300 }, lastModifiedVersion = 1 },
		bankUIGBankFramePosition = { type = "table", default = { 100, 300 }, lastModifiedVersion = 1 },
		inventory = { type = "table", default = {}, lastModifiedVersion = 1 },
		pendingMail = { type = "table", default = {}, lastModifiedVersion = 1 },
		guildVaults = { type = "table", default = {}, lastModifiedVersion = 1 },
	},
	char = {
		auctionPrices = { type = "table", default = {}, lastModifiedVersion = 1 },
		auctionMessages = { type = "table", default = {}, lastModifiedVersion = 1 },
	},
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function TSM:OnInitialize()
	TSM.moduleObjects = nil
	TSM.moduleNames = nil
	TSM.moduleOperationInfo = nil
	TSM.exportedForTesting = nil

	TradeSkillMasterModulesDB = TradeSkillMasterModulesDB or {}

	-- load settings
	TSM.db = TSMAPI.Settings:Init("TradeSkillMasterDB", settingsInfo)

	for name, module in pairs(TSM.modules) do
		TSM[name] = module
	end

	-- TSM3 updates (do this before registering DB callbacks)
	for profile in TSMAPI:GetTSMProfileIterator() do
		local needsUpdate = nil
		for itemString in pairs(TSM.db.profile.items) do
			if type(itemString) == "string" and not strmatch(itemString, "^[ip]:%d+") then
				needsUpdate = true
				break
			end
		end
		if needsUpdate then
			local newData = {}
			for itemString, groupPath in pairs(TSM.db.profile.items) do
				local origItemString = itemString
				itemString = TSMAPI.Item:ToItemString(itemString)
				if itemString then
					newData[itemString] = groupPath
				end
			end
			TSM.db.profile.items = newData
		end

		-- fix some bad battlepet itemStrings (changed again in 3.1)
		local toFix = {}
		for itemString, groupPath in pairs(TSM.db.profile.items) do
			if strmatch(itemString, "^p:%d+:%d+$") then
				tinsert(toFix, itemString)
			end
		end
		for _, itemString in ipairs(toFix) do
			local newItemString = strmatch(itemString, "^p:%d+")
			local oldGroup = TSM.db.profile.items[itemString]
			TSM.db.profile.items[itemString] = nil
			TSM.db.profile.items[newItemString] = TSM.db.profile.items[newItemString] or oldGroup
		end

		-- fix some bad variant itemStrings (fixed in 3.3.8)
		wipe(toFix)
		for itemString, groupPath in pairs(TSM.db.profile.items) do
			local itemId = TSMAPI.Item:ToItemID(itemString)
			if itemId and itemId < 105000 and strmatch(itemString, "^i:[0-9]+:[%-0-9]+:") then
				-- the item has bonusIds and shouldn't
				tinsert(toFix, itemString)
			end
		end
		for _, itemString in ipairs(toFix) do
			local newItemString = TSMAPI.Item:ToItemString(strmatch(itemString, "^i:[0-9]+:[0-9%-]+"))
			local oldGroup = TSM.db.profile.items[itemString]
			TSM.db.profile.items[itemString] = nil
			TSM.db.profile.items[newItemString] = TSM.db.profile.items[newItemString] or oldGroup
		end

		-- fix some bad item links which got into the items table and some old bonusId strings
		wipe(toFix)
		for itemString, groupPath in pairs(TSM.db.profile.items) do
			if strmatch(itemString, "^p:%d+:%d+:%d+:%d+:%d+:%d+$") or strmatch(itemString, "^\124c[0-9a-fA-F]+\124H.+\124h\124r$") or select(2, gsub(itemString, ":", "")) > 2 then
				tinsert(toFix, itemString)
			end
		end
		for _, itemString in ipairs(toFix) do
			local newItemString = TSMAPI.Item:ToItemString(itemString)
			local oldGroup = TSM.db.profile.items[itemString]
			TSM.db.profile.items[itemString] = nil
			TSM.db.profile.items[newItemString] = TSM.db.profile.items[newItemString] or oldGroup
		end
	end

	TSM.db:RegisterCallback("OnLogout", TSM.Modules.OnLogout)
	TSM.db:RegisterCallback("OnProfileUpdated", function(isReset) TSM.Modules:ProfileUpdated(isReset) end)

	if TSM.db.global.globalOperations then
		TSM.operations = TSM.db.global.operations
	else
		TSM.operations = TSM.db.profile.operations
	end

	-- TSM core must be registered just like the modules
	TSM:RegisterModule()

	-- create account key for multi-account syncing if necessary
	TSM.db.factionrealm.accountKey = TSM.db.factionrealm.accountKey or (GetRealmName() .. random(time()))

	-- add this character to the list of characters on this realm
	TSMAPI.Sync:Mirror(TSM.db.factionrealm.characters, "TSM_CHARACTERS")
	TSMAPI.Sync:SetKeyValue(TSM.db.factionrealm.characters, UnitName("player"), select(2, UnitClass("player")))

	if not TSM.db.profile.design then
		TSM.Options:LoadDefaultDesign()
		TSM.db.global.infoMessagesShown.resetDesign = true
	elseif not TSM.db.global.infoMessagesShown.resetDesign then
		StaticPopupDialogs["TSMResetDesignPopup"] = StaticPopupDialogs["TSMResetDesignPopup"] or {
			text = L["The default design has been changed in TSM3. Would you like to reset your appearance settings and use this new default?"],
			button1 = YES,
			button2 = NO,
			timeout = 0,
			OnAccept = TSM.Options.LoadDefaultDesign,
		}
		TSMAPI.Util:ShowStaticPopupDialog("TSMResetDesignPopup")
		TSM.db.global.infoMessagesShown.resetDesign = true
	end
	TSM.Options:SetDesignDefaults(TSM.designDefaults, TSM.db.profile.design)

	-- create / register the minimap button
	TSM.LDBIcon = LibStub("LibDataBroker-1.1", true) and LibStub("LibDBIcon-1.0", true)
	local TradeSkillMasterLauncher = LibStub("LibDataBroker-1.1", true):NewDataObject("TradeSkillMasterMinimapIcon", {
		icon = "Interface\\Addons\\TradeSkillMaster\\Media\\TSM_Icon",
		OnClick = function(_, button) -- fires when a user clicks on the minimap icon
			if button == "LeftButton" then
				-- does the same thing as typing '/tsm'
				TSM.Modules:ChatCommand("")
			end
		end,
		OnTooltipShow = function(tt) -- tooltip that shows when you hover over the minimap icon
			local cs = "|cffffffcc"
			local ce = "|r"
			tt:AddLine("TradeSkillMaster " .. TSM._version)
			tt:AddLine(format(L["%sLeft-Click%s to open the main window"], cs, ce))
			tt:AddLine(format(L["%sDrag%s to move this button"], cs, ce))
		end,
	})
	TSM.LDBIcon:Register("TradeSkillMaster", TradeSkillMasterLauncher, TSM.db.profile.minimapIcon)
	local TradeSkillMasterLauncher2 = LibStub("LibDataBroker-1.1", true):NewDataObject("TradeSkillMaster", {
		type = "launcher",
		icon = "Interface\\Addons\\TradeSkillMaster\\Media\\TSM_Icon2",
		OnClick = function(_, button) -- fires when a user clicks on the minimap icon
			if button == "LeftButton" then
				-- does the same thing as typing '/tsm'
				TSM.Modules:ChatCommand("")
			end
		end,
		OnTooltipShow = function(tt) -- tooltip that shows when you hover over the minimap icon
			local cs = "|cffffffcc"
			local ce = "|r"
			tt:AddLine("TradeSkillMaster " .. TSM._version)
			tt:AddLine(format(L["%sLeft-Click%s to open the main window"], cs, ce))
			tt:AddLine(format(L["%sDrag%s to move this button"], cs, ce))
		end,
	})
	
	-- fix patch 7.3 sound changes
	local sounds = TSMAPI:GetSounds()
	if not sounds[TSM.db.global.auctionSaleSound] then
		TSM.db.global.auctionSaleSound = TSM.NO_SOUND_KEY
	end
	
	
	-- Cache battle pet names
	for i=1, C_PetJournal.GetNumPets() do C_PetJournal.GetPetInfoByIndex(i) end
	-- force a garbage collection
	collectgarbage()
end

function TSM:OnEnable()
	-- load app info if available
	if TSMAPI.AppHelper then
		local appInfo = TSMAPI.AppHelper:FetchData("APP_INFO")
		if appInfo and #appInfo == 1 and #appInfo[1] == 2 and appInfo[1][1] == "Global" then
			private.appInfo = assert(loadstring(appInfo[1][2]))()
			if private.appInfo.message and private.appInfo.message.id > TSM.db.global.appMessageId then
				TSM.db.global.appMessageId = private.appInfo.message.id
				StaticPopupDialogs["TSMAppMessagePopup"] = {
					text = private.appInfo.message.msg,
					button1 = OKAY,
					timeout = 0,
				}
				TSMAPI.Util:ShowStaticPopupDialog("TSMAppMessagePopup")
			end
		end
	end
end

function TSM:RegisterModule()
	TSM.icons = {
		{ side = "options", desc = L["TSM Features"], slashCommand = "features", callback = "FeaturesGUI:LoadGUI", icon = "Interface\\Icons\\Achievement_Quests_Completed_04" },
		{ side = "options", desc = L["Options"], callback = "Options:Load", icon = "Interface\\Icons\\INV_Inscription_Tooltip_DarkmoonCard_MOP" },
		{ side = "options", desc = L["Groups"], callback = "GroupOptions:Load", slashCommand = "groups", icon = "Interface\\Icons\\INV_DataCrystal08" },
		{ side = "options", desc = L["Operations"], slashCommand = "operations", callback = "Operations:LoadOperationOptions", icon = "Interface\\Icons\\INV_Misc_Enggizmos_33" },
	}

	TSM.priceSources = {}
	-- Auctioneer
	if select(4, GetAddOnInfo("Auc-Advanced")) and AucAdvanced then
		if AucAdvanced.Modules.Util.Appraiser and AucAdvanced.Modules.Util.Appraiser.GetPrice then
			tinsert(TSM.priceSources, { key = "AucAppraiser", label = L["Auctioneer - Appraiser"], callback = AucAdvanced.Modules.Util.Appraiser.GetPrice })
		end
		if AucAdvanced.Modules.Util.SimpleAuction and AucAdvanced.Modules.Util.SimpleAuction.Private.GetItems then
			tinsert(TSM.priceSources, { key = "AucMinBuyout", label = L["Auctioneer - Minimum Buyout"], callback = function(itemLink) return select(6, AucAdvanced.Modules.Util.SimpleAuction.Private.GetItems(itemLink)) end })
		end
		if AucAdvanced.API.GetMarketValue then
			tinsert(TSM.priceSources, { key = "AucMarket", label = L["Auctioneer - Market Value"], callback = AucAdvanced.API.GetMarketValue })
		end
	end

	-- Auctionator
	if select(4, GetAddOnInfo("Auctionator")) and Atr_GetAuctionBuyout then
		tinsert(TSM.priceSources, { key = "AtrValue", label = L["Auctionator - Auction Value"], callback = Atr_GetAuctionBuyout })
	end

	-- CostBasis
	if select(4, GetAddOnInfo("CostBasis")) then
		tinsert(TSM.priceSources, { key = "CostBasis", label = L["CostBasis"], callback = function(itemLink) local CB = LibStub("AceAddon-3.0"):GetAddon("CostBasis", true) return CB and CB:QueryItem(itemLink) end})
	end

	-- TheUndermineJournal
	if select(4, GetAddOnInfo("TheUndermineJournal")) and TUJMarketInfo then
        local function GetTUJPrice(itemLink, key)
            local data = TUJMarketInfo(itemLink)
            if not data then return end
            return data[key]
        end
		tinsert(TSM.priceSources, { key = "TUJRecent", label = L["TUJ 3-Day Price"], callback = GetTUJPrice, arg = "recent" })
		tinsert(TSM.priceSources, { key = "TUJMarket", label = L["TUJ 14-Day Price"], callback = GetTUJPrice, arg = "market" })
		tinsert(TSM.priceSources, { key = "TUJGlobalMean", label = L["TUJ Global Mean"], callback = GetTUJPrice, arg = "globalMean" })
		tinsert(TSM.priceSources, { key = "TUJGlobalMedian", label = L["TUJ Global Median"], callback = GetTUJPrice, arg = "globalMedian" })
	end

	-- Vendor Buy Price
	tinsert(TSM.priceSources, { key = "VendorBuy", label = L["Buy from Vendor"], callback = function(itemString) return TSMAPI.Item:GetVendorCost(itemString) end, takeItemString = true })

	-- Vendor Buy Price
	tinsert(TSM.priceSources, { key = "VendorSell", label = L["Sell to Vendor"], callback = function(itemString) local sell = TSMAPI.Item:GetVendorPrice(itemString) return (sell or 0) > 0 and sell or nil end, takeItemString = true })

	-- Disenchant Value
	tinsert(TSM.priceSources, { key = "Destroy", label = L["Destroy Value"], callback = function(itemString) return TSMAPI.Conversions:GetValue(itemString, TSM.db.profile.destroyValueSource) end, takeItemString = true })

	TSM.slashCommands = {
		{ key = "version", label = L["Prints out the version numbers of all installed modules"], callback = "PrintVersion" },
		{ key = "freset", label = L["Resets the position, scale, and size of all applicable TSM and module frames."], callback = "GUI:ResetFrames" },
		{ key = "bankui", label = L["Toggles the bankui"], callback = "toggleBankUI" },
		{ key = "sources", label = L["Prints out the available price sources for use in custom price boxes."], callback = "PrintPriceSources" },
		{ key = "price", label = L["Allows for testing of custom prices."], callback = "TestPriceSource" },
		{ key = "profile", label = L["Changes to the specified profile (i.e. '/tsm profile Default' changes to the 'Default' profile)"], callback = "ChangeProfile" },
		{ key = "debug", label = L["Some debug commands for TSM."], callback = "Debug:SlashCommandHandler", hidden = true },
	}
	--@debug@
	if TSM.Testing then
		tinsert(TSM.slashCommands, { key = "test", label = "", callback = "Testing:SlashCommandHandler", hidden = true })
	end
	--@end-debug@

	TSMAPI:NewModule(TSM)
end

function TSM:OnTSMDBShutdown(appDB)
	if not appDB then return end

	-- store region
	local region = TSMAPI:GetRegion()
	appDB.region = region

	local function GetShoppingMaxPrice(itemString, groupPath)
		local operationName = TSM.db.profile.groups[groupPath].Shopping[1]
		if not operationName or operationName == "" or TSM.Modules:IsOperationIgnored("Shopping", operationName) then return end
		local operation = TSM.operations.Shopping[operationName]
		if not operation or type(operation.maxPrice) ~= "string" then return end
		local value = TSMAPI:GetCustomPriceValue(operation.maxPrice, itemString)
		if not value or value <= 0 then return end
		return value
	end

	-- save TSM_Shopping max prices in the app DB
	if TSM.operations.Shopping then
		appDB.shoppingMaxPrices = {}
		for profile in TSMAPI:GetTSMProfileIterator() do
			local profileGroupData = {}
			for itemString, groupPath in pairs(TSM.db.profile.items) do
				local itemId = tonumber(strmatch(itemString, "^i:([0-9]+)$"))
				if itemId and TSM.db.profile.groups[groupPath] and TSM.db.profile.groups[groupPath].Shopping then
					local maxPrice = GetShoppingMaxPrice(itemString, groupPath)
					if maxPrice then
						if not profileGroupData[groupPath] then
							profileGroupData[groupPath] = {}
						end
						tinsert(profileGroupData[groupPath], "["..table.concat({itemId, maxPrice}, ",").."]")
					end
				end
			end
			if next(profileGroupData) then
				appDB.shoppingMaxPrices[profile] = {}
				for groupPath, data in pairs(profileGroupData) do
					appDB.shoppingMaxPrices[profile][groupPath] = "["..table.concat(data, ",").."]"
				end
				appDB.shoppingMaxPrices[profile].updateTime = time()
			end
		end
	end

	-- save black market data
	local realmName = GetRealmName()
	appDB.blackMarket = appDB.blackMarket or {}
	if TSM.Features.blackMarket then
		local hash = TSMAPI.Util:CalculateHash(TSM.Features.blackMarket..":"..TSM.Features.blackMarketTime)
		appDB.blackMarket[realmName] = {data=TSM.Features.blackMarket, key=hash, updateTime=TSM.Features.blackMarketTime}
	end

	-- save wow token
	appDB.wowToken = appDB.wowToken or {}
	if TSM.Features.wowToken then
		local hash = TSMAPI.Util:CalculateHash(TSM.Features.wowToken..":"..TSM.Features.wowTokenTime)
		appDB.wowToken[region] = {data=TSM.Features.wowToken, key=hash, updateTime=TSM.Features.wowTokenTime}
	end

	-- save analytics
	TSM.Analytics:Save(appDB)
end



-- ============================================================================
-- TSM Tooltip Handling
-- ============================================================================

function TSM:LoadTooltip(itemString, quantity, moneyCoins, lines)
	local numStartingLines = #lines

	-- add group / operation info
	if TSM.db.profile.groupOperationTooltip then
		local isBaseItem
		local path = TSM.db.profile.items[itemString]
		if not path then
			path = TSM.db.profile.items[TSMAPI.Item:ToBaseItemString(itemString)]
			isBaseItem = true
		end
		if path and TSM.db.profile.groups[path] then
			local leftText = nil
			if isBaseItem then
				leftText = L["Group(Base Item):"]
			else
				leftText = L["Group:"]
			end
			tinsert(lines, {left="  "..leftText, right = "|cffffffff"..TSMAPI.Groups:FormatPath(path).."|r"})
			local modules = {}
			for module, operations in pairs(TSM.db.profile.groups[path]) do
				if operations[1] and operations[1] ~= "" and TSM.db.profile.operationTooltips[module] then
					tinsert(modules, {module=module, operations=table.concat(operations, ", ")})
				end
			end
			sort(modules, function(a, b) return a.module < b.module end)
			for _, info in ipairs(modules) do
				tinsert(lines, {left="  "..format(L["%s operation(s):"], info.module), right="|cffffffff"..info.operations.."|r"})
			end
		end
	end

	-- add disenchant value info
	if TSM.db.profile.deTooltip then
		local value = TSMAPI.Conversions:GetValue(itemString, TSM.db.profile.destroyValueSource, "disenchant")
		if value then
			local leftText = "  "..(quantity > 1 and format(L["Disenchant Value x%s:"], quantity) or L["Disenchant Value:"])
			tinsert(lines, {left=leftText, right=TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})
			if TSM.db.profile.detailedDestroyTooltip then
				local rarity = TSMAPI.Item:GetQuality(itemString)
				local ilvl = TSMAPI.Item:GetItemLevel(itemString)
				local iType = GetItemClassInfo(TSMAPI.Item:GetClassId(itemString))
				for _, data in ipairs(TSM.STATIC_DATA.disenchantInfo) do
					for targetItem, itemData in pairs(data) do
						if targetItem ~= "desc" then
							for _, deData in ipairs(itemData.sourceInfo) do
								if deData.itemType == iType and deData.rarity == rarity and ilvl >= deData.minItemLevel and ilvl <= deData.maxItemLevel then
									local matValue = (TSMAPI:GetCustomPriceValue(TSM.db.profile.destroyValueSource, targetItem) or 0) * deData.amountOfMats
									local matQuality = TSMAPI.Item:GetQuality(targetItem)
									if matQuality and matValue > 0 then
										local colorName = format("|c%s%s x %s|r", select(4, GetItemQualityColor(matQuality)), TSMAPI.Item:GetName(targetItem), deData.amountOfMats)
										tinsert(lines, {left="    "..colorName, right=TSMAPI:MoneyToString(matValue, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- add mill value info
	if TSM.db.profile.millTooltip then
		local value = TSMAPI.Conversions:GetValue(itemString, TSM.db.profile.destroyValueSource, "mill")
		if value then
			local leftText = "  "..(quantity > 1 and format(L["Mill Value x%s:"], quantity) or L["Mill Value:"])
			tinsert(lines, {left=leftText, right=TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})

			if TSM.db.profile.detailedDestroyTooltip then
				for _, targetItem in ipairs(TSMAPI.Conversions:GetTargetItemsByMethod("mill")) do
					local herbs = TSMAPI.Conversions:GetData(targetItem)
					if herbs[itemString] then
						local value = (TSMAPI:GetCustomPriceValue(TSM.db.profile.destroyValueSource, targetItem) or 0) * herbs[itemString].rate
						local matQuality = TSMAPI.Item:GetQuality(targetItem)
						if matQuality then
							local colorName = format("|c%s%s%s%s|r", select(4, GetItemQualityColor(matQuality)), TSMAPI.Item:GetName(targetItem), " x ", herbs[itemString].rate * quantity)
							if value > 0 then
								tinsert(lines, {left="    "..colorName, right=TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})
							end
						end
					end
				end
			end
		end
	end

	-- add prospect value info
	if TSM.db.profile.prospectTooltip then
		local value = TSMAPI.Conversions:GetValue(itemString, TSM.db.profile.destroyValueSource, "prospect")
		if value then
			local leftText = "  "..(quantity > 1 and format(L["Prospect Value x%s:"], quantity) or L["Prospect Value:"])
			tinsert(lines, {left=leftText, right=TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})

			if TSM.db.profile.detailedDestroyTooltip then
				for _, targetItem in ipairs(TSMAPI.Conversions:GetTargetItemsByMethod("prospect")) do
					local gems = TSMAPI.Conversions:GetData(targetItem)
					if gems[itemString] then
						local value = (TSMAPI:GetCustomPriceValue(TSM.db.profile.destroyValueSource, targetItem) or 0) * gems[itemString].rate
						local matQuality = TSMAPI.Item:GetQuality(targetItem)
						if matQuality then
							local colorName = format("|c%s%s%s%s|r", select(4, GetItemQualityColor(matQuality)), TSMAPI.Item:GetName(targetItem), " x ", gems[itemString].rate * quantity)
							if value > 0 then
								tinsert(lines, {left="    "..colorName, right=TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})
							end
						end
					end
				end
			end
		end
	end

	-- add transform value info
	if TSM.db.profile.transformTooltip then
		local value = TSMAPI.Conversions:GetValue(itemString, TSM.db.profile.destroyValueSource, "transform")
		if value then
			local leftText = "  "..(quantity > 1 and format(L["Transform Value x%s:"], quantity) or L["Transform Value:"])
			tinsert(lines, {left=leftText, right=TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})

			if TSM.db.profile.detailedDestroyTooltip then
				for _, targetItem in ipairs(TSMAPI.Conversions:GetTargetItemsByMethod("transform")) do
					local srcItems = TSMAPI.Conversions:GetData(targetItem)
					if srcItems[itemString] then
						local value = (TSMAPI:GetCustomPriceValue(TSM.db.profile.destroyValueSource, targetItem) or 0) * srcItems[itemString].rate
						local matQuality = TSMAPI.Item:GetQuality(targetItem)
						if matQuality then
							local colorName = format("|c%s%s%s%s|r",select(4, GetItemQualityColor(matQuality)), TSMAPI.Item:GetName(targetItem), " x ", srcItems[itemString].rate * quantity)
							if value > 0 then
								tinsert(lines, {left="    "..colorName, right=TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})
							end
						end
					end
				end
			end
		end
	end

	-- add vendor buy price
	if TSM.db.profile.vendorBuyTooltip then
		local value = TSMAPI.Item:GetVendorCost(itemString) or 0
		if value > 0 then
			local leftText = "  "..(quantity > 1 and format(L["Vendor Buy Price x%s:"], quantity) or L["Vendor Buy Price:"])
			tinsert(lines, {left=leftText, right=TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})
		end
	end

	-- add vendor sell price
	if TSM.db.profile.vendorSellTooltip then
		local value = TSMAPI.Item:GetVendorPrice(itemString) or 0
		if value > 0 then
			local leftText = "  "..(quantity > 1 and format(L["Vendor Sell Price x%s:"], quantity) or L["Vendor Sell Price:"])
			tinsert(lines, {left=leftText, right=TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})
		end
	end

	-- add custom price sources
	for name, method in pairs(TSM.db.global.customPriceSources) do
		if TSM.db.global.customPriceTooltips[name] then
			local price = TSMAPI:GetCustomPriceValue(name, itemString) or 0
			if price > 0 then
				tinsert(lines, {left="  "..L["Custom Price Source"].." '"..name.."':", right=TSMAPI:MoneyToString(price*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)})
			end
		end
	end

	-- add inventory information
	if TSM.db.profile.inventoryTooltipFormat == "full" then
		local numLines = #lines
		local totalNum = 0
		local playerData, guildData = TSM.Inventory:GetItemData(itemString)
		for playerName, data in pairs(playerData) do
			local playerTotal = data.bag + data.bank + data.reagentBank + data.auction + data.mail
			if playerTotal > 0 then
				totalNum = totalNum + playerTotal
				local classColor = type(TSM.db.factionrealm.characters[playerName]) == "string" and RAID_CLASS_COLORS[TSM.db.factionrealm.characters[playerName]]
				local rightText = format(L["%s (%s bags, %s bank, %s AH, %s mail)"], "|cffffffff"..playerTotal.."|r", "|cffffffff"..data.bag.."|r", "|cffffffff"..(data.bank+data.reagentBank).."|r", "|cffffffff"..data.auction.."|r", "|cffffffff"..data.mail.."|r")
				if classColor then
					tinsert(lines, {left="    |c"..classColor.colorStr..playerName.."|r:", right=rightText})
				else
					tinsert(lines, {left="    "..playerName..":", right=rightText})
				end
			end
		end
		for guildName, guildQuantity in pairs(guildData) do
			if guildQuantity > 0 then
				totalNum = totalNum + guildQuantity
				tinsert(lines, {left="    "..guildName..":", right=format(L["%s in guild vault"], "|cffffffff"..guildQuantity.."|r")})
			end
		end
		if #lines > numLines then
			tinsert(lines, numLines+1, {left="  "..L["Inventory:"], right=format(L["%s total"], "|cffffffff"..totalNum.."|r")})
		end
	elseif TSM.db.profile.inventoryTooltipFormat == "simple" then
		local numLines = #lines
		local totalPlayer, totalAlt, totalGuild, totalAuction = 0, 0, 0, 0
		local playerData, guildData = TSM.Inventory:GetItemData(itemString)
		for playerName, data in pairs(playerData) do
			if playerName == UnitName("player") then
				totalPlayer = totalPlayer + data.bag + data.bank + data.reagentBank + data.mail
				totalAuction = totalAuction + data.auction
			else
				totalAlt = totalAlt + data.bag + data.bank + data.reagentBank + data.mail
				totalAuction = totalAuction + data.auction
			end
		end
		for guildName, guildQuantity in pairs(guildData) do
			totalGuild = totalGuild + guildQuantity
		end
		local totalNum = totalPlayer + totalAlt + totalGuild + totalAuction
		if totalNum > 0 then
			local rightText = format(L["%s (%s player, %s alts, %s guild, %s AH)"], "|cffffffff"..totalNum.."|r", "|cffffffff"..totalPlayer.."|r", "|cffffffff"..totalAlt.."|r", "|cffffffff"..totalGuild.."|r", "|cffffffff"..totalAuction.."|r")
			tinsert(lines, numLines+1, {left="  "..L["Inventory:"], right=rightText})
		end
	end

	-- add heading
	if #lines > numStartingLines then
		tinsert(lines, numStartingLines+1, "|cffffff00" .. L["TradeSkillMaster Info:"].."|r")
	end
end



-- ============================================================================
-- General Slash-Command Handlers
-- ============================================================================

function TSM:PrintPriceSources()
	TSM:Printf(L["Below are your currently available price sources organized by module. The %skey|r is what you would type into a custom price box."], TSMAPI.Design:GetInlineColor("link"))
	local lines = {}
	local modulesList = {}
	local sources, modules = TSMAPI:GetPriceSources()
	for key, label in pairs(sources) do
		local module = modules[key]
		if not lines[module] then
			lines[module] = {}
			tinsert(modulesList, module)
		end
		tinsert(lines[module], {key=key, label=label})
	end
	for _, moduleLines in pairs(lines) do
		sort(moduleLines, function(a, b) return strlower(a.key) < strlower(b.key) end)
	end
	local chatFrame = TSMAPI:GetChatFrame()
	sort(modulesList, function(a, b) return strlower(a) < strlower(b) end)
	for _, module in ipairs(modulesList) do
		chatFrame:AddMessage("|cffffff00"..module..":|r")
		for _, info in ipairs(lines[module]) do
			chatFrame:AddMessage(format("  %s (%s)", TSMAPI.Design:GetInlineColor("link")..info.key.."|r", info.label))
		end
	end
end

function TSM:TestPriceSource(price)
	local endIndex, link = select(2, strfind(price, "(\124c[0-9a-f]+\124H[^\124]+\124h%[[^%]]+%]\124h\124r)"))
	if not link then return TSM:Print(L["Usage: /tsm price <ItemLink> <Price String>"]) end
	price = strsub(price, endIndex+1):trim()
	if price == "" then return TSM:Print(L["Usage: /tsm price <ItemLink> <Price String>"]) end
	local isValid, err = TSMAPI:ValidateCustomPrice(price)
	if not isValid then
		TSM:Printf(L["%s is not a valid custom price and gave the following error: %s"], TSMAPI.Design:GetInlineColor("link") .. price .. "|r", err)
	else
		local itemString = TSMAPI.Item:ToItemString(link)
		if not itemString then return TSM:Printf(L["%s is a valid custom price but %s is an invalid item."], TSMAPI.Design:GetInlineColor("link") .. price .. "|r", link) end
		local value = TSMAPI:GetCustomPriceValue(price, itemString)
		if not value then return TSM:Printf(L["%s is a valid custom price but did not give a value for %s."], TSMAPI.Design:GetInlineColor("link") .. price .. "|r", link) end
		TSM:Printf(L["A custom price of %s for %s evaluates to %s."], TSMAPI.Design:GetInlineColor("link") .. price .. "|r", link, TSMAPI:MoneyToString(value))
	end
end

function TSM:PrintVersion()
	TSM:Print(L["TSM Version Info:"])
	local chatFrame = TSMAPI:GetChatFrame()
	local unofficialModules = {}
	for _, module in ipairs(TSM.Modules:GetInfo()) do
		if module.isOfficial then
			chatFrame:AddMessage(module.name.." |cff99ffff"..module.version.."|r")
		else
			tinsert(unofficialModules, module)
		end
	end
	for _, module in ipairs(unofficialModules) do
		chatFrame:AddMessage(module.name.." |cff99ffff"..module.version.."|r |cffff0000["..L["Unofficial Module"].."]|r")
	end
end

function TSM:ChangeProfile(targetProfile)
	targetProfile = targetProfile:trim()
	local profiles = TSM.db:GetProfiles()
	if targetProfile == "" then
		TSM:Printf(L["No profile specified. Possible profiles: '%s'"], table.concat(profiles, "\", \""))
	else
		for _, profile in ipairs(profiles) do
			if profile == targetProfile then
				if profile ~= TSM.db:GetCurrentProfile() then
					TSM.db:SetProfile(profile)
				end
				TSM:Printf(L["Profile changed to '%s'."], profile)
				return
			end
		end
		TSM:Printf(L["Could not find profile '%s'. Possible profiles: '%s'"], targetProfile, table.concat(profiles, "\", \""))
	end
end

function TSM:GetAppVersion()
	return private.appInfo and private.appInfo.version or 0
end

function TSM:GetAppAddonVersions()
	return private.appInfo and private.appInfo.addonVersions
end



-- ============================================================================
-- General TSMAPI Getter Functions
-- ============================================================================

function TSMAPI:GetTSMProfileIterator()
	local originalProfile = TSM.db:GetCurrentProfile()
	local profiles = TSM.db:GetProfiles()

	return function()
		local profile = tremove(profiles)
		if profile then
			TSM.db:SetProfile(profile)
			return profile
		end
		TSM.db:SetProfile(originalProfile)
	end
end

function TSMAPI:GetChatFrame()
	local chatFrame = DEFAULT_CHAT_FRAME
	for i = 1, NUM_CHAT_WINDOWS do
		local name = strlower(GetChatWindowInfo(i) or "")
		if name ~= "" and name == strlower(TSM.db.global.chatFrame) then
			chatFrame = _G["ChatFrame" .. i]
			break
		end
	end
	return chatFrame
end

function TSMAPI:GetConnectedRealms()
	if not private.cachedConnectedRealms then
		local currentRealm = gsub(GetRealmName(), "[ %-]", "")
		local connectedRealms = GetAutoCompleteRealms() or {}

		if #connectedRealms > 0 then
			local currentRealmIndex = nil
			for i, realm in ipairs(connectedRealms) do
				if realm == currentRealm then
					currentRealmIndex = i
					break
				end
			end
			TSMAPI:Assert(currentRealmIndex, "Could not find current realm")
		end
		private.cachedConnectedRealms = connectedRealms
	end
	return private.cachedConnectedRealms
end

function TSMAPI:GetRegion()
	local cVar = GetCVar("Portal")
	return LibStub("LibRealmInfo"):GetCurrentRegion() or (cVar ~= "public-test" and cVar) or "PTR"
end
