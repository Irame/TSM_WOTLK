-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code and APIs related to inventory data (bag/bank/auction/vault/mail)

local TSM = select(2, ...)
local Inventory = TSM:NewModule("Inventory", "AceEvent-3.0", "AceHook-3.0")
local private = {
	bagIndexList = { bag = nil, bank = nil },
	isOpen = { bank = nil, auctionHouse = nil, mail = nil, guildVault = nil },
	pendingMailQuantities = {},
	oldState = {},
	lastUpdate = { bag = 0, bank = 0, reagentBank = 0, auction = 0, mail = 0, pendingMail = 0, guildVault = 0 },
	playerData = {}, -- reference to all characters on this realm (and connected realms) - kept in sync
	guildData = {}, -- reference to all guilds on this realm (and connected realms)
	inventoryChangeCallbacks = {},
	petSpeciesCache = {},
	bagIteratorCache = { items = {}, hasData = nil, hasSoulbound = nil, hasSoulboundBOA = nil },
}
local PLAYER_NAME = UnitName("player")
local PLAYER_GUILD = nil
local SECONDS_PER_DAY = 24 * 60 * 60
local GUILD_VAULT_SLOTS_PER_TAB = 98



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Inventory:BagIterator(autoBaseItems, includeSoulbound, includeBOA)
	if not private.bagIteratorCache.hasData then
		private.bagIteratorCache.hasSoulbound = nil
		private.bagIteratorCache.hasSoulboundBOA = nil
		wipe(private.bagIteratorCache.items)
		local isValid = true
		for b = 0, NUM_BAG_SLOTS do
			for s = 1, GetContainerNumSlots(b) do
				local link = GetContainerItemLink(b, s)
				if link and strmatch(link, "keystone:[0-9]+") then
					-- ignore keystone items introduced in patch 7.2
					link = nil
				end
				if link then
					isValid = isValid and not strmatch(link, "\124h%[%]\124h")
					local _, quantity, locked = GetContainerItemInfo(b, s)
					tinsert(private.bagIteratorCache.items, {
						bag = b,
						slot = s,
						link = link,
						quantity = quantity,
						locked = locked
					})
				end
			end
		end
		if isValid then
			private.bagIteratorCache.hasData = true
		end
	end

	local index = 1
	local iter
	iter = function()
		local info = private.bagIteratorCache.items[index]
		index = index + 1
		if not info then return end

		local shouldInclude = nil
		if includeSoulbound then
			-- include all items
			shouldInclude = true
		elseif includeBOA then
			-- include BOA items
			if info.isSoulboundBOA == nil then
				info.isSoulboundBOA = TSMAPI.Item:IsSoulbound(info.bag, info.slot, true)
			end
			shouldInclude = not info.isSoulboundBOA
		else
			-- include non-soulbound items
			if info.isSoulbound == nil then
				info.isSoulbound = TSMAPI.Item:IsSoulbound(info.bag, info.slot)
			end
			shouldInclude = not info.isSoulbound
		end
		if not shouldInclude then
			return iter()
		end

		local itemString = autoBaseItems and TSMAPI.Item:ToBaseItemString(info.link, true) or TSMAPI.Item:ToItemString(info.link)
		return info.bag, info.slot, itemString, info.quantity, info.locked
	end

	return iter
end

function TSMAPI.Inventory:BankIterator(autoBaseItems, includeSoulbound, includeBOA, includeReagents)
	local bags, b, s = {}, 1, 0
	tinsert(bags, -1)
	if includeReagents and IsReagentBankUnlocked() then
		tinsert(bags, REAGENTBANK_CONTAINER)
	end
	for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		tinsert(bags, bag)
	end

	local iter
	iter = function()
		if bags[b] then
			if s < GetContainerNumSlots(bags[b]) then
				s = s + 1
			else
				s = 1
				b = b + 1
				if not bags[b] then return end
			end
			local link = GetContainerItemLink(bags[b], s)
			local itemString
			if autoBaseItems then
				itemString = TSMAPI.Item:ToBaseItemString(link, true)
			else
				itemString = TSMAPI.Item:ToItemString(link)
			end

			if not itemString or (not includeSoulbound and TSMAPI.Item:IsSoulbound(bags[b], s, includeBOA)) then
				return iter()
			else
				local _, quantity, locked = GetContainerItemInfo(bags[b], s)
				return bags[b], s, itemString, quantity, locked
			end
		end
	end

	return iter
