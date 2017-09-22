-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Cost = TSM:NewModule("Cost", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local private = {loopCheck={item=nil, visitCount=nil}, matsVisited={}}



-- ============================================================================
-- Module Functions
-- ============================================================================

-- gets the cost of a material
function Cost:GetMatCost(itemString)
	if not TSM.db.factionrealm.mats[itemString] then return end
	if itemString == private.loopCheck.item then
		private.loopCheck.visitCount = private.loopCheck.visitCount + 1
	end
	if private.matsVisited[itemString] then return end

	private.matsVisited[itemString] = true
	local cost = TSMAPI:GetCustomPriceValue(TSM.db.factionrealm.mats[itemString].customValue or TSM.db.global.defaultMatCostMethod, itemString)
	private.matsVisited[itemString] = nil

	return cost
end

-- checks if a mat has a loop in its mat cost custom price
function Cost:MatCostHasLoop(itemString)
	if not TSM.db.factionrealm.mats[itemString] then return end

	private.loopCheck.item = itemString
	private.loopCheck.visitCount = 0

	Cost:GetMatCost(itemString)

	private.loopCheck.item = nil
	TSMAPI:Assert(private.loopCheck.visitCount > 0) -- should be visited at least once

	return private.loopCheck.visitCount > 1
end

-- calculates the cost, buyout, and profit for a crafted item
function Cost:GetSpellCraftPrices(spellId)
	if not spellId or not TSM.db.factionrealm.crafts[spellId] then return end

	local cost = private:GetSpellCraftingCost(spellId)
	local buyout = private:GetCraftValue(TSM.db.factionrealm.crafts[spellId].itemString)
	local profit = nil
	if cost and buyout then
		profit = TSMAPI.Util:Round(buyout - buyout * TSM.db.global.profitPercent - cost)
	end
	return cost, buyout, profit
end

-- gets the spellId, cost, buyout, and profit for the cheapest way to craft the given item
function Cost:GetItemCraftPrices(itemString)
	local spellIds = TSM.craftReverseLookup[itemString]
	if not spellIds then return end

	local lowestCost, cheapestSpellId = nil, nil
	for _, spellId in ipairs(spellIds) do
		local cost = private:GetSpellCraftingCost(spellId)
		if cost and (not lowestCost or cost < lowestCost) then
			-- exclude spells with cooldown if option to ignore is enabled and there is more than one way to craft
			if not TSM.db.factionrealm.crafts[spellId].hasCD or not TSM.db.global.ignoreCDCraftCost or #spellIds == 1 then
				lowestCost = cost
				cheapestSpellId = spellId
			end
		end
	end

	if not lowestCost or not cheapestSpellId then return end
	local buyout = private:GetCraftValue(itemString)
	local profit = nil
	if buyout then
		profit = floor(buyout - buyout * TSM.db.global.profitPercent - lowestCost + 0.5)
	end

	return cheapestSpellId, lowestCost, buyout, profit
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

-- gets the craft cost for a given spell
function private:GetSpellCraftingCost(spellId)
	if not TSM.db.factionrealm.crafts[spellId] then return end
	local cost = 0
	for itemString, quantity in pairs(TSM.db.factionrealm.crafts[spellId].mats) do
		local matCost = Cost:GetMatCost(itemString) or 0
		if matCost == 0 then
			return
		end
		cost = cost + quantity * matCost
	end
	cost = TSMAPI.Util:Round(cost / TSM.db.factionrealm.crafts[spellId].numResult)
	return cost > 0 and cost or nil
end

-- gets the value of a crafted item
function private:GetCraftValue(itemString)
	if not itemString then return end

	local priceMethod = TSM.db.global.defaultCraftPriceMethod
	local operation = TSMAPI.Operations:GetFirstByItem(itemString, "Crafting")
	if operation and TSM.operations[operation] then
		TSMAPI.Operations:Update("Crafting", operation)
		priceMethod = TSM.operations[operation].craftPriceMethod or priceMethod
	end
	return TSMAPI:GetCustomPriceValue(priceMethod, itemString)
end
