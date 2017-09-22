-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local AuctionTabFrame = TSM:NewModule("AuctionTabFrame")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table
local private = nil
local frameFunctions = {}


function AuctionTabFrame:SetPrivate(tbl)
	private = tbl
end

function AuctionTabFrame:Create(parent)
	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		parent = parent,
		points = "ALL",
		scripts = {"OnShow"},
		children = {
			{
				type = "Frame",
				key = "content",
				points = {{"TOPLEFT", parent.content}, {"BOTTOMRIGHT", parent.content}},
				children = {
					{
						type = "Frame",
						points = "ALL",
						key = "result",
						children = {
							{
								type = "AuctionResultsTableFrame",
								key = "rt",
								sortIndex = 9,
								points = "ALL",
								scripts = {"OnSelectionChanged"},
							},
							{
								type = "StatusBarFrame",
								key = "statusBar",
								name = "TSMShoppingStatusBar",
								size = {265, 30},
								points = {{"TOPLEFT", BFC.PARENT, "BOTTOMLEFT", 165, -3}},
							},
							{
								type = "Button",
								key = "cancelBtn",
								name = "TSMShoppingCancelButton",
								text = CANCEL,
								textHeight = 20,
								size = {80, 24},
								points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 3, -3}},
								scripts = {"OnClick"},
							},
							{
								type = "Button",
								key = "postBtn",
								name = "TSMShoppingPostButton",
								text = L["Post"],
								textHeight = 20,
								size = {80, 24},
								points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 3, 0}},
								scripts = {"OnClick"},
							},
							{
								type = "Button",
								key = "bidBtn",
								name = "TSMShoppingBidButton",
								text = BID,
								textHeight = 20,
								size = {60, 24},
								points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 3, 0}},
								scripts = {"OnClick"},
							},
							{
								type = "Button",
								key = "buyoutBtn",
								name = "TSMShoppingBuyoutButton",
								text = BUYOUT,
								textHeight = 20,
								size = {80, 24},
								points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 3, 0}},
								scripts = {"OnClick"},
							},
							{
								type = "Frame",
								key = "confirmation",
								mouse = true,
								points = "ALL",
								strata = "DIALOG",
								children = {
									{
										type = "Frame",
										key = "progress",
										size = {250, 150},
										points = {{"CENTER"}},
										children = {
											{
												type = "Text",
												key = "text",
												text = "",
												textHeight = 16,
												justify = {"CENTER", "MIDDLE"},
												points = {{"CENTER"}},
											},
										},
									},
									{
										type = "Frame",
										key = "buyout",
										size = {300, 140},
										points = {{"CENTER"}},
										children = {
											{
												type = "ItemLinkLabel",
												key = "item",
												textHeight = 16,
												points = {{"TOPLEFT", 5, -5}, {"TOPRIGHT", -5, -5}},
											},
											{
												type = "Text",
												text = L["Price Per Item:"],
												textHeight = 14,
												justify = {"LEFT", "MIDDLE"},
												size = {0, 14},
												points = {{"TOPLEFT", 5, -41}},
											},
											{
												type = "Text",
												key = "itemBuyoutText",
												textHeight = 14,
												justify = {"RIGHT", "MIDDLE"},
												points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 2, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 2, 0}, {"TOPRIGHT", -5, -41}},
											},
											{
												type = "Text",
												text = L["Auction Buyout:"],
												textHeight = 14,
												justify = {"LEFT", "MIDDLE"},
												size = {0, 14},
												points = {{"TOPLEFT", 5, -60}},
											},
											{
												type = "Text",
												key = "auctionBuyoutText",
												textHeight = 14,
												justify = {"RIGHT", "MIDDLE"},
												points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 2, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 2, 0}, {"TOPRIGHT", -5, -60}},
											},
											{
												type = "Text",
												text = L["Purchasing Auction:"],
												textHeight = 14,
												justify = {"LEFT", "MIDDLE"},
												size = {0, 14},
												points = {{"TOPLEFT", 5, -80}},
											},
											{
												type = "Text",
												key = "auctionCountText",
												textHeight = 14,
												justify = {"RIGHT", "MIDDLE"},
												points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 2, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 2, 0}, {"TOPRIGHT", -5, -80}},
											},
											{
												type = "Button",
												key = "buyoutBtn",
												name = "TSMShoppingBuyoutConfirmationButton",
												isSecure = true,
												text = BUYOUT,
												textHeight = 18,
												points = {{"TOPLEFT", 5, -110}, {"BOTTOMRIGHT", BFC.PARENT, "BOTTOM", -2, 5}},
												scripts = {"OnClick"},
											},
											{
												type = "Button",
												key = "closeBtn",
												text = CLOSE,
												textHeight = 16,
												points = {{"BOTTOMLEFT", BFC.PARENT, "BOTTOM", 2, 5}, {"TOPRIGHT", -5, -110}},
												scripts = {"OnClick"},
											},
										},
									},
									{
										type = "Frame",
										key = "post",
										size = {275, 250},
										points = {{"CENTER"}},
										children = {
											{
												type = "ItemLinkLabel",
												key = "item",
												textHeight = 16,
												points = {{"TOPLEFT", 5, -5}, {"TOPRIGHT", -5, -5}},
											},
											{
												type = "HLine",
												offset = -30,
											},
											{
												type = "Dropdown",
												key = "modeDropdown",
												value = 2,
												list = {L["Auction Buyout"], L["Item Buyout"]},
												size = {140, 25},
												points = {{"TOPLEFT", 5, -40}},
												scripts = {"OnValueChanged"},
											},
											{
												type = "Text",
												text = ":",
												textHeight = 14,
												justify = {"LEFT", "MIDDLE"},
												size = {0, 25},
												points = {{"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT"}},
											},
											{
												type = "InputBox",
												key = "buyoutBox",
												justify = {"RIGHT", "MIDDLE"},
												points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}, {"TOPRIGHT", "item", "BOTTOMRIGHT", 0, -40}},
												scripts = {"OnTextChanged", "OnEnterPressed", "OnEditFocusGained", "OnEditFocusLost"},
											},
											{
												type = "Text",
												key = "stackText",
												text = L["stack(s) of"],
												textHeight = 14,
												justify = {"LEFT", "MIDDLE"},
												size = {0, 25},
												points = {{"TOP", BFC.PARENT, 0, -80}},
											},
											{
												type = "InputBox",
												key = "numStacksBox",
												numeric = true,
												justify = {"CENTER", "MIDDLE"},
												points = {{"TOPLEFT", 15, -80}, {"BOTTOMRIGHT", BFC.PREV, "BOTTOMLEFT", -10, 0}},
												scripts = {"OnTextChanged"},
											},
											{
												type = "InputBox",
												key = "stackSizeBox",
												numeric = true,
												justify = {"CENTER", "MIDDLE"},
												points = {{"BOTTOMLEFT", "stackText", "BOTTOMRIGHT", 10, 0}, {"TOPRIGHT", -15, -80}},
												scripts = {"OnTextChanged"},
											},
											{
												type = "Button",
												key = "numStacksMaxBtn",
												text = MAXIMUM,
												textHeight = 12,
												size = {70, 18},
												points = {{"TOP", "numStacksBox", "BOTTOM", 0, -5}},
												scripts = {"OnClick"},
											},
											{
												type = "Button",
												key = "stackSizeMaxBtn",
												text = MAXIMUM,
												textHeight = 12,
												size = {70, 18},
												points = {{"TOP", "stackSizeBox", "BOTTOM", 0, -5}},
												scripts = {"OnClick"},
											},
											{
												type = "Text",
												text = L["Duration:"],
												textHeight = 14,
												size = {0, 25},
												points = {{"TOPLEFT", 5, -145}},
											},
											{
												type = "Dropdown",
												key = "durationDropdown",
												value = 2,
												list = {AUCTION_DURATION_ONE, AUCTION_DURATION_TWO, AUCTION_DURATION_THREE},
												points = {{"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}, {"TOPRIGHT", 0, -145}},
												scripts = {"OnValueChanged"},
											},
											{
												type = "HLine",
												offset = -175,
											},
											{
												type = "Text",
												text = L["Total Deposit:"],
												textHeight = 13,
												size = {0, 25},
												points = {{"TOPLEFT", 5, -180}},
											},
											{
												type = "Text",
												key = "depositText",
												text = "---",
												textHeight = 13,
												justify = {"RIGHT", "MIDDLE"},
												points = {{"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}, {"TOPRIGHT", -5, -180}}
											},
											{
												type = "HLine",
												offset = -210,
											},
											{
												type = "Button",
												key = "postBtn",
												name = "TSMShoppingPostConfirmationButton",
												isSecure = true,
												text = CREATE_AUCTION,
												textHeight = 18,
												size = {0, 25},
												points = {{"BOTTOMLEFT", 5, 5}, {"BOTTOMRIGHT", BFC.PARENT, "BOTTOM", -2, 5}},
												scripts = {"OnClick"},
											},
											{
												type = "Button",
												key = "closeBtn",
												text = CLOSE,
												textHeight = 16,
												size = {0, 25},
												points = {{"BOTTOMLEFT", BFC.PARENT, "BOTTOM", 2, 5}, {"BOTTOMRIGHT", -5, 5}},
												scripts = {"OnClick"},
											},
										},
									},
									{
										type = "Frame",
										key = "cancel",
										size = {300, 90},
										points = {{"CENTER"}},
										children = {
											{
												type = "ItemLinkLabel",
												key = "item",
												textHeight = 16,
												points = {{"TOPLEFT", 5, -5}, {"TOPRIGHT", -5, -5}},
											},
											{
												type = "Text",
												text = L["Canceling Auction:"],
												textHeight = 14,
												justify = {"LEFT", "MIDDLE"},
												size = {0, 14},
												points = {{"TOPLEFT", 5, -35}},
											},
											{
												type = "Text",
												key = "auctionCountText",
												textHeight = 14,
												justify = {"RIGHT", "MIDDLE"},
												points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 2, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 2, 0}, {"TOPRIGHT", -5, -35}},
											},
											{
												type = "Button",
												key = "cancelBtn",
												name = "TSMShoppingCancelConfirmationButton",
												isSecure = true,
												text = CANCEL,
												textHeight = 18,
												size = {0, 25},
												points = {{"BOTTOMLEFT", 5, 5}, {"BOTTOMRIGHT", BFC.PARENT, "BOTTOM", -2, 5}},
												scripts = {"OnClick"},
											},
											{
												type = "Button",
												key = "closeBtn",
												text = CLOSE,
												textHeight = 16,
												size = {0, 25},
												points = {{"BOTTOMLEFT", BFC.PARENT, "BOTTOM", 2, 5}, {"BOTTOMRIGHT", -5, 5}},
												scripts = {"OnClick"},
											},
										},
									},
									{
										type = "Frame",
										key = "bid",
										size = {300, 160},
										points = {{"CENTER"}},
										children = {
											{
												type = "ItemLinkLabel",
												key = "item",
												textHeight = 16,
												points = {{"TOPLEFT", 5, -5}, {"TOPRIGHT", -5, -5}},
											},
											{
												type = "HLine",
												offset = -30,
											},
											{
												type = "Text",
												text = L["Minimum Bid:"],
												textHeight = 13,
												size = {0, 15},
												points = {{"TOPLEFT", 5, -35}},
											},
											{
												type = "Text",
												key = "minBidText",
												text = "---",
												textHeight = 13,
												justify = {"RIGHT", "MIDDLE"},
												points = {{"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}, {"TOPRIGHT", -5, -35}}
											},
											{
												type = "Text",
												text = L["Auction Buyout:"],
												textHeight = 13,
												size = {0, 25},
												points = {{"TOPLEFT", 5, -55}},
											},
											{
												type = "Text",
												key = "buyoutText",
												text = "---",
												textHeight = 13,
												justify = {"RIGHT", "MIDDLE"},
												points = {{"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}, {"TOPRIGHT", -5, -55}}
											},
											{
												type = "HLine",
												offset = -80,
											},
											{
												type = "Text",
												text = L["Auction Bid:"],
												textHeight = 14,
												justify = {"LEFT", "MIDDLE"},
												size = {0, 25},
												points = {{"TOPLEFT", 5, -90}},
											},
											{
												type = "InputBox",
												key = "bidBox",
												justify = {"RIGHT", "MIDDLE"},
												points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}, {"TOPRIGHT", -5, -90}},
												scripts = {"OnTextChanged", "OnEnterPressed", "OnEditFocusGained", "OnEditFocusLost"},
											},
											{
												type = "HLine",
												offset = -150,
											},
											{
												type = "Button",
												key = "bidBtn",
												name = "TSMShoppingBidConfirmationButton",
												isSecure = true,
												text = BID,
												textHeight = 18,
												size = {0, 25},
												points = {{"BOTTOMLEFT", 5, 5}, {"BOTTOMRIGHT", BFC.PARENT, "BOTTOM", -2, 5}},
												scripts = {"OnClick"},
											},
											{
												type = "Button",
												key = "closeBtn",
												text = CLOSE,
												textHeight = 16,
												size = {0, 25},
												points = {{"BOTTOMLEFT", BFC.PARENT, "BOTTOM", 2, 5}, {"BOTTOMRIGHT", -5, 5}},
												scripts = {"OnClick"},
											},
										},
									},
								},
							},
						},
					},
					TSM.AuctionTabSaved:GetFrameInfo(),
					TSM.AuctionTabOther:GetFrameInfo(),
				},
			},
			{
				type = "VLine",
				size = {2, 80},
				points = {{"TOPLEFT", 80, 0}},
			},
			{
				type = "Frame",
				key = "header",
				points = {{"TOPLEFT", 80, -5}, {"BOTTOMRIGHT", "content", "TOPRIGHT", 3, 0}},
				children = {
					{
						type = "Frame",
						key = "modeBtns",
						size = {250, 25},
						points = {{"TOPLEFT", 10, -3}},
						children = {
							{
								type = "Text",
								text = L["Search Mode:"],
								textHeight = 16,
								justify = {"RIGHT", "MIDDLE"},
								size = {95, 0},
								points = {{"TOPLEFT"}, {"BOTTOMLEFT"}}
							},
							{
								type = "Button",
								key = "normal",
								text = L["Normal"],
								textHeight = 18,
								tooltip = L["When in normal mode, you may run simple and filtered searches of the auction house."],
								size = {70, 22},
								points = {{"LEFT", BFC.PREV, "RIGHT", 4, 0}},
								scripts = {"OnClick"},
							},
							{
								type = "Button",
								key = "crafting",
								text = "Crafting",
								textHeight = 18,
								tooltip = L["When in crafting mode, the search results will include materials which can be used to craft the item which you search for. This includes milling, prospecting, and disenchanting."],
								size = {0, 22},
								points = {{"LEFT", BFC.PREV, "RIGHT", 4, 0}, {"RIGHT"}},
								scripts = {"OnClick"},
							},
						},
					},
					{
						type = "VLine",
						size = {2, 40},
						points = {{"LEFT", "modeBtns", "RIGHT", 4, 0}},
					},
					{
						type = "InputBox",
						key = "searchBox",
						size = {405, 25},
						points = {{"LEFT", "modeBtns", "RIGHT", 10, 0}},
						scripts = {"OnEnterPressed", "OnChar", "OnEditFocusGained", "OnEditFocusLost", "OnEnter", "OnLeave", "OnUpdate"},
					},
					{
						type = "Button",
						key = "searchBtn",
						text = SEARCH,
						textHeight = 22,
						size = {0, 25},
						points = {{"TOPLEFT", "searchBox", "TOPRIGHT", 4, 0}, {"TOPRIGHT", -5, -3}},
						scripts = {"OnClick"},
					},
					{
						type = "HLine",
						offset = -35,
					},
					{
						type = "Frame",
						key = "tabBtns",
						size = {0, 21},
						points = {{"BOTTOMLEFT", 10, 8}, {"BOTTOMRIGHT", -10, 8}},
						children = {
							{
								type = "Button",
								key = "result",
								text = L["Search Results"],
								textHeight = 18,
								size = {155, 0},
								points = {{"TOPLEFT"}, {"BOTTOMLEFT"}},
								scripts = {"OnClick"},
							},
							{
								type = "Button",
								key = "saved",
								text = L["Saved Searches / TSM Groups"],
								textHeight = 18,
								size = {280, 0},
								points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}},
								scripts = {"OnClick"},
							},
							{
								type = "Button",
								key = "other",
								text = L["Custom Filter / Other Searches"],
								textHeight = 18,
								size = {285, 0},
								points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}},
								scripts = {"OnClick"},
							},
						},
					},
				},
			},
		},
		handlers = {
			OnShow = function(self) if not private.searchInProgress then private.frame.header.searchBox:SetFocus() end end,
			content = {
				result = {
					rt = {
						OnSelectionChanged = function(_, data) TSMAPI.Threading:SendMsg(private.threadId, {"RESULT_ROW_SELECTED", data}) end,
					},
					cancelBtn = {
						OnClick = function(self) self:Disable() TSMAPI.Threading:SendMsg(private.threadId, {"SHOW_CONFIRMATION", "cancel"}) end,
					},
					postBtn = {
						OnClick = function(self) self:Disable() TSMAPI.Threading:SendMsg(private.threadId, {"SHOW_CONFIRMATION", "post"}) end,
					},
					bidBtn = {
						OnClick = function(self) self:Disable() TSMAPI.Threading:SendMsg(private.threadId, {"SHOW_CONFIRMATION", "bid"}) end,
					},
					buyoutBtn = {
						OnClick = function(self) self:Disable() TSMAPI.Threading:SendMsg(private.threadId, {"SHOW_CONFIRMATION", "buyout"}) end,
					},
					confirmation = {
						buyout = {
							buyoutBtn = {
								OnClick = function() if TSMAPI.Util:UseHardwareEvent() then TSMAPI.Threading:SendMsg(private.threadId, {"AUCTION_CONFIRMED", true}, true) end end,
							},
							closeBtn = {
								OnClick = function() TSMAPI.Threading:SendMsg(private.threadId, {"AUCTION_CONFIRMED", false}) end,
							},
						},
						post = {
							modeDropdown = {
								OnValueChanged = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION"}) end,
							},
							durationDropdown = {
								OnValueChanged = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION"}) end,
							},
							buyoutBox = {
								OnTextChanged = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION", "buyout"}) end,
								OnEnterPressed = "ClearFocus",
								OnEditFocusGained = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION"}) end,
								OnEditFocusLost = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION"}) end,
							},
							numStacksBox = {
								OnTextChanged = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION"}) end,
							},
							stackSizeBox = {
								OnTextChanged = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION"}) end,
							},
							numStacksMaxBtn = {
								OnClick = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION", "numStacksMax"}) end,
							},
							stackSizeMaxBtn = {
								OnClick = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION", "stackSizeMax"}) end,
							},
							postBtn = {
								OnClick = function() if TSMAPI.Util:UseHardwareEvent() then TSMAPI.Threading:SendMsg(private.threadId, {"AUCTION_CONFIRMED", true}, true) end end,
							},
							closeBtn = {
								OnClick = function() TSMAPI.Threading:SendMsg(private.threadId, {"AUCTION_CONFIRMED", false}) end,
							},
						},
						cancel = {
							cancelBtn = {
								OnClick = function() if TSMAPI.Util:UseHardwareEvent() then TSMAPI.Threading:SendMsg(private.threadId, {"AUCTION_CONFIRMED", true}, true) end end,
							},
							closeBtn = {
								OnClick = function() TSMAPI.Threading:SendMsg(private.threadId, {"AUCTION_CONFIRMED", false}) end,
							},
						},
						bid = {
							bidBox = {
								OnTextChanged = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION", "bid"}) end,
								OnEnterPressed = "ClearFocus",
								OnEditFocusGained = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION"}) end,
								OnEditFocusLost = function() TSMAPI.Threading:SendMsg(private.threadId, {"UPDATE_CONFIRMATION"}) end,
							},
							bidBtn = {
								OnClick = function() if TSMAPI.Util:UseHardwareEvent() then TSMAPI.Threading:SendMsg(private.threadId, {"AUCTION_CONFIRMED", true}, true) end end,
							},
							closeBtn = {
								OnClick = function() TSMAPI.Threading:SendMsg(private.threadId, {"AUCTION_CONFIRMED", false}) end,
							},
						},
					},
				},
			},
			header = {
				searchBox = {
					OnEnterPressed = function(self) self:GetParent().searchBtn:Click() end,
					OnChar = function(self)
						local text = strlower(self:GetText())
						local textLen = #text
						if private.searchMode == "normal" then
							for _, data in ipairs(TSM.db.global.savedSearches) do
								if data.searchMode == "normal" then
									local prevSearch = strlower(data.filter)
									if strsub(prevSearch, 1, textLen) == text then
										self:SetText(prevSearch)
										self:HighlightText(textLen, -1)
										break
									end
								end
							end
						elseif private.searchMode == "crafting" then
							local itemNames = nil
							if private.craftingItemNames then
								itemNames = private.craftingItemNames
							else
								local resultIsComplete = nil
								itemNames, resultIsComplete = TSMAPI.Conversions:GetTargetItemNames()
								if resultIsComplete then
									private.craftingItemNames = itemNames
								end
							end
							-- do a binary search for the auto-complete match
							local low, mid, high = 1, 0, #itemNames
							while low <= high do
								mid = floor((low + high) / 2)
								local midValue = strsub(itemNames[mid], 1, textLen)
								if midValue == text then
									self:SetText(itemNames[mid])
									self:HighlightText(textLen, -1)
									break
								elseif text < midValue then
									high = mid - 1
								else
									low = mid + 1
								end
							end
						end
					end,
					OnEditFocusGained = "HighlightText",
					OnEditFocusLost = "HighlightText",
					OnEnter = function(self)
						GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
						GameTooltip:SetMinimumWidth(400)
						GameTooltip:AddLine(L["Enter what you want to search for in this box. You can also use the following options for more complicated searches."].."\n", 1, 1, 1, 1)
						GameTooltip:AddLine(format("|cffffff00"..L["Multiple Search Terms:|r You can search for multiple things at once by simply separated them with a ';'. For example '%selementium ore; obsidium ore|r' will search for both elementium and obsidium ore."].."\n", TSMAPI.Design:GetInlineColor("link2")), 1, 1, 1, 1)
						GameTooltip:AddLine(format("|cffffff00"..L["Inline Filters:|r You can easily add common search filters to your search such as rarity, level, and item type. For example '%sarmor/leather/epic/85/i350/i377|r' will search for all leather armor of epic quality that requires level 85 and has an ilvl between 350 and 377 inclusive. Also, '%sinferno ruby/exact|r' will display only raw inferno rubys (none of the cuts)."].."\n", TSMAPI.Design:GetInlineColor("link2"), TSMAPI.Design:GetInlineColor("link2")), 1, 1, 1, 1)
						GameTooltip:Show()
					end,
					OnLeave = function() GameTooltip:Hide() end,
					OnUpdate = function(self)
						if not self:IsEnabled() then return end
						if not TSMAPI.Auction:IsTabVisible("Shopping") then
							self:ClearFocus()
						elseif strmatch(self:GetText(), "^~") then
							-- clear text if it starts with a "~" as that indicates a special search
							self:SetText("")
						end
					end,
				},
				searchBtn = {
					OnClick = function(self)
						if private.searchInProgress then
							TSMAPI.Threading:SendMsg(private.threadId, {"STOP_SCAN"})
						elseif self.continueCallback and IsShiftKeyDown() then
							self.continueCallback()
						else
							local text = self:GetParent().searchBox:GetText()
							if text == "" then
								return TSM:Print(L["You must enter a search filter before starting the search."])
							end
							TSM.AuctionTab:StartSearch({searchMode=private.searchMode, extraInfo={searchType="filter"}, filter=text})
						end
					end,
				},
				modeBtns = {
					normal = {
						OnClick = frameFunctions.UpdateSearchMode,
					},
					crafting = {
						OnClick = frameFunctions.UpdateSearchMode,
					},
				},
				tabBtns = {
					result = {
						OnClick = frameFunctions.UpdateCurrentTab,
					},
					saved = {
						OnClick = frameFunctions.UpdateCurrentTab,
					},
					other = {
						OnClick = frameFunctions.UpdateCurrentTab,
					},
				},
			},
		},
	}

	private.frame = TSMAPI.GUI:BuildFrame(frameInfo)

	for key, func in pairs(frameFunctions) do
		private.frame[key] = func
	end

	local helpPlateInfo = {
		FramePos = {x = 5, y = -5},
		FrameSize = {width = private.frame:GetWidth(), height = private.frame:GetHeight()},
		{
			ButtonPos = {x = 200, y = 5},
			HighLightBox = {x = 80, y = 5, width = 260, height = 40},
			ToolTipDir = "DOWN",
			ToolTipText = L["You can change the search mode here. Crafting mode will include items which can be crafted into the specific items (through professions, milling, prospecting, disenchanting, and more) in the search."]
		},
		{
			ButtonPos = {x = 480, y = 5},
			HighLightBox = {x = 340, y = 2, width = 485, height = 35},
			ToolTipDir = "DOWN",
			ToolTipText = L["You can type search filters into the search bar and click on the 'SEARCH' button to quickly search the auction house. Refer to the tooltip of the search bar for details on more advanced filters."]
		},
		{
			ButtonPos = {x = 350, y = -35},
			HighLightBox = {x = 80, y = -35, width = 745, height = 40},
			ToolTipDir = "DOWN",
			ToolTipText = L["Use these buttons to change what is shown below."]
		},
		{
			ButtonPos = {x = 400, y = -200},
			HighLightBox = {x = 0, y = -75, width = 825, height = 330},
			ToolTipDir = "RIGHT",
			ToolTipText = L["This is the main content area which will change depending on which button is selected above."]
		},
	}

	local mainHelpBtn = CreateFrame("Button", nil, private.frame, "MainHelpPlateButton")
	mainHelpBtn:SetPoint("TOPLEFT", private.frame, 50, 35)
	mainHelpBtn:SetScript("OnClick", function() frameFunctions:ToggleHelpPlate(private.frame, helpPlateInfo, mainHelpBtn, true) end)
	mainHelpBtn:SetScript("OnHide", function() if HelpPlate_IsShowing(helpPlateInfo) then frameFunctions:ToggleHelpPlate(private.frame, helpPlateInfo, mainHelpBtn, false) end end)

	if not TSM.db.global.helpPlatesShown.auction then
		TSM.db.global.helpPlatesShown.auction = true
		frameFunctions:ToggleHelpPlate(private.frame, helpPlateInfo, mainHelpBtn, false)
	end
