-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

--load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local TradeSkill = TSM:GetModule("TradeSkill")
local Gather = TSM:NewModule("Gather", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table

--Professions--
TSM.spells = {
	milling = 51005,
	prospect = 31252,
	disenchant = 13262,
}

local private = { shoppingItems = {} }

function Gather:BuyFromMerchant(neededMats)
	for i = 1, GetMerchantNumItems() do
		local itemString = TSMAPI.Item:ToBaseItemString(GetMerchantItemLink(i))
		if neededMats[itemString] then
			local maxStack = GetMerchantItemMaxStack(i)
			local toBuy = neededMats[itemString]
			local bought = toBuy
			while toBuy > 0 do
				BuyMerchantItem(i, math.min(toBuy, maxStack))
				toBuy = toBuy - maxStack
				TSM.db.factionrealm.gathering.gatheredMats = true
			end
			if UnitName("player") ~= TSM.db.factionrealm.gathering.crafter then
				Gather:updateSelectedSource("vendor", itemString)
				Gather:updateSelectedSource(UnitName("player"), itemString, bought)
			end
		end
	end
end

function Gather:gatherItems(source, task, disableCrafting, ignoreDE)
	local items = TSM.db.factionrealm.gathering.availableMats

	if source == "vendor" then
		Gather:BuyFromMerchant(items)
	elseif source == UnitName("player") and (task == "bank" or task == "gVault") then
		Gather:GatherBank(items)
	elseif source == UnitName("player") and task == "mail" then
		Gather:MailItems(items)
	elseif source == "crafting" then
		Gather:CraftNext(items)
	elseif source == "auction" then
		if TSMAPI.Auction:IsTabVisible("Shopping") then
			private.shoppingItems = {}
			for itemString, quantity in pairs(items) do
				tinsert(private.shoppingItems, { itemString = itemString, quantity = quantity })
			end
			Gather:ShoppingSearch(private.shoppingItems[1].itemString, private.shoppingItems[1].quantity, disableCrafting, ignoreDE)
		else
			TSM:Printf(L["Please switch to the Shopping Tab to perform the gathering search."])
		end
	end
end

function Gather:GatherBank(moveItems)
	local next = next
	if next(moveItems) == nil then
		TSM:Print(L["Nothing to Gather"])
	else
		TSM:Print(L["Gathering Crafting Mats"])
		local ignoreReagents = UnitName("player") == TSM.db.factionrealm.gathering.crafter and true or false
		TSMAPI:MoveItems(moveItems, Gather.PrintMsg, false, ignoreReagents)
		TSM.db.factionrealm.gathering.gatheredMats = true
	end
end

function Gather.PrintMsg(message)
	if message then
		TSM:Print(message)
	end
end

function Gather:MerchantSells(neededItem)
	for i = 1, GetMerchantNumItems() do
		local itemString = TSMAPI.Item:ToItemString(GetMerchantItemLink(i))
		if neededItem == itemString then
			return true
		end
	end
	return false
end

function Gather:MailItems(neededItems)
	if next(neededItems) == nil then
		TSM:Print(L["Nothing to Mail"])
	else
		local crafter = TSM.db.factionrealm.gathering.crafter
		if crafter then
			TSM:Print(format(L["Mailing Craft Mats to %s"], crafter))
			TSMAPI:ModuleAPI("Mailing", "mailItems", neededItems, crafter, Gather.PrintMsg)
			TSM.db.factionrealm.gathering.gatheredMats = true
		end
	end
end

function private.ShoppingNextSearch()
	if next(private.shoppingItems) then
		Gather:ShoppingSearch(private.shoppingItems[1].itemString, private.shoppingItems[1].quantity, private.disableCrafting, private.ignoreDE, private.even)
	end
end

function private.reverseSpellLookups(itemString, boughtItemString)
	local spellIds = {}
	TSM:UpdateCraftReverseLookup()
	local spellId = TSM.craftReverseLookup[boughtItemString] and TSM.craftReverseLookup[boughtItemString][1]
	if spellId and TSM.db.factionrealm.crafts[spellId] then
		local spellData = TSM.db.factionrealm.crafts[spellId]
		tinsert(spellIds, { spellId, spellData.itemString })
		if spellData.itemString == itemString then
			--TSM:Print("1st spell")
		else
			local nextSpellID = TSM.craftReverseLookup[spellData.itemString] and TSM.craftReverseLookup[spellData.itemString][1]
			if nextSpellID and TSM.db.factionrealm.crafts[nextSpellID] then
				local nextSpellData = TSM.db.factionrealm.crafts[nextSpellID]
				tinsert(spellIds, { nextSpellID, nextSpellData.itemString })
				if nextSpellData.itemString == itemString then
					--TSM:Print("2nd spell")
				else
					--TSM:Print("another conversion needed", Gather.gatherItem, boughtItemString)
				end
			end
		end
	end
	return spellIds
end

function Gather:CraftNext(spellList)
	local bagTotals = TSM:GetInventoryTotals()
	for _, spellId in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
		if spellList[spellId] then
			local spellQuantity = spellList[spellId]
			local craft = TSM.db.factionrealm.crafts[spellId]
			-- figure out how many we can craft with mats in our bags
			local numCanCraft = math.huge
			for itemString, quantity in pairs(craft.mats) do
				numCanCraft = max(min(numCanCraft, floor((bagTotals[itemString] or 0) / quantity)), 0)
			end
			numCanCraft = min(spellQuantity, floor(numCanCraft / craft.numResult))
			if numCanCraft > 0 then
				local velName = craft.mats[TSM.VELLUM_ITEM_STRING] and (TSMAPI.Item:GetName(TSM.VELLUM_ITEM_STRING) or TSM.db.factionrealm.mats[TSM.VELLUM_ITEM_STRING].name) or nil
				TradeSkill:CastTradeSkill(spellId, numCanCraft, velName)
				return
			end
		end
	end
end

function private.ShoppingCallback(boughtItem, boughtQty)
	local convertQty
	if not boughtItem then
		if next(private.shoppingItems) then
			TSM:Printf(L["No Auctions found for %s"], TSMAPI.Item:GetLink(private.shoppingItems[1].itemString))
			tremove(private.shoppingItems, 1)
			TSMAPI.Delay:AfterTime("shoppingSearchThrottle", 0.5, private.ShoppingNextSearch)
		end
	else
		if Gather.gatherItem and boughtItem ~= Gather.gatherItem then
			local method, destroyQty = private:IsDestroyable(boughtItem)
--			if method and destroyQty then
--				TSM:Print(method, "bought: ", floor(boughtQty / destroyQty), "destroyNeed: ", destroyQty)
--			end

			TSM:UpdateCraftReverseLookup()
			local spellIds = private.reverseSpellLookups(Gather.gatherItem, boughtItem)
			--			if next(spellIds) then
			--				TSM:Print("spells found", #spellIds)
			--			end
			local conversionData = TSMAPI.Conversions:GetData(Gather.gatherItem)
			if conversionData and conversionData[boughtItem] then
				--TSM:Print(boughtItem, "bought:", boughtQty, " remaining:", "rate: ", conversionData[boughtItem].rate)
				convertQty = floor(boughtQty / conversionData[boughtItem].rate)
				TSM.db.factionrealm.gathering.destroyingMats[boughtItem] = (TSM.db.factionrealm.gathering.destroyingMats[boughtItem] or 0) + convertQty
			end
		end
		Gather.gatherQuantity = Gather.gatherQuantity - boughtQty
		if max(Gather.gatherQuantity, 0) == 0 then
			if next(private.shoppingItems) then
				tremove(private.shoppingItems, 1)
				TSMAPI.Delay:AfterTime("shoppingSearchThrottle", 0.5, private.ShoppingNextSearch)
			end
		end
		TSMAPI.Delay:AfterTime("GatherUpdate", 0.3, TradeSkill.Gather.Update)
	end
end

function Gather:ShoppingSearch(itemString, need, disableCrafting, ignoreDE, even)
	Gather.gatherItem = itemString
	Gather.gatherQuantity = need
	private.disableCrafting = disableCrafting
	private.ignoreDE = ignoreDE
	private.even = even

	TSMAPI:ModuleAPI("Shopping", "startSearchGathering", itemString, need, private.ShoppingCallback, disableCrafting, ignoreDE, even)
end

function Gather:GetItemSources(crafter, neededMats)
	local mustHaveBags = {} -- items must be in bags
	mustHaveBags[TSM.VELLUM_ITEM_STRING] = true
	if not neededMats then return end
	local sources = {}
	local inkTradeItem
	local intermediate = {}
	-- add crafting tasks
	if not TSM.db.factionrealm.gathering.sessionOptions.ignoreIntermediate then
		for itemString, quantity in pairs(neededMats) do
			local matCost = TSM.Cost:GetMatCost(itemString) or math.huge
			local cheapestSpellId, lowestCost = TSM.Cost:GetItemCraftPrices(itemString)
			if cheapestSpellId and lowestCost <= matCost then
				local data = TSM.db.factionrealm.crafts[cheapestSpellId]
				if not data.hasCD then
					local need = quantity - (TSMAPI.Inventory:GetBagQuantity(itemString, crafter) + TSMAPI.Inventory:GetBankQuantity(itemString, crafter) + TSMAPI.Inventory:GetReagentBankQuantity(itemString, crafter) + TSMAPI.Inventory:GetMailQuantity(itemString, crafter))
					if need > 0 then
						local spellNeed = ceil(need / data.numResult)
						sources[itemString] = sources[itemString] or {}
						sources[itemString]["crafting"] = sources[itemString]["crafting"] or {}
						sources[itemString]["crafting"][cheapestSpellId] = need
						if TSM.db.factionrealm.gathering.selectedSourceStatus[cheapestSpellId] then
							intermediate[itemString] = true
							sources[itemString]["selected"] = (sources[itemString]["selected"] or 0) + need
							for mat, matQty in pairs(data.mats) do
								neededMats[mat] = (neededMats[mat] or 0) + (matQty * spellNeed)
							end
						end
					end
				end
			end
		end
	end

	-- add vendor items
	for itemString, quantity in pairs(neededMats) do
		if TSMAPI.Item:GetVendorCost(itemString) then
			local vendorNeed = quantity - (TSMAPI.Inventory:GetBagQuantity(itemString, crafter) + TSMAPI.Inventory:GetBankQuantity(itemString, crafter) + TSMAPI.Inventory:GetReagentBankQuantity(itemString, crafter) + TSMAPI.Inventory:GetMailQuantity(itemString, crafter))
			if vendorNeed > 0 then
				sources[itemString] = sources[itemString] or {}
				sources[itemString]["vendorBuy"] = sources[itemString]["vendorBuy"] or {}
				sources[itemString]["vendorBuy"]["buy"] = vendorNeed
				sources[itemString]["selected"] = (sources[itemString]["selected"] or 0) + vendorNeed
			end
		elseif TSMAPI.Conversions:GetData(itemString) and TSM.db.factionrealm.gathering.sessionOptions.inkTrade and not intermediate[itemString] then
			for tradeItemString, info in pairs(TSMAPI.Conversions:GetData(itemString)) do
				tradeItemString = TSMAPI.Item:ToItemString(tradeItemString)
				if info.method == "vendortrade" then
					local totalNum = TSMAPI.Inventory:GetTotalQuantity(itemString)
					if quantity > totalNum then
						sources[itemString] = sources[itemString] or {}
						sources[itemString]["vendorTrade"] = sources[itemString]["vendorTrade"] or {}
						sources[itemString]["vendorTrade"]["buy"] = quantity - totalNum
						sources[itemString]["selected"] = (sources[itemString]["selected"] or 0) + (quantity - totalNum)
						inkTradeItem = tradeItemString
						mustHaveBags[inkTradeItem] = true
						neededMats[tradeItemString] = (neededMats[tradeItemString] or 0) + quantity / info.rate -- add the qty of Warbinders ink to needed mats
					end
				end
			end
		end
	end

	-- add conversion tasks
--	for itemString, quantity in pairs(neededMats) do
--		if TSMAPI.Conversions:GetData(itemString) then
--			for srcItemString, info in pairs(TSMAPI.Conversions:GetData(itemString)) do
--				srcItemString = TSMAPI.Item:ToItemString(srcItemString)
--				if info.method == "transform" then
--					local totalNum = TSMAPI.Inventory:GetTotalQuantity(itemString)
--					if quantity > totalNum then
--						local srcNum = TSMAPI.Inventory:GetTotalQuantity(srcItemString)
--						if srcNum * info.rate > 1 then
--							mustHaveBags[srcItemString] = true
--							sources[itemString] = sources[itemString] or {}
--							sources[itemString]["transform"] = sources[itemString]["transform"] or {}
--							sources[itemString]["transform"]["transform"] = quantity - totalNum
--							if TSM.db.factionrealm.gathering.selectedSourceStatus["transform" .. "|" .. itemString] then
--								neededMats[srcItemString] = (neededMats[srcItemString] or 0) + (quantity - totalNum) / info.rate
--							end
--						end
--					end
--				end
--			end
--		end
--	end

	-- double check if crafter already has all the items needed
	local shortItems = {}
	for itemString, quantity in pairs(neededMats) do
		local numHave = TSMAPI.Inventory:GetBagQuantity(itemString, crafter)
		if not mustHaveBags[itemString] then -- you need the item in your bags
		numHave = numHave + TSMAPI.Inventory:GetReagentBankQuantity(itemString, crafter)
		end
		if quantity > numHave then
			shortItems[itemString] = quantity - numHave
		end
	end
	TSM.db.factionrealm.gathering.shortItems = shortItems
	if not next(shortItems) then return end

	-- add bags/bank/mail "tasks" for needed items of all non-ignored characters (always include crafter)
	for player in pairs(TSMAPI.Player:GetCharacters()) do
		if player == crafter or not TSM.db.global.ignoreCharacters[player] and not TSM.db.factionrealm.gathering.sessionOptions.ignoreAlts then
			local task = {}
			local bankItems = {}
			local gVaultItems = {}
			local mailItems = {}
			local bagItems = {}

			for itemString in pairs(neededMats) do
				if (TSMAPI.Inventory:GetBankQuantity(itemString, player) > 0 or TSMAPI.Inventory:GetReagentBankQuantity(itemString, player) > 0) and shortItems[itemString] then
					if shortItems[itemString] - TSMAPI.Inventory:GetMailQuantity(itemString, crafter) - (player ~= crafter and TSMAPI.Inventory:GetBagQuantity(itemString, player) or 0) > 0 then
						if TSMAPI.Item:IsSoulboundMat(itemString) then
							if player == crafter then
								bankItems[itemString] = TSMAPI.Inventory:GetBankQuantity(itemString, player)
							end
						else
							bankItems[itemString] = TSMAPI.Inventory:GetBankQuantity(itemString, player)
							if player ~= crafter or mustHaveBags[itemString] then
								bankItems[itemString] = bankItems[itemString] + TSMAPI.Inventory:GetReagentBankQuantity(itemString, player)
							end
						end
						if bankItems[itemString] and bankItems[itemString] > 0 then
							sources[itemString] = sources[itemString] or {}
							sources[itemString][player] = sources[itemString][player] or {}
							sources[itemString][player]["bank"] = min(bankItems[itemString], shortItems[itemString])
							sources[itemString]["selected"] = (sources[itemString]["selected"] or 0) + min(bankItems[itemString], shortItems[itemString])
						end
					end
				end
				local playerGuild = TSMAPI.Player:GetPlayerGuild(player)
				if playerGuild and not TSM.db.global.ignoreGuilds[playerGuild] and TSMAPI.Inventory:GetGuildQuantity(itemString, playerGuild) > 0 and shortItems[itemString] then
					if shortItems[itemString] - TSMAPI.Inventory:GetMailQuantity(itemString, crafter) - (player ~= crafter and TSMAPI.Inventory:GetBagQuantity(itemString, player) or 0) > 0 then
						gVaultItems[itemString] = TSMAPI.Inventory:GetGuildQuantity(itemString, playerGuild)
					end
					if gVaultItems[itemString] then
						sources[itemString] = sources[itemString] or {}
						sources[itemString][player] = sources[itemString][player] or {}
						sources[itemString][player]["gVault"] = min(gVaultItems[itemString], shortItems[itemString])
						sources[itemString]["selected"] = (sources[itemString]["selected"] or 0) + min(gVaultItems[itemString], shortItems[itemString])
					end
				end
				if TSMAPI.Inventory:GetMailQuantity(itemString, player) > 0 and shortItems[itemString] then
					mailItems[itemString] = TSMAPI.Inventory:GetMailQuantity(itemString, player)
					if mailItems[itemString] then
						sources[itemString] = sources[itemString] or {}
						sources[itemString][player] = sources[itemString][player] or {}
						sources[itemString][player]["mail"] = min(mailItems[itemString], shortItems[itemString])
						sources[itemString]["selected"] = (sources[itemString]["selected"] or 0) + min(mailItems[itemString], shortItems[itemString])
					end
				end
				if TSMAPI.Inventory:GetBagQuantity(itemString, player) > 0 and shortItems[itemString] then
					if player ~= crafter and not TSMAPI.Item:IsSoulboundMat(itemString) then
						if shortItems[itemString] - TSMAPI.Inventory:GetMailQuantity(itemString, crafter) > 0 then
							bagItems[itemString] = TSMAPI.Inventory:GetBagQuantity(itemString, player)
							sources[itemString] = sources[itemString] or {}
							sources[itemString][player] = sources[itemString][player] or {}
							sources[itemString][player]["bags"] = min(bagItems[itemString], shortItems[itemString])
							sources[itemString]["selected"] = (sources[itemString]["selected"] or 0) + min(bagItems[itemString], shortItems[itemString])
						end
					end
				end
				-- add mail tasks for destroyable items bought through shopping search (exclude items already added to mail tasks)
				for itemString, quantity in pairs(TSM.db.factionrealm.gathering.destroyingMats) do
					if TSMAPI.Inventory:GetMailQuantity(itemString, player) > 0 and not shortItems[itemString] then
						sources[itemString] = sources[itemString] or {}
						sources[itemString][player] = sources[itemString][player] or {}
						sources[itemString][player]["mail"] = min(quantity, TSMAPI.Inventory:GetMailQuantity(itemString, player))
						sources[itemString]["selected"] = (sources[itemString]["selected"] or 0) + min(quantity, TSMAPI.Inventory:GetMailQuantity(itemString, player))
					end
				end
			end
		end
	end


	-- add auction house tasks
	for itemString, quantity in pairs(neededMats) do
		if not TSMAPI.Item:IsSoulboundMat(itemString) and (not TSMAPI.Item:GetVendorCost(itemString) or (TSM.Cost:GetMatCost(itemString) or math.huge) < TSMAPI.Item:GetVendorCost(itemString)) then
			local need
			if Gather.gatherItem == itemString and Gather.gatherQuantity then
				need = Gather.gatherQuantity
			else
				need = shortItems[itemString] or 0
			end
			if not TSM.db.factionrealm.gathering.sessionOptions.buyAH then
				need = need - (sources[itemString] and sources[itemString]["selected"] or 0)
			end
			if need > 0 then
				sources[itemString] = sources[itemString] or {}
				sources[itemString]["auction"] = sources[itemString]["auction"] or {}
				sources[itemString]["auction"]["buy"] = need
				sources[itemString]["selected"] = (sources[itemString]["selected"] or 0) + need
				sources[itemString]["ahQty"] = (sources[itemString]["ahQty"] or 0) + need
			end
		end
	end

	return sources, neededMats
end

function Gather:updateSelectedSource(sourceName, itemString, quantity, spellId, spellQty)
	local selectedQty, totalQty = 0, 0
	if spellId then
		sourceName = spellId
	end
	if TSM.db.factionrealm.gathering.selectedSourceStatus[sourceName .. "|" .. itemString] then
		TSM.db.factionrealm.gathering.selectedSources[itemString][sourceName] = nil
		TSM.db.factionrealm.gathering.selectedSourceStatus[sourceName .. "|" .. itemString] = false
		if spellId then
			TSM.Queue:Remove(spellId, spellQty)
			TradeSkill.Queue:Update()
		end
	elseif quantity then
		TSM.db.factionrealm.gathering.selectedSources[itemString] = TSM.db.factionrealm.gathering.selectedSources[itemString] or {}
		if sourceName ~= "auction" or ((TSM.db.factionrealm.gathering.selectedSources[itemString]["total"] or 0) < (TSM.db.factionrealm.gathering.shortItems[itemString] or math.huge)) then
			selectedQty = min(quantity, (TSM.db.factionrealm.gathering.shortItems[itemString] or math.huge))
			TSM.db.factionrealm.gathering.selectedSources[itemString][sourceName] = selectedQty
			TSM.db.factionrealm.gathering.selectedSourceStatus[sourceName .. "|" .. itemString] = true
			if spellId then
				TSM.Queue:Add(spellId, spellQty)
				TradeSkill.Queue:Update()
			end
		end
	end
end

-- determines if an item is disenchantable, millable or prospectable
local TRADE_GOODS = GetItemClassInfo(LE_ITEM_CLASS_TRADEGOODS)
local METAL_AND_STONE = GetItemSubClassInfo(LE_ITEM_CLASS_TRADEGOODS, 7)
local HERB = GetItemSubClassInfo(LE_ITEM_CLASS_TRADEGOODS, 9)
local destroyCache = {}
function private:IsDestroyable(itemString)
	if destroyCache[itemString] then
		return unpack(destroyCache[itemString])
	end

	-- disenchanting
	if TSMAPI.Item:IsDisenchantable(itemString) then
		destroyCache[itemString] = { IsSpellKnown(TSM.spells.disenchant) and GetSpellInfo(TSM.spells.disenchant), 1 }
		return unpack(destroyCache[itemString])
	end

	local classId = TSMAPI.Item:GetClassId(itemString)
	local subClassId = TSMAPI.Item:GetSubClassId(itemString)
	if classId ~= LE_ITEM_CLASS_TRADEGOODS or (subClassId ~= 7 and subClassId ~= 9) then
		destroyCache[itemString] = {}
		return unpack(destroyCache[itemString])
	end

	-- milling
	for _, targetItem in ipairs(TSMAPI.Conversions:GetTargetItemsByMethod("mill")) do
		local herbs = TSMAPI.Conversions:GetData(targetItem)
		if herbs[itemString] then
			destroyCache[itemString] = { GetSpellInfo(TSM.spells.milling), 5 }
			return unpack(destroyCache[itemString])
		end
	end

	-- prospecting
	for _, targetItem in ipairs(TSMAPI.Conversions:GetTargetItemsByMethod("prospect")) do
		local gems = TSMAPI.Conversions:GetData(targetItem)
		if gems[itemString] then
			destroyCache[itemString] = { GetSpellInfo(TSM.spells.prospect), 5 }
			return unpack(destroyCache[itemString])
		end
	end

	return destroyCache[itemString] and unpack(destroyCache[itemString]) or nil
end
