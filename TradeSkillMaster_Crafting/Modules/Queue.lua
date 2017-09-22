-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Queue = TSM:NewModule("Queue")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local private = { isQueued = {}, notified = {} }



function Queue:OnEnable()
	for spellID, data in pairs(TSM.db.factionrealm.crafts) do
		Queue:SetNumQueued(spellID, data.queued) -- sanitize / cache the number queued
	end
end

function Queue:SetNumQueued(spellID, numQueued)
	local prevQueued = TSM.db.factionrealm.crafts[spellID].queued
	TSM.db.factionrealm.crafts[spellID].queued = max(floor(numQueued or 0), 0)
	if TSM.db.factionrealm.crafts[spellID].queued > 0 then
		private.isQueued[spellID] = true
	else
		private.isQueued[spellID] = nil
	end
	return prevQueued ~= TSM.db.factionrealm.crafts[spellID].queued
end

function Queue:Add(spellID, quantity)
	local craft = TSM.db.factionrealm.crafts[spellID]
	if not craft then return end
	quantity = quantity or 1
	TSMAPI:Assert(quantity > 0)
	return Queue:SetNumQueued(spellID, craft.queued + quantity)
end

function Queue:Remove(spellID, quantity)
	local craft = TSM.db.factionrealm.crafts[spellID]
	if not craft then return end
	quantity = quantity or 1
	TSMAPI:Assert(quantity > 0)
	return Queue:SetNumQueued(spellID, craft.queued - quantity)
end

function Queue:Get(spellID)
	local craft = TSM.db.factionrealm.crafts[spellID]
	return craft and craft.queued or 0
end

function Queue:Clear()
	wipe(private.isQueued)
	for spellID, data in pairs(TSM.db.factionrealm.crafts) do
		data.queued = 0
	end
end

function Queue:GetNumItems()
	private:PruneQueue()
	local num = 0
	for _ in pairs(private.isQueued) do
		num = num + 1
	end
	return num
end

function private:PruneQueue()
	-- remove any items from the queue which we don't have data for
	local toRemove = {}
	for spellID in pairs(private.isQueued) do
		if not TSM.db.factionrealm.crafts[spellID] then
			tinsert(toRemove, spellID)
		end
	end
	for _, spellID in ipairs(toRemove) do
		private.isQueued[spellID] = nil
	end
end

function private:IsOperationValid(operation, opName)
	if not operation then return end
	if operation.minRestock > operation.maxRestock then
		-- invalid cause min > max restock quantity (shouldn't happen)
		if not private.notified[opName] then
			private.notified[opName] = true
			TSM:Printf(L["'%s' is an invalid operation! Min restock of %d is higher than max restock of %d."], opName, operation.minRestock, operation.maxRestock)
		end
		return
	end
	return true
end

function Queue:DoRestock(groupInfo)
	TSM:UpdateCraftReverseLookup()
	private:PruneQueue()

	for _, data in pairs(groupInfo) do
		for _, opName in ipairs(data.operations) do
			TSMAPI.Operations:Update("Crafting", opName)
			local operation = TSM.operations[opName]
			if private:IsOperationValid(operation, opName) then
				-- it's a valid operation
				for itemString in pairs(data.items) do
					itemString = TSMAPI.Item:ToItemString(itemString)
					local spellID = TSM.craftReverseLookup[itemString] and TSM.craftReverseLookup[itemString][1]
					if spellID and TSM.db.factionrealm.crafts[spellID] then
						local cheapestSpellID, _, _, profit = TSM.Cost:GetItemCraftPrices(itemString)
						spellID = cheapestSpellID or spellID
						local ignoredQty = 0
						for guild, ignored in pairs(TSM.db.global.ignoreGuilds) do
							if ignored then
								ignoredQty = ignoredQty + TSMAPI.Inventory:GetGuildQuantity(itemString, guild)
							end
						end
						for player, ignored in pairs(TSM.db.global.ignoreCharacters) do
							if ignored then
								ignoredQty = ignoredQty + TSMAPI.Inventory:GetBagQuantity(itemString, player)
								ignoredQty = ignoredQty + TSMAPI.Inventory:GetBankQuantity(itemString, player)
								ignoredQty = ignoredQty + TSMAPI.Inventory:GetReagentBankQuantity(itemString, player)
								ignoredQty = ignoredQty + TSMAPI.Inventory:GetAuctionQuantity(itemString, player)
								ignoredQty = ignoredQty + TSMAPI.Inventory:GetMailQuantity(itemString, player)
							end
						end
						local numToQueue = max(operation.maxRestock - (TSMAPI.Inventory:GetTotalQuantity(itemString) - ignoredQty), 0)
						local minProfit = operation.minProfit and TSMAPI:GetCustomPriceValue(operation.minProfit, itemString) or nil
						-- queue only if it satisfies all operation criteria
						if numToQueue >= operation.minRestock and (not operation.minProfit or (minProfit and profit and profit >= minProfit)) then
							Queue:SetNumQueued(spellID, floor(numToQueue / TSM.db.factionrealm.crafts[spellID].numResult))
						end
					end
				end
			end
		end
	end
end

function Queue:GetStatus()
	private:PruneQueue()
	local queueCrafts, queueMats = {}, {}
	local totalCost, totalProfit
	for spellID in pairs(private.isQueued) do
		local data = TSM.db.factionrealm.crafts[spellID]
		local cost, _, profit = TSM.Cost:GetSpellCraftPrices(spellID)
		if cost then
			totalCost = (totalCost or 0) + (cost * data.queued) * data.numResult
		end
		if profit then
			totalProfit = (totalProfit or 0) + profit * data.queued * data.numResult
		end

		local trueProfession = gsub(data.profession, TSMAPI.Util:StrEscape(" (" .. GARRISON_LOCATION_TOOLTIP..")"), "")

		queueCrafts[trueProfession] = queueCrafts[trueProfession] or {}
		queueCrafts[trueProfession][spellID] = data.queued
		for itemString, quantity in pairs(data.mats) do
			queueMats[itemString] = (queueMats[itemString] or 0) + quantity * data.queued
		end
	end

	return queueCrafts, queueMats, totalCost, totalProfit
end

function Queue:GetMatsByProfession(professionsList)
	private:PruneQueue()
	local queueMats = {}
	for spellID in pairs(private.isQueued) do
		local data = TSM.db.factionrealm.crafts[spellID]
		if data and professionsList and professionsList[data.profession] then
			queueMats[data.profession] = queueMats[data.profession] or {}
			for itemString, quantity in pairs(data.mats) do
				queueMats[data.profession][itemString] = (queueMats[data.profession][itemString] or 0) + quantity * data.queued
			end
		end
	end

	return queueMats
end