end

function frameFunctions:ToggleHelpPlate(frame, info, btn, isUser)
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



-- ============================================================================
-- Results Table Price Functions
-- ============================================================================

local rtPriceInfoDefaults = {
	normal = {
		headers = {{L["Auction Bid\n(per item)"], L["Auction Bid\n(per stack)"]}, {L["Auction Buyout\n(per item)"], L["Auction Buyout\n(per stack)"]}},
		defaultPctHeader = L["% Market Value"],
		apiGatheringPctHeader = L["% Mat Price"],
		groupPctHeader = L["% Max Price"],
		vendorPctHeader = L["% Vendor Value"],
		disenchantPctHeader = L["% DE Value"],
		GetRowPrices = function(record, isPerItem)
			if isPerItem then
				return record.itemDisplayedBid, record.itemBuyout, record.isHighBidder and "|cffffff00" or nil
			else
				return record.displayedBid, record.buyout, record.isHighBidder and "|cff00ff00" or nil
			end
		end,
		DefaultGetMarketValue = function(itemString)
			return TSMAPI:GetCustomPriceValue(TSM.db.global.marketValueSource, itemString) or 0
		end,
		APIGatheringGetMarketValue = function(itemString)
			return TSMAPI:GetItemValue(itemString, "matPrice") or 0
		end,
		GroupGetMarketValue = function(itemString)
			itemString = private.extraInfo.itemOperations[itemString] and itemString or TSMAPI.Item:ToBaseItemString(itemString)
			return TSMAPI:GetCustomPriceValue(private.extraInfo.itemOperations[itemString].maxPrice, itemString) or 0
		end,
		VendorGetMarketValue = function(itemString)
			return TSMAPI.Item:GetVendorPrice(itemString) or 0
		end,
		DisenchantGetMarketValue = function(itemString)
			return TSMAPI.Conversions:GetValue(itemString, TSM.db.global.marketValueSource, "disenchant")
		end,
	},
	crafting = {
		headers = {{L["Auction Buyout\n(per item)"], L["Auction Buyout\n(per stack)"]}, {L["Target Price\n(per item)"], L["Target Price\n(per stack)"]}},
		defaultPctHeader = L["% Target Value"],
		apiGatheringPctHeader = L["% Mat Price"],
		GetRowPrices = function(record, isPerItem)
			local rate = TSM.AuctionTabUtil:GetConvertRate(private.targetItem, record.itemString, record)
			if isPerItem then
				return record.itemBuyout, record.itemBuyout/rate
			else
				return record.buyout, record.buyout/rate
			end
		end,
		DefaultGetMarketValue = function(itemString)
			local rate = TSM.AuctionTabUtil:GetConvertRate(private.targetItem, itemString)
			-- the rate represents how many of the target item 1 of this item will craft into
			-- so, the "market" value for this item is the market value of the target item multiplied by the rate
			return (TSMAPI:GetCustomPriceValue(TSM.db.global.marketValueSource, private.targetItem) or 0) * rate
		end,
		APIGatheringGetMarketValue = function(itemString)
			local rate = TSM.AuctionTabUtil:GetConvertRate(private.targetItem, itemString)
			-- the rate represents how many of the target item 1 of this item will craft into
			-- so, the "mat price" for this item is the mat price of the target item multiplied by the rate
			return (TSMAPI:GetItemValue(private.targetItem, "matPrice") or 0) * rate
		end,
	},
}



