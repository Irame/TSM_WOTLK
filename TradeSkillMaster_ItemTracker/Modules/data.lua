-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_ItemTracker.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Data = TSM:NewModule("Data", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ItemTracker")

local CURRENT_PLAYER, CURRENT_GUILD = UnitName("player"), GetGuildInfo("player")
local BUCKET_TIME = 0.2 -- wait at least this amount of time between throttled events firing
local throttleFrames = {}
local isScanning = false

function Data:Initialize()
	Data:RegisterEvent("BAG_UPDATE", "EventHandler")
	Data:RegisterEvent("BANKFRAME_OPENED", "EventHandler")
	Data:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "EventHandler")
	Data:RegisterEvent("GUILDBANKFRAME_OPENED", "EventHandler")
	Data:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED", "EventHandler")
	Data:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", "EventHandler")
	
	TSMAPI:RegisterData("playerlist", Data.GetPlayers)
	TSMAPI:RegisterData("guildlist", Data.GetGuilds)
	TSMAPI:RegisterData("playerbags", Data.GetPlayerBags)
	TSMAPI:RegisterData("playerbank", Data.GetPlayerBank)
	TSMAPI:RegisterData("guildbank", Data.GetGuildBank)
	TSMAPI:RegisterData("playerauctions", Data.GetPlayerAuctions)
	TSMAPI:RegisterData("totalplayerauctions", Data.GetAuctionsTotal)
	TSMAPI:RegisterData("playertotal", Data.GetPlayerTotal)
	TSMAPI:RegisterData("guildtotal", Data.GetGuildTotal)
	
	CURRENT_PLAYER, CURRENT_GUILD = UnitName("player"), GetGuildInfo("player")
	Data:StoreCurrentGuildInfo()
end

local guildThrottle = CreateFrame("frame")
guildThrottle:Hide()
guildThrottle.attemptsLeft = 20
guildThrottle:SetScript("OnUpdate", function(self, elapsed)
		self.timeLeft = self.timeLeft - elapsed
		if self.timeLeft <= 0 then
			self.attemptsLeft = self.attemptsLeft - 1
			Data:StoreCurrentGuildInfo(self.attemptsLeft == 0)
		end
	end)

function Data:StoreCurrentGuildInfo(noDelay)
	CURRENT_GUILD = GetGuildInfo("player")
	if CURRENT_GUILD then
		TSM.guilds[CURRENT_GUILD] = TSM.guilds[CURRENT_GUILD] or {items={}, characters={[CURRENT_PLAYER]=true}}
		TSM.guilds[CURRENT_GUILD].characters = TSM.guilds[CURRENT_GUILD].characters or {}
		TSM.guilds[CURRENT_GUILD].items = TSM.guilds[CURRENT_GUILD].items or {}
		if not TSM.guilds[CURRENT_GUILD].characters[CURRENT_PLAYER] then
			TSM.guilds[CURRENT_GUILD].characters[CURRENT_PLAYER] = true
		end
		for guildName, data in pairs(TSM.guilds) do
			data.characters = data.characters or {}
			if guildName ~= CURRENT_GUILD and data.characters[CURRENT_PLAYER] then
				data.characters[CURRENT_PLAYER] = nil
			end
		end
		guildThrottle:Hide()
	elseif not noDelay then
		guildThrottle.timeLeft = 0.5
		guildThrottle:Show()
	else
		guildThrottle:Hide()
	end
	TSM.characters[CURRENT_PLAYER].guild = CURRENT_GUILD
end

function Data:ThrottleEvent(event)
	if not throttleFrames[event] then
		local frame = CreateFrame("Frame")
		frame.baseTime = BUCKET_TIME
		frame.event = event
		frame:Hide()
		frame:SetScript("OnShow", function(self) Data:UnregisterEvent(self.event) self.timeLeft = self.baseTime end)
		frame:SetScript("OnUpdate", function(self, elapsed)
				self.timeLeft = self.timeLeft - elapsed
				if self.timeLeft <= 0 then
					Data:EventHandler(self.event, "FIRE")
					self:Hide()
					Data:RegisterEvent(self.event, "EventHandler")
				end
			end)
		throttleFrames[event] = frame
	end
	
	-- resets the delay time on the frame
	throttleFrames[event]:Hide()
	throttleFrames[event]:Show()
end

function Data:EventHandler(event, fire)
	if isScanning then return end
	if fire ~= "FIRE" then
		Data:ThrottleEvent(event)
	else
		if event == "BAG_UPDATE" then
			Data:GetBagData()
		elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "BANKFRAME_OPENED" then
			Data:GetBankData()
		elseif event == "GUILDBANKFRAME_OPENED" then
			-- Query all tabs of the gbank to ensure all tabs will be scanned.
			local initialTab = GetCurrentGuildBankTab()
			for tab=1, GetNumGuildBankTabs() do
				if select(5, GetGuildBankTabInfo(tab)) > 0 or IsGuildLeader(UnitName("player")) then
					QueryGuildBankTab(tab)
				end
			end
			QueryGuildBankTab(initialTab)
		elseif event == "GUILDBANKBAGSLOTS_CHANGED" then
			Data:GetGuildBankData()
		elseif event == "AUCTION_OWNED_LIST_UPDATE" then
			Data:ScanPlayerAuctions()
		end
	end
end

-- scan the player's bags
function Data:GetBagData()
	wipe(TSM.characters[CURRENT_PLAYER].bags)
	for bag=0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bag) do
			local itemID = TSMAPI:GetItemID(GetContainerItemLink(bag, slot))
			if itemID and not TSM:IsSoulbound(bag, slot, itemID) then
				local quantity = select(2, GetContainerItemInfo(bag, slot))
				TSM.characters[CURRENT_PLAYER].bags[itemID] = (TSM.characters[CURRENT_PLAYER].bags[itemID] or 0) + quantity
			end
		end
	end
