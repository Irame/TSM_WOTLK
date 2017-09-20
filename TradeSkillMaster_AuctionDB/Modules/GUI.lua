-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_AuctionDB                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctiondb           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local GUI = TSM:NewModule("GUI")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_AuctionDB") -- loads the localization table
local private = {frame=nil}



-- ============================================================================
-- Module Functions
-- ============================================================================

function GUI:Show(frame)
	private:Create(frame)
	private.frame:Show()
	GUI:UpdateStatus("", 0, 0)
	TSMAPI.Delay:AfterTime("auctionDBGetAllStatus", 0, private.UpdateGetAllStatus, 0.2)
end

function GUI:Hide()
	private.frame:Hide()
	TSM.Scan:StopScanning()
	TSMAPI.Delay:Cancel("auctionDBGetAllStatus")
end

function GUI:UpdateStatus(text, major, minor)
	if text then
		private.frame.statusBar:SetStatusText(text)
	end
	if major or minor then
		private.frame.statusBar:UpdateStatus(major, minor)
	end
end


-- ============================================================================
-- GUI Creation Functions
-- ============================================================================

function private:Create(parent)
	if private.frame then return end

	local function UpdateGetAllButton()
	end

	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		parent = parent,
		points = "ALL",
		children = {
			{
				type = "Text",
				key = "appAd",
				text = TSMAPI.Design:GetInlineColor("link")..L["Scanning the auction house in game is no longer necessary!"].."|r",
				textHeight = 20,
				justify = {"CENTER", "MIDDLE"},
				size = {0, 20},
				points = {{"TOP", 45, -5}},
			},
			{
				type = "Text",
				text = format(L["Download the FREE TSM desktop application which will automatically update your TSM_AuctionDB prices using Blizzard's online APIs (and does MUCH more). Visit %s for more info and never scan the AH again! This is the best way to update your AuctionDB prices."], TSMAPI.Design:GetInlineColor("link").."http://tradeskillmaster.com/app/overview".."|r"),
				justify = {"LEFT", "TOP"},
				size = {0, 55},
				points = {{"TOPLEFT", 90, -30}, {"TOPRIGHT", -5, -30}},
			},
			{
				type = "Frame",
				key = "content",
				points = {{"TOPLEFT", parent.content}, {"BOTTOMRIGHT", parent.content}},
				children = {
					{
						type = "GroupTreeFrame",
						key = "groupTree",
						groupTreeInfo = {nil, "AuctionDB"},
						points = {{"TOPLEFT", 5, -35}, {"BOTTOMRIGHT", -205, 5}},
					},
					{
						type = "StatusBarFrame",
						key = "statusBar",
						name = "TSMAuctionDBStatusBar",
						size = {0, 30},
						points = {{"TOPLEFT"}, {"TOPRIGHT"}},
					},
					{
						type = "HLine",
						offset = -30,
					},
					{
						type = "VLine",
						points = {{"TOPRIGHT", -200, -30}, {"BOTTOMRIGHT", -200, 0}},
					},
					{
						type = "Frame",
						key = "buttonFrame",
						points = {{"TOPLEFT", BFC.PARENT, "TOPRIGHT", -200, 0}, {"BOTTOMRIGHT"}},
						children = {
							-- row 1 - getall scan
							{
								type = "Button",
								key = "getAllBtn",
								text = L["Run GetAll Scan"],
								textHeight = 18,
								tooltip = L["A GetAll scan is the fastest in-game method for scanning every item on the auction house. However, there are many possible bugs on Blizzard's end with it including the chance for it to disconnect you from the game. Also, it has a 15 minute cooldown."],
								size = {0, 22},
								points = {{"TOPLEFT", 6, -50}, {"TOPRIGHT", -6, -50}},
								scripts = {"OnClick"},
							},
							{
								type = "Text",
								key = "getAllStatusText",
								text = "",
								justify = {"CENTER", "MIDDLE"},
								size = {0, 16},
								points = {{"TOPLEFT", BFC.PREV, "BOTTOMLEFT", 0, -3}, {"TOPRIGHT", BFC.PREV, "BOTTOMRIGHT", 0, -3}},
							},
							{
								type = "HLine",
								offset = -110,
							},
							-- row 2 - full scan
							{
								type = "Button",
								key = "fullBtn",
								text = L["Run Full Scan"],
								textHeight = 18,
								tooltip = L["A full auction house scan will scan every item on the auction house but is far slower than a GetAll scan. Expect this scan to take several minutes or longer."],
								size = {0, 22},
								points = {{"TOPLEFT", 6, -150}, {"TOPRIGHT", -6, -150}},
								scripts = {"OnClick"},
							},
							{
								type = "HLine",
								offset = -200,
							},
							-- row 3 - group scan
							{
								type = "Button",
								key = "groupBtn",
								text = L["Scan Selected Groups"],
								textHeight = 18,
								tooltip = L["This will do a slow auction house scan of every item in the selected groups and update their AuctionDB prices. This may take several minutes."],
								size = {0, 22},
								points = {{"TOPLEFT", 6, -225}, {"TOPRIGHT", -6, -225}},
								scripts = {"OnClick"},
							},
						},
					},
				},
			},
		},
		handlers = {
			content = {
				buttonFrame = {
					getAllBtn = {
						OnClick = TSM.Scan.StartGetAllScan,
					},
					fullBtn = {
						OnClick = TSM.Scan.StartFullScan,
					},
					groupBtn = {
						OnClick = function()
							local items, includedItems = {}, {}
							for _, data in pairs(private.frame.content.groupTree:GetSelectedGroupInfo()) do
								for itemString in pairs(data.items) do
									itemString = TSMAPI.Item:ToBaseItemString(itemString)
									if not includedItems[itemString] then
										includedItems[itemString] = true
										tinsert(items, itemString)
									end
								end
							end
							if #items == 0 then
								TSM:Print(L["You must select at least one group before starting the group scan."])
								return
							end
							TSM.Scan:StartGroupScan(items)
						end,
					},
				},
			},
		},
	}
	private.frame = TSMAPI.GUI:BuildFrame(frameInfo)
	TSMAPI.Design:SetFrameBackdropColor(private.frame.content)
	private.frame.statusBar = private.frame.content.statusBar

	-- create animation for app ad
	local ag = private.frame.appAd:CreateAnimationGroup()
	local a1 = ag:CreateAnimation("Alpha")
	a1:SetChange(-0.4)
	a1:SetDuration(.5)
	ag:SetLooping("BOUNCE")
	ag:Play()