-- ============================================================================
-- Functions to be set on private.frame
-- ============================================================================

function frameFunctions.UpdateCurrentTab(tab)
	if type(tab) == "table" then
		-- new tab specified by button (OnClick handler)
		for name, btn in pairs(private.frame.header.tabBtns) do
			if btn == tab then
				tab = name
				break
			end
		end
	end
	TSMAPI:Assert(type(tab) == "string")

	-- set button highlights
	for name, btn in pairs(private.frame.header.tabBtns) do
		if type(btn) == "table" and btn.tsmFrameType == "Button" then
			if name == tab then
				btn:LockHighlight()
			else
				btn:UnlockHighlight()
			end
		end
	end

	-- set content frame visibility
	for name, frame in pairs(private.frame.content) do
		if type(frame) == "table" and frame.tsmFrameType == "Frame" then
			if name == tab then
				frame:Show()
			else
				frame:Hide()
			end
		end
	end
end

function frameFunctions.UpdateSearchMode(mode)
	if private.searchInProgress then return end
	if type(mode) == "table" then
		-- new mode specified by button (OnClick handler)
		for name, btn in pairs(private.frame.header.modeBtns) do
			if btn == mode then
				mode = name
				break
			end
		end
		-- clear the extra info
		private.extraInfo = nil
	end
	TSMAPI:Assert(type(mode) == "string")
	private.searchMode = mode

	-- clear button highlights
	for name, btn in pairs(private.frame.header.modeBtns) do
		if type(btn) == "table" and btn.tsmFrameType == "Button" then
			if name == mode then
				btn:LockHighlight()
			else
				btn:UnlockHighlight()
			end
		end
	end

	-- clear the search bar
	private.frame.header.searchBox:SetText("")
	private.frame.header.searchBox:Enable()

	-- update the results table
	private.frame.content.result.rt:Clear()
	local info = {
		headers = rtPriceInfoDefaults[mode].headers,
		pctHeader = rtPriceInfoDefaults[mode].defaultPctHeader,
		GetRowPrices = rtPriceInfoDefaults[mode].GetRowPrices,
		GetMarketValue = rtPriceInfoDefaults[mode].DefaultGetMarketValue,
	}
	local searchType = private.extraInfo and private.extraInfo.searchType or ""
	if searchType == "apiGathering" then
		info.pctHeader = rtPriceInfoDefaults[mode].apiGatheringPctHeader
		info.GetMarketValue = rtPriceInfoDefaults[mode].APIGatheringGetMarketValue
	elseif searchType == "group" then
		info.pctHeader = rtPriceInfoDefaults[mode].groupPctHeader
		info.GetMarketValue = rtPriceInfoDefaults[mode].GroupGetMarketValue
	elseif searchType == "vendor" then
		info.pctHeader = rtPriceInfoDefaults[mode].vendorPctHeader
		info.GetMarketValue = rtPriceInfoDefaults[mode].VendorGetMarketValue
	elseif searchType == "disenchant" then
		info.pctHeader = rtPriceInfoDefaults[mode].disenchantPctHeader
		info.GetMarketValue = rtPriceInfoDefaults[mode].DisenchantGetMarketValue
	end
	private.frame.content.result.rt:SetPriceInfo(info)
