-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_Crafting", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table

TSM.MINING_SPELLID = 2575
TSM.SMELTING_SPELLID = 2656
TSM.MASS_MILLING_RECIPES = {
	[190381] = "i:114931",  -- Frostweed
	[190382] = "i:114931",  -- Fireweed
	[190383] = "i:114931",  -- Gorgrond Flytrap
	[190384] = "i:114931",  -- Starflower
	[190385] = "i:114931",  -- Nargrand Arrowbloom
	[190386] = "i:114931",  -- Talador Orchid
}


-- default values for the savedDB
local settingsInfo = {
	version = 7,
	global = {
		ignoreCDCraftCost = { type = "boolean", default = true, lastModifiedVersion = 1 },
		questSmartCrafting = { type = "boolean", default = true, lastModifiedVersion = 1 },
		showingDefaultFrame = { type = "boolean", default = false, lastModifiedVersion = 1 },
		frameQueueOpen = { type = "boolean", default = false, lastModifiedVersion = 1 },
		profitPercent = { type = "number", default = 0, lastModifiedVersion = 1 },
		priceColumn = { type = "number", default = 1, lastModifiedVersion = 1 },
		queueSort = { type = "number", default = 1, lastModifiedVersion = 1 },
		defaultMatCostMethod = { type = "string", default = "min(dbmarket, crafting, vendorbuy, convert(dbmarket))", lastModifiedVersion = 1 },
		defaultCraftPriceMethod = { type = "string", default = "first(dbminbuyout, dbmarket)", lastModifiedVersion = 1 },
		ignoreCharacters = { type = "table", default = {}, lastModifiedVersion = 1 },
		ignoreGuilds = { type = "table", default = {}, lastModifiedVersion = 1 },
		helpPlatesShown = { type = "table", default = { profession = nil, groups = nil, gatherSelection = nil, gatheringFrame = nil }, lastModifiedVersion = 1 },
	},
	factionrealm = {
		ignoreAlts = { type = "boolean", default = false, lastModifiedVersion = 1 },
		ignoreIntermediate = { type = "boolean", default = false, lastModifiedVersion = 1 },
		disableCheckBox = { type = "boolean", default = false, lastModifiedVersion = 1 },
		ignoreDECheckBox = { type = "boolean", default = false, lastModifiedVersion = 1 },
		evenStacks = { type = "boolean", default = false, lastModifiedVersion = 1 },
		playerProfessions = { type = "table", default = {}, lastModifiedVersion = 1 },
		professionScanCache = { type = "table", default = {}, lastModifiedVersion = 1 },
		crafts = { type = "table", default = {}, lastModifiedVersion = 1 },
		mats = { type = "table", default = {}, lastModifiedVersion = 1 },
		gathering = { type = "table", default = { crafter = nil, professions = {}, neededMats = {}, shortItems = {}, availableMats = {}, extraMats = {}, selectedSources = {}, selectedSourceStatus = {}, gatheredMats = false, destroyingMats = {}, sessionOptions = {} }, lastModifiedVersion = 2 },
		queueStatus = { type = "table", default = { collapsed = {} }, lastModifiedVersion = 1 },
		inkTrade = { type = "boolean", default = false, lastModifiedVersion = 3 },
		buyAH = { type = "boolean", default = false, lastModifiedVersion = 5 },
	},
}
TSM.defaultMatCostMethod = settingsInfo.global.defaultMatCostMethod.default
TSM.defaultCraftPriceMethod = settingsInfo.global.defaultCraftPriceMethod.default

local tooltipDefaults = {
	craftingCost = true,
	matPrice = false,
	detailedMats = false,
}
local operationDefaults = {
	minRestock = 1, -- min of 1
	maxRestock = 3, -- max of 3
	minProfit = 1000000,
	craftPriceMethod = nil,
}
TSM.operationDefaults = operationDefaults

