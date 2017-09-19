-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for moving items between bags / bank.

local TSM = select(2, ...)
local Mover = TSM:NewModule("Mover", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {}

private.moves, private.splitMoves, private.bagState, private.callback = {}, {}, {}, {}, {}
private.includeSoulbound = nil

-- this is a set of wrapper functions so that I can switch
-- between GuildVault and bank function easily (taken from warehousing)

-- source functions
private.pickupContainerItemSrc = nil
private.getContainerItemIDSrc = nil
private.getContainerNumSlotsSrc = nil
private.getContainerItemLinkSrc = nil
private.getContainerNumFreeSlotsSrc = nil
private.splitContainerItemSrc = nil
private.getContainerItemInfoSrc = nil
-- dest functions
private.pickupContainerItemDest = nil
private.getContainerItemIDDest = nil
private.getContainerNumSlotsDest = nil
private.getContainerItemLinkDest = nil
private.getContainerNumFreeSlotsDest = nil
private.getContainerItemInfoDest = nil
-- misc functions
private.autoStoreItem = nil
private.getContainerItemQty = nil

function Mover:OnEnable()
	TSM:RegisterEvent("GUILDBANKFRAME_OPENED", function(event)
		private.bankType = "GuildVault"
	end)

	TSM:RegisterEvent("BANKFRAME_OPENED", function(event)
		private.bankType = "Bank"
		--workaround for blizzard bug if using default bank frame and you dont click the reagent bank tab while pulling stuff from the reagent bank
		if IsReagentBankUnlocked() and ReagentBankFrame and BankFrame:IsVisible() then
			BankFrameTab2:Click()
			BankFrameTab1:Click()
		end
	end)

	TSM:RegisterEvent("GUILDBANKFRAME_CLOSED", function(event, addon)
		private.bankType = nil
		private.includeSoulbound = nil
		TSM:UnregisterEvent("GUILDBANKBAGSLOTS_CHANGED")
		if private.moveThreadId then
			TSMAPI.Threading:Kill(private.moveThreadId)
			private:DoneSending()
		end
	end)

	TSM:RegisterEvent("BANKFRAME_CLOSED", function(event)
		private.bankType = nil
		private.includeSoulbound = nil
		TSM:UnregisterEvent("BAG_UPDATE")
		if private.moveThreadId then
			TSMAPI.Threading:Kill(private.moveThreadId)
			private:DoneSending()
		end
	end)
end

function private.setSrcBagFunctions(bagType)
	if bagType == "GuildVault" then
		private.autoStoreItem = function(bag, slot) AutoStoreGuildBankItem(bag, slot)
		end
		private.getContainerItemQty = function(bag, slot) return select(2, GetGuildBankItemInfo(bag, slot))
		end
		private.splitContainerItemSrc = function(bag, slot, need) SplitGuildBankItem(bag, slot, need);
		end
		private.pickupContainerItemSrc = function(bag, slot) PickupGuildBankItem(bag, slot)
		end
		private.getContainerNumSlotsSrc = function(bag) return MAX_GUILDBANK_SLOTS_PER_TAB or 98
		end
		private.getContainerItemLinkSrc = function(bag, slot) return GetGuildBankItemLink(bag, slot)
		end
		private.getContainerNumFreeSlotsSrc = function(bag) return MAX_GUILDBANK_SLOTS_PER_TAB or 98
		end --need to change this eventually
		private.getContainerItemIDSrc = function(bag, slot)
			local tmpLink = GetGuildBankItemLink(bag, slot)
			local quantity = select(2, GetGuildBankItemInfo(bag, slot))
			if tmpLink then
				return TSMAPI.Item:ToBaseItemString(tmpLink, true), quantity
			else
				return nil
			end
		end
		private.getContainerItemInfoSrc = function(bag, slot) return GetGuildBankItemInfo(bag, slot)
		end
	else
		private.autoStoreItem = function(bag, slot) UseContainerItem(bag, slot)
		end
		private.getContainerItemQty = function(bag, slot) return select(2, GetContainerItemInfo(bag, slot))
		end
		private.splitContainerItemSrc = function(bag, slot, need) SplitContainerItem(bag, slot, need)
		end
		private.pickupContainerItemSrc = function(bag, slot) PickupContainerItem(bag, slot)
		end
		private.getContainerItemIDSrc = function(bag, slot)
			local tmpLink = GetContainerItemLink(bag, slot)
			local quantity = select(2, GetContainerItemInfo(bag, slot))
			return TSMAPI.Item:ToBaseItemString(tmpLink, true), quantity
		end
		private.getContainerNumSlotsSrc = function(bag) return GetContainerNumSlots(bag)
		end
		private.getContainerItemLinkSrc = function(bag, slot) return GetContainerItemLink(bag, slot)
		end
		private.getContainerNumFreeSlotsSrc = function(bag) return GetContainerNumFreeSlots(bag)
		end
		private.getContainerItemInfoSrc = function(bag, slot) return GetContainerItemInfo(bag, slot)
		end
	end
end

function private.setDestBagFunctions(bagType)
	if bagType == "GuildVault" then
		private.pickupContainerItemDest = function(bag, slot) PickupGuildBankItem(bag, slot)
		end
		private.getContainerNumSlotsDest = function(bag) return MAX_GUILDBANK_SLOTS_PER_TAB or 98
		end
		private.getContainerNumFreeSlotsDest = function(bag) return private.GetEmptySlotCountThread(bag)
		end --need to change this eventually
		private.getContainerItemLinkDest = function(bag, slot) return GetGuildBankItemLink(bag, slot)
		end
		private.getDestContainerItemQty = function(bag, slot) return select(2, GetGuildBankItemInfo(bag, slot))
		end
		private.getContainerItemIDDest = function(bag, slot)
			local tmpLink = GetGuildBankItemLink(bag, slot)
			local quantity = select(2, GetGuildBankItemInfo(bag, slot))
			if tmpLink then
				return TSMAPI.Item:ToBaseItemString(tmpLink, true), quantity
			else
				return nil
			end
		end
		private.getContainerItemInfoDest = function(bag, slot) return GetGuildBankItemInfo(bag, slot)
		end
	else
		private.pickupContainerItemDest = function(bag, slot) PickupContainerItem(bag, slot)
		end
		private.getContainerItemIDDest = function(bag, slot)
			local tmpLink = GetContainerItemLink(bag, slot)
			local quantity = select(2, GetContainerItemInfo(bag, slot))
			return TSMAPI.Item:ToBaseItemString(tmpLink, true), quantity
		end
		private.getContainerNumSlotsDest = function(bag) return GetContainerNumSlots(bag)
		end
		private.getContainerItemLinkDest = function(bag, slot) return GetContainerItemLink(bag, slot)
		end
		private.getDestContainerItemQty = function(bag, slot) return select(2, GetContainerItemInfo(bag, slot))
		end
		private.getContainerNumFreeSlotsDest = function(bag) return GetContainerNumFreeSlots(bag)
		end
		private.getContainerItemInfoDest = function(bag, slot) return GetContainerItemInfo(bag, slot)
		end
	end
end

function private.getContainerTableThread(self, cnt)
	local t = {}

	if cnt == "Bank" then
		local numSlots, _ = GetNumBankSlots()
		local maxSlot, increment = 1, 3
		if IsReagentBankUnlocked() then
			maxSlot = 2
			increment = 2
		end

		for i = 1, numSlots + maxSlot do
			if i == 1 then
				t[i] = -1
			elseif i == 2 and maxSlot == 2 then
				t[i] = -3
			else
				t[i] = i + increment
			end
			self:Yield()
		end

		return t

	elseif cnt == "GuildVault" then
		for i = 1, GetNumGuildBankTabs() do
			local canView, canDeposit, stacksPerDay = GetGuildBankTabInfo(i);
			if canView and canDeposit and stacksPerDay then
				t[i] = i
			end
			self:Yield()
		end

		return t
	elseif cnt == "bags" then
		for i = 1, NUM_BAG_SLOTS + 1 do
			t[i] = i - 1
			self:Yield()
		end
		return t
	end
end

function private.GetEmptySlotsThread(self, container, limitBag)
	local emptySlots = {}
	for i, bag in ipairs(private.getContainerTableThread(self, container)) do
		if not limitBag or limitBag == bag then
			if private.getContainerNumSlotsDest(bag) > 0 then
				for slot = 1, private.getContainerNumSlotsDest(bag) do
					if not private.getContainerItemIDDest(bag, slot) then
						if not emptySlots[bag] then emptySlots[bag] = {}
						end
						table.insert(emptySlots[bag], slot)
					end
					self:Yield()
				end
			end
		end
	end
	return emptySlots
end

function private.GetEmptySlotCountThread(self, bag)
	local count = 0
	for slot = 1, private.getContainerNumSlotsDest(bag) do
		if not private.getContainerItemLinkDest(bag, slot) then
			count = count + 1
		end
	end
	if count ~= 0 then
		return count
	else
		return false
	end
end

function private.canGoInBagThread(self, itemLink, destTable, isCraftingReagent)
	local itemFamily = GetItemFamily(TSMAPI.Item:ToItemID(itemLink)) or 0
	local default
	if isCraftingReagent and IsReagentBankUnlocked() then
		if private.GetEmptySlotCountThread(self, REAGENTBANK_CONTAINER) then
			return REAGENTBANK_CONTAINER
		end
	end
	for _, bag in pairs(destTable) do
		if bag ~= REAGENTBANK_CONTAINER then
			local bagFamily = GetItemFamily(GetBagName(bag)) or 0
			if itemFamily and bagFamily and bagFamily > 0 and bit.band(itemFamily, bagFamily) > 0 then
				if private.GetEmptySlotCountThread(self, bag) then
					return bag
				end
			elseif bagFamily == 0 then
				if private.GetEmptySlotCountThread(self, bag) then
					if not default then
						default = bag
					end
				end
			end
			self:Yield()
		end
	end
	return default
end

function private.findExistingStackThread(self, itemLink, dest, quantity)
	local itemString = TSMAPI.Item:ToBaseItemString(itemLink, true)
	local maxStack = TSMAPI.Item:GetMaxStack(itemString)
	for i, bag in ipairs(private.getContainerTableThread(self, dest)) do
		if dest == "GuildVault" then
			if bag == GetCurrentGuildBankTab() then
				for slot = 1, private.getContainerNumSlotsDest(bag) do
					if private.getContainerItemIDDest(bag, slot) == TSMAPI.Item:ToBaseItemString(itemString, true) then
						local _, currentQuantity = private.getContainerItemIDDest(bag, slot)
						if currentQuantity and (currentQuantity + quantity) <= maxStack then
							return bag, slot, currentQuantity
						end
					end
					self:Yield()
				end
			end
		else
			for slot = 1, private.getContainerNumSlotsDest(bag) do
				if private.getContainerItemIDDest(bag, slot) == TSMAPI.Item:ToBaseItemString(itemString, true) then
					local _, currentQuantity = private.getContainerItemIDDest(bag, slot)
					if currentQuantity and (currentQuantity + quantity) <= maxStack then
						return bag, slot, currentQuantity
					end
				end
				self:Yield()
			end
		end
	end
end

function private.getTotalItemsThread(self, src)
	local results = {}
	if src == "Bank" then
		for _, _, itemString, quantity in TSMAPI.Inventory:BankIterator(true, true) do
			results[itemString] = (results[itemString] or 0) + quantity
			if self then self:Yield() end
		end

		return results
	elseif src == "GuildVault" then
		for tab = 1, GetNumGuildBankTabs() do
			if select(5, GetGuildBankTabInfo(tab)) > 0 or IsGuildLeader(UnitName("player")) then
				for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB or 98 do
					local itemString = TSMAPI.Item:ToBaseItemString(GetGuildBankItemLink(tab, slot), true)
					if itemString == "i:82800" then
						local speciesID = GameTooltip:SetGuildBankItem(tab, slot)
						itemString = speciesID and ("p:" .. speciesID)
					end
					if itemString then
						results[itemString] = (results[itemString] or 0) + select(2, GetGuildBankItemInfo(tab, slot))
					end
				end
			end
		end

		return results
	elseif src == "bags" then
		for bag, slot, itemString, quantity in TSMAPI.Inventory:BagIterator(true, true) do
			if private.bankType == "Bank" or not TSMAPI.Item:IsSoulbound(bag, slot) then
				results[itemString] = (results[itemString] or 0) + quantity
				if self then self:Yield() end
			end
		end

		return results
	end
end

function private.generateMovesThread(self)
	private.bagsFull, private.bankFull = false, false
	local bagMoves, bankMoves = {}, {}
	private.moves, private.splitMoves = {}, {}

	local currentBagState = private.getTotalItemsThread(self, "bags")

	for itemString, quantity in pairs(private.bagState) do
		local currentQty = currentBagState[itemString] or 0
		if quantity < currentQty then
			bagMoves[itemString] = currentQty - quantity
		elseif quantity > currentQty then
			bankMoves[itemString] = quantity - currentQty
		end
		self:Yield()
	end
	if next(bagMoves) ~= nil then
		-- generate moves from bags to bank
		private.setSrcBagFunctions("bags")
		private.setDestBagFunctions(private.bankType)
		for item, _ in pairs(bagMoves) do
			for i, bag in ipairs(private.getContainerTableThread(self, "bags")) do
				for slot = 1, private.getContainerNumSlotsSrc(bag) do
					local itemLink = private.getContainerItemLinkSrc(bag, slot)
					local itemString = TSMAPI.Item:ToBaseItemString(itemLink, true)
					if itemString and itemString == item then
						if (private.bankType == "GuildVault" and not TSMAPI.Item:IsSoulbound(bag, slot)) or private.includeSoulbound or not TSMAPI.Item:IsSoulbound(bag, slot) then
							local have = private.getContainerItemQty(bag, slot)
							local need = bagMoves[itemString]
							if have and need then
								local reagent = TSMAPI.Item:IsCraftingReagent(itemLink)
								-- find a destination bag
								local destBag = private.getDestBagSlotThread(self, itemLink, private.bankType, need, reagent)
								if destBag then
									if have > need then
										tinsert(private.splitMoves, { src = "bags", bag = bag, slot = slot, quantity = need, split = true })
										bagMoves[itemString] = nil
									else
										tinsert(private.moves, { src = "bags", bag = bag, slot = slot, quantity = have, split = false })
										bagMoves[itemString] = bagMoves[itemString] - have
										if bagMoves[itemString] <= 0 then
											bagMoves[itemString] = nil
										end
									end
								else
									private.bankFull = true
								end
							end
						end
					end
					self:Yield()
				end
				self:Yield()
			end
			self:Yield()
		end
	end


	if next(bankMoves) ~= nil then
		-- generate moves from bank to bags
		private.setSrcBagFunctions(private.bankType)
		private.setDestBagFunctions("bags")
		for item, _ in pairs(bankMoves) do
			for i, bag in ipairs(private.getContainerTableThread(self, private.bankType)) do
				for slot = 1, private.getContainerNumSlotsSrc(bag) do
					local itemLink = private.getContainerItemLinkSrc(bag, slot)
					local itemString = TSMAPI.Item:ToBaseItemString(itemLink, true)
					if private.bankType == "GuildVault" and itemString == "i:82800" then
						local speciesID = GameTooltip:SetGuildBankItem(bag, slot)
						itemString = speciesID and ("p:" .. speciesID)
					end
					if itemString and itemString == item then
						local have = private.getContainerItemQty(bag, slot)
						local need = bankMoves[itemString]
						if have and need then
							if not TSMAPI.Item:IsSoulbound(bag, slot, true) or private.includeSoulbound or private.bankType == "GuildVault" then
								local destBag = private.getDestBagSlotThread(self, itemLink, "bags", need)
								if destBag then
									if have > need then
										tinsert(private.splitMoves, { src = private.bankType, bag = bag, slot = slot, quantity = need, split = true })
										bankMoves[itemString] = nil
									else
										tinsert(private.moves, { src = private.bankType, bag = bag, slot = slot, quantity = have, split = false })
										bankMoves[itemString] = bankMoves[itemString] - have
										if bankMoves[itemString] <= 0 then
											bankMoves[itemString] = nil
										end
									end
								else
									private.bagsFull = true
								end
							end
						end
					end
					self:Yield()
				end
				self:Yield()
			end
			self:Yield()
		end
	end

	if next(private.moves) ~= nil or next(private.splitMoves) ~= nil then
		if next(private.moves) ~= nil then
			sort(private.moves, function(a, b)
				if a.bag == b.bag then
					return a.slot < b.slot
				end
				return a.bag < b.bag
			end)
			for i, move in pairs(private.moves) do
				private.moveItemThread(self, { move.src, move.bag, move.slot, move.quantity, move.split })
				self:Sleep(TSM.db.global.moveDelay or 0)
			end
		end
		self:Sleep(0.7)
		if next(private.splitMoves) ~= nil then
			sort(private.splitMoves, function(a, b)
				if a.bag == b.bag then
					return a.slot < b.slot
				end
				return a.bag < b.bag
			end)
			for _, move in pairs(private.splitMoves) do
				private.moveItemThread(self, { move.src, move.bag, move.slot, move.quantity, move.split })
				self:Sleep(TSM.db.global.moveDelay or 0)
			end
		end
		self:Sleep(0.5)
		if private.bankType == "bank" then
			if TSM.db.profile.cleanBank then
				SortBankBags()
			end
			if TSM.db.profile.cleanReagentBank and IsReagentBankUnlocked() then
				SortReagentBankBags()
			end
		end
		if TSM.db.profile.cleanBags then
			SortBags()
		end
		private.generateMovesThread(self)
	end
end

function private.moveItemThread(self, move)
	local src, bag, slot, need, split = unpack(move)
	-- Setup Source / Destination functions
	local source, destination
	if src == "bags" then
		source = src
		destination = private.bankType
	else
		source = private.bankType
		destination = "bags"
	end
	private.setSrcBagFunctions(source)
	private.setDestBagFunctions(destination)

	-- Get item details
	local itemLink = private.getContainerItemLinkSrc(bag, slot)
	local reagent
	if source == "bags" and itemLink then
		reagent = TSMAPI.Item:IsCraftingReagent(itemLink)
	end
	local have = private.getContainerItemQty(bag, slot)

	-- move the item if we can
	if have and need and itemLink then
		local destBag, destSlot, destExistingQty = private.getDestBagSlotThread(self, itemLink, destination, need, reagent)
		if destBag and destSlot then
			private.doTheMoveThread(self, source, destination, bag, slot, destBag, destSlot, need, split, destExistingQty)
		end
	end
end

function private.getDestBagSlotThread(self, itemLink, destType, need, reagent)
	--find an existing bag/slot
	local destBag, destSlot, destExistingQty = private.findExistingStackThread(self, itemLink, destType, need)
	if destExistingQty then
		return destBag, destSlot, destExistingQty
	else
		-- find an empty bag/slot
		local limitBag
		if destType == "GuildVault" then
			limitBag = GetCurrentGuildBankTab()
		end
		local emptySlots = private.GetEmptySlotsThread(self, destType, limitBag)
		if destType == "GuildVault" then
			destBag = GetCurrentGuildBankTab()
		else
			destBag = private.canGoInBagThread(self, itemLink, private.getContainerTableThread(self, destType), reagent)
		end
		if destBag then
			if emptySlots[destBag] then
				destSlot = emptySlots[destBag][1]
			end
			if destSlot then
				return destBag, destSlot
			end
		end
	end
end

function private.doTheMoveThread(self, source, destination, bag, slot, destBag, destSlot, need, split, existingQty)
	-- split or full move ?
	local moved, autoStore
	local itemLink = private.getContainerItemLinkSrc(bag, slot)
	if itemLink then
		if GetCursorInfo() == "item" then
			TSM:LOG_WARN("Pickup Item failed cursor not empty: %s %s bag=%s slot=%s", tostring(source), TSMAPI.Item:GetName(itemLink) or "None", tostring(bag), tostring(slot))
		elseif split then
			private.splitContainerItemSrc(bag, slot, need)
			if GetCursorInfo() == "item" then
				private.pickupContainerItemDest(destBag, destSlot)
				moved = true
			else
				TSM:LOG_WARN("Pickup Item failed from: %s %s bag=%s slot=%s", tostring(source), TSMAPI.Item:GetName(itemLink) or "None", tostring(bag), tostring(slot))
			end
		elseif destBag == REAGENTBANK_CONTAINER then
			private.pickupContainerItemSrc(bag, slot)
			if GetCursorInfo() == "item" then
				private.pickupContainerItemDest(destBag, destSlot)
				moved = true
			else
				TSM:LOG_WARN("Pickup Item failed from: %s %s bag=%s slot=%s", tostring(source), TSMAPI.Item:GetName(itemLink) or "None", tostring(bag), tostring(slot))
			end
		else
			private.autoStoreItem(bag, slot)
			moved, autoStore = true, true
		end

		-- wait for move to complete
		if moved then
			if source == "GuildVault" then
				QueryGuildBankTab(bag)
			end
			if destination == "GuildVault" then
				QueryGuildBankTab(destBag)
			end
			local numYields = 0
			while true do
				if autoStore or existingQty and not GetCursorInfo() then
					break
				elseif private.getContainerItemInfoDest(destBag, destSlot) then
					break
				elseif numYields >= 100 then
					TSM:LOG_WARN("Move Item failed from: %s %s bag=%s slot=%s", tostring(source), TSMAPI.Item:GetName(itemLink) or "None", tostring(bag), tostring(slot))
					return
				end
				numYields = numYields + 1
				self:Yield(true)
			end
			if private.bankType == "GuildVault" then
				self:Sleep(0.5)
			end
			self:Yield(true)
		else
			TSM:LOG_WARN("Move Item failed from: %s %s bag=%s slot=%s", tostring(source), TSMAPI.Item:GetName(itemLink) or "None", tostring(bag), tostring(slot))
			self:Yield(true)
		end
	else
		TSM:LOG_WARN("Invalid Move attempted from: %s %s bag=%s slot=%s, split = %s", tostring(source), TSMAPI.Item:GetName(itemLink) or "None", tostring(bag), tostring(slot), tostring(split))
		self:Yield(true)
	end
end

function TSMAPI:MoveItems(requestedItems, callback, includeSoulbound)
	if private.moveThreadId or not TSM:areBanksVisible() then return end
	private.moveThreadId = TSMAPI.Threading:Start(private.startMovingThread, 0.7, private.DoneSending, { requestedItems, includeSoulbound })
	private.callback = callback
end

function private.startMovingThread(self, args)
	self:SetThreadName("MOVER_MAIN")
	local requestedItems, includeSoulbound = unpack(args)
	wipe(private.bagState)
	if includeSoulbound then
		private.includeSoulbound = true
	else
		private.includeSoulbound = false
	end

	private.bagState = private.getTotalItemsThread(nil, "bags") -- create initial bagstate

	-- iterates over the requested items and adjusts bagState quantities , negative removes from bagState, positive adds to bagState
	-- this gives the final states to generate the moves from
	for itemString, qty in pairs(requestedItems) do
		private.bagState[itemString] = (private.bagState[itemString] or 0) + qty
		if private.bagState[itemString] < 0 then
			private.bagState[itemString] = 0
		end
		self:Yield()
	end
	private.generateMovesThread(self)
end

function TSM:areBanksVisible()
	if BagnonFrameGuildBank and BagnonFrameGuildBank:IsVisible() then
		return true
	elseif BagnonFrameguild and BagnonFrameguild:IsVisible() then
		return true
	elseif BagnonFramebank and BagnonFramebank:IsVisible() then
		return true
	elseif GuildBankFrame and GuildBankFrame:IsVisible() then
		return true
	elseif BankFrame and BankFrame:IsVisible() then
		return true
	elseif (ARKINV_Frame4 and ARKINV_Frame4:IsVisible()) or (ARKINV_Frame3 and ARKINV_Frame3:IsVisible()) then
		return true
	elseif (BagginsBag8 and BagginsBag8:IsVisible()) or (BagginsBag9 and BagginsBag9:IsVisible()) or (BagginsBag10 and BagginsBag10:IsVisible()) or (BagginsBag11 and BagginsBag11:IsVisible()) or (BagginsBag12 and BagginsBag12:IsVisible()) then
		return true
	elseif (CombuctorFramebank and CombuctorFramebank:IsVisible()) then
		return true
	elseif (CombuctorFrame2 and CombuctorFrame2:IsVisible()) then
		return true
	elseif (BaudBagContainer2_1 and BaudBagContainer2_1:IsVisible()) then
		return true
	elseif (OneBankFrame and OneBankFrame:IsVisible()) then
		return true
	elseif (EngBank_frame and EngBank_frame:IsVisible()) then
		return true
	elseif (TBnkFrame and TBnkFrame:IsVisible()) then
		return true
	elseif (famBankFrame and famBankFrame:IsVisible()) then
		return true
	elseif (LUIBank and LUIBank:IsVisible()) then
		return true
	elseif (ElvUI_BankContainerFrame and ElvUI_BankContainerFrame:IsVisible()) then
		return true
	elseif (TukuiBank and TukuiBank:IsShown()) then
		return true
	elseif (AdiBagsContainer1 and AdiBagsContainer1.isBank and AdiBagsContainer1:IsVisible()) or (AdiBagsContainer2 and AdiBagsContainer2.isBank and AdiBagsContainer2:IsVisible()) then
		return true
	elseif BagsFrameBank and BagsFrameBank:IsVisible() then
		return true
	elseif AspUIBank and AspUIBank:IsVisible() then
		return true
	elseif NivayacBniv_Bank and NivayacBniv_Bank:IsVisible() then
		return true
	elseif DufUIBank and DufUIBank:IsVisible() then
		return true
	elseif SVUI_BankContainerFrame and SVUI_BankContainerFrame:IsVisible() then
		return true
	elseif LiteBagBank and LiteBagBank:IsVisible() then
		return true
	elseif LiteBagInventory and LiteBagInventory:IsVisible() then
		return true
	end
	return false
end

function private:DoneSending()
	if private.cancelled then
		private.callback(L["Cancelled - You must be at a bank or GuildVault"])
	elseif private.bagsFull and not private.bankFull then
		private.callback(L["Cancelled - Bags are full"])
	elseif private.bankFull and not private.bagsFull then
		private.callback(L["Cancelled - Bank / Guild Vault is full"])
	elseif private.bagsFull and private.bankFull then
		private.callback(L["Cancelled - Bags and Bank / Guild Vault are full"])
	else
		private.callback(L["Done"])
	end
	private.bagState, private.moves, private.splitMoves = {}, {}, {}
	private.moveThreadId = nil
	private.callback, private.cancelled, private.bagsFull, private.bankFull, private.includeSoulbound = nil, nil, nil, nil, nil
end