end

function TSMAPI.Inventory:RegisterCallback(callback)
	TSMAPI:Assert(type(callback) == "function")
	tinsert(private.inventoryChangeCallbacks, callback)
end

function TSMAPI.Inventory:ItemWillGoInBag(link, bag)
	if not link or not bag then return end
	if bag == 0 then return true end
	local itemFamily = GetItemFamily(link)
	local _, bagFamily = GetContainerNumFreeSlots(bag)
	if not bagFamily then return end
	return bagFamily == 0 or bit.band(itemFamily, bagFamily) > 0
end

function TSMAPI.Inventory:GetBagQuantity(itemString, player)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	player = player or PLAYER_NAME
	if not itemString then return 0 end
	return private.playerData[player] and private.playerData[player].bag[itemString] or 0
end

function TSMAPI.Inventory:GetBankQuantity(itemString, player)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	player = player or PLAYER_NAME
	if not itemString then return 0 end
	return private.playerData[player] and private.playerData[player].bank[itemString] or 0
end

function TSMAPI.Inventory:GetReagentBankQuantity(itemString, player)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	player = player or PLAYER_NAME
	if not itemString then return 0 end
	return private.playerData[player] and private.playerData[player].reagentBank[itemString] or 0
end

function TSMAPI.Inventory:GetAuctionQuantity(itemString, player)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	player = player or PLAYER_NAME
	if not itemString then return 0 end
	return private.playerData[player] and private.playerData[player].auction[itemString] or 0
end

function TSMAPI.Inventory:GetMailQuantity(itemString, player)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	player = player or PLAYER_NAME
	if not itemString then return 0 end
	return (private.playerData[player] and private.playerData[player].mail[itemString] or 0) + (private.pendingMailQuantities[player] and private.pendingMailQuantities[player][itemString] or 0)
end

function TSMAPI.Inventory:GetGuildQuantity(itemString, guild)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	guild = guild or PLAYER_GUILD
	if not guild or not itemString then return 0 end
	if TSM.db.factionrealm.ignoreGuilds[guild] then return 0 end
	return private.guildData[guild] and private.guildData[guild][itemString] or 0
end

function TSMAPI.Inventory:GetPlayerTotals(itemString)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	if not itemString then return end
	local numPlayer, numAlts, numAuctions, numAltAuctions = 0, 0, 0, 0
	for playerName, data in pairs(private.playerData) do
		if playerName == PLAYER_NAME then
			numPlayer = numPlayer + (data.bag[itemString] or 0)
			numPlayer = numPlayer + (data.bank[itemString] or 0)
			numPlayer = numPlayer + (data.reagentBank[itemString] or 0)
			numPlayer = numPlayer + (data.mail[itemString] or 0) + (private.pendingMailQuantities[playerName] and private.pendingMailQuantities[playerName][itemString] or 0)
		else
			numAlts = numAlts + (data.bag[itemString] or 0)
			numAlts = numAlts + (data.bank[itemString] or 0)
			numAlts = numAlts + (data.reagentBank[itemString] or 0)
			numAlts = numAlts + (data.mail[itemString] or 0) + (private.pendingMailQuantities[playerName] and private.pendingMailQuantities[playerName][itemString] or 0)
			numAltAuctions = numAltAuctions + (data.auction[itemString] or 0)
		end
		numAuctions = numAuctions + (data.auction[itemString] or 0)
	end
	return numPlayer, numAlts, numAuctions, numAltAuctions
end