--	local helpPlateInfo = {
--		FramePos = {x=5, y=-100},
--		FrameSize = {width=private.frame:GetWidth(), height=private.frame:GetHeight()},
--		{
--			ButtonPos = {x = 380, y = -75},
--			HighLightBox = {x = 2, y = -12, width = 615, height = 295},
--			ToolTipDir = "DOWN",
--			ToolTipText = L["If you have created TSM groups, they will be listed here for selection."]
--		},
--		{
--			ButtonPos = {x = 800, y = -20},
--			HighLightBox = {x = 622, y = -12, width = 200, height = 80},
--			ToolTipDir = "RIGHT",
--			ToolTipText = L["A 'GetAll' scan is an extremely fast way to manually scan the entire AH, but may run into bugs on Blizzard's end such as disconnection issues. It also has a 15 minute cooldown."]
--		},
--		{
--			ButtonPos = {x = 800, y = -120},
--			HighLightBox = {x = 622, y = -100, width = 200, height = 80},
--			ToolTipDir = "RIGHT",
--			ToolTipText = L["A full scan is a slow, manual scan of the entire auction house."]
--		},
--		{
--			ButtonPos = {x = 800, y = -190},
--			HighLightBox = {x = 622, y = -190, width = 200, height = 50},
--			ToolTipDir = "RIGHT",
--			ToolTipText = L["This button will scan just the items in the groups you have selected."]
--		},
--	}
--
--	local mainHelpBtn = CreateFrame("Button", nil, private.frame, "MainHelpPlateButton")
--	mainHelpBtn:SetPoint("TOPLEFT", private.frame, 70, 25)
--	mainHelpBtn:SetScript("OnClick", function() private:ToggleHelpPlate(private.frame, helpPlateInfo, mainHelpBtn, true) end)
--	mainHelpBtn:SetScript("OnHide", function() if HelpPlate_IsShowing(helpPlateInfo) then private:ToggleHelpPlate(private.frame, helpPlateInfo, mainHelpBtn, false) end end)
--
--	if not TSM.db.global.helpPlatesShown.auction then
--		TSM.db.global.helpPlatesShown.auction = true
--		private:ToggleHelpPlate(private.frame, helpPlateInfo, mainHelpBtn, false)
--	end
end

--function private:ToggleHelpPlate(frame, info, btn, isUser)
--	if not HelpPlate_IsShowing(info) then
--		HelpPlate:SetParent(frame)
--		HelpPlate:SetFrameStrata("DIALOG")
--		HelpPlate_Show(info, frame, btn, isUser)
--	else
--		HelpPlate:SetParent(UIParent)
--		HelpPlate:SetFrameStrata("DIALOG")
--		HelpPlate_Hide(isUser)
--	end
--end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:UpdateGetAllStatus()
	if TSM.Scan:IsScanning() then
		private.frame.content.buttonFrame.getAllBtn:Disable()
		private.frame.content.buttonFrame.fullBtn:Disable()
		private.frame.content.buttonFrame.groupBtn:Disable()
	elseif not select(2, CanSendAuctionQuery()) or GetNumAuctionItems("list") > NUM_AUCTION_ITEMS_PER_PAGE then
		private.frame.content.buttonFrame.getAllStatusText:SetText("|cff990000"..L["Not Ready"])
		private.frame.content.buttonFrame.getAllBtn:Disable()
		private.frame.content.buttonFrame.fullBtn:Enable()
		private.frame.content.buttonFrame.groupBtn:Enable()
	else
		private.frame.content.buttonFrame.getAllBtn:Enable()
		private.frame.content.buttonFrame.fullBtn:Enable()
		private.frame.content.buttonFrame.groupBtn:Enable()
		private.frame.content.buttonFrame.getAllStatusText:SetText("|cff009900"..L["Ready"])
	end
end