end

function frameFunctions.UpdateSearchInProgress(inProgress, updateStatus)
	local headerFrame = private.frame.header
	headerFrame.searchBtn.continueCallback = nil
	headerFrame.searchBtn.tooltip = nil
	private.searchInProgress = inProgress
	if inProgress then
		-- disable mode buttons which aren't active
		for name, btn in pairs(headerFrame.modeBtns) do
			if type(btn) == "table" and btn.tsmFrameType == "Button" and name ~= private.searchMode then
				btn:Disable()
			end
		end
		-- select result tab and disable tab buttons
		private.frame.UpdateCurrentTab("result")
		for name, btn in pairs(headerFrame.tabBtns) do
			if type(btn) == "table" and btn.tsmFrameType == "Button" and name ~= "result" then
				btn:Disable()
			end
		end
		-- disable search box
		headerFrame.searchBox:Disable()
		headerFrame.searchBox:ClearFocus()
		headerFrame.searchBox:HighlightText(0, 0)
		if private.frame.content.result.confirmation:IsVisible() then
			headerFrame.searchBtn:SetText(SEARCH)
			headerFrame.searchBtn:Disable()
		else
			headerFrame.searchBtn:SetText(L["Stop"])
			headerFrame.searchBtn:Enable()
		end
		-- check if we are just starting a search
		if updateStatus then
			private.frame.content.result.statusBar:SetStatusText(L["Preparing Filters..."])
			private.frame.content.result.statusBar:UpdateStatus(0, 0)
			private.frame.content.result.rt:Clear()
		end
	else
		-- enable mode buttons
		for _, btn in pairs(headerFrame.modeBtns) do
			if type(btn) == "table" and btn.tsmFrameType == "Button" then
				btn:Enable()
			end
		end
		-- enable tab buttons
		for name, btn in pairs(headerFrame.tabBtns) do
			if type(btn) == "table" and btn.tsmFrameType == "Button" then
				btn:Enable()
			end
		end
		-- enable search box
		headerFrame.searchBox:Enable()
		headerFrame.searchBtn:Enable()
		headerFrame.searchBtn:SetText(SEARCH)
		-- check if we are just finishing a search
		if updateStatus then
			private.frame.content.result.statusBar:UpdateStatus(100, 100)
			private.frame.content.result.statusBar:SetStatusText(L["Done Scanning"])
		end

		if private.extraInfo and private.extraInfo.continue then
			headerFrame.searchBtn:SetText(TSMAPI.Design:GetInlineColor("link")..SEARCH.."|r")
			headerFrame.searchBtn.tooltip = private.extraInfo.continue.tooltip
			headerFrame.searchBtn.continueCallback = private.extraInfo.continue.callback
		else
			headerFrame.searchBtn.tooltip = nil
		end
	end