function TSMAPI.Inventory:GetGuildTotal(itemString)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	if not itemString then return end
	local numGuild = 0
	for guild, data in pairs(private.guildData) do
		if not TSM.db.factionrealm.ignoreGuilds[guild] then
			numGuild = numGuild + (data[itemString] or 0)
		end
	end
	return numGuild
end

function TSMAPI.Inventory:GetTotalQuantity(itemString)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	local numPlayer, numAlts, numAuctions = TSMAPI.Inventory:GetPlayerTotals(itemString)
	local numGuild = TSMAPI.Inventory:GetGuildTotal(itemString)
	return numPlayer + numAlts + numAuctions + numGuild
end

function TSMAPI.Inventory:GetCraftingTotals(ignoreCharacters, otherItems)
	local bagTotal, auctionTotal, otherTotal, total = {}, {}, {}, {}

	for player, data in pairs(private.playerData) do
		if not ignoreCharacters[player] then
			for itemString, quantity in pairs(data.bag) do
				if player == PLAYER_NAME then
					bagTotal[itemString] = (bagTotal[itemString] or 0) + quantity
					total[itemString] = (total[itemString] or 0) + quantity
				else
					otherTotal[itemString] = (otherTotal[itemString] or 0) + quantity
					total[itemString] = (total[itemString] or 0) + quantity
				end
			end
			for itemString, quantity in pairs(data.bank) do
				otherTotal[itemString] = (otherTotal[itemString] or 0) + quantity
				total[itemString] = (total[itemString] or 0) + quantity
			end
			for itemString, quantity in pairs(data.reagentBank) do
				if player == PLAYER_NAME then
					if otherItems[itemString] then
						otherTotal[itemString] = (otherTotal[itemString] or 0) + quantity
					else
						bagTotal[itemString] = (bagTotal[itemString] or 0) + quantity
					end
				else
					otherTotal[itemString] = (otherTotal[itemString] or 0) + quantity
				end
				total[itemString] = (total[itemString] or 0) + quantity
			end
			for itemString, quantity in pairs(data.mail) do
				otherTotal[itemString] = (otherTotal[itemString] or 0) + quantity
				total[itemString] = (total[itemString] or 0) + quantity
			end
			for itemString, quantity in pairs(data.auction) do
				auctionTotal[itemString] = (auctionTotal[itemString] or 0) + quantity
				total[itemString] = (total[itemString] or 0) + quantity
			end
		end
	end

	for player, data in pairs(private.pendingMailQuantities) do
		for itemString, quantity in pairs(data) do
			otherTotal[itemString] = (otherTotal[itemString] or 0) + quantity
			total[itemString] = (total[itemString] or 0) + quantity
		end
	end

	for guild, data in pairs(private.guildData) do
		if not TSM.db.factionrealm.ignoreGuilds[guild] then
			for itemString, quantity in pairs(data) do
				otherTotal[itemString] = (otherTotal[itemString] or 0) + quantity
				total[itemString] = (total[itemString] or 0) + quantity
			end
		end
	end

	return bagTotal, auctionTotal, otherTotal, total
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Inventory:OnEnable()
	for player, data in pairs(TSM.db.factionrealm.inventory) do
		private.playerData[player] = data
	end
	for guild, data in pairs(TSM.db.factionrealm.guildVaults) do
		private.guildData[guild] = data
	end
	for factionrealm, connectedRealmSettings in TSM.db:GetConnectedRealmIterator("factionrealm") do
		local realmName = strmatch(factionrealm, "[A-Za-z]+ %- (.+)")
		for player, data in pairs(connectedRealmSettings.inventory) do
			if realmName and realmName ~= GetRealmName() then
				player = player.."-"..realmName
			end
			private.playerData[player] = data
		end
		for guild, data in pairs(connectedRealmSettings.guildVaults) do
			private.guildData[guild] = data
		end
	end
	-- initialize pendingMailQuantities
	wipe(private.pendingMailQuantities)
	for player, pendingMailData in pairs(TSM.db.factionrealm.pendingMail) do
		private.pendingMailQuantities[player] = private.pendingMailQuantities[player] or {}
		for _, info in ipairs(pendingMailData) do
			for itemString, quantity in pairs(info.items) do
				private.pendingMailQuantities[player][itemString] = (private.pendingMailQuantities[player][itemString] or 0) + quantity
			end
		end
	end
	Inventory:RegisterEvent("BAG_UPDATE", private.EventHandler)
	Inventory:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", private.EventHandler)
	Inventory:RegisterEvent("BANKFRAME_OPENED", private.EventHandler)
	Inventory:RegisterEvent("BANKFRAME_CLOSED", private.EventHandler)
	Inventory:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", private.EventHandler)
	Inventory:RegisterEvent("AUCTION_HOUSE_SHOW", private.EventHandler)
	Inventory:RegisterEvent("AUCTION_HOUSE_CLOSED", private.EventHandler)
	Inventory:RegisterEvent("MAIL_INBOX_UPDATE", private.EventHandler)
	Inventory:RegisterEvent("MAIL_SHOW", private.EventHandler)
	Inventory:RegisterEvent("MAIL_CLOSED", private.EventHandler)
	Inventory:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED", private.EventHandler)
	Inventory:RegisterEvent("GUILDBANKFRAME_OPENED", private.EventHandler)
	Inventory:RegisterEvent("GUILDBANKFRAME_CLOSED", private.EventHandler)
	TSMAPI.Threading:StartImmortal(private.MainThread, 0.3)
