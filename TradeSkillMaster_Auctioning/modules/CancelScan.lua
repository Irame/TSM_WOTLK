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
local Cancel = TSM:NewModule("Cancel", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table

local cancelQueue, currentItem, tempIndexList, itemsToCancel = {}, {}, {}, {}
local totalToCancel, totalCanceled, count = 0, 0, 0
local isScanning, GUI, cancelError, isCancelAll

function Cancel:GetScanListAndSetup(GUIRef, options)
	-- setup stuff
	GUI = GUIRef
	options = options or {}
	isScanning = true
	isCancelAll = options.cancelAll or options.cancelDuration or options.cancelFilter
	cancelError = nil
	wipe(cancelQueue)
	wipe(currentItem)
	wipe(itemsToCancel)
	totalToCancel, totalCanceled, count = 0, 0, 0
	
	local tempList, scanList, groupTemp = {}, {}, {}
	
	if options.cancelAll then
		for i=GetNumAuctionItems("owner"), 1, -1 do
			if select(13, GetAuctionItemInfo("owner", i)) == 0 and (not TSM.db.global.cancelWithBid or select(10, GetAuctionItemInfo("owner", i)) == 0) then
				local itemString = TSMAPI:GetItemString(GetAuctionItemLink("owner", i))
				itemsToCancel[itemString] = true
				tempList[itemString] = true
			end
		end
	elseif options.cancelDuration then
		for i=GetNumAuctionItems("owner"), 1, -1 do
			if select(13, GetAuctionItemInfo("owner", i)) == 0 and (not TSM.db.global.cancelWithBid or select(10, GetAuctionItemInfo("owner", i)) == 0) then
				local timeLeft = GetAuctionItemTimeLeft("owner", i)
				if timeLeft <= TSM.db.global.lowDuration then
					local itemString = TSMAPI:GetItemString(GetAuctionItemLink("owner", i))
					itemsToCancel[itemString] = true
					tempList[itemString] = true
				end
			end
		end
		isCancelAll = TSM.db.global.lowDuration
	elseif options.cancelFilter then
		for i=GetNumAuctionItems("owner"), 1, -1 do
			if select(13, GetAuctionItemInfo("owner", i)) == 0 and (not TSM.db.global.cancelWithBid or select(10, GetAuctionItemInfo("owner", i)) == 0) then
				local itemName = GetAuctionItemInfo("owner", i)
				if strfind(strlower(itemName), strlower(options.cancelFilter)) then
					local itemString = TSMAPI:GetItemString(GetAuctionItemLink("owner", i))
					itemsToCancel[itemString] = true
					tempList[itemString] = true
				end
			end
		end
	else
		-- Add a scan based on items in the AH that match
		for i=GetNumAuctionItems("owner"), 1, -1 do
			if select(13, GetAuctionItemInfo("owner", i)) == 0 then
				local itemString = TSMAPI:GetItemString(GetAuctionItemLink("owner", i))
				local itemID = TSMAPI:GetItemID(itemString)
				if TSM.itemReverseLookup[itemID] then
					itemString = itemID
				end
				local groupName = TSM.itemReverseLookup[itemString]
				if groupName and not tempList[itemString] and TSM.Scan:ShouldScan(itemString, "Cancel", options.groups) then
					local searchTerm = TSM.Config:GetConfigValue(itemString, "searchTerm")
					if not TSM.db.profile.itemIDGroups[groupName] and searchTerm and searchTerm ~= "" then
						searchTerm = strlower(searchTerm)
						groupTemp[searchTerm] = groupTemp[searchTerm] or {group=groupName}
						tinsert(groupTemp[searchTerm], itemString)
					end
					tempList[itemString] = true
				end
			end
		end
		
		for searchTerm, items in pairs(groupTemp) do
			tinsert(scanList, {name=searchTerm, items=items, group=items.group})
			for _, itemString in ipairs(items) do
				tempList[itemString] = nil
			end
		end
	end
	
	for itemString in pairs(tempList) do
		tinsert(scanList, itemString)
	end
	
	return scanList
end

function Cancel:ProcessItem(itemString, noLog)
	local toCancel, reasonToCancel, reasonNotToCancel
	for i=GetNumAuctionItems("owner"), 1, -1 do
		local link = GetAuctionItemLink("owner", i)
		if itemString == TSMAPI:GetItemString(link) or itemString == TSMAPI:GetItemID(link) then
			local shouldCancel, reason = Cancel:ShouldCancel(i)
			if shouldCancel then
				toCancel = true
				reasonToCancel = reason
				totalToCancel = totalToCancel + 1
				tinsert(cancelQueue, shouldCancel)
			else
				reasonNotToCancel = reasonNotToCancel or reason
			end
		end
	end
	
	if not noLog then
		if toCancel then
			TSM.Log:AddLogRecord(itemString, "cancel", "Cancel", reasonToCancel)
		elseif reasonNotToCancel then
			TSM.Log:AddLogRecord(itemString, "cancel", "Skip", reasonNotToCancel)
		end
	end
	
	if #cancelQueue > 0 then
		TSM.Manage:UpdateGUI()
	end
end

function Cancel:ShouldCancel(index)
	local _, _, quantity, _, _, _, bid, _, buyout, activeBid, _, _, wasSold = GetAuctionItemInfo("owner", index)     
	local buyoutPerItem = floor(buyout / quantity)
	local bidPerItem = floor(bid / quantity)
	
	local itemString = TSMAPI:GetItemString(GetAuctionItemLink("owner", index))
	local itemID = TSMAPI:GetItemID(itemString)
	if TSM.itemReverseLookup[itemID] then
		itemString = itemID
	end
	local cancelData = {itemString=itemString, stackSize=quantity, buyout=buyout, bid=bid, index=index, numStacks=1}
	
	if isCancelAll then
		if type(isCancelAll) ~= "number" or GetAuctionItemTimeLeft("owner", index) <= isCancelAll then
			return cancelData, "cancelAll"
		else
			return false, "cancelAll"
		end
	end
	
	local item = TSM.Config:GetConfigObject(itemString)
	local lowestBuyout, lowestBid, lowestOwner, isWhitelist, _, isPlayer, isInvalidSeller = TSM.Scan:GetLowestAuction(item.auctionItem)
	local secondLowest = TSM.Scan:GetSecondLowest(itemString, lowestBuyout)
	
	if wasSold == 1 or not lowestOwner then
		-- if this auction was sold or we don't have any data on it then this request is invalid
		return
	elseif isInvalidSeller or not lowestBuyout then
		if isInvalidSeller then
			TSM:Printf(L["Seller name of lowest auction for item %s was not returned from server. Skipping this item."], GetAuctionItemLink("owner", index))
		else
			TSM:Printf(L["Invalid scan data for item %s. Skipping this item."], GetAuctionItemLink("owner", index))
		end
		return false, "invalidSeller"
	end
	
	if not TSM.db.global.cancelWithBid and activeBid > 0 then
		-- Don't cancel an auction if it has a bid and we're set to not cancel those
		return false, "bid"
	end
	
	
	if item.reset ~= "none" and lowestBuyout < item.threshold then
		-- item is below threshold so it was posted according to reset method
		local resetBuyout
		local resolution
		if item.reset == "custom" then
			resolution = 0
			resetBuyout = item.resetPrice
		else
			resolution = item.resetResolutionPercent/100
			resetBuyout = item[item.reset]
		end
		if resetBuyout and (abs(resetBuyout - buyoutPerItem) / buyoutPerItem) <= resolution then
			-- we are at the reset price so don't cancel
			return false, "atReset"
		else
			-- we should cancel to repost this item at the reset price
			return cancelData, "reset"
		end
	elseif not (TSM.db.global.smartCancel and lowestBuyout <= item.threshold and not item.auctionItem:IsPlayerOnly()) and (buyoutPerItem - item.undercut) > (TSM.Scan:GetPlayerLowestBuyout(item.auctionItem) or math.huge) then
		-- we should cancel and this isn't the player's lowest auction
		return cancelData, "notLowest"
	elseif (item.auctionItem:IsPlayerOnly() or (isPlayer and secondLowest and secondLowest > (item.fallback * item.fallbackCap))) and abs(item.fallback - buyoutPerItem) < quantity then
		-- we are posted at fallback with no competition under our max price
		return false, "atFallback"
	elseif TSM.db.global.repostCancel and isPlayer and ((secondLowest and secondLowest > (lowestBuyout + item.undercut)) or (not secondLowest and abs(item.fallback - buyoutPerItem) > quantity)) then
		-- Lowest is the player and the percent difference between the players lowest and the second lowest is too large so cancel to repost higher
		if floor(lowestBuyout) == floor(buyoutPerItem) and item.undercut ~= 0 then
			-- The item that the difference is too high is actually on the tier that was too high as well
			-- so cancel it, the reason this check is done here is so it doesn't think it undercut itself.
			return cancelData, "repost"
		end
	elseif TSM.db.global.smartCancel and lowestBuyout <= item.threshold and not item.auctionItem:IsPlayerOnly() then
		-- we can't repost at all so don't bother canceling
		return false, "belowThreshold"
	elseif not (isPlayer or isWhitelist) then
		-- they aren't us (The player posting) or on our whitelist and they undercut us
		return cancelData, "undercut"
	elseif (not isPlayer and isWhitelist) and (buyoutPerItem > lowestBuyout or (buyoutPerItem == lowestBuyout and lowestBid < bidPerItem)) then
		-- they are on our white list, but they undercut us or their bid is lower
		return cancelData, "whitelistUndercut"
	end
	
	return false, "notUndercut"
end

-- register events and queue up the first item to cancel
function Cancel:SetupForAction()
	Cancel:RegisterEvent("CHAT_MSG_SYSTEM")
	Cancel:RegisterEvent("UI_ERROR_MESSAGE")
	Cancel:UpdateItem()
end

-- Check if an auction was canceled and move on if so
function Cancel:CHAT_MSG_SYSTEM(_, msg)
	if msg == ERR_AUCTION_REMOVED then
		count = count + 1
	end
end

-- "Item Not Found" error
function Cancel:UI_ERROR_MESSAGE(event, msg)
	if msg == ERR_ITEM_NOT_FOUND then
		cancelError = true
		count = count + 1
	end
end

local function CountFrame()
	if count == totalToCancel then
		TSMAPI:CancelFrame("cancelCountFrame")
		Cancel:Stop()
	end
end

local function DelayFrame()
	if not isScanning and #(cancelQueue) == 0 then
		TSMAPI:CreateFunctionRepeat("cancelCountFrame", CountFrame)
		TSMAPI:CancelFrame("cancelDelayFrame")
	elseif #(cancelQueue) > 0 then
		Cancel:UpdateItem()
		TSMAPI:CancelFrame("cancelDelayFrame")
	end
end

-- updates the current item to the first one in the list
function Cancel:UpdateItem()
	if #(cancelQueue) == 0 then
		GUI.buttons:Disable()
		if isScanning then
			TSMAPI:CreateFunctionRepeat("cancelDelayFrame", DelayFrame)
		else
			TSMAPI:CreateFunctionRepeat("cancelCountFrame", CountFrame)
		end
		return
	end
	
	sort(cancelQueue, function(a, b) return (a.index or 0)>(b.index or 0) end)

	totalCanceled = totalCanceled + 1
	wipe(currentItem)
	currentItem = cancelQueue[1]
	TSM.Manage:UpdateGUI()
	GUI.buttons:Enable()
end

-- cancel the current item (gets called when the button is pressed
function Cancel:DoAction()
	local index, backupIndex
	-- make sure the currentItem is accurate
	if cancelQueue[1].itemString ~= currentItem.itemString then
		Cancel:UpdateItem()
	end
	
	-- figure out which index the item goes to
	for i=GetNumAuctionItems("owner"), 1, -1 do
		local _, _, quantity, _, _, _, bid, _, buyout, activeBid = GetAuctionItemInfo("owner", i)
		local itemString = TSMAPI:GetItemString(GetAuctionItemLink("owner", i))
		if type(currentItem.itemString) == "number" then
			itemString = TSMAPI:GetItemID(itemString)
		end
		if itemString == currentItem.itemString and abs((buyout or 0) - (currentItem.buyout or 0)) < quantity and abs((bid or 0) - (currentItem.bid or 0)) < quantity and (not TSM.db.global.cancelWithBid and activeBid == 0 or TSM.db.global.cancelWithBid) then
			if not tempIndexList[itemString..buyout..bid..i] then
				tempIndexList[itemString..buyout..bid..i] = true
				index = i
				break
			else
				backupIndex = i
			end
		end
	end
	
	-- if we found an index then cancel the item
	if index then
		CancelAuction(index)
	elseif backupIndex then
		CancelAuction(backupIndex)
	end
	
	-- disable the button and move onto the next item
	GUI.buttons:Disable()
	tremove(cancelQueue, 1)
	Cancel:UpdateItem()
end

-- gets called when the "Skip Item" button is pressed
function Cancel:SkipItem()
	tremove(cancelQueue, 1)
	count = count + 1
	Cancel:UpdateItem()
end

-- we are done canceling (maybe)
function Cancel:Stop(interrupted)
	wipe(tempIndexList)
	if not cancelError or interrupted then
		-- didn't get "item not found" for any cancels or we were interrupted so we are done
		TSMAPI:CancelFrame("cancelCountFrame")
		TSMAPI:CancelFrame("cancelDelayFrame")
		TSMAPI:CancelFrame("updateCancelStatus")
		GUI:Stopped()
	
		Cancel:UnregisterAllEvents()
		Cancel:UnregisterAllMessages()
		wipe(currentItem)
		totalToCancel, totalCanceled = 0, 0
		isScanning = false
	else -- got an "item not found" so requeue ones that we missed
		count = totalToCancel
		cancelError = nil
		local tempList = {}
		for i=GetNumAuctionItems("owner"), 1, -1 do
			local itemString = TSMAPI:GetItemString(GetAuctionItemLink("owner", i))
			local itemID = TSMAPI:GetItemID(itemString)
			if not isCancelAll and TSM.itemReverseLookup[itemID] then
				itemString = itemID
			end
			if not tempList[itemString] then
				if not isCancelAll or itemsToCancel[itemString] then
					Cancel:ProcessItem(itemString, true)
				end
				tempList[itemString] = true
			end
		end
		isScanning = false
		Cancel:UpdateItem()
	end
end

function Cancel:GetStatus()
	return count, totalCanceled, totalToCancel
end

function Cancel:GetCurrentItem()
	return currentItem
end

function Cancel:DoneScanning()
	isScanning = false
end