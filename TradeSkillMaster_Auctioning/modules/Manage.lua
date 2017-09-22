-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Auctioning                          --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctioning          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file is to contain things that are common between different scan types.

local TSM = select(2, ...)
local Manage = TSM:NewModule("Manage", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
local private = {mode=nil, scanStatus={}, currentItem=nil}

function Manage:StartScan(options, mode, isGroup)
	private.mode = mode
	private.currentItem = nil
	wipe(private.scanStatus)
	
	local scanStarted = false
	if mode == "Post" then
		scanStarted = TSM.Post:StartScan(isGroup, options)
	elseif mode == "Cancel" then
		scanStarted = TSM.Cancel:StartScan(isGroup, options)
	elseif mode == "Reset" then
		scanStarted = TSM.Reset:StartScan(options)
	end
	if scanStarted then
		TSM.GUI:SetStatusBar(L["Starting Scan..."], 0, 0)
		TSM.GUI:SetInfo(L["Running Scan..."])
	else
		TSM.GUI:Stopped()
	end
end

-- these functions help display the status text which goes inside the statusbar
local function IsStepStarted(step)
	return private.scanStatus[step] and private.scanStatus[step][1] and private.scanStatus[step][2]
end
local function IsStepDone(step)
	return IsStepStarted(step) and private.scanStatus[step][1] == private.scanStatus[step][2]
end
function Manage:UpdateStatus(statusType, current, total)
	private.scanStatus[statusType] = {current, total}
	if statusType == "query" then
		if total >= 0 then
			TSM.GUI:SetStatusBar(format(L["Preparing Filter %d / %d"], current, total))
		else
			TSM.GUI:SetStatusBar(L["Preparing Filters..."])
		end
	elseif IsStepDone("scan") and IsStepDone("manage") and IsStepDone("confirm") then -- scan complete
		TSM.GUI:SetStatusBar(L["Scan Complete!"])
	else
		local parts = {}
		if IsStepDone("scan") then
			if IsStepDone("manage") then
				if private.mode == "Post" then
					tinsert(parts, L["Done Posting"])
				elseif private.mode == "Cancel" then
					tinsert(parts, L["Done Canceling"])
				elseif private.mode == "Reset" then
					tinsert(parts, L["Done Resetting"])
				end
				if private.mode ~= "Reset" then
					if IsStepStarted("confirm") then
						tinsert(parts, format(L["Confirming %d / %d"], private.scanStatus.confirm[1]+1, private.scanStatus.confirm[2]))
					else
						tinsert(parts, format(L["Confirming %d / %d"], 1, private.scanStatus.manage[2]))
					end
				end
			elseif IsStepStarted("manage") then
				if private.mode == "Post" then
					tinsert(parts, format(L["Posting %d / %d"], private.scanStatus.manage[1]+1, private.scanStatus.manage[2]))
				elseif private.mode == "Cancel" then
					tinsert(parts, format(L["Canceling %d / %d"], private.scanStatus.manage[1]+1, private.scanStatus.manage[2]))
				elseif private.mode == "Reset" then
					tinsert(parts, format(L["Resetting %d / %d"], private.scanStatus.manage[1]+1, private.scanStatus.manage[2]))
				end
				if private.mode ~= "Reset" then
					if IsStepStarted("confirm") then
						tinsert(parts, format(L["Confirming %d / %d"], private.scanStatus.confirm[1]+1, private.scanStatus.confirm[2]))
					else
						tinsert(parts, format(L["Confirming %d / %d"], 1, private.scanStatus.manage[2]))
					end
				end
			end
		elseif IsStepStarted("scan") then
			if IsStepStarted("page") then
				tinsert(parts, format(L["Scanning %d / %d (Page %d / %d)"], private.scanStatus.scan[1]+1, private.scanStatus.scan[2], private.scanStatus.page[1]+1, private.scanStatus.page[2]))
			else
				tinsert(parts, format(L["Scanning %d / %d"], private.scanStatus.scan[1]+1, private.scanStatus.scan[2]))
			end
		end
		TSM.GUI:SetStatusBar(table.concat(parts, "  -  "))
	end
	
	if IsStepDone("query") then
		local scanCurrent = private.scanStatus.scan and private.scanStatus.scan[1] or 0
		local scanTotal = private.scanStatus.scan and private.scanStatus.scan[2] or 1
		local confirmCurrent = private.scanStatus.confirm and private.scanStatus.confirm[1] or 0
		local confirmTotal = private.scanStatus.confirm and private.scanStatus.confirm[2] or 1
		TSM.GUI:SetStatusBar(nil, 100*confirmCurrent/confirmTotal, 100*scanCurrent/scanTotal)
	end
end

function Manage:SetCurrentItem(currentItem)
	private.currentItem = currentItem
	if currentItem and currentItem.itemString then
		TSM.GUI:SetInfo(currentItem)
	end
end

function Manage:GetCurrentItem()	
	return private.currentItem
end

function Manage:SetInfoText(text)
	TSM.GUI:SetInfo(text)
end

function Manage:StopScan()
	TSM.GUI:Stopped()
	if private.mode == "Post" then
		TSM.Post:StopPosting()
	elseif private.mode == "Cancel" then
		TSM.Cancel:StopCanceling()
	elseif private.mode == "Reset" then
		TSM.Reset:StopResetting()
	end
	TSM.Scan:StopScanning()
	TSMAPI.Auction:StopScan("Auctioning")
	
	-- clean up local variables
	private.currentItem = nil
	private.mode = nil
	wipe(private.scanStatus)
end