-- Called once the player has loaded WOW.
function TSM:OnInitialize()
	if TradeSkillMasterModulesDB then
		TradeSkillMasterModulesDB.Crafting = TradeSkillMaster_CraftingDB
	end

	-- load settings
	TSM.db = TSMAPI.Settings:Init("TradeSkillMaster_CraftingDB", settingsInfo)

	-- create shortcuts to TradeSkillMaster_Crafting's modules
	for moduleName, module in pairs(TSM.modules) do
		TSM[moduleName] = module
	end

	-- update for TSM3
	for spellId, craft in pairs(TSM.db.factionrealm.crafts) do
		if craft.itemID then
			craft.itemString = craft.itemID
			craft.itemID = nil
			craft.queued = 0
			local newMats = {}
			for itemString, quantity in pairs(craft.mats) do
				itemString = TSMAPI.Item:ToItemString(itemString)
				if itemString then
					newMats[itemString] = quantity
				end
			end
			craft.mats = newMats
		end
	end
	local newMatData = {}
	for itemString, data in pairs(TSM.db.factionrealm.mats) do
		itemString = TSMAPI.Item:ToItemString(itemString)
		if itemString then
			newMatData[itemString] = data
		end
	end
	TSM.db.factionrealm.mats = newMatData

	TSM:UpdateCraftReverseLookup()

	-- apparently we used the queueSort key in the distant past, so just fix it
	if TSM.db.global.queueSort < 1 or TSM.db.global.queueSort > 3 then
		TSM.db.global.queueSort = 1
	end

	-- register this module with TSM
	TSM:RegisterModule()

	-- sync player professions data
	TSMAPI.Sync:Mirror(TSM.db.factionrealm.playerProfessions, "CRAFTING_PROFESSIONS")

	-- register 1:1 crafting conversions
	for spell, data in pairs(TSM.db.factionrealm.crafts) do
		local sourceItem, rate = nil, nil
		local numMats = 0
		for itemString, num in pairs(data.mats) do
			numMats = numMats + 1
			if numMats > 1 then break end -- skip crafts which involve more than one mat
			if not TSMAPI.Item:ToItemString(itemString) then
				-- this is not a valid itemString so remove it and bail out for this craft
				data.mats[itemString] = nil
				sourceItem = nil
				numMats = 2
				TSM:LOG_INFO("Found bad material itemString: %s", itemString)
				break
			end
			sourceItem = itemString
			rate = data.numResult / num
		end
		if numMats == 1 and not data.hasCD and not TSM.MASS_MILLING_RECIPES[spell] then
			TSMAPI.Conversions:Add(data.itemString, sourceItem, rate, "craft")
		end
	end
end

function TSM:OnEnable()
	local isValid, err = TSMAPI:ValidateCustomPrice(TSM.db.global.defaultCraftPriceMethod, "crafting")
	if not isValid then
		TSM:Printf(L["Your default craft value method was invalid so it has been returned to the default. Details: %s"], err)
		TSM.db.global.defaultCraftPriceMethod = TSM.defaultCraftPriceMethod
	end
	for name, operation in pairs(TSM.operations) do
		if operation.craftPriceMethod then
			local isValid, err = TSMAPI:ValidateCustomPrice(operation.craftPriceMethod, "crafting")
			if not isValid then
				TSM:Printf(L["Your craft value method for '%s' was invalid so it has been returned to the default. Details: %s"], name, err)
				operation.craftPriceMethod = operationDefaults.craftPriceMethod
			end
		end
	end
end

-- registers this module with TSM by first setting all fields and then calling TSMAPI:NewModule().
function TSM:RegisterModule()
	TSM.icons = { { side = "module", desc = "Crafting", slashCommand = "crafting", callback = "Options:LoadCrafting", icon = "Interface\\Icons\\INV_Misc_Gear_08" } }
	TSM.operations = { maxOperations = 1, callbackOptions = "Options:GetOperationOptionsInfo", callbackInfo = "GetOperationInfo", defaults = operationDefaults }
	TSM.moduleOptions = { callback = "Options:Load" }
	TSM.priceSources = {
		{ key = "Crafting", label = L["Crafting Cost"], callback = "GetCraftingCost", takeItemString = true },
		{ key = "matPrice", label = L["Crafting Material Cost"], callback = "GetCraftingMatCost", takeItemString = true },
	}
	TSM.slashCommands = {
		{ key = "profession", label = L["Opens the Crafting window to the first profession."], callback = TSM.TradeSkill.OpenFirstProfession },
		{ key = "restock_help", label = L["Tells you why a specific item is not being restocked and added to the queue."], callback = "RestockHelp" },
	}
	TSM.tooltip = { callbackLoad = "LoadTooltip", callbackOptions = "Options:LoadTooltipOptions", defaults = tooltipDefaults }

	TSMAPI:NewModule(TSM)
end

