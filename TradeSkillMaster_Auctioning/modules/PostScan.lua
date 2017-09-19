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
local Post = TSM:NewModule("Post", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table

local postQueue, currentItem = {}, {}
local totalToPost, totalPosted, count = 0, 0
local isScanning, GUI

function Post:GetScanListAndSetup(GUIRef, options)
	-- setup stuff
	GUI = GUIRef
	isScanning = true
	wipe(postQueue)
	wipe(currentItem)
	totalToPost, totalPosted, count = 0, 0, 0

	local tempList, scanList, groupTemp, validItems = {}, {}, {}, {}
	
	for bag, slot, itemString in TSM:GetBagIterator() do
		local itemID = TSMAPI:GetItemID(itemString)
		if TSM.itemReverseLookup[itemID] then
			itemString = itemID
		end
		local groupName = TSM.itemReverseLookup[itemString]
		if groupName and TSM.Scan:ShouldScan(itemString, "Post", options and options.groups) then
			tempList[itemString] = true
		end
	end
	
	local function IsInvalidNumber(value)
		return not tonumber(tostring(value)) or value == 0
	end
	
	function HasEnoughToPost(item)
		local maxStackSize = select(8, GetItemInfo(item.itemString))
		local numInBags = Post:GetNumInBags(item.itemString)
		local perAuction = min(maxStackSize, item.perAuction)
		local perAuctionIsCap = TSM.Config:GetBoolConfigValue(item.itemString, "perAuctionIsCap")
		
		return numInBags >= perAuction or perAuctionIsCap
	end
	
	for itemString in pairs(tempList) do
		local _, itemLink = GetItemInfo(itemString)
		local item = TSM.Config:GetConfigObject(itemString)
		
		-- don't post this item if their threshold or fallback is 0 or some really big number
		if IsInvalidNumber(item.threshold) then
			TSM:Printf(L["Did not post %s because your threshold (%s) is invalid. Check your settings."], itemLink or itemString, item.threshold)
			TSM.Log:AddLogRecord(itemString, "post", "Skip", "invalid")
		elseif IsInvalidNumber(item.fallback) then
			TSM:Printf(L["Did not post %s because your fallback (%s) is invalid. Check your settings."], itemLink or itemString, item.fallback)
			TSM.Log:AddLogRecord(itemString, "post", "Skip", "invalid")
		elseif item.fallback < item.threshold then
			TSM:Printf(L["Did not post %s because your fallback (%s) is lower than your threshold (%s). Check your settings."], itemLink or itemString, item.fallback, item.threshold)
			TSM.Log:AddLogRecord(itemString, "post", "Skip", "invalid")
		elseif item.threshold == item.fallback then
			TSM:Printf("Did not post %s because your threshold (%s) is equal to your fallback (%s). Raise your fallback by 1c if you intended them to be effectively the same.", itemLink or itemString, item.threshold, item.fallback)
			TSM.Log:AddLogRecord(itemString, "post", "Skip", "invalid")
		elseif not HasEnoughToPost(item) then
			TSM.Log:AddLogRecord(itemString, "post", "Skip", "notEnough")
		else
			local groupName = TSM.itemReverseLookup[itemString]
			local searchTerm = TSM.Config:GetConfigValue(itemString, "searchTerm")
			local name = GetItemInfo(itemString)
			if not TSM.db.profile.itemIDGroups[groupName] and searchTerm and searchTerm ~= "" then
				searchTerm = strlower(searchTerm)
				groupTemp[searchTerm] = groupTemp[searchTerm] or {group=groupName}
				tinsert(groupTemp[searchTerm], itemString)
			end
			validItems[itemString] = true
		end
	end
	
	for searchTerm, items in pairs(groupTemp) do
		tinsert(scanList, {name=searchTerm, items=items, group=items.group})
		for _, itemString in ipairs(items) do
			tempList[itemString] = nil
		end
	end
	
	for itemString in pairs(tempList) do
		if validItems[itemString] then
			tinsert(scanList, itemString)
		end
	end
	
	return scanList
end

function Post:ProcessItem(itemString)
	local item = TSM.Config:GetConfigObject(itemString)
	local toPost, reason = Post:ShouldPost(item)
	local data = {}
	
	if toPost then
		local bid, buyout
		bid, buyout, reason = Post:GetPostPrice(item)
		local postTime = (item.postTime == 48 and 3) or (item.postTime == 24 and 2) or 1
		
		for i=1, #toPost do
			local stackSize, numStacks = unpack(toPost[i])
			
			-- Increase the bid/buyout based on how many items we're posting
			local stackBid, stackBuyout = floor(bid*stackSize), floor(buyout*stackSize)
			Post:QueueItemToPost(item.itemString, numStacks, stackSize, stackBid, stackBuyout, postTime)
			tinsert(data, {numStacks=numStacks, stackSize=stackSize, buyout=buyout, postTime=postTime})
		end
	end
	
	TSM.Log:AddLogRecord(itemString, "post", (toPost and L["Post"] or L["Skip"]), reason, data)
	TSM.Manage:UpdateGUI()
end

function Post:ShouldPost(item)
	local maxStackSize = select(8, GetItemInfo(item.itemString))
	local numInBags = Post:GetNumInBags(item.itemString)
	local perAuction = min(maxStackSize, item.perAuction)
	local maxCanPost = floor(numInBags / perAuction)
	
	local auctionsCreated, activeAuctions = 0, 0
	local perAuctionIsCap = TSM.Config:GetBoolConfigValue(item.itemString, "perAuctionIsCap")
	
	if maxCanPost == 0 then
		if perAuctionIsCap then
			perAuction = numInBags
			maxCanPost = 1
		else
			return nil, "notEnough" -- not enough for single post
		end
	end

	local extraStack
	local buyout, bid, _, isWhitelist, isBlacklist, isPlayer, isInvalidSeller = TSM.Scan:GetLowestAuction(item.auctionItem)
	
	if isInvalidSeller then
		TSM:Printf(L["Seller name of lowest auction for item %s was not returned from server. Skipping this item."], select(2, GetItemInfo(item.itemString)))
		return nil, "invalidSeller"
	end
	
	-- Check if we're going to go below the threshold
	if buyout and item.reset == "none" and not isBlacklist then
		if (buyout - item.undercut) < item.threshold and buyout <= item.threshold then
			return nil, "belowThreshold" -- below threshold
		end
	end
	-- Auto fallback is on, and lowest buyout is below threshold, instead of posting them all
	-- use the post count of the fallback tier
	if item.reset ~= "none" and buyout and buyout <= item.threshold and not isBlacklist then
		local resetBuyout = item.reset == "custom" and item.resetPrice or item[item.reset]
		local resetBid = resetBuyout * item.bidPercent
		activeAuctions = TSM.Scan:GetPlayerAuctionCount(item.itemString, resetBuyout, resetBid)
	elseif isPlayer or isWhitelist then
		if not isPlayer and isWhitelist and not TSM.db.global.matchWhitelist then
			return nil, "notPostingWhitelist"
		end
		-- Either the player or a whitelist person is the lowest teir so use this tiers quantity of items
		activeAuctions = TSM.Scan:GetPlayerAuctionCount(item.itemString, buyout or 0, bid or 0)
	end
	
	-- If we have a post cap of 20, and 10 active auctions, but we can only have 5 of the item then this will only let us create 5 auctions
	-- however, if we have 20 of the item it will let us post another 10
	auctionsCreated = min(item.postCap - activeAuctions, maxCanPost)
	if auctionsCreated <= 0 then
		return nil, "tooManyPosted"
	end
	
	if (auctionsCreated + activeAuctions) < item.postCap then
		-- can post at least one more
		local extra = numInBags % perAuction
		if perAuctionIsCap and extra > 0 then
			extraStack = extra
		end
	end
	
	if Post:FindItemSlot(item.itemString) then
		local posts = {{perAuction, auctionsCreated}}
		if extraStack then
			tinsert(posts, {extraStack, 1})
		end
		return posts, nil
	end
end

function Post:GetPostPrice(item)
	local lowestBuyout, lowestBid, lowestOwner, isWhitelist, isBlacklist, isPlayer = TSM.Scan:GetLowestAuction(item.auctionItem)
	local bid, buyout, differencedPrice, info

	if not lowestOwner then
		-- No other auctions up, default to fallback
		info = "postingFallback"
		buyout = item.fallback
	elseif item.reset ~= "none" and lowestBuyout <= item.threshold and not isBlacklist then
		-- Item goes below the threshold price, default it to the reset method
		info = "postingReset"
		buyout = item.reset == "custom" and item.resetPrice or item[item.reset]
	elseif (isPlayer or isWhitelist) and not differencedPrice then
		-- Either we already have one up or someone on the whitelist does
		bid, buyout =  min(max(lowestBid, item.threshold), lowestBuyout), lowestBuyout
		if isPlayer then
			info = "postingPlayer"
		else
			info = "postingWhitelist"
		end
	else
		-- We got undercut :(
		local goldTotal = lowestBuyout / COPPER_PER_GOLD
		-- Smart undercutting is enabled, and the auction is for at least 1 gold, round it down to the nearest gold piece
		-- the floor(blah) == blah check is so we only do a smart undercut if the price isn't a whole gold piece and not a partial
		if TSM.db.global.smartUndercut and lowestBuyout > COPPER_PER_GOLD and goldTotal ~= floor(goldTotal) then
			buyout = floor(goldTotal) * COPPER_PER_GOLD
		else
			buyout = lowestBuyout - item.undercut
		end
		
		-- Check if we're posting something too high
		if buyout > (item.fallback * item.fallbackCap) then
			info = "postingFallback"
			buyout = item.fallback
		end
		
		-- Check if we're posting too low!
		if buyout < item.threshold and not isBlacklist then
			buyout = item.threshold
		end
		

		-- Check if the bid is too low
		bid = buyout * item.bidPercent
		if bid < item.threshold and not isBlacklist then
			bid = item.threshold
		end
		info = info or "postingUndercut"
	end
	
	-- unless there's a special bid, set the bid to the buyout * the bid percent
	return (bid or buyout*item.bidPercent), buyout, info
end

function Post:QueueItemToPost(itemString, numStacks, stackSize, bid, buyout, postTime)	
	local itemID = TSMAPI:GetItemID(itemString)
	local itemLocations = {}
	if TSMAPI:GetNewGem(itemID) then -- if it's a gem with multiple itemIDs, we need to do something special
		for _, oldGemID in ipairs(TSMAPI:GetOldGems(itemID)) do
			local locations = Post:FindItemSlot(TSMAPI:GetItemString(oldGemID), true)
			for i=1, #locations do
				tinsert(itemLocations, locations[i])
			end
		end
	else
		itemLocations = Post:FindItemSlot(itemString, true)
	end

	for i=1, numStacks do
		local oBag, oSlot
		for j=1, #itemLocations do
			if itemLocations[j].quantity >= stackSize then
				oBag, oSlot = itemLocations[j].bag, itemLocations[j].slot
				itemLocations[j].quantity = itemLocations[j].quantity - stackSize
				break
			end
		end
		if not oBag or not oSlot then
			oBag, oSlot = Post:FindItemSlot(itemString)
			if not (oBag and oSlot) then break end
		end
		tinsert(postQueue, {bag=oBag, slot=oSlot, bid=bid, buyout=buyout, postTime=postTime, stackSize=stackSize, numStacks=(numStacks-i+1), itemString=itemString})
		totalToPost = totalToPost + 1
	end
end

function Post:FindItemSlot(findItemString, allLocations, ignoreBagSlot)
	local locations = {}
	for bag, slot, itemString in TSM:GetBagIterator() do
		local quantity = select(2, GetContainerItemInfo(bag, slot))
		if findItemString == TSMAPI:GetItemID(itemString) or findItemString == itemString then
			if not TSM.Util:IsSoulbound(bag, slot) and not (ignoreBagSlot and ignoreBagSlot[bag.."$"..slot]) then
				tinsert(locations, {bag=bag, slot=slot, quantity=quantity})
				if not allLocations then
					return bag, slot
				end
			end
		end
	end
	return allLocations and locations
end

function Post:GetNumInBags(itemString)
	local function GetItemBagCount(findItemString)
		local num = 0
		for bag, slot, itemString in TSM:GetBagIterator() do
			if findItemString == TSMAPI:GetItemID(itemString) or findItemString == itemString then
				if not TSM.Util:IsSoulbound(bag, slot) then
					num = num + select(2, GetContainerItemInfo(bag, slot))
				end
			end
		end
		return num
	end

	local oldGems = TSMAPI:GetOldGems(TSMAPI:GetItemID(itemString))
	if oldGems then
		local num = 0
		for _, gemItemID in ipairs(oldGems) do
			local gemItemString = TSMAPI:GetItemString(gemItemID)
			num = num + GetItemBagCount(gemItemString)
		end
		return num
	else
		return GetItemBagCount(itemString)
	end
end

function Post:SetupForAction()
	Post:RegisterEvent("CHAT_MSG_SYSTEM")
	Post:UpdateItem()
end

local timeout = CreateFrame("Frame")
timeout:Hide()
timeout:SetScript("OnUpdate", function(self, elapsed)
		self.timeLeft = self.timeLeft - elapsed
		if self.timeLeft <= 0 or (not select(3, GetContainerItemInfo(postQueue[1].bag, postQueue[1].slot)) and 0 == AuctionsCreateAuctionButton:IsEnabled()) then
			tremove(postQueue, 1)
			Post:UpdateItem()
		end
	end)

-- Check if an auction was posted and move on if so
function Post:CHAT_MSG_SYSTEM(_, msg)
	if msg == ERR_AUCTION_STARTED then
		count = count + 1
	end
end

local countFrame = CreateFrame("Frame")
countFrame:Hide()
countFrame.count = -1
countFrame.timeLeft = 10
countFrame:SetScript("OnUpdate", function(self, elapsed)
		self.timeLeft = self.timeLeft - elapsed
		if count >= totalToPost or self.timeLeft <= 0 then
			self:Hide()
			Post:Stop()
		elseif count ~= self.count then
			self.count = count
			self.timeLeft = (totalToPost - count) * 2
		end
	end)
	
local function DelayFrame()
	if not isScanning and #(postQueue) == 0 then
		Post:Stop()
		TSMAPI:CancelFrame("postDelayFrame")
	elseif #(postQueue) > 0 then
		Post:UpdateItem()
		TSMAPI:CancelFrame("postDelayFrame")
	end
end

function Post:UpdateItem()
	timeout:Hide()
	if #(postQueue) == 0 then
		GUI.buttons:Disable()
		if isScanning then
			TSMAPI:CreateFunctionRepeat("postDelayFrame", DelayFrame)
		else
			countFrame:Show()
		end
		return
	end

	totalPosted = totalPosted + 1
	wipe(currentItem)
	currentItem = CopyTable(postQueue[1])
	TSM.Manage:UpdateGUI()
	GUI.buttons:Enable()
end

function Post:DoAction()
	timeout.timeLeft = 5
	timeout:Show()
	if not AuctionFrameAuctions.duration then
		-- Fix in case Blizzard_AuctionUI hasn't set this value yet (which could cause an error)
		AuctionFrameAuctions.duration = 2
	end
	
	local containerItemLink = GetContainerItemLink(currentItem.bag, currentItem.slot)
	if TSMAPI:GetItemID(containerItemLink) ~= currentItem.itemString and TSMAPI:GetItemString(containerItemLink) ~= currentItem.itemString then
		TSM:Print(L["Please don't move items around in your bags while a post scan is running! The item was skipped to avoid an incorrect item being posted."])
		timeout:Hide()
		Post:SkipItem()
		return
	end
	
	PickupContainerItem(currentItem.bag, currentItem.slot)
	ClickAuctionSellItemButton(AuctionsItemButton, "LeftButton")
	StartAuction(currentItem.bid, currentItem.buyout, currentItem.postTime, currentItem.stackSize, 1)
	GUI.buttons:Disable()
end

function Post:SkipItem()
	local toSkip = {}
	local skipped = tremove(postQueue, 1)
	count = count + 1
	for i, item in ipairs(postQueue) do
		if item.itemString == skipped.itemString and item.bid == skipped.bid and item.buyout == skipped.buyout then
			tinsert(toSkip, i)
		end
	end
	sort(toSkip, function(a, b) return a > b end)
	for _, index in ipairs(toSkip) do
		tremove(postQueue, index)
		count = count + 1
		totalPosted = totalPosted + 1
	end
	Post:UpdateItem()
end

function Post:Stop()
	GUI:Stopped()
	TSMAPI:CancelFrame("postDelayFrame")
	TSMAPI:CancelFrame("updatePostStatus")
	
	Post:UnregisterAllEvents()
	Post:UnregisterAllMessages()
	
	wipe(currentItem)
	totalToPost, totalPosted = 0, 0
	isScanning = false
end

function Post:GetAHGoldTotal()
	local total = 0
	local incomingTotal = 0
	for i=1, GetNumAuctionItems("owner") do
		local count, _, _, _, _, _, buyoutAmount = select(3, GetAuctionItemInfo("owner", i))
		total = total + buyoutAmount
		if count == 0 then
			incomingTotal = incomingTotal + buyoutAmount
		end
	end
	return TSMAPI:FormatTextMoneyIcon(total), TSMAPI:FormatTextMoneyIcon(incomingTotal)
end

function Post:GetStatus()
	return count, totalPosted, totalToPost
end

function Post:GetCurrentItem()
	return currentItem
end

function Post:EditPostPrice(itemString, buyout)
	local bid = TSM.Config:GetConfigValue(itemString, "bidPercent") * buyout
	
	if currentItem.itemString == itemString then
		currentItem.buyout = buyout
		currentItem.bid = bid
	end
	
	for _, data in ipairs(postQueue) do
		if data.itemString == itemString then
			data.buyout = buyout
			data.bid = bid
		end
	end
end

function Post:DoneScanning()
	isScanning = false
end