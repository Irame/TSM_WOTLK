-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Auctioning                          --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctioning          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Util = TSM:NewModule("Util", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
local private = { currentBank = nil, frame = nil, minPriceCache = {} }



function Util:OnEnable()
	Util:RegisterEvent("GUILDBANKFRAME_OPENED", "EventHandler")
	Util:RegisterEvent("BANKFRAME_OPENED", "EventHandler")
	Util:RegisterEvent("GUILDBANKFRAME_CLOSED", "EventHandler")
	Util:RegisterEvent("BANKFRAME_CLOSED", "EventHandler")
	Util:RegisterEvent("BAG_UPDATE", "EventHandler")
end

function Util:EventHandler(event)
	if event == "GUILDBANKFRAME_OPENED" then
		private.currentBank = "guildbank"
	elseif event == "BANKFRAME_OPENED" then
		private.currentBank = "bank"
	elseif event == "GUILDBANKFRAME_CLOSED" or event == "BANKFRAME_CLOSED" then
		private.currentBank = nil
	end
end

function Util:GetMinPrice(operation, itemString)
	if private.minPriceCache.updateTime ~= GetTime() then
		wipe(private.minPriceCache)
		private.minPriceCache.updateTime = GetTime()
	end
	if not private.minPriceCache[tostring(operation) .. itemString] then
		private.minPriceCache[tostring(operation) .. itemString] = TSMAPI:GetCustomPriceValue(operation.minPrice, itemString)
	end
	return private.minPriceCache[tostring(operation) .. itemString]
end

function Util:GetItemPrices(operation, itemString, isResetScan, keys)
	local prices = {}
	keys = keys or { undercut = true, minPrice = true, maxPrice = true, normalPrice = true, cancelRepostThreshold = true, resetPrice = true, aboveMax = true }
	if isResetScan then
		keys.resetMaxCost = true
		keys.resetMinProfit = true
		keys.resetResolution = true
		keys.resetMaxItemCost = true
	end
	if keys.resetPrice and operation.priceReset ~= "none" and operation.priceReset ~= "ignore" then
		keys[operation.priceReset] = true
	end
	if keys.aboveMax and operation.aboveMax ~= "none" then
		keys[operation.aboveMax] = true
	end

	prices.undercut = keys.undercut and TSMAPI:GetCustomPriceValue(operation.undercut, itemString)
	prices.minPrice = keys.minPrice and TSMAPI:GetCustomPriceValue(operation.minPrice, itemString)
	prices.maxPrice = keys.maxPrice and TSMAPI:GetCustomPriceValue(operation.maxPrice, itemString)
	prices.normalPrice = keys.normalPrice and TSMAPI:GetCustomPriceValue(operation.normalPrice, itemString)
	if TSM.db.global.roundNormalPrice and prices.normalPrice then
		prices.normalPrice = ceil(prices.normalPrice / COPPER_PER_GOLD) * COPPER_PER_GOLD
	end
	prices.cancelRepostThreshold = keys.cancelRepostThreshold and TSMAPI:GetCustomPriceValue(operation.cancelRepostThreshold, itemString)
	prices.resetMaxCost = keys.resetMaxCost and TSMAPI:GetCustomPriceValue(operation.resetMaxCost, itemString)
	prices.resetMinProfit = keys.resetMinProfit and TSMAPI:GetCustomPriceValue(operation.resetMinProfit, itemString)
	prices.resetResolution = keys.resetResolution and TSMAPI:GetCustomPriceValue(operation.resetResolution, itemString)
	prices.resetMaxItemCost = keys.resetMaxItemCost and TSMAPI:GetCustomPriceValue(operation.resetMaxItemCost, itemString)
	prices.resetPrice = keys.resetPrice and operation.priceReset ~= "none" and operation.priceReset ~= "ignore" and prices[operation.priceReset]
	prices.aboveMax = keys.aboveMax and operation.aboveMax ~= "none" and prices[operation.aboveMax]
	return prices
end

function Util:createTab(parent)
	if private.frame then return private.frame end

	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		parent = parent,
		hidden = true,
		points = "ALL",
		children = {
			{
				type = "GroupTreeFrame",
				key = "groupTree",
				groupTreeInfo = { "Auctioning", "Auctioning_Bank" },
				points = { { "TOPLEFT" }, { "BOTTOMRIGHT", 0, 137 } },
			},
			{
				type = "Frame",
				key = "buttonFrame",
				points = { { "TOPLEFT", BFC.PREV, "BOTTOMLEFT", 0, 0 }, { "BOTTOMRIGHT" } },
				children = {
					{
						type = "Button",
						key = "btnToBags",
						text = L["Post Cap To Bags"],
						textHeight = 14,
						size = { 0, 28 },
						points = { { "TOPLEFT", 5, -5 }, { "TOPRIGHT", BFC.PARENT, "CENTER", -3, -15 } },
						scripts = { "OnClick" },
					},
					{
						type = "Button",
						key = "btnAHToBags",
						text = L["AH Shortfall To Bags"],
						textHeight = 14,
						size = { 0, 28 },
						points = { { "TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0 }, { "TOPRIGHT", -5, -5 } },
						scripts = { "OnClick" },
					},
					{
						type = "Button",
						key = "btnToBank",
						text = L["Group To Bank"],
						textHeight = 14,
						size = { 0, 28 },
						points = { { "TOPLEFT", "btnToBags", "BOTTOMLEFT", 0, -5 }, { "TOPRIGHT", "btnToBags", "BOTTOMRIGHT", 0, -5 } },
						scripts = { "OnClick" },
					},
					{
						type = "Button",
						key = "btnAllToBags",
						text = L["Group To Bags"],
						textHeight = 14,
						size = { 0, 28 },
						points = { { "TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0 }, { "TOPRIGHT", "btnAHToBags", "BOTTOMRIGHT", 0, -5 } },
						scripts = { "OnClick" },
					},
					{
						type = "Button",
						key = "btnMaxExpToBank",
						text = L["Max Expired to Bank"],
						textHeight = 14,
						size = { 0, 28 },
						points = { { "TOPLEFT", "btnToBank", "BOTTOMLEFT", 0, -5 }, { "TOPRIGHT", "btnToBank", "BOTTOMRIGHT", 0, -5 } },
						scripts = { "OnClick" },
					},
					{
						type = "Button",
						key = "btnMaxExpToBags",
						text = L["Max Expired to Bags"],
						textHeight = 14,
						size = { 0, 28 },
						points = { { "TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0 }, { "TOPRIGHT", "btnAllToBags", "BOTTOMRIGHT", 0, -5 } },
						scripts = { "OnClick" },
					},
					{
						type = "Button",
						key = "btnNonGroupBank",
						text = L["Non Group to Bank"],
						textHeight = 14,
						size = { 0, 28 },
						points = { { "TOPLEFT", "btnMaxExpToBank", "BOTTOMLEFT", 0, -5 }, { "TOPRIGHT", "btnMaxExpToBank", "BOTTOMRIGHT", 0, -5 } },
						scripts = { "OnClick" },
					},
					{
						type = "Button",
						key = "btnNonGroupBags",
						text = L["Non Group to Bags"],
						textHeight = 14,
						size = { 0, 28 },
						points = { { "TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0 }, { "TOPRIGHT", "btnMaxExpToBags", "BOTTOMRIGHT", 0, -5 } },
						scripts = { "OnClick" },
					},
				},
			},
		},
		handlers = {
			buttonFrame = {
				btnToBank = {
					OnClick = function() Util:groupTree(private.frame.groupTree:GetSelectedGroupInfo(), "bags") end,
				},
				btnMaxExpToBank = {
					OnClick = function() Util:groupTree(private.frame.groupTree:GetSelectedGroupInfo(), "bags", false, false, true) end,
				},
				btnNonGroupBank = {
					OnClick = function() Util:nonGroupTree(private.frame.groupTree:GetSelectedGroupInfo(), "bags") end,
				},
				btnNonGroupBags = {
					OnClick = function() Util:nonGroupTree(private.frame.groupTree:GetSelectedGroupInfo(), private.currentBank) end,
				},
				btnToBags = {
					OnClick = function() Util:groupTree(private.frame.groupTree:GetSelectedGroupInfo(), private.currentBank) end,
				},
				btnAHToBags = {
					OnClick = function() Util:groupTree(private.frame.groupTree:GetSelectedGroupInfo(), private.currentBank, false, true) end,
				},
				btnMaxExpToBags = {
					OnClick = function() Util:groupTree(private.frame.groupTree:GetSelectedGroupInfo(), private.currentBank, false, true, true) end,
				},
				btnAllToBags = {
					OnClick = function() Util:groupTree(private.frame.groupTree:GetSelectedGroupInfo(), private.currentBank, true) end,
				},
			},
		},
	}

	private.frame = TSMAPI.GUI:BuildFrame(frameInfo)

	local helpPlateInfo = {
		FramePos = { x = -5, y = 100 },
		FrameSize = { width = 275, height = 490 },
		{
			ButtonPos = { x = 115, y = -66 },
			HighLightBox = { x = 0, y = -75, width = 275, height = 27 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["These will toggle between the module specific tabs."],
		},
		{
			ButtonPos = { x = 115, y = -196 },
			HighLightBox = { x = 0, y = -103, width = 275, height = 243 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["Lists the groups with auctioning operations. Left click to select/deselect the group, Right click to expand/collapse the group."],
		},
		{
			ButtonPos = { x = 52.5, y = -335 },
			HighLightBox = { x = 0, y = -347, width = 136, height = 23 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will select all groups."],
		},
		{
			ButtonPos = { x = 182.5, y = -335 },
			HighLightBox = { x = 138, y = -347, width = 136, height = 23 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will de-select all groups."],
		},
		{
			ButtonPos = { x = 52.5, y = -364 },
			HighLightBox = { x = 0, y = -371, width = 136, height = 30 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will move items in the selected groups up to your post cap (sum of post caps if you have multiple operations) from the bank to your bags."],
		},
		{
			ButtonPos = { x = 182.5, y = -364 },
			HighLightBox = { x = 138, y = -371, width = 136, height = 30 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will move items in the selected groups from the bank to your bags. It will take into account the number you already have on the auction house (across all players) or pending in your mailbox (current player only) and only move what the shortfall is."],
		},
		{
			ButtonPos = { x = 52.5, y = -394 },
			HighLightBox = { x = 0, y = -403, width = 136, height = 30 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will move all items in the selected groups from your bags to the bank."],
		},
		{
			ButtonPos = { x = 182.5, y = -394 },
			HighLightBox = { x = 138, y = -403, width = 136, height = 30 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will move all items in the selected groups from the bank to your bags."],
		},
		{
			ButtonPos = { x = 52.5, y = -428 },
			HighLightBox = { x = 0, y = -437, width = 136, height = 30 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will move all items in the selected groups that have exceeded the max expires setting from your bags to the bank."],
		},
		{
			ButtonPos = { x = 182.5, y = -428 },
			HighLightBox = { x = 138, y = -437, width = 136, height = 30 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will move all items in the selected groups that have exceeded the max expires setting from the bank to your bags."],
		},
		{
			ButtonPos = { x = 52.5, y = -462 },
			HighLightBox = { x = 0, y = -470, width = 136, height = 32 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will move all items NOT in the selected groups from your bags to the bank."],
		},
		{
			ButtonPos = { x = 182.5, y = -462 },
			HighLightBox = { x = 138, y = -470, width = 136, height = 32 },
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button will move all items NOT in the selected groups from the bank to your bags."],
		},
	}

	local mainHelpBtn = CreateFrame("Button", nil, private.frame, "MainHelpPlateButton")
	mainHelpBtn:SetPoint("TOPRIGHT", private.frame, 45, 70)
	mainHelpBtn:SetScript("OnClick", function() Util:ToggleHelpPlate(private.frame, helpPlateInfo, mainHelpBtn, true) end)
	mainHelpBtn:SetScript("OnHide", function() if HelpPlate_IsShowing(helpPlateInfo) then Util:ToggleHelpPlate(private.frame, helpPlateInfo, mainHelpBtn, false) end end)

	return private.frame
end

function Util:groupTree(grpInfo, src, all, ah, maxExpired)
	local next = next
	local newgrp = {}
	local totalItems = Util:getTotalItems(src)
	local bagItems = Util:getTotalItems("bags") or {}
	for groupName, data in pairs(grpInfo) do
		groupName = TSMAPI.Groups:FormatPath(groupName, true)
		for _, opName in ipairs(data.operations) do
			TSMAPI.Operations:Update("Auctioning", opName)
			local opSettings = TSM.operations[opName]

			if not opSettings then
				-- operation doesn't exist anymore in Auctioning
				TSM:Printf(L["'%s' has an Auctioning operation of '%s' which no longer exists."], groupName, opName)
			else
				--it's a valid operation
				for itemString in pairs(data.items) do
					local totalq = 0
					if totalItems then
						totalq = totalItems[itemString] or 0
					end
					--check if maxExpires has been exceeded
					local expired = false
					if opSettings.maxExpires > 0 and TSMAPI:HasModule("Accounting") then
						local numExpires = select(2, TSMAPI:ModuleAPI("Accounting", "getAuctionStatsSinceLastSale", itemString))
						if type(numExpires) == "number" and numExpires > opSettings.maxExpires then
							expired = true
						end
					end
					if src == "bags" then -- move them all back to bank/gbank
					if (maxExpired and expired) or not maxExpired then
						if totalq > 0 then
							newgrp[itemString] = totalq * -1
							totalItems[itemString] = nil -- remove the current bag count in case we loop round for another operation
						end
					end
					else -- move from bank/gbank to bags
						if (maxExpired and expired) or (not maxExpired and not expired) then
							if totalq > 0 then
								if all or maxExpired then
									newgrp[itemString] = totalq
									totalItems[itemString] = nil
								else
									local availQty = totalq
									if opSettings.keepQuantity > 0 then
										if src == "bank" then
											if opSettings.keepQtySources.bank then
												if opSettings.keepQtySources.guild then
													availQty = availQty + TSMAPI.Inventory:GetGuildQuantity(itemString)
												end
												availQty = availQty - opSettings.keepQuantity
											end
										end
										if src == "guildbank" then
											if opSettings.keepQtySources.guild then
												if opSettings.keepQtySources.bank then
													availQty = availQty + TSMAPI.Inventory:GetBankQuantity(itemString) + TSMAPI.Inventory:GetReagentBankQuantity(itemString)
												end
												availQty = availQty - opSettings.keepQuantity
											end
										end
									end

									local ahQty = ah and (TSMAPI.Inventory:GetMailQuantity(itemString) + select(3, TSMAPI.Inventory:GetPlayerTotals(itemString))) or 0
									local quantity = min(availQty, (opSettings.stackSize * opSettings.postCap) - ahQty - (bagItems[itemString] or 0))
									if quantity > 0 then
										newgrp[itemString] = (newgrp[itemString] or 0) + quantity
										totalItems[itemString] = totalItems[itemString] - quantity -- remove this operations qty to move from source quantity in case we loop again for another operation
										if bagItems[itemString] then --remove this operations maxPost quantity from the bag total in case we loop again for another operation
											bagItems[itemString] = bagItems[itemString] - (opSettings.stackSize * opSettings.postCap)
											if bagItems[itemString] <= 0 then
												bagItems[itemString] = nil
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if next(newgrp) == nil then
		TSM:Print(L["Nothing to Move"])
	else
		TSM:Print(L["Preparing to Move"])
		TSMAPI:MoveItems(newgrp, Util.PrintMsg, false)
	end
end

function Util:nonGroupTree(grpInfo, src)
	local next = next
	local newgrp = {}
	local totalItems = Util:getTotalItems(src, true)
	local bagItems = Util:getTotalItems("bags", true)
	for groupName, data in pairs(grpInfo) do
		groupName = TSMAPI.Groups:FormatPath(groupName, true)
		for _, opName in ipairs(data.operations) do
			TSMAPI.Operations:Update("Auctioning", opName)
			local opSettings = TSM.operations[opName]

			if not opSettings then
				-- operation doesn't exist anymore in Auctioning
				TSM:Printf(L["'%s' has an Auctioning operation of '%s' which no longer exists."], groupName, opName)
			else
				-- it's a valid operation so remove all the items from bagItems so we are left with non group items to move
				for itemString in pairs(data.items) do
					if totalItems then
						if totalItems[itemString] then
							totalItems[itemString] = nil
						end
					end
				end
			end
		end
	end


	for itemString, quantity in pairs(totalItems) do
		if src == "bags" then -- move them all back to bank/gbank
		newgrp[itemString] = totalItems[itemString] * -1
		else -- move from bank/gbank to bags
		newgrp[itemString] = quantity
		end
	end

	if next(newgrp) == nil then
		TSM:Print(L["Nothing to Move"])
	else
		TSM:Print(L["Preparing to Move"])
		TSMAPI:MoveItems(newgrp, Util.PrintMsg, true)
	end
end

function Util.PrintMsg(message)
	TSM:Print(message)
end

function Util:getTotalItems(src, includeSoulbound)
	local results = {}
	if src == "bank" then
		for _, _, itemString, quantity in TSMAPI.Inventory:BankIterator(true, includeSoulbound, false, true) do
			results[itemString] = (results[itemString] or 0) + quantity
		end
		return results
	elseif src == "guildbank" then
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
		for bag, slot, itemString, quantity in TSMAPI.Inventory:BagIterator(true, includeSoulbound) do
			if private.currentBank == "bank" or not TSMAPI.Item:IsSoulbound(bag, slot) then
				results[itemString] = (results[itemString] or 0) + quantity
			end
		end
		return results
	end
end

function Util:ToggleHelpPlate(frame, info, btn, isUser)
	if not HelpPlate_IsShowing(info) then
		HelpPlate:SetParent(frame)
		HelpPlate:SetFrameStrata("DIALOG")
		HelpPlate_Show(info, frame, btn, isUser)
	else
		HelpPlate:SetParent(UIParent)
		HelpPlate:SetFrameStrata("DIALOG")
		HelpPlate_Hide(isUser)
	end
end