end

function Inventory:RemoveCharacterData(playerName)
	TSMAPI.Sync:SetKeyValue(TSM.db.factionrealm.characters, playerName, nil)
	TSMAPI.Sync:SetKeyValue(TSM.db.factionrealm.inventory, playerName, nil)
	TSM.db.factionrealm.pendingMail[playerName] = nil
	TSM.db.factionrealm.characterGuilds[playerName] = nil
	private.playerData[playerName] = nil
	private.pendingMailQuantities[playerName] = nil
end

function Inventory:GetItemData(itemString)
	itemString = TSMAPI.Item:ToBaseItemString(itemString)
	local playerData = {}
	for playerName, data in pairs(private.playerData) do
		playerData[playerName] = {}
		playerData[playerName].bag = data.bag[itemString] or 0
		playerData[playerName].bank = data.bank[itemString] or 0
		playerData[playerName].reagentBank = data.reagentBank[itemString] or 0
		playerData[playerName].auction = data.auction[itemString] or 0
		playerData[playerName].mail = data.mail[itemString] or 0
		if private.pendingMailQuantities[playerName] then
			playerData[playerName].mail = playerData[playerName].mail + (private.pendingMailQuantities[playerName][itemString] or 0)
		end
	end

	local guildData = {}
	for guild, data in pairs(private.guildData) do
		if not TSM.db.factionrealm.ignoreGuilds[guild] then
			guildData[guild] = data[itemString] or 0
		end
	end
	return playerData, guildData
end

function Inventory:GetAllData()
	local playerData = {}
	for playerName, data in pairs(private.playerData) do
		playerData[playerName] = {}
		playerData[playerName].bag = CopyTable(data.bag)
		playerData[playerName].bank = CopyTable(data.bank)
		playerData[playerName].reagentBank = CopyTable(data.reagentBank)
		playerData[playerName].auction = CopyTable(data.auction)
		playerData[playerName].mail = CopyTable(data.mail)
		if private.pendingMailQuantities[playerName] then
			for itemString, quantity in pairs(private.pendingMailQuantities[playerName]) do
				playerData[playerName].mail[itemString] = (playerData[playerName].mail[itemString] or 0) + quantity
			end
		end
	end

	local guildData = {}
	for guild, data in pairs(private.guildData) do
		if not TSM.db.factionrealm.ignoreGuilds[guild] then
			guildData[guild] = data
		end
	end
	return playerData, guildData
end



-- ============================================================================
-- Event Handler
-- ============================================================================