function TSM:GetOperationInfo(name)
	TSMAPI.Operations:Update("Crafting", name)
	local operation = TSM.operations[name]
	if not operation then return end
	if operation.minProfit then
		return format(L["Restocking to a max of %d (min of %d) with a min profit."], operation.maxRestock, operation.minRestock)
	else
		return format(L["Restocking to a max of %d (min of %d) with no min profit."], operation.maxRestock, operation.minRestock)
	end
end

function TSM:LoadTooltip(itemString, quantity, options, moneyCoins, lines)
	TSM:UpdateCraftReverseLookup()
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	local numStartingLines = #lines

	if TSM.craftReverseLookup[itemString] and options.craftingCost then
		local spellID, cost, buyout, profit = TSM.Cost:GetItemCraftPrices(itemString)
		if cost then
			local costText = (TSMAPI:MoneyToString(cost, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil) or "|cffffffff---|r")
			local profitColor = (profit or 0) < 0 and "|cffff0000" or "|cff00ff00"
			local profitText = (TSMAPI:MoneyToString(profit, profitColor, "OPT_PAD", moneyCoins and "OPT_ICON" or nil) or "|cffffffff---|r")
			tinsert(lines, { left = "  " .. L["Crafting Cost"], right = format(L["%s (%s profit)"], costText, profitText) })

			local craftInfo = TSM.db.factionrealm.crafts[spellID]
			if options.detailedMats and craftInfo then
				for matItemString, matQuantity in pairs(craftInfo.mats) do
					local name = TSMAPI.Item:GetName(matItemString)
					local mat = TSM.db.factionrealm.mats[matItemString]
					if name and mat then
						local cost = TSMAPI:GetCustomPriceValue(mat.customValue or TSM.db.global.defaultMatCostMethod, matItemString)
						if cost then
							local quality = TSMAPI.Item:GetQuality(matItemString)
							local colorName = format("|c%s%s%s%s|r", select(4, GetItemQualityColor(quality)), name, " x ", TSMAPI.Util:Round(matQuantity / craftInfo.numResult, 0.01))
							tinsert(lines, { left = "    " .. colorName, right = TSMAPI:MoneyToString((cost * matQuantity) / craftInfo.numResult, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil) })
						end
					end
				end
			end
		end
	end

	-- add mat price
	if options.matPrice then
		local matInfo = TSM.db.factionrealm.mats[itemString]
		local cost = matInfo and TSMAPI:GetCustomPriceValue(matInfo.customValue or TSM.db.global.defaultMatCostMethod, itemString) or nil
		if cost then
			tinsert(lines, { left = "  " .. L["Mat Cost"], right = TSMAPI:MoneyToString(cost, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil) })
		end
	end

	if #lines > numStartingLines then
		tinsert(lines, numStartingLines + 1, "|cffffff00TSM Crafting:|r")
	end
end

function TSM:GetCraftingCost(itemString)
	itemString = TSMAPI.Item:ToBaseItemString(TSMAPI.Item:ToItemString(itemString))
	if not itemString then return end

	TSM:UpdateCraftReverseLookup()
	local _, cost = TSM.Cost:GetItemCraftPrices(itemString)
	return cost
end

function TSM:GetCraftingMatCost(itemString)
	itemString = TSMAPI.Item:ToBaseItemString(TSMAPI.Item:ToItemString(itemString))
	if not itemString then return end

	TSM:UpdateCraftReverseLookup()
	return TSM.Cost:GetMatCost(itemString)
end

local reverseLookupUpdate = 0
function TSM:UpdateCraftReverseLookup()
	if reverseLookupUpdate >= time() - 30 then return end
	reverseLookupUpdate = time()
	TSM.craftReverseLookup = {}

	for spellID, data in pairs(TSM.db.factionrealm.crafts) do
		TSM.craftReverseLookup[data.itemString] = TSM.craftReverseLookup[data.itemString] or {}
		tinsert(TSM.craftReverseLookup[data.itemString], spellID)
	end
end

