-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Auctioning                          --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctioning          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
local GUI = TSM:NewModule("GUI", "AceEvent-3.0", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local private = {scanThreadId=nil, logSTCache={}}
TSMAPI.Auction:GetTabShowFunction("Auctioning") -- not currently used, but prevents anybody else from getting it


function private:CreateSelectionFrame(parent)
	if private.selectionFrame then return end

	local actionBtnWidth = (parent.content:GetWidth() - 240) / 3
	local durationList = {}
	local durationText = {L["Under 30min"], L["30min to 2hrs"], L["2 to 12 hrs"]} -- use our own short-hand strings
	for i=1, 3 do -- go up to long duration
		durationList[i] = format("%s (%s)", _G["AUCTION_TIME_LEFT"..i], durationText[i])
	end

	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		parent = parent.content,
		points = "ALL",
		children = {
			{
				type = "GroupTreeFrame",
				key = "groupTree",
				groupTreeInfo = {"Auctioning", "Auctioning_AH"},
				points = {{"TOPLEFT", 5, -25}, {"BOTTOMRIGHT", -225, 35}},
			},
			{
				type = "Text",
				text = L["Select the groups which you would like to include in the scan."],
				textFont = {TSMAPI.Design:GetContentFont("normal")},
				justify = {"CENTER", "MIDDLE"},
				points = {{"BOTTOM", BFC.PREV, "TOP", 0, 2}},
			},
			{
				type = "Button",
				key = "postBtn",
				text = L["Start Post Scan"],
				textHeight = 18,
				size = {actionBtnWidth, 25},
				points = {{"BOTTOMLEFT", 5, 5}},
				scripts = {"OnClick"},
			},
			{
				type = "Button",
				key = "cancelBtn",
				text = L["Start Cancel Scan"],
				textHeight = 18,
				size = {actionBtnWidth, 25},
				points = {{"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}},
				scripts = {"OnClick"},
			},
			{
				type = "Button",
				key = "resetBtn",
				text = L["Start Reset Scan"],
				textHeight = 18,
				size = {actionBtnWidth, 25},
				points = {{"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}},
				scripts = {"OnClick"},
			},
			{
				type = "Frame",
				key = "customScanFrame",
				points = {{"TOPLEFT", BFC.PARENT, "TOPRIGHT", -221, 0}, {"BOTTOMRIGHT"}},
				children = {
					{
						type = "Text",
						text = L["Other Auctioning Searches"],
						textFont = {TSMAPI.Design:GetContentFont("normal")},
						justify = {"CENTER", "MIDDLE"},
						points = {{"TOP", 0, -2}},
					},
					{
						type = "HLine",
						offset = -20,
					},
					{
						type = "Button",
						key = "cancelAllBtn",
						text = L["Cancel All Auctions"],
						textHeight = 16,
						tooltip = L["Will cancel all your auctions, including ones which you didn't post with Auctioning."],
						size = {0, 20},
						points = {{"TOPLEFT", 4, -24}, {"TOPRIGHT", -4, -24}},
						scripts = {"OnClick"},
					},
					{
						type = "HLine",
						offset = -48,
					},
					{
						type = "Text",
						text = L["Cancel Filter:"],
						textFont = {TSMAPI.Design:GetContentFont("small")},
						justify = {"LEFT", "MIDDLE"},
						points = {{"TOPLEFT", 4, -52}, {"TOPRIGHT", -4, -52}},
					},
					{
						type = "InputBox",
						key = "filterEditBox",
						name = "TSMAuctioningCancelFilterEditbox",
						size = {0, 20},
						points = {{"TOPLEFT", 4, -72}, {"TOPRIGHT", -4, -72}},
					},
					{
						type = "Button",
						key = "cancelFilterBtn",
						text = L["Cancel Items Matching Filter"],
						textHeight = 16,
						tooltip = L["Will cancel all your auctions which match the specified filter, including ones which you didn't post with Auctioning."],
						size = {0, 20},
						points = {{"TOPLEFT", 4, -96}, {"TOPRIGHT", -4, -96}},
						scripts = {"OnClick"},
					},
					{
						type = "HLine",
						offset = -120,
					},
					{
						type = "Dropdown",
						key = "cancelDurationDropdown",
						label = L["Low Duration"],
						list = durationList,
						value = 1,
						tooltip = L["Select a duration in this dropdown and click on the button below to cancel all auctions at or below this duration."],
						points = {{"TOPLEFT", 2, -124}, {"TOPRIGHT", 0, -124}},
					},
					{
						type = "Button",
						key = "cancelDurationBtn",
						text = L["Cancel Low Duration"],
						textHeight = 16,
						tooltip = L["Will cancel all your auctions at or below the specified duration, including ones you didn't post with Auctioning."],
						size = {0, 20},
						points = {{"TOPLEFT", 4, -172}, {"TOPRIGHT", -4, -172}},
						scripts = {"OnClick"},
					},
					{
						type = "HLine",
						offset = -196,
					},
					{
						type = "Text",
						text = L["No-Group Posting:"],
						textFont = {TSMAPI.Design:GetContentFont("small")},
						justify = {"LEFT", "MIDDLE"},
						points = {{"TOPLEFT", 4, -202}, {"TOPRIGHT", -4, -202}},
					},
					{
						type = "Button",
						key = "quickPostBtn",
						text = L["Quick Post from Bags"],
						textHeight = 18,
						tooltip = L["Will do a post scan for any items in your bags which aren't in a group with an Auctioning operation using some generic settings."],
						size = {0, 25},
						points = {{"TOPLEFT", 4, -216}, {"TOPRIGHT", -4, -216}},
						scripts = {"OnClick"},
					},
					{
						type = "HLine",
						offset = -245,
					},
				},
			},
		},
		handlers = {
			postBtn = {
				OnClick = function() private:StartScan(parent, "Post") end,
			},
			cancelBtn = {
				OnClick = function() private:StartScan(parent, "Cancel") end,
			},
			resetBtn = {
				OnClick = function() private:StartScan(parent, "Reset") end,
			},
			customScanFrame = {
				cancelAllBtn = {
					OnClick = function() private:StartScan(parent, "Cancel", {cancelAll=true}) end,
				},
				cancelFilterBtn = {
					OnClick = function(self)
						local filter = self:GetParent().filterEditBox:GetText()
						if filter:trim() == "" then
							TSM:Print(L["The filter cannot be empty. If you'd like to cancel all auctions, use the 'Cancel All Auctions' button."])
							return
						end
						private:StartScan(parent, "Cancel", {filter=filter})
					end,
				},
				cancelDurationBtn = {
					OnClick = function(self) private:StartScan(parent, "Cancel", {duration=self:GetParent().cancelDurationDropdown:GetValue()}) end,
				},
				quickPostBtn = {
					OnClick = function(self) private:StartScan(parent, "Post", {quickPost=true}) end,
				},
			},
		},
	}

	local frame = TSMAPI.GUI:BuildFrame(frameInfo)
	TSMAPI.Design:SetFrameBackdropColor(frame)
	TSMAPI.Design:SetFrameColor(frame.customScanFrame)
	private.selectionFrame = frame

	local helpPlateInfo = {
		FramePos = {x=0, y=0},
		FrameSize = {width=frame:GetWidth(), height=frame:GetHeight()},
		{
			ButtonPos = {x = 380, y = -75},
			HighLightBox = {x = 5, y = -5, width = 594, height = 292},
			ToolTipDir = "UP",
			ToolTipText = L["If you have created TSM groups and assigned Auctioning operations, they will be listed here for selection."]
		},
		{
			ButtonPos = {x = 380, y = -290},
			HighLightBox = {x = 5, y = -297, width = 594, height = 30},
			ToolTipDir = "UP",
			ToolTipText = L["These buttons will start a Post, Cancel, or Reset scan for the groups you have selected."]
		},
		{
			ButtonPos = {x = 800, y = -100},
			HighLightBox = {x = 605, y = 0, width = 220, height = 200},
			ToolTipDir = "RIGHT",
			ToolTipText = L["These buttons allow you to quickly cancel auctions regardless of having TSM groups with Auctioning operations."]
		},
		{
			ButtonPos = {x = 800, y = -200},
			HighLightBox = {x = 605, y = -200, width = 220, height = 50},
			ToolTipDir = "RIGHT",
			ToolTipText = L["This button lets you quickly post items from your bags without setting up groups / operations for them."]
		},
	}

	local mainHelpBtn = CreateFrame("Button", nil, frame, "MainHelpPlateButton")
	mainHelpBtn:SetPoint("TOP", frame, -300, 70)
	mainHelpBtn:SetScript("OnClick", function() private:ToggleHelpPlate(frame, helpPlateInfo, mainHelpBtn, true) end)
	mainHelpBtn:SetScript("OnHide", function() if HelpPlate_IsShowing(helpPlateInfo) then private:ToggleHelpPlate(frame, helpPlateInfo, mainHelpBtn, false) end end)

	if not TSM.db.global.helpPlatesShown.selection then
		TSM.db.global.helpPlatesShown.selection = true
		private:ToggleHelpPlate(frame, helpPlateInfo, mainHelpBtn, false)
	end
end

function private:ToggleHelpPlate(frame, info, btn, isUser)
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


function private:CreateScanFrame(parent)
	if private.scanFrame then return end
	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		parent = parent,
		points = "ALL",
		children = {
			{
				type = "Frame",
				key = "content",
				points = {{"TOPLEFT", parent.content}, {"BOTTOMRIGHT", parent.content}},
				children = {
					{
						type = "StatusBarFrame",
						key = "statusBar",
						name = "TSMAuctioningStatusBar",
						size = {355, 30},
						points = {{"TOPLEFT", BFC.PARENT, "BOTTOMLEFT", 165, -2}},
					},
					{
						type = "AuctionResultsTableFrame",
						key = "auctionsST",
						sortIndex = 9,
						points = "ALL",
					},
					{
						type = "ScrollingTableFrame",
						key = "logST",
						stCols = {{name=L["Item"], width=0.31}, {name=L["Operation"], width=0.17, align="CENTER"}, {name=private:GetLogSTPriceColumnText(), width=0.12, align="RIGHT"}, {name=L["Seller"], width=0.11, align="CENTER"}, {name=L["Info"], width=0.28}, {name="", width=0}},
						sortInfo = {true, 6},
						stDisableSelection = true,
						points = "ALL",
						scripts = {"OnEnter", "OnLeave", "OnClick", "OnColumnClick"},
					},
				},
			},
			{
				type = "Frame",
				key = "actionButtonsFrame",
				size = {210, 24},
				points = {{"BOTTOMRIGHT", -94, 5}},
				children = {
					{
						type = "Button",
						key = "post",
						name = "TSMAuctioningPostButton",
						isSecure = true,
						text = L["Post"],
						textHeight = 22,
						size = {80, 24},
						points = {{"TOPLEFT"}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "cancel",
						name = "TSMAuctioningCancelButton",
						isSecure = true,
						text = CANCEL,
						textHeight = 22,
						size = {80, 24},
						points = {{"TOPLEFT"}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "skip",
						text = L["Skip"],
						textHeight = 18,
						size = {60, 24},
						points = {{"TOPLEFT", "post", "TOPRIGHT", 4, 0}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "stop",
						text = L["Stop"],
						textHeight = 18,
						size = {70, 24},
						points = {{"TOPLEFT", "skip", "TOPRIGHT", 4, 0}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "restart",
						text = L["Restart"],
						textHeight = 18,
						size = {70, 24},
						points = {{"TOPLEFT", "skip", "TOPRIGHT", 4, 0}},
						scripts = {"OnClick"},
					},
				},
			},
			{
				type = "Frame",
				key = "contentButtonsFrame",
				points = "ALL",
				children = {
					{
						type = "Button",
						key = "auctionsButton",
						text = L["Show All Auctions"],
						textHeight = 16,
						size = {150, 17},
						points = {{"TOPRIGHT", -10, -20}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "currAuctionsButton",
						text = L["Show Item Auctions"],
						textHeight = 16,
						size = {150, 17},
						points = {{"TOPRIGHT", -170, -20}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "logButton",
						text = L["Show Log"],
						textHeight = 16,
						size = {150, 17},
						points = {{"TOPRIGHT", -10, -45}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "editPriceButton",
						text = L["Edit Post Price"],
						textHeight = 16,
						size = {150, 17},
						points = {{"TOPRIGHT", -170, -45}},
						scripts = {"OnClick"},
					},
				},
			},
			{
				type = "Frame",
				key = "editPriceFrame",
				strata = "DIALOG",
				mouse = true,
				hidden = true,
				size = {350, 150},
				points = {{"CENTER"}},
				scripts = {"OnShow", "OnUpdate"},
				children = {
					{
						type = "ItemLinkLabel",
						key = "linkLabel",
						text = "",
						textHeight = 15,
						size = {0, 20},
						justify = {"CENTER", "TOP"},
						points = {{"TOPLEFT", 0, -14}, {"TOPRIGHT", 0, -14}},
					},
					{
						type = "Text",
						text = L["Auction Buyout (Stack Price):"],
						textHeight = 12,
						points = {{"TOPLEFT", 14, -40}},
					},
					{
						type = "MoneyInputBox",
						name = "TSMPostPriceChangeBox",
						key = "priceBox",
						size = {120, 20},
						points = {{"TOPLEFT", 20, -60}},
					},
					{
						type = "Dropdown",
						key = "durationDropdown",
						label = L["Duration"],
						list = {[12]=AUCTION_DURATION_ONE, [24]=AUCTION_DURATION_TWO, [48]=AUCTION_DURATION_THREE},
						value = 12,
						size = {140, 40},
						points = {{"TOPRIGHT", -5, -40}},
					},
					{
						type = "Button",
						key = "saveButton",
						text = L["Save New Price"],
						textHeight = 16,
						size = {0, 20},
						points = {{"BOTTOMRIGHT", BFC.PARENT, "BOTTOM", -2, 10}, {"BOTTOMLEFT", 10, 10}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "cancelButton",
						text = CANCEL,
						textHeight = 16,
						size = {0, 20},
						points = {{"BOTTOMLEFT", BFC.PARENT, "BOTTOM", 2, 10}, {"BOTTOMRIGHT", -10, 10}},
						scripts = {"OnClick"},
					},
				},
			},
			{
				type = "Frame",
				key = "infoTextFrame",
				points = "ALL",
				children = {
					{
						type = "IconButton",
						key = "icon",
						size = {50, 50},
						points = {{"TOPLEFT", 85, -20}},
						scripts = {"OnEnter", "OnLeave", "OnClick"},
					},
					{
						type = "ItemLinkLabel",
						key = "linkText",
						text = "",
						textHeight = 15,
						size = {0, 20},
						justify = {"LEFT", "MIDDLE"},
						points = {{"LEFT", "icon", "RIGHT", 4, 0}},
					},
					{
						type = "Text",
						key = "stackText",
						justify = {"LEFT", "MIDDLE"},
						size = {175, 18},
						points = {{"TOPLEFT", 350, -18}},
					},
					{
						type = "Text",
						key = "bidText",
						justify = {"LEFT", "MIDDLE"},
						size = {175, 18},
						points = {{"TOPLEFT", 350, -38}},
					},
					{
						type = "Text",
						key = "buyoutText",
						justify = {"LEFT", "MIDDLE"},
						size = {175, 18},
						points = {{"TOPLEFT", 350, -58}},
					},
					{
						type = "Text",
						key = "statusText",
						justify = {"CENTER", "MIDDLE"},
						points = {{"TOP", BFC.PARENT, "TOPLEFT", 300, -15}},
					},
					{
						type = "Text",
						key = "goldText",
						justify = {"CENTER", "MIDDLE"},
						points = {{"TOP", BFC.PREV, "BOTTOM", 0, -15}},
					},
					{
						type = "Text",
						key = "goldText2",
						justify = {"CENTER", "MIDDLE"},
						points = {{"TOP", BFC.PREV, "BOTTOM"}},
					},
					{
						type = "Text",
						key = "quantityText",
						justify = {"LEFT", "MIDDLE"},
						size = {18, 175},
						points = {{"TOPLEFT", 535, -58}},
					},
				},
			},
		},
		handlers = {
			content = {
				logST = {
					OnEnter = function(_, data, self)
						if not data.operation or not data.operation.minPrice then return end
						local prices = TSM.Util:GetItemPrices(data.operation, data.itemString, false, {minPrice=true, maxPrice=true, normalPrice=true})

						GameTooltip:SetOwner(self, "ANCHOR_NONE")
						GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
						GameTooltip:AddLine(data.link)
						GameTooltip:AddLine(L["Group:"].." |cffffffff"..(TSMAPI.Groups:FormatPath(TSMAPI.Groups:GetPath(data.itemString)) or "---").."|r")
						GameTooltip:AddLine(L["Minimum Price:"].." "..(TSMAPI:MoneyToString(prices.minPrice, "|cffffffff") or "---"))
						GameTooltip:AddLine(L["Maximum Price:"].." "..(TSMAPI:MoneyToString(prices.maxPrice, "|cffffffff") or "---"))
						GameTooltip:AddLine(L["Normal Price:"].." "..(TSMAPI:MoneyToString(prices.normalPrice, "|cffffffff") or "---"))
						GameTooltip:AddLine(L["Lowest Buyout:"].." "..(TSMAPI:MoneyToString(data.lowestBuyout, "|cffffffff") or "---"))
						if TSMAPI:HasModule("Accounting") then
							local numExpires = select(2, TSMAPI:ModuleAPI("Accounting", "getAuctionStatsSinceLastSale", data.itemString))
							if type(numExpires) ~= "number" then
								numExpires = 0
							end
							if data.operation.maxExpires > 0 then
								GameTooltip:AddLine(L["Expires / Max Expires:"].." |cffffffff("..numExpires.."/"..data.operation.maxExpires..")")
							else
								GameTooltip:AddLine(L["Expires:"].." |cffffffff"..numExpires)
							end
						end
						GameTooltip:AddLine(L["Log Info:"].." "..data.info)
						GameTooltip:AddLine("")
						GameTooltip:AddLine(TSMAPI.Design:GetInlineColor("link2")..L["Click to show auctions for this item."].."|r")
						if private.mode == "Post" then
							GameTooltip:AddLine(TSMAPI.Design:GetInlineColor("link2")..L["Shift-Click to buy auctions for this item."].."|r")
						end
						GameTooltip:AddLine(TSMAPI.Design:GetInlineColor("link2")..format(L["Right-Click to add %s to your friends list."], "|r"..(data.seller or "---")..TSMAPI.Design:GetInlineColor("link2")).."|r")
						if not data.operation.isFake then
							GameTooltip:AddLine(TSMAPI.Design:GetInlineColor("link2")..L["Shift-Right-Click to show the options for this operation."].."|r")
						end
						GameTooltip:Show()
					end,
					OnLeave = function()
						GameTooltip:Hide()
						private:UpdateLogSTHighlight(TSM.Manage:GetCurrentItem())
					end,
					OnClick = function(_, data, _, button)
						if button == "LeftButton" then
							if IsShiftKeyDown() and private.mode == "Post" then
								if not TSMAPI:HasModule("Shopping") then
									TSM:Print(L["This feature requires the TSM_Shopping module."])
									return
								end
								local canBuy, reason = TSM.Post:CanBuyAuction(data.itemString)
								if canBuy then
									TSMAPI:ModuleAPI("Shopping", "startSearchAuctioning", TSMAPI.Item:ToItemString(data.itemString), TSM.Scan:GetDatabase(), function() private:DoCallbackAsync("REPROCESS_ITEM", data.itemString) end, TSM.Scan:GetFilterFunction(data.itemString, data.operation))
								elseif reason == "scanning" then
									TSM:Print(L["Cannot buy items until the post scan is complete."])
								elseif reason == "posted" then
									TSM:Print(L["Cannot buy this item because you have already posted it."])
								end
							else
								private.scanFrame.contentButtonsFrame.auctionsButton:UnlockHighlight()
								private.scanFrame.contentButtonsFrame.logButton:UnlockHighlight()
								private.scanFrame.contentButtonsFrame.currAuctionsButton:UnlockHighlight()
								private.scanFrame.contentButtonsFrame.editPriceButton:UnlockHighlight()
								private.scanFrame.content.logST:Hide()
								private.scanFrame.content.auctionsST:Show()
								private.scanFrame.content.auctionsST.isCurrentItem = data.itemString
								private:UpdateAuctionsSTData()
							end
						elseif button == "RightButton" then
							if IsShiftKeyDown() then
								if not data.operation or data.operation.isFake then return end
								TSMAPI.Operations:ShowOptions("Auctioning", TSM.operationNameLookup[data.operation])
							else
								if data.seller then
									AddFriend(data.seller)
								else
									TSM:Print(L["This item does not have any seller data."])
								end
							end
						end
					end,
					OnColumnClick = function(self, button)
						if self.colNum == 3 and button == "RightButton" then
							if TSM.db.global.priceColumn == 1 then
								TSM.db.global.priceColumn = 2
							else
								TSM.db.global.priceColumn = 1
							end
							self:SetText(private:GetLogSTPriceColumnText())
							wipe(private.scanFrame.content.logST.cache)
							private:UpdateLogSTData()
						end
						if self.colNum == 5 and button == "RightButton" then
							-- reset sorting
							private.scanFrame.content.logST:EnableSorting(true, 6)
						end
						wipe(private.logSTCache)
						private:UpdateLogSTHighlight(TSM.Manage:GetCurrentItem())
					end,
				},
			},
			actionButtonsFrame = {
				post = {
					OnClick = function() if TSMAPI.Util:UseHardwareEvent() then private:DoCallback("ACTION_BUTTON") end end,
				},
				cancel = {
					OnClick = function() if TSMAPI.Util:UseHardwareEvent() then private:DoCallback("ACTION_BUTTON") end end,
				},
				skip = {
					OnClick = function() private:DoCallback("SKIP_BUTTON") end,
				},
				stop = {
					OnClick = function() TSM.Manage:StopScan() end,
				},
				restart = {
					OnClick = function(self)
						GUI:HideSelectionFrame()
						private.selectionFrame:Show()
					end,
				},
			},
			contentButtonsFrame = {
				auctionsButton = {
					OnClick = function(self)
						private:ResetContentButtons()
						self:LockHighlight()
						private.scanFrame.content.logST:Hide()
						private.scanFrame.content.auctionsST:Show()
						private.scanFrame.content.auctionsST.isCurrentItem = nil
						private:UpdateAuctionsSTData()
					end,
				},
				currAuctionsButton = {
					OnClick = function(self)
						private:ResetContentButtons()
						self:LockHighlight()
						private.scanFrame.content.logST:Hide()
						private.scanFrame.content.auctionsST:Show()
						private.scanFrame.content.auctionsST.isCurrentItem = true
						private:UpdateAuctionsSTData()
					end,
				},
				logButton = {
					OnClick = function(self)
						private:ResetContentButtons()
						self:LockHighlight()
						private.scanFrame.content.auctionsST:Hide()
						private.scanFrame.content.logST:Show()
						private:UpdateLogSTData()
					end,
				},
				editPriceButton = {
					OnClick = function(self)
						private:ResetContentButtons()
						self:LockHighlight()
						private.scanFrame.editPriceFrame:Show()
					end,
				},
			},
			editPriceFrame = {
				OnShow = function(self)
					self:SetFrameStrata("DIALOG")
					TSMPostPriceChangeBox:SetCopper(self.info.buyout)
					self.linkLabel:SetText(self.info.link)
				end,
				OnUpdate = function(self)
					if not TSMAPI.Auction:IsTabVisible("Auctioning") then
						self:Hide()
					end
				end,
				saveButton = {
					OnClick = function(self)
						private:DoCallback("EDIT_POST_PRICE", self:GetParent().info.itemString, TSMPostPriceChangeBox:GetCopper(), self:GetParent().info.operation, self:GetParent().durationDropdown:GetValue())
						self:GetParent():Hide()
					end,
				},
				cancelButton = {
					OnClick = function(self) self:GetParent():Hide() end,
				},
			},
			infoTextFrame = {
				icon = {
					OnEnter = function(self)
						if self.link and self.link ~= "" then
							GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
							TSMAPI.Util:SafeTooltipLink(self.link)
							GameTooltip:Show()
						end
					end,
					OnLeave = function(self) GameTooltip:Hide() end,
					OnClick = function(self) if IsModifiedClick() then HandleModifiedItemClick(self.link) end end,
				},
			},
		},
	}

	private.scanFrame = TSMAPI.GUI:BuildFrame(frameInfo)
	TSMAPI.Design:SetFrameColor(private.scanFrame.content)
	TSMAPI.Design:SetFrameBackdropColor(private.scanFrame.editPriceFrame)
	local auctionRTInfo = {
		headers = {{"Auction Bid\n(per item)", "Auction Bid\n(per stack)"}, {"Auction Buyout\n(per item)", "Auction Buyout\n(per stack)"}},
		pctHeader = L["% Market Value"],
		GetRowPrices = function(record, isPerItem)
			if isPerItem then
				return record.itemDisplayedBid, record.itemBuyout, record.isHighBidder and "|cffffff00" or nil
			else
				return record.displayedBid, record.buyout, record.isHighBidder and "|cff00ff00" or nil
			end
		end,
		GetMarketValue = function(itemString)
			return TSMAPI:GetItemValue(itemString, "DBMarket") or 0
		end,
	}
	private.scanFrame.content.auctionsST:SetPriceInfo(auctionRTInfo)
end

function private:UpdateScanMode()
	if private.mode == "Post" then
		private.scanFrame.actionButtonsFrame.post:Show()
		private.scanFrame.actionButtonsFrame.cancel:Hide()
		private.scanFrame.contentButtonsFrame.currAuctionsButton:Show()
		private.scanFrame.contentButtonsFrame.editPriceButton:Show()
		private.scanFrame.contentButtonsFrame.editPriceButton:Disable()
	elseif private.mode == "Cancel" then
		private.scanFrame.actionButtonsFrame.post:Hide()
		private.scanFrame.actionButtonsFrame.cancel:Show()
		private.scanFrame.contentButtonsFrame.currAuctionsButton:Show()
		private.scanFrame.contentButtonsFrame.editPriceButton:Hide()
	end
end

function private:ResetContentButtons()
	private.scanFrame.contentButtonsFrame.auctionsButton:UnlockHighlight()
	private.scanFrame.contentButtonsFrame.logButton:UnlockHighlight()
	private.scanFrame.contentButtonsFrame.currAuctionsButton:UnlockHighlight()
	private.scanFrame.contentButtonsFrame.editPriceButton:UnlockHighlight()
	private.scanFrame.editPriceFrame:Hide()
end

function private:GetLogSTPriceColumnText()
	if TSM.db.global.priceColumn == 1 then
		return L["Your Buyout"]
	elseif TSM.db.global.priceColumn == 2 then
		return L["Lowest Buyout"]
	end
end

function private:GetCurrentAuctionSTItem()
	if not private.scanFrame.content.auctionsST:IsVisible() then return end
	local currentItem = private.scanFrame.content.auctionsST.isCurrentItem
	if not currentItem then return end
	if type(currentItem) == "string" then
		return currentItem
	else
		if not TSM.Manage:GetCurrentItem() then
			return
		end
		return TSM.Manage:GetCurrentItem().itemString
	end
end

function private.AuctionSTFilterFunc(record)
	if not private.scanFrame.content.auctionsST.isCurrentItem then return true end
	local currentItem = private:GetCurrentAuctionSTItem()
	if not currentItem then return end
	return record.itemString == currentItem or record.baseItemString == currentItem
end

function private:UpdateAuctionsSTData()
	local auctionsST = private.scanFrame.content.auctionsST
	if not auctionsST:IsVisible() then return end
	local db = TSM.Scan:GetDatabase()
	if db then
		auctionsST:SetDatabase(db, private.AuctionSTFilterFunc, private:GetCurrentAuctionSTItem())
	else
		auctionsST:Clear()
	end
	auctionsST:SetDisabled(false)
end

function private:UpdateLogSTData()
	wipe(private.logSTCache)
	local rows = {}
	for i, record in ipairs(TSM.Log:GetData()) do
		local row
		if private.scanFrame.content.logST.cache[record] then
			row = private.scanFrame.content.logST.cache[record]
		else
			local name = TSMAPI.Item:GetName(record.itemString)
			local link = TSMAPI.Item:GetLink(record.itemString)
			local lowestAuction = {}
			local shownBuyout = nil
			if not TSM.Log:IsNoScanReason(record.mode, record.reason) then
				lowestAuction = TSM.Scan:GetLowestAuction(record.itemString, record.operation) or {}
				shownBuyout = TSM.db.global.priceColumn == 1 and record.buyout or lowestAuction.buyout
			end

			local sellerText
			if lowestAuction.seller then
				if lowestAuction.isPlayer then
					sellerText = "|cffffff00"..lowestAuction.seller.."|r"
				elseif lowestAuction.isWhitelist then
					sellerText = TSMAPI.Design:GetInlineColor("link2")..lowestAuction.seller.."|r"
				else
					sellerText = "|cffffffff"..lowestAuction.seller.."|r"
				end
			else
				sellerText = "|cffffffff---|r"
			end

			local color = TSM.Log:GetColor(record.mode, record.reason)
			local infoText = (color or "|cffffffff")..(record.info or "---").."|r"

			row = {
				cols = {
					{
						value = link,
						sortArg = name or "",
					},
					{
						value = record.operation and TSM.operationNameLookup[record.operation] or "---",
						sortArg = record.operation and TSM.operationNameLookup[record.operation] or "---",
					},
					{
						value = TSMAPI:MoneyToString(shownBuyout, "OPT_PAD") or "---",
						sortArg = shownBuyout or 0,
					},
					{
						value = sellerText,
						sortArg = lowestAuction.seller or "~",
					},
					{
						value = infoText,
						sortArg = record.info or "~",
					},
					{ -- invisible column at the end for default sorting
						value = "",
						sortArg = i,
					},
				},
				link = link or name or record.itemString,
				itemString = record.itemString,
				operation = record.operation,
				buyout = shownBuyout,
				lowestBuyout = lowestAuction.buyout,
				seller = lowestAuction.seller,
				info = infoText,
			}

			private.scanFrame.content.logST.cache[record] = row
		end
		tinsert(rows, row)
	end
	private.scanFrame.content.logST:SetData(rows)

	if #private.scanFrame.content.logST.rowData > private.scanFrame.content.logST:GetNumRows() then
		TSMAPI.Delay:AfterFrame("logSTOffset", 2, function() private.scanFrame.content.logST:SetScrollOffset(#private.scanFrame.content.logST.rowData - private.scanFrame.content.logST:GetNumRows()) end)
	end
end

function private:UpdateLogSTHighlight(currentItem)
	if not currentItem then return private.scanFrame.content.logST:SetHighlighted() end

	if not next(private.logSTCache) then
		for i, data in ipairs(private.scanFrame.content.logST.rowData) do
			private.logSTCache[data.itemString.."@"..tostring(data.operation)] = i
			if data.operation == currentItem.operation and data.itemString == currentItem.itemString then
			end
		end
	end
	local index = private.logSTCache[currentItem.itemString.."@"..tostring(currentItem.operation)]
	if index then
		private.scanFrame.content.logST:SetHighlighted(index)
	end
end

function private:SetGoldText()
	local total = 0
	local incomingTotal = 0
	for i = 1, GetNumAuctionItems("owner") do
		local count, buyoutAmount = TSMAPI.Util:Select({3, 10}, GetAuctionItemInfo("owner", i))
		total = total + buyoutAmount
		if count == 0 then
			incomingTotal = incomingTotal + buyoutAmount
		end
	end
	local text = format(L["Done Posting\n\nTotal value of your auctions: %s\nIncoming Gold: %s"], TSMAPI:MoneyToString(total, "OPT_ICON"), TSMAPI:MoneyToString(incomingTotal, "OPT_ICON"))
	GUI:SetInfo(text)
end

function private:StartScan(frame, mode, options)
	private.mode = mode
	private.selectionFrame:Hide()
	private:CreateScanFrame(frame)
	private.scanFrame:Show()
	private.scanFrame.content.statusBar:Show()
	private.scanFrame.actionButtonsFrame:Show()
	GUI:SetButtonsEnabled(false)
	private.scanFrame.actionButtonsFrame.stop:Show()
	private.scanFrame.actionButtonsFrame.restart:Hide()
	private.scanFrame.contentButtonsFrame:Show()
	private.scanFrame.infoTextFrame:Show()
	private.scanFrame.contentButtonsFrame.logButton:Click()
	private.scanFrame.content.auctionsST:Clear()
	private.scanFrame.content.logST:EnableSorting(true, 6) -- reset sorting
	private.scanFrame.content.logST:SetData({})
	private.scanFrame.content.logST.cache = {}
	private:UpdateScanMode()

	if private.mode == "Reset" then
		private.scanFrame.actionButtonsFrame:Hide()
		private.scanFrame.contentButtonsFrame:Hide()
		private.scanFrame.content.auctionsST:Hide()
		private.scanFrame.content.logST:Hide()
		TSM.Reset:Show(frame)
	end

	local isGroup = false
	if not options then
		-- it's a group scan
		isGroup = true
		options = {}
		for groupName, data in pairs(private.selectionFrame.groupTree:GetSelectedGroupInfo()) do
			groupName = TSMAPI.Groups:FormatPath(groupName, true)
			for _, opName in ipairs(data.operations) do
				TSMAPI.Operations:Update("Auctioning", opName)
				local opSettings = TSM.operations[opName]
				if not opSettings then
					-- operation doesn't exist anymore in Auctioning
					TSM:Printf(L["'%s' has an Auctioning operation of '%s' which no longer exists. Auctioning will ignore this group until this is fixed."], groupName, opName)
				else
					-- it's a valid operation
					TSM.operationNameLookup[opSettings] = opName
					for itemString in pairs(data.items) do
						options[itemString] = options[itemString] or {}
						tinsert(options[itemString], opSettings)
					end
				end
			end
		end
	end

	TSM.Log:Clear()
	TSM.Scan:Clear()
	GUI:UpdateSTData()
	TSMAPI.Delay:AfterTime(0, function() TSM.Manage:StartScan(options, private.mode, isGroup) end)
end

function private:DoCallback(...)
	if private.scanThreadId then
		TSMAPI.Threading:SendMsg(private.scanThreadId, {...}, true)
	end
end

function private:DoCallbackAsync(...)
	if private.scanThreadId then
		TSMAPI.Threading:SendMsg(private.scanThreadId, {...})
	end
end



function GUI:ShowSelectionFrame(frame)
	if private.scanFrame then private.scanFrame:Hide() end
	private:CreateSelectionFrame(frame)
	private.selectionFrame:Show()
end

function GUI:HideSelectionFrame()
	private.selectionFrame:Hide()
	if private.scanFrame then private.scanFrame:Hide() end
	TSM.Manage:StopScan()
	TSM.Reset:Hide()
end

function GUI:SetStatusBar(text, major, minor)
	if text then
		private.scanFrame.content.statusBar:SetStatusText(text)
	end
	if major or minor then
		private.scanFrame.content.statusBar:UpdateStatus(major, minor)
	end
end

function GUI:SetInfo(info)
	if not info then return private:UpdateLogSTHighlight() end
	private:UpdateAuctionsSTData()

	if type(info) == "string" then
		private.scanFrame.infoTextFrame.icon:Hide()
		private.scanFrame.infoTextFrame.linkText:Hide()
		private.scanFrame.infoTextFrame.stackText:Hide()
		private.scanFrame.infoTextFrame.bidText:Hide()
		private.scanFrame.infoTextFrame.buyoutText:Hide()
		private.scanFrame.infoTextFrame.quantityText:Hide()
		private.scanFrame.infoTextFrame.statusText:Show()

		local status, _, gold, gold2 = ("\n"):split(info)
		if gold then
			private.scanFrame.infoTextFrame.goldText:Show()
			private.scanFrame.infoTextFrame.goldText2:Show()
			private.scanFrame.infoTextFrame.goldText:SetText(gold)
			private.scanFrame.infoTextFrame.goldText2:SetText(gold2)
		else
			private.scanFrame.infoTextFrame.goldText:Hide()
			private.scanFrame.infoTextFrame.goldText2:Hide()
		end
		private.scanFrame.infoTextFrame.statusText:SetText(status)
	elseif info.isReset then
		private.scanFrame.infoTextFrame.icon:Show()
		private.scanFrame.infoTextFrame.linkText:Show()
		private.scanFrame.infoTextFrame.stackText:Show()
		private.scanFrame.infoTextFrame.bidText:Show()
		private.scanFrame.infoTextFrame.buyoutText:Show()
		private.scanFrame.infoTextFrame.statusText:Hide()
		private.scanFrame.infoTextFrame.goldText:Hide()
		private.scanFrame.infoTextFrame.goldText2:Hide()

		local itemID = TSMAPI.Item:ToItemID(info.itemString)
		local total = TSMAPI.Inventory:GetTotalQuantity(info.itemString)
		private.scanFrame.infoTextFrame.quantityText:Show()
		private.scanFrame.infoTextFrame.quantityText:SetText(TSMAPI.Design:GetInlineColor("link")..L["Currently Owned:"].."|r "..total)

		local link = TSMAPI.Item:GetLink(info.itemString)
		private.scanFrame.infoTextFrame.linkText:SetText(link)
		if private.scanFrame.infoTextFrame.linkText:GetFontString():GetStringWidth() > 200 then
			private.scanFrame.infoTextFrame.linkText:SetWidth(200)
		else
			private.scanFrame.infoTextFrame.linkText:SetWidth(private.scanFrame.infoTextFrame.linkText:GetFontString():GetStringWidth())
		end
		private.scanFrame.infoTextFrame.icon.link = link
		private.scanFrame.infoTextFrame.icon:SetTexture(TSMAPI.Item:GetTexture(info.itemString))
		private.scanFrame.infoTextFrame.stackText:SetText(format(L["%s item(s) to buy/cancel"], info.num..TSMAPI.Design:GetInlineColor("link")))
		private.scanFrame.infoTextFrame.bidText:SetText(TSMAPI.Design:GetInlineColor("link")..L["Target Price:"].."|r "..TSMAPI:MoneyToString(info.targetPrice, "OPT_ICON"))
		private.scanFrame.infoTextFrame.buyoutText:SetText(TSMAPI.Design:GetInlineColor("link")..L["Profit:"].."|r "..TSMAPI:MoneyToString(info.profit, "OPT_ICON"))
	else
		private.scanFrame.infoTextFrame.icon:Show()
		private.scanFrame.infoTextFrame.linkText:Show()
		private.scanFrame.infoTextFrame.stackText:Show()
		private.scanFrame.infoTextFrame.bidText:Show()
		private.scanFrame.infoTextFrame.buyoutText:Show()
		private.scanFrame.infoTextFrame.statusText:Hide()
		private.scanFrame.infoTextFrame.quantityText:Hide()
		private.scanFrame.infoTextFrame.goldText:Hide()
		private.scanFrame.infoTextFrame.goldText2:Hide()

		local link = TSMAPI.Item:GetLink(info.itemString)
		private.scanFrame.infoTextFrame.linkText:SetText(link)
		if private.scanFrame.infoTextFrame.linkText:GetFontString():GetStringWidth() > 200 then
			private.scanFrame.infoTextFrame.linkText:SetWidth(200)
		else
			private.scanFrame.infoTextFrame.linkText:SetWidth(private.scanFrame.infoTextFrame.linkText:GetFontString():GetStringWidth())
		end
		private.scanFrame.infoTextFrame.icon.link = link
		private.scanFrame.infoTextFrame.icon:SetTexture(TSMAPI.Item:GetTexture(info.itemString))

		local sText = format("%s "..TSMAPI.Design:GetInlineColor("link")..L["auctions of|r %s"], info.numStacks, info.stackSize)
		private.scanFrame.infoTextFrame.stackText:SetText(sText)

		private.scanFrame.infoTextFrame.bidText:SetText(TSMAPI.Design:GetInlineColor("link")..BID..":|r "..TSMAPI:MoneyToString(info.bid, "OPT_ICON"))
		private.scanFrame.infoTextFrame.buyoutText:SetText(TSMAPI.Design:GetInlineColor("link")..BUYOUT..":|r "..TSMAPI:MoneyToString(info.buyout, "OPT_ICON"))

		private.scanFrame.contentButtonsFrame.editPriceButton:Enable()
		private.scanFrame.editPriceFrame.itemString = info.itemString
		private.scanFrame.editPriceFrame.info = {itemString=info.itemString, link=link, buyout=info.buyout, operation=info.operation}

		TSMAPI.Delay:AfterFrame(2, function() private:UpdateLogSTHighlight(TSM.Manage:GetCurrentItem()) end)
	end
end

function GUI:SetButtonsEnabled(enabled)
	if private.mode == "Post" then
		private.scanFrame.actionButtonsFrame.post:SetDisabled(not enabled)
	elseif private.mode == "Cancel" then
		private.scanFrame.actionButtonsFrame.cancel:SetDisabled(not enabled)
	end
	private.scanFrame.actionButtonsFrame.skip:SetDisabled(not enabled)
end

function GUI:UpdateSTData()
	private:UpdateLogSTData()
	private:UpdateAuctionsSTData()
end

function GUI:Stopped(notDone)
	if not private.scanFrame or not private.scanFrame.actionButtonsFrame then return end
	GUI:SetButtonsEnabled(false)
	private.scanFrame.content.statusBar:UpdateStatus(100, 100)
	private.scanFrame.contentButtonsFrame.currAuctionsButton:Hide()

	if private.mode == "Post" then
		TSMAPI.Delay:AfterTime(0.5, private.SetGoldText)
		private.SetGoldText()
		private.scanFrame.content.statusBar:SetStatusText(L["Post Scan Finished"])
	elseif private.mode == "Cancel" then
		GUI:SetInfo(L["Done Canceling"])
		private.scanFrame.content.statusBar:SetStatusText(L["Cancel Scan Finished"])
	elseif private.mode == "Reset" then
		if not notDone then
			GUI:SetInfo(L["No Items to Reset"])
		end
		private.scanFrame.content.statusBar:SetStatusText(L["Reset Scan Finished"])
	end
	private.scanFrame.actionButtonsFrame.stop:Hide()
	private.scanFrame.actionButtonsFrame.restart:Show()
end

function GUI:SetScanThreadId(threadId)
	private.scanThreadId = threadId
end