function private.EventHandler(event, data)
	if event == "BANKFRAME_OPENED" then
		private.isOpen.bank = true
		private.lastUpdate.bank = GetTime()
	elseif event == "BANKFRAME_CLOSED" then
		private.isOpen.bank = nil
	elseif event == "BAG_UPDATE" then
		private.bagIteratorCache.hasData = nil
		if data < 0 or data > NUM_BAG_SLOTS then
			private.lastUpdate.bank = GetTime()
		else
			private.lastUpdate.bag = GetTime()
		end
	elseif event == "BAG_CLOSED" then
		private.bagIndexList.bag = nil
		private.bagIndexList.bank = nil
	elseif event == "PLAYERREAGENTBANKSLOTS_CHANGED" then
		private.lastUpdate.reagentBank = GetTime()
	elseif event == "AUCTION_HOUSE_SHOW" then
		private.isOpen.auctionHouse = true
	elseif event == "AUCTION_HOUSE_CLOSED" then
		private.isOpen.auctionHouse = nil
	elseif event == "AUCTION_OWNED_LIST_UPDATE" then
		private.lastUpdate.auction = GetTime()
	elseif event == "MAIL_INBOX_UPDATE" then
		private.lastUpdate.mail = GetTime()
	elseif event == "MAIL_SHOW" then
		private.isOpen.mail = true
	elseif event == "MAIL_CLOSED" then
		private.isOpen.mail = nil
	elseif event == "GUILDBANKBAGSLOTS_CHANGED" then
		private.lastUpdate.guildVault = GetTime()
	elseif event == "GUILDBANKFRAME_OPENED" then
		local initTab = GetCurrentGuildBankTab()
		for i = 1, GetNumGuildBankTabs() do
			QueryGuildBankTab(i)
		end
		QueryGuildBankTab(initTab)
		private.isOpen.guildVault = true
	elseif event == "GUILDBANKFRAME_CLOSED" then
		private.isOpen.guildVault = nil
	end
end



-- ============================================================================
-- Inventory Threads
-- ============================================================================

