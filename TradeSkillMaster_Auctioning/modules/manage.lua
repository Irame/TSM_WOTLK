-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Auctioning - AddOn by Sapu94							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_auctioning.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- This module is to contain things that are common between other modules.
-- Mostly stuff in common between scanning and posting such as the " Auction" Frame


local TSM = select(2, ...)
local Manage = TSM:NewModule("Manage", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table

local totalToScan, totalScanned, pagePercent = 0, 0, 0
local startedManaging, GUI, Util, mode

function Manage:StartScan(GUIRef, options)
	GUI = GUIRef
	mode = GUI.mode
	Util = TSM[mode]
	GUI.OnAction = Manage.OnGUIEvent
	
	totalScanned, totalToScan = 0, 0
	startedManaging = false

	TSM.Log:Clear()
	TSM:UpdateItemReverseLookup()
	TSM:UpdateGroupReverseLookup()
	
	local scanList = Util:GetScanListAndSetup(GUI, options)
	if #(scanList) == 0 then
		GUI:Stopped()
		return
	end
	
	if options and options.noScan then -- no scanning required
		Manage:StartNoScanScan(GUIRef, scanList)
		return
	end
	
	local toRemove = {}
	for i, query in ipairs(scanList) do
		if type(query) == "table" then
			local filter = TSMAPI:GetCommonAuctionQueryInfo(query.items, query.name)
			if filter then
				filter.isCombinedFilter = true
				filter.arg = CopyTable(query.items)
				scanList[i] = filter
				totalToScan = totalToScan + #query.items
			else
				tinsert(toRemove, i)
			end
		elseif type(query) == "number" then
			local filter = TSMAPI:GetAuctionQueryInfo(query)
			if filter then
				filter.isItemIDFilter = true
				filter.arg = query
				scanList[i] = filter
				totalToScan = totalToScan + 1
			else
				tinsert(toRemove, i)
			end
		else
			totalToScan = totalToScan + 1
		end
	end
	
	for i=#toRemove, 1, -1 do
		if type(scanList[toRemove[i]]) == "table" then
			local items = CopyTable(scanList[toRemove[i]].items)
			TSM:Printf(L["Invalid search term for group %s. Searching for items individually instead."], scanList[toRemove[i]].group)
			tremove(scanList, toRemove[i])
			for _, itemString in ipairs(items) do
				tinsert(scanList, itemString)
			end
		else
			TSM:Printf(L["Could not resolve search filters for item %s"], scanList[toRemove[i]])
			tremove(scanList, toRemove[i])
		end
	end
	
	sort(scanList, function(a, b)
			if type(a) == "table" then
				return false
			end
			return type(b) == "table"
		end)
	
	Manage:RegisterMessage("TSMAuc_QUERY_FINISHED", "MessageHandler")
	Manage:RegisterMessage("TSMAuc_NEW_ITEM_DATA", "MessageHandler")
	Manage:RegisterMessage("TSMAuc_SCAN_COMPLETE", "MessageHandler")
	Manage:RegisterMessage("TSMAuc_SCAN_INTERRUPTED", "MessageHandler")
	Manage:RegisterMessage("TSMAuc_SCAN_NEW_PAGE", "MessageHandler")
	Manage:RegisterMessage("TSMAuc_UPDATE_TOTAL_FILTERS", "MessageHandler")
	GUI.statusBar:SetStatusText(L["Scanning"])
	if mode == "Reset" then
		TSMAPI:CancelFrame("updatePostStatus")
		TSMAPI:CancelFrame("updateCancelStatus")
		GUI.statusBar:UpdateStatus(0, 100)
	else
		local delayName = (mode == "Post" and "updatePostStatus") or (mode == "Cancel" and "updateCancelStatus")
		GUI.statusBar:UpdateStatus(nil, 0)
		TSMAPI:CancelFrame("updatePostStatus")
		TSMAPI:CancelFrame("updateCancelStatus")
		TSMAPI:CreateTimeDelay(delayName, 0, function()
				local count, totalManaged, totalToManage = Util:GetStatus()
				local status = floor(TSMAPI:SafeDivide(totalScanned, totalToScan)*TSMAPI:SafeDivide(count, totalToManage)*100)
				if totalToManage == 0 or totalToScan == 0 then status = 0 end
				GUI.statusBar:UpdateStatus(status)
				
				if (totalToScan == totalScanned) then
					statusText = format(L["All Items Scanned"])
				else
					statusText = format(L["Scanning Item %s / %s"], totalScanned, totalToScan)
				end
				statusText = statusText .. " : "
				if mode == "Post" then
					statusText = statusText .. format(L["Posting %s / %s"], totalManaged, totalToManage)
				else
					statusText = statusText .. format(L["Canceling %s / %s"], totalManaged, totalToManage)
				end
				GUI.statusBar:SetStatusText(statusText)
			end, 0.1)
	end
	GUI.infoText:SetInfo(L["Running Scan..."])
	TSM.Scan:StartItemScan(scanList)
end

function Manage:StartNoScanScan(GUIRef, scanList)
	GUI.infoText:SetInfo(L["Processing Items..."])
	totalToScan = #scanList
	GUI.statusBar:UpdateStatus(0)
	TSMAPI:CancelFrame("updateCancelStatus")
	TSMAPI:CreateTimeDelay("updateCancelStatus", 0, function()
				local count, totalManaged, totalToManage = Util:GetStatus()
				local status = floor(TSMAPI:SafeDivide(totalScanned, totalToScan)*TSMAPI:SafeDivide(count, totalToManage)*100)
				if totalToManage == 0 or totalToScan == 0 then status = 0 end
				GUI.statusBar:UpdateStatus(status)
				if totalManaged > 1 or totalToScan == totalScanned then
					GUI.statusBar:SetStatusText(format(L["Canceling %s / %s"], totalManaged, totalToManage))
				end
			end, 0.1)
	GUI.statusBar:SetStatusText(L["Processing Items..."])
	TSMAPI:CancelFrame("auctioningNoScanProcessing")
	TSMAPI:CreateTimeDelay("auctioningNoScanProcessing", 0.1, function() Manage:ProcessNoScanItems(scanList) end, 0.1)
end

function Manage:ProcessNoScanItems(scanList)
	local numItemsToProcess = 10
	local startNum, endNum = totalScanned, min(totalScanned+numItemsToProcess, totalToScan)
	
	for i=startNum, endNum do
		local doUpdate = (i == endNum or i == 1)
		Manage:MessageHandler("TSMAuc_NEW_ITEM_DATA", scanList[i], doUpdate and "doUpdate" or "noUpdate")
	end
	
	if endNum == totalToScan then
		TSMAPI:CancelFrame("auctioningNoScanProcessing")
		Manage:MessageHandler("TSMAuc_SCAN_COMPLETE")
	end
end

function Manage:OnGUIEvent(event)
	if event == "action" then
		Util:DoAction()
	elseif event == "skip" then
		Util:SkipItem()
	elseif event == "stop" then
		TSMAPI:CancelFrame("auctioningNoScanProcessing")
		if not TSMAPI:StopScan() then
			Util:Stop()
		end
	end
	TSMAPI:CreateTimeDelay("aucManageSTUpdate", 0.01, GUI.UpdateAuctionsSTData)
end

function Manage:MessageHandler(msg, arg1, arg2)
	if msg == "TSMAuc_QUERY_FINISHED" or msg == "TSMAuc_NEW_ITEM_DATA" then
		totalScanned = totalScanned + 1
		if mode == "Reset" then
			GUI.statusBar:UpdateStatus(TSMAPI:SafeDivide(totalScanned, totalToScan)*100)
			GUI.statusBar:SetStatusText(format(L["Scanning Item %s / %s"], totalScanned, totalToScan))
		else
			GUI.statusBar:UpdateStatus(nil, TSMAPI:SafeDivide(totalScanned, totalToScan)*100)
		end
		if type(arg1) ~= "table" then
			if not TSM.itemReverseLookup[arg1] then
				arg1 = TSMAPI:GetItemID(arg1)
			end
			Util:ProcessItem(arg1)
		end
		if not arg2 ~= "noUpdate" then
			GUI:UpdateSTData()
		end
	elseif msg == "TSMAuc_SCAN_COMPLETE" then
		local _, _, totalToManage = Util:GetStatus()
		Util:DoneScanning()
		if totalToManage == 0 then
			Util:Stop()
		else
			if TSM.db.global.enableSounds then
				PlaySound("ReadyCheck")
			end
		end
	elseif msg == "TSMAuc_SCAN_INTERRUPTED" then
		Util:Stop(true)
	elseif msg == "TSMAuc_SCAN_NEW_PAGE" then
		if mode == "Reset" then
			GUI.statusBar:UpdateStatus(TSMAPI:SafeDivide(totalScanned+arg1, totalToScan)*100)
		else
			GUI.statusBar:UpdateStatus(nil, TSMAPI:SafeDivide(totalScanned+arg1, totalToScan)*100)
		end
	elseif msg == "TSMAuc_UPDATE_TOTAL_FILTERS" then
		totalToScan = arg1
	end
end

-- updates the GUI info with the current item
function Manage:UpdateGUI()
	if not startedManaging then
		startedManaging = true
		Util:SetupForAction()
	end

	if mode == "Post" then
		ClearCursor()
	end
	
	local currentItem = Util:GetCurrentItem()
	if currentItem and currentItem.itemString then
		GUI.infoText:SetInfo(currentItem)
	end
end

function Manage:SetInfoText(text)
	GUI.infoText:SetInfo(text)
end