end

-- scan the player's bank
function Data:GetBankData()
	local locationList = {}
	wipe(TSM.characters[CURRENT_PLAYER].bank)
	
	local function ScanBankBag(bag)
		for slot=1, GetContainerNumSlots(bag) do
			local itemID = TSMAPI:GetItemID(GetContainerItemLink(bag, slot))
			if itemID and not TSM:IsSoulbound(bag, slot, itemID) then
				locationList[itemID] = locationList[itemID] or {}
				local quantity = select(2, GetContainerItemInfo(bag, slot))
				TSM.characters[CURRENT_PLAYER].bank[itemID] = (TSM.characters[CURRENT_PLAYER].bank[itemID] or 0) + quantity
				tinsert(locationList[itemID], {bag=bag, slot=slot, quantity=quantity})
			end
		end
	end
	
	for bag=NUM_BAG_SLOTS+1, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
		ScanBankBag(bag)
	end
	ScanBankBag(-1)
	
	Data:SendMessage("TSMBANK", locationList)
end

local gFrame = CreateFrame("Frame")
gFrame:Hide()
gFrame.timeLeft = 0.5
gFrame:SetScript("OnUpdate", function(self, elapsed)
	self.timeLeft = self.timeLeft - elapsed
	if self.timeLeft <= 0 then
		self.timeLeft = 0.5
		self:Hide()
		Data:SendMessage("TSMGUILDBANK", CopyTable(self.locationList))
	end
end)

-- scan the guild bank
function Data:GetGuildBankData()
	if not CURRENT_GUILD then
		Data:StoreCurrentGuildInfo(true)
		if not CURRENT_GUILD then return end
	end
	wipe(TSM.guilds[CURRENT_GUILD].items)
	
	local locationList = {}
	for tab=1, GetNumGuildBankTabs() do
		if select(5, GetGuildBankTabInfo(tab)) > 0 or IsGuildLeader(UnitName("player")) then
			for slot=1, MAX_GUILDBANK_SLOTS_PER_TAB or 98 do
				local itemID = TSMAPI:GetItemID(GetGuildBankItemLink(tab, slot))
				if itemID then
					locationList[itemID] = locationList[itemID] or {}
					local quantity = select(2, GetGuildBankItemInfo(tab, slot))
					TSM.guilds[CURRENT_GUILD].items[itemID] = (TSM.guilds[CURRENT_GUILD].items[itemID] or 0) + quantity
					tinsert(locationList[itemID], {tab=tab, slot=slot, quantity=quantity})
				end
			end
		end
	end
	
	gFrame:Show()
	gFrame.locationList = locationList
end

function Data:ScanPlayerAuctions()
	wipe(TSM.characters[CURRENT_PLAYER].auctions)
	TSM.characters[CURRENT_PLAYER].auctions.time = time()
	
	for i=1, GetNumAuctionItems("owner") do
		local itemID = TSMAPI:GetItemID(GetAuctionItemLink("owner", i))
		local _, _, quantity, _, _, _, _, _, _, _, _, _, wasSold = GetAuctionItemInfo("owner", i)
		if wasSold == 0 and itemID then
			TSM.characters[CURRENT_PLAYER].auctions[itemID] = (TSM.characters[CURRENT_PLAYER].auctions[itemID] or 0) + quantity
		end
	end
end




-- functions for getting data through TSMAPI:GetData()

function Data:GetPlayers()
	local temp = {}
	for name in pairs(TSM.characters) do
		tinsert(temp, name)
	end
	return temp
end

function Data:GetGuilds()
	local temp = {}
	for name in pairs(TSM.guilds) do
		tinsert(temp, name)
	end
	return temp
end

function Data:GetPlayerBags(player)
	player = player or CURRENT_PLAYER
	if not player or not TSM.characters[player] then return end
	
	return TSM.characters[player].bags
end

function Data:GetPlayerBank(player)
	player = player or CURRENT_PLAYER
	if not player or not TSM.characters[player] then return end
	
	return TSM.characters[player].bank
end

function Data:GetGuildBank(guild)
	guild = guild or CURRENT_GUILD
	if not guild or not TSM.guilds[guild] then return end
	
	return TSM.guilds[guild].items
end

function Data:GetPlayerAuctions(player)
	player = player or CURRENT_PLAYER
	if not TSM.characters[player] then return end
	
	TSM.characters[player].auctions = TSM.characters[player].auctions or {}
	local lastScanTime = TSM.characters[player].auctions.time or 0
	
	if (time() - lastScanTime) < (48*60*60) then
		return TSM.characters[player].auctions
	end -- make sure the data isn't old
end

function Data:GetPlayerTotal(itemID)
	local playerTotal, altTotal = 0, 0
	
	for name, data in pairs(TSM.characters) do
		if name == CURRENT_PLAYER then
			playerTotal = playerTotal + (data.bags[itemID] or 0)
			playerTotal = playerTotal + (data.bank[itemID] or 0)
		else
			altTotal = altTotal + (data.bags[itemID] or 0)
			altTotal = altTotal + (data.bank[itemID] or 0)
		end
	end
	
	return playerTotal, altTotal
end

function Data:GetGuildTotal(itemID)
	local guildTotal = 0
	for _, data in pairs(TSM.guilds) do
		guildTotal = guildTotal + (data.items[itemID] or 0)
	end
	
	return guildTotal
end

function Data:GetAuctionsTotal(itemID)
	local auctionsTotal = 0
	for _, data in pairs(TSM.characters) do
		auctionsTotal = auctionsTotal + (data.auctions[itemID] or 0)
	end
	
	return auctionsTotal
end