function private.MainThread(self)
	self:SetThreadName("INVENTORY_MAIN")

	while not PLAYER_NAME do
		PLAYER_NAME = UnitName("player")
		self:Yield(true)
	end
	if IsInGuild() then
		while not PLAYER_GUILD do
			PLAYER_GUILD = GetGuildInfo("player")
			self:Yield(true)
		end
	end

	if PLAYER_GUILD then
		TSM.db.factionrealm.characterGuilds[PLAYER_NAME] = PLAYER_GUILD
		-- clean up any guilds with no players in them
		local validGuilds = {}
		for player in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters) do
			local guild = TSM.db.factionrealm.characterGuilds[player]
			if guild then
				validGuilds[guild] = true
			end
		end
		local toRemove = {}
		for player, guild in pairs(TSM.db.factionrealm.characterGuilds) do
			if not validGuilds[guild] then
				tinsert(toRemove, player)
			end
		end
		for _, player in ipairs(toRemove) do
			TSM.db.factionrealm.characterGuilds[player] = nil
		end
		wipe(toRemove)
		for guild in pairs(TSM.db.factionrealm.guildVaults) do
			if not validGuilds[guild] then
				tinsert(toRemove, guild)
			end
		end
		for _, guild in ipairs(toRemove) do
			TSM.db.factionrealm.guildVaults[guild] = nil
		end
	end

	if not TSM.db.factionrealm.inventory[PLAYER_NAME] then
		TSM.db.factionrealm.inventory[PLAYER_NAME] = { bag = {}, bank = {}, reagentBank = {}, auction = {}, mail = {} }
		private.playerData[PLAYER_NAME] = TSM.db.factionrealm.inventory[PLAYER_NAME]
	end
	if PLAYER_GUILD and not TSM.db.factionrealm.guildVaults[PLAYER_GUILD] then
		TSM.db.factionrealm.guildVaults[PLAYER_GUILD] = {}
		private.guildData[PLAYER_GUILD] = TSM.db.factionrealm.guildVaults[PLAYER_GUILD]
	end
	TSMAPI.Threading:Start(private.MailThread, 0.5, nil, nil, self:GetThreadId())
	TSMAPI.Sync:Mirror(TSM.db.factionrealm.inventory, "TSM_INVENTORY")

	local MIN_SCAN_TIME = 5
	local scanTimes = { bag = -1, bank = -1, reagentBank = -1, auction = -1, guildVault = -1 }
	while true do
		local didChange = nil

		-- check if we need to scan the player's bags
		if scanTimes.bag < private.lastUpdate.bag or scanTimes.bag < GetTime() - MIN_SCAN_TIME then
			if private:DoScan("bag") then
				didChange = true
			end
			scanTimes.bag = GetTime()
		end

		-- check if we need to scan the player's bank
		if (scanTimes.bank < private.lastUpdate.bank or scanTimes.bank < GetTime() - MIN_SCAN_TIME) and private.isOpen.bank then
			if private:DoScan("bank") then
				didChange = true
			end
			scanTimes.bank = GetTime()
		end

		-- check if we need to scan the player's reagent bank
		if scanTimes.reagentBank < private.lastUpdate.reagentBank or scanTimes.reagentBank < GetTime() - MIN_SCAN_TIME then
			if private:DoScan("reagentBank") then
				didChange = true
			end
			scanTimes.reagentBank = GetTime()
		end

		-- check if we need to scan the player's auctions
		if (scanTimes.auction < private.lastUpdate.auction or scanTimes.auction < GetTime() - MIN_SCAN_TIME) and private.isOpen.auctionHouse then
			if private:DoScan("auction") then
				didChange = true
			end
			scanTimes.auction = GetTime()
		end

		-- check if we need to scan the guild vault
		if (scanTimes.guildVault < private.lastUpdate.guildVault or scanTimes.guildVault < GetTime() - MIN_SCAN_TIME) and private.isOpen.guildVault and PLAYER_GUILD then
			private:DoScan("guildVault")
			scanTimes.guildVault = GetTime()
		end

		-- if something changed, notify the sync code
		if didChange then
			TSMAPI.Sync:KeyUpdated(TSM.db.factionrealm.inventory, PLAYER_NAME)
		end

		-- need to constantly check that private.playerData is kept in sync because
		-- there might be account syncing going on which will update it
		for player, data in pairs(TSM.db.factionrealm.inventory) do
			private.playerData[player] = data
		end

		-- if something changed, run the callbacks
		if didChange then
			for _, callback in ipairs(private.inventoryChangeCallbacks) do
				callback()
			end
		end

		self:Yield(true)
	end
end