function TSM:RestockHelp(link)
	local itemString = TSMAPI.Item:ToItemString(link)
	if not itemString then
		return print(L["No item specified. Usage: /tsm restock_help [ITEM_LINK]"])
	end

	TSM:Printf(L["Restock help for %s:"], link)

	-- check if the item is in a group
	local groupPath = TSMAPI.Groups:GetPath(itemString)
	if not groupPath then
		return print(L["This item is not in a TSM group."])
	end

	-- check that there's a crafting operation applied
	local opName = TSMAPI.Operations:GetFirstByItem(itemString, "Crafting")
	local opSettings = opName and TSM.operations[opName]
	if not opSettings then
		return print(format(L["There is no TSM_Crafting operation applied to this item's TSM group (%s)."], TSMAPI.Groups:FormatPath(groupPath)))
	end

	-- check if it's an invalid operation
	if opSettings.minRestock > opSettings.maxRestock then
		return print(format(L["The operation applied to this item is invalid! Min restock of %d is higher than max restock of %d."], opSettings.minRestock, opSettings.maxRestock))
	end

	-- check that this item is craftable
	TSM:UpdateCraftReverseLookup()
	local spellID = TSM.craftReverseLookup[itemString] and TSM.craftReverseLookup[itemString][1]
	if not spellID or not TSM.db.factionrealm.crafts[spellID] then
		return print(L["You don't know how to craft this item."])
	end

	-- check the restock quantity
	local numHave = TSMAPI.Inventory:GetTotalQuantity(itemString)
	if numHave >= opSettings.maxRestock then
		return print(format(L["You already have at least your max restock quantity of this item. You have %d and the max restock quantity is %d"], numHave, opSettings.maxRestock))
	elseif (opSettings.maxRestock - numHave) < opSettings.minRestock then
		return print(format(L["The number which would be queued (%d) is less than the min restock quantity (%d)."], (opSettings.maxRestock - numHave), opSettings.minRestock))
	end

	-- check the prices on the item and the min profit
	if opSettings.minProfit then
		local cheapestSpellID, cost, craftedValue, profit = TSM.Cost:GetItemCraftPrices(itemString)

		-- check that there's a crafted value
		if not craftedValue then
			local craftPriceMethod = opSettings and opSettings.craftPriceMethod or TSM.db.global.defaultCraftPriceMethod
			return print(format(L["The 'Craft Value Method' (%s) did not return a value for this item. If it is based on some price database (AuctionDB, TSM_WoWuction, TUJ, etc), then ensure that you have scanned for or downloaded the data as appropriate."], craftPriceMethod))
		end

		-- check that there's a crafted cost
		if not cost then
			return print(L["This item does not have a crafting cost. Check that all of its mats have mat prices. If the mat prices are based on some price database (AuctionDB, TSM_WoWuction, TUJ, etc), then ensure that you have scanned for or downloaded the data as appropriate."])
		end

		-- check that there's a profit
		if not profit then
			return print(L["There is a crafting cost and crafted item value, but TSM_Crafting wasn't able to calculate a profit. This shouldn't happen!"])
		end

		local minProfit = TSMAPI:GetCustomPriceValue(opSettings.minProfit, itemString)
		if not minProfit then
			return print(format(L["The min profit (%s) did not evalulate to a valid value for this item."], opSettings.minProfit))
		end

		if profit < minProfit then
			return print(format(L["The profit of this item (%s) is below the min profit (%s)."], TSMAPI:MoneyToString(profit), TSMAPI:MoneyToString(minProfit)))
		end
	end

	print(L["This item will be added to the queue when you restock its group. If this isn't happening, make a post on the TSM forums with a screenshot of the item's tooltip, operation settings, and your general TSM_Crafting options."])
end

function TSM:GetSpellId(link)
	TSMAPI:Assert(type(linkOrIndex) == "string")
	return tonumber(strmatch(linkOrIndex, ":(%d+)\124h"))
end

function TSM:GetCurrentProfessionName()
	local _, name = C_TradeSkillUI.GetTradeSkillLine()
	if name and C_TradeSkillUI.IsNPCCrafting() then
		return name .. " (" .. GARRISON_LOCATION_TOOLTIP..")"
	end
	return name or "UNKNOWN"
end

function TSM:IsCurrentProfessionEnchanting()
	return select(2, C_TradeSkillUI.GetTradeSkillLine()) == GetSpellInfo(7411)
end

function TSM:GetInventoryTotals()
	local ignoreCharacters = CopyTable(TSM.db.global.ignoreCharacters)
	ignoreCharacters[UnitName("player")] = nil
	return TSMAPI.Inventory:GetCraftingTotals(ignoreCharacters, { [TSM.VELLUM_ITEM_STRING] = true })
end