end

function frameFunctions.UpdateConfirmation(mode, auctionRecord, info)
	local confirmationFrame = private.frame.content.result.confirmation
	private.frame.content.result.rt:SetScrollDisabled(true)
	confirmationFrame:Show()
	if mode then
		for key, frame in pairs(confirmationFrame) do
			if type(frame) == "table" and frame.tsmFrameType == "Frame" then
				if key == mode then
					frame:Show()
				else
					frame:Hide()
				end
			end
		end
		confirmationFrame = confirmationFrame[mode]
	end

	if not mode then
		confirmationFrame:Hide()
		private.frame.content.result.rt:SetScrollDisabled(false)
	elseif mode == "progress" then
		confirmationFrame.text:SetText(info)
	elseif mode == "buyout" then
		confirmationFrame.item:SetText(format("%sx%d", auctionRecord.itemLink, auctionRecord.stackSize))
		confirmationFrame.item.link = auctionRecord.itemLink
		confirmationFrame.itemBuyoutText:SetText(TSMAPI:MoneyToString(auctionRecord.itemBuyout, "OPT_ICON"))
		confirmationFrame.auctionBuyoutText:SetText(TSMAPI:MoneyToString(auctionRecord.buyout, "OPT_ICON"))
		confirmationFrame.auctionCountText:SetText(format("%d/%d", min(info.progress+1, info.totalNum), info.totalNum))
	elseif mode == "bid" then
		confirmationFrame.item:SetText(format("%sx%d", auctionRecord.itemLink, auctionRecord.stackSize))
		confirmationFrame.item.link = auctionRecord.itemLink
		confirmationFrame.minBidText:SetText(TSMAPI:MoneyToString(auctionRecord.requiredBid, "OPT_ICON"))
		if auctionRecord.buyout == 0 then
			confirmationFrame.buyoutText:SetText("---")
		else
			confirmationFrame.buyoutText:SetText(TSMAPI:MoneyToString(auctionRecord.buyout, "OPT_ICON"))
		end
		confirmationFrame.bidBox:SetText(TSMAPI:MoneyToString(info.bid, confirmationFrame.bidBox:HasFocus() and "OPT_DISABLE" or nil))
	elseif mode == "post" then
		confirmationFrame.item:SetText(info.itemLink)
		confirmationFrame.item.link = info.itemLink
		confirmationFrame.stackSizeBox:SetNumber(info.stackSize)
		confirmationFrame.numStacksBox:SetNumber(info.numStacks)
		if info.updateBuyout then
			local buyout = (confirmationFrame.modeDropdown:GetValue() == 1) and info.buyout or TSMAPI.Util:Round(info.buyout/info.stackSize)
			confirmationFrame.buyoutBox:SetText(TSMAPI:MoneyToString(buyout, "OPT_TRIM", confirmationFrame.buyoutBox:HasFocus() and "OPT_DISABLE" or nil))
		end
		local deposit = max(info.stackSize * 0.15 * 2 ^ (info.duration-1) * (TSMAPI:GetItemValue(auctionRecord.itemLink, "VendorSell") or 0), 100) * info.numStacks
		confirmationFrame.depositText:SetText(TSMAPI:MoneyToString(deposit, "OPT_TRIM"))
	elseif mode == "cancel" then
		confirmationFrame.item:SetText(format("%sx%d", auctionRecord.itemLink, auctionRecord.stackSize))
		confirmationFrame.item.link = auctionRecord.itemLink
		confirmationFrame.auctionCountText:SetText(format("%d/%d", min(info.progress+1, info.totalNum), info.totalNum))
	else
		error("Unexpected confirmation mode: "..tostring(mode))
	end
	if not private.extraInfo or private.extraInfo.searchType ~= "sniper" then
		private.frame.UpdateSearchInProgress(mode and true or false)
	end
end

local scanStatus, pageStatus = {0, 1}, {0, 1}
function frameFunctions:UpdateScanStatus(statusType, ...)
	if not private.frame then return end
	if statusType == "scan" then
		scanStatus = {...}
	elseif statusType == "page" then
		pageStatus = {...}
	end
	pageStatus[2] = max(pageStatus[2], 1)
	private.frame.content.result.statusBar:SetStatusText(format(L["Scanning %d / %d (Page %d / %d)"], scanStatus[1], scanStatus[2], min(pageStatus[1]+1, pageStatus[2]), pageStatus[2]))
	private.frame.content.result.statusBar:UpdateStatus(100*(scanStatus[1]-1)/scanStatus[2], 100*pageStatus[1]/pageStatus[2])
end