function private.MailThread(self)
	self:SetThreadName("INVENTORY_MAIL")
	TSM.db.factionrealm.pendingMail[PLAYER_NAME] = TSM.db.factionrealm.pendingMail[PLAYER_NAME] or {}

	-- handle auction buying
	local function OnAuctionBid(listType, index, bidPlaced)
		local itemString = TSMAPI.Item:ToBaseItemString(GetAuctionItemLink(listType, index))
		local name, stackSize, buyout = TSMAPI.Util:Select({ 1, 3, 10 }, GetAuctionItemInfo(listType, index))
		if itemString and bidPlaced == buyout then
			private:InsertPendingMail(PLAYER_NAME, "auction_buy", { [itemString] = stackSize }, time())
		end
	end

	-- handle auction canceling
	local function OnAuctionCanceled(index)
		local itemString = TSMAPI.Item:ToBaseItemString(GetAuctionItemLink("owner", index))
		local _, _, stackSize = GetAuctionItemInfo("owner", index)
		private:InsertPendingMail(PLAYER_NAME, "auction_cancel", { [itemString] = stackSize }, time())
	end

	-- handle sending mail to alts
	local function OnMailSent(target)
		local targetName, realm = ("-"):split(strlower(target))
		if realm and realm ~= strlower(GetRealmName()) then return end
		local altName
		for name in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters) do
			if strlower(name) == targetName then
				altName = name
				break
			end
		end
		if not altName then return end
		local items = {}
		for i = 1, ATTACHMENTS_MAX_SEND do
			local itemString = TSMAPI.Item:ToBaseItemString(GetSendMailItemLink(i))
			if itemString then
				items[itemString] = (items[itemString] or 0) + select(4, GetSendMailItem(i))
			end
		end
		private:InsertPendingMail(altName, "sent_mail", items, time())
	end

	-- handle returning mail to alts
	local function OnReturnMail(index)
		local sender = strlower(select(3, GetInboxHeaderInfo(index)))
		local altName
		for name in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters) do
			if strlower(name) == sender then
				altName = name
				break
			end
		end
		if not altName then return end
		local items = {}
		for i = 1, ATTACHMENTS_MAX_SEND do
			local itemString = TSMAPI.Item:ToBaseItemString(GetInboxItemLink(index, i))
			if itemString then
				items[itemString] = (items[itemString] or 0) + (select(4, GetInboxItem(index, i)) or 0)
			end
		end
		private:InsertPendingMail(altName, "return_mail", items, time())
	end

	Inventory:UnhookAll()
	Inventory:SecureHook("PlaceAuctionBid", OnAuctionBid)
	Inventory:SecureHook("CancelAuction", OnAuctionCanceled)
	Inventory:SecureHook("SendMail", OnMailSent)
	Inventory:SecureHook("ReturnInboxItem", OnReturnMail)

	local mailScanTime, pendingUpdateTime = -1, -1
	while true do
		local didChange = nil
		-- check if we need to scan the player's mail
		if mailScanTime < private.lastUpdate.mail and private.isOpen.mail then
			private.lastUpdate.pendingMail = GetTime()
			wipe(TSM.db.factionrealm.pendingMail[PLAYER_NAME])
			if private:DoScan("mail") then
				didChange = true
			end
			mailScanTime = GetTime()
		end

		-- if something changed, notify the sync code
		if didChange then
			TSMAPI.Sync:KeyUpdated(TSM.db.factionrealm.inventory, PLAYER_NAME)
		end

		-- check if we need to update the pending mail quantities
		if pendingUpdateTime < private.lastUpdate.pendingMail then
			wipe(private.pendingMailQuantities)
			for player, pendingMailData in pairs(TSM.db.factionrealm.pendingMail) do
				private.pendingMailQuantities[player] = private.pendingMailQuantities[player] or {}
				for _, info in ipairs(pendingMailData) do
					for itemString, quantity in pairs(info.items) do
						private.pendingMailQuantities[player][itemString] = (private.pendingMailQuantities[player][itemString] or 0) + quantity
					end
				end
			end
			pendingUpdateTime = GetTime()
		end
		self:Yield(true)
	end
end




-- ============================================================================
-- Scanning Functions
-- ============================================================================

function private:DoScan(key)
	-- remove data from dataTbl and put it into oldState
	local dataTbl = nil
	if key == "guildVault" then
		dataTbl = private.guildData[PLAYER_GUILD]
	else
		dataTbl = private.playerData[PLAYER_NAME][key]
	end
	TSMAPI:Assert(dataTbl)
	wipe(private.oldState)
	for itemString, quantity in pairs(dataTbl) do
		dataTbl[itemString] = nil
		private.oldState[itemString] = quantity
	end
	TSMAPI:Assert(not next(dataTbl))

	-- do the scanning
	if key == "bag" then
		private:ScanBag(dataTbl)
	elseif key == "bank" then
		private:ScanBank(dataTbl)
	elseif key == "reagentBank" then
		private:ScanReagentBank(dataTbl)
	elseif key == "auction" then
		private:ScanAuction(dataTbl)
	elseif key == "guildVault" then
		private:ScanGuildVault(dataTbl)
	elseif key == "mail" then
		private:ScanMail(dataTbl)
	else
		error("Invalid key: " .. tostring(key))
	end

	-- check if anything changed from the old state
	for itemString, quantity in pairs(dataTbl) do
		if private.oldState[itemString] ~= quantity then
			return true
		end
		private.oldState[itemString] = nil
	end
	return next(private.oldState) and true or false
end

function private:ScanBag(dataTbl)
	if not private.bagIndexList.bag then
		private.bagIndexList.bag = {}
		for bag = 0, NUM_BAG_SLOTS do
			tinsert(private.bagIndexList.bag, bag)
		end
	end
	for _, bag in ipairs(private.bagIndexList.bag) do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			local itemString = TSMAPI.Item:ToBaseItemString(link)
			if itemString then
				dataTbl[itemString] = (dataTbl[itemString] or 0) + select(2, GetContainerItemInfo(bag, slot))
			end
		end
	end
end

function private:ScanBank(dataTbl)
	if not private.bagIndexList.bank then
		private.bagIndexList.bank = { -1 }
		for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
			tinsert(private.bagIndexList.bank, bag)
		end
	end
	for _, bag in ipairs(private.bagIndexList.bank) do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			local itemString = TSMAPI.Item:ToBaseItemString(link)
			if itemString then
				dataTbl[itemString] = (dataTbl[itemString] or 0) + select(2, GetContainerItemInfo(bag, slot))
			end
		end
	end
end

function private:ScanReagentBank(dataTbl)
	for slot = 1, GetContainerNumSlots(REAGENTBANK_CONTAINER) do
		local link = GetContainerItemLink(REAGENTBANK_CONTAINER, slot)
		local itemString = TSMAPI.Item:ToBaseItemString(link)
		if itemString then
			dataTbl[itemString] = (dataTbl[itemString] or 0) + select(2, GetContainerItemInfo(REAGENTBANK_CONTAINER, slot))
		end
	end
end

function private:ScanAuction(dataTbl)
	for i = 1, GetNumAuctionItems("owner") do
		local itemString = TSMAPI.Item:ToBaseItemString(GetAuctionItemLink("owner", i))
		if itemString then
			local _, _, quantity, _, _, _, _, _, _, _, _, bidder = GetAuctionItemInfo("owner", i)
			if not bidder then
				dataTbl[itemString] = (dataTbl[itemString] or 0) + quantity
			end
		end
	end
end

function private:ScanGuildVault(dataTbl)
	for tab = 1, GetNumGuildBankTabs() do
		if select(5, GetGuildBankTabInfo(tab)) > 0 or IsGuildLeader(UnitName("player")) then
			for slot = 1, GUILD_VAULT_SLOTS_PER_TAB do
				local link = GetGuildBankItemLink(tab, slot)
				local itemString = TSMAPI.Item:ToBaseItemString(link)
				if itemString == "i:82800" then
					if not private.petSpeciesCache[link] then
						private.petSpeciesCache[link] = GameTooltip:SetGuildBankItem(tab, slot)
					end
					itemString = private.petSpeciesCache[link] and ("p:" .. private.petSpeciesCache[link])
				end
				if itemString then
					dataTbl[itemString] = (dataTbl[itemString] or 0) + select(2, GetGuildBankItemInfo(tab, slot))
				end
			end
		end
	end
end

function private:ScanMail(dataTbl)
	for i = 1, GetInboxNumItems() do
		local _, _, _, _, _, _, daysLeft, hasItem = GetInboxHeaderInfo(i)
		if hasItem then
			for j = 1, ATTACHMENTS_MAX_RECEIVE do
				local itemString = TSMAPI.Item:ToBaseItemString(GetInboxItemLink(i, j))
				if itemString then
					local quantity = select(4, GetInboxItem(i, j)) or 0
					dataTbl[itemString] = (dataTbl[itemString] or 0) + quantity
				end
			end
		end
	end
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:InsertPendingMail(player, mailType, items, arrivalTime)
	TSM.db.factionrealm.pendingMail[player] = TSM.db.factionrealm.pendingMail[player] or {}
	tinsert(TSM.db.factionrealm.pendingMail[player], { mailType = mailType, items = items, arrivalTime = arrivalTime - 3 })
	private.lastUpdate.pendingMail = GetTime()
end
