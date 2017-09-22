-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local AuctionTabOther = TSM:NewModule("AuctionTabOther")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table
local private = {frame=nil}


function private:ResetFilters()
	private.frame.filter.filterInputBox:SetText("")
	private.frame.filter.levelMinBox:SetText("")
	private.frame.filter.levelMaxBox:SetText("")
	private.frame.filter.itemLevelMinBox:SetText("")
	private.frame.filter.itemLevelMaxBox:SetText("")
	private.frame.filter.classDropdown:SetValue()
	private.frame.filter.subClassDropdown:SetValue()
	private.frame.filter.subClassDropdown:SetDisabled(true)
	private.frame.filter.rarityDropdown:SetValue()
	private.frame.filter.usableCheckBox:SetValue(false)
	private.frame.filter.exactCheckBox:SetValue(false)
	private.frame.filter.maxQtyBox:SetText("")
end

function private:StartFilterSearch()
	local filter = private.frame.filter.filterInputBox:GetText()

	local minLevel = private.frame.filter.levelMinBox:GetNumber()
	local maxLevel = private.frame.filter.levelMaxBox:GetNumber()
	if maxLevel > 0 then
		filter = format("%s/%d/%d", filter, minLevel, maxLevel)
	elseif minLevel > 0 then
		filter = format("%s/%d", filter, minLevel)
	end

	local minItemLevel = private.frame.filter.itemLevelMinBox:GetNumber()
	local maxItemLevel = private.frame.filter.itemLevelMaxBox:GetNumber()
	if maxItemLevel > 0 then
		filter = format("%s/i%d/i%d", filter, minItemLevel, maxItemLevel)
	elseif minItemLevel > 0 then
		filter = format("%s/i%d", filter, minItemLevel)
	end

	local class = private.frame.filter.classDropdown:GetValue()
	if class then
		local classes = TSMAPI.Item:GetItemClasses()
		filter = format("%s/%s", filter, classes[class])
		local subClass = private.frame.filter.subClassDropdown:GetValue()
		if subClass then
			local subClasses = TSMAPI.Item:GetItemSubClasses(TSMAPI.Item:GetClassIdFromClassString(classes[class]))
			filter = format("%s/%s", filter, subClasses[subClass])
		end
	end

	local rarity = private.frame.filter.rarityDropdown:GetValue()
	if rarity then
		filter = format("%s/%s", filter,  _G["ITEM_QUALITY"..rarity.."_DESC"])
	end

	if private.frame.filter.usableCheckBox:GetValue() then
		filter = format("%s/usable", filter)
	end

	if private.frame.filter.exactCheckBox:GetValue() then
		filter = format("%s/exact", filter)
	end

	local maxQty = private.frame.filter.maxQtyBox:GetNumber()
	if maxQty > 0 then
		filter = format("%s/x%d", filter, maxQty)
	end

	local searchInfo = {searchMode="normal", extraInfo={searchType="filter"}, filter=filter}
	TSM.AuctionTab:StartSearch(searchInfo)
end



function private.StartSearchThread(self, mode)
	self:SetThreadName("SHOPPING_START_OTHER_SEARCH")
	TSMAPI:Assert(mode == "vendor" or mode == "disenchant")

	local lastScanTime = TSMAPI:ModuleAPI("AuctionDB", "lastCompleteScanTime")
	local lastScanData = TSMAPI:ModuleAPI("AuctionDB", "lastCompleteScan")
	if not lastScanData or lastScanTime < time() - 60 * 60 * 12 or not next(lastScanData) then
		TSM:Print(L["No recent AuctionDB scan data found."])
		return
	end

	for itemString in pairs(lastScanData) do
		TSMAPI.Item:FetchInfo(itemString)
	end
	for i = 1, 30 do
		local haveInfo = true
		for itemString in pairs(lastScanData) do
			if not TSMAPI.Item:GetName(itemString) then
				haveInfo = false
			end
		end
		if haveInfo then break end
		self:Sleep(0.1)
	end

	local itemList = {}
	local searchBoxText = nil
	if mode == "vendor" then
		for itemString, data in pairs(lastScanData) do
			itemString = TSMAPI.Item:ToItemString(itemString)
			local vendor = TSMAPI.Item:GetVendorPrice(itemString) or 0
			if data.minBuyout and data.minBuyout > 0 and data.minBuyout < vendor then
				tinsert(itemList, itemString)
			end
			self:Yield()
		end
		searchBoxText = "~"..L["vendor search"].."~"
	elseif mode == "disenchant" then
		for itemString, data in pairs(lastScanData) do
			local iLvl = TSMAPI.Item:GetItemLevel(itemString) or -1
			if iLvl >= TSM.db.global.minDeSearchLvl and iLvl <= TSM.db.global.maxDeSearchLvl then
				local deValue = TSMAPI.Conversions:GetValue(itemString, TSM.db.global.marketValueSource, "disenchant")
				if deValue and data.minBuyout and data.minBuyout > 0 and (data.minBuyout / deValue) < (TSM.db.global.maxDeSearchPercent or 1) then
					tinsert(itemList, itemString)
				end
			end
			self:Yield()
		end
		searchBoxText = "~"..L["disenchant search"].."~"
	end

	if #itemList == 0 then
		TSM:Print(L["Nothing to search for!"])
		return
	end

	local searchInfo = {searchMode="normal", item=itemList, searchBoxText=searchBoxText, extraInfo={searchType=mode}}
	TSM.AuctionTab:StartSearch(searchInfo)
	-- need a sleep here since it will take a few frames for the scan to actually start and until then this thread shouldn't exit
	self:Sleep(0.5)
end

function private.StartSearchThreadDone()
	private.threadId = nil
	private.frame.other.startVendorBtn:Enable()
	private.frame.other.startDisenchantBtn:Enable()
end

function private:StartVendorSearch()
	private.frame.other.startVendorBtn:Disable()
	private.frame.other.startDisenchantBtn:Disable()
	TSMAPI.Threading:Kill(private.threadId)
	private.threadId = TSMAPI.Threading:Start(private.StartSearchThread, 0.7, private.StartSearchThreadDone, "vendor")
end

function private:StartDisenchantSearch()
	private.frame.other.startVendorBtn:Disable()
	private.frame.other.startDisenchantBtn:Disable()
	TSMAPI.Threading:Kill(private.threadId)
	private.threadId = TSMAPI.Threading:Start(private.StartSearchThread, 0.7, private.StartSearchThreadDone, "disenchant")
end

function private:StartSniperSearch()
	local continueInfo = {
		tooltip = L["Shift-Click to run sniper again."],
		callback = private.StartSniperSearch,
	}
	TSM.AuctionTab:StartSearch({searchMode="normal", extraInfo={searchType="sniper", continue=continueInfo}, searchBoxText="~"..L["sniper"].."~"})
end

function private:StartGreatDealsSearch()
	TSM.AuctionTab:StartSearch({searchMode="normal", extraInfo={searchType="deals"}, filter=private.appData.greatDeals, searchBoxText="~"..L["great deals"].."~"})
end

function private:StartItemNotificationsSearch()
	TSM.AuctionTab:StartSearch({searchMode="normal", extraInfo={searchType="deals"}, filter=private.appData.itemNotifications, searchBoxText="~"..L["item notifications"].."~"})
end



function AuctionTabOther:GetFrameInfo()
	local rarityList = {}
    local itemClasses = TSMAPI.Item:GetItemClasses()
	for i = 1, 4 do tinsert(rarityList, _G["ITEM_QUALITY"..i.."_DESC"]) end
	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		points = "ALL",
		key = "other",
		hidden = true,
		scripts = {"OnShow"},
		children = {
			{
				type = "Frame",
				key = "filter",
				points = {{"TOPLEFT"}, {"BOTTOMRIGHT", BFC.PARENT, "BOTTOM"}},
				children = {
					{
						type = "Text",
						text = L["Custom Filter"],
						textHeight = 20,
						size = {0, 20},
						points = {{"TOPLEFT", 5, -5}, {"TOPRIGHT", -5, -5}},
					},
					{
						type = "HLine",
						offset = -30,
					},
					-- row 1 - filter
					{
						type = "Text",
						text = L["Search Filter:"],
						size = {0, 20},
						points = {{"TOPLEFT", 5, -35}},
					},
					{
						type = "InputBox",
						key = "filterInputBox",
						size = {0, 20},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"TOPRIGHT", -5, -35}},
					},
					{
						type = "HLine",
						offset = -62,
					},
					-- row 2 - level
					{
						type = "Text",
						key = "levelText",
						text = L["Required Level Range:"],
						size = {0, 20},
						points = {{"TOPLEFT", 5, -70}},
					},
					{
						type = "InputBox",
						key = "levelMinBox",
						numeric = true,
						size = {60, 20},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}},
					},
					{
						type = "Text",
						text = "-",
						size = {0, 20},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}},
					},
					{
						type = "InputBox",
						key = "levelMaxBox",
						numeric = true,
						size = {0, 20},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"TOPRIGHT", -5, -70}},
					},
					{
						type = "HLine",
						offset = -100,
					},
					-- row 3 - item level
					{
						type = "Text",
						text = L["Item Level Range:"],
						size = {0, 20},
						points = {{"TOPLEFT", 5, -105}},
					},
					{
						type = "InputBox",
						key = "itemLevelMinBox",
						numeric = true,
						size = {70, 20},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}},
					},
					{
						type = "Text",
						text = "-",
						size = {0, 20},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}},
					},
					{
						type = "InputBox",
						key = "itemLevelMaxBox",
						numeric = true,
						size = {0, 20},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"TOPRIGHT", -5, -105}},
					},
					{
						type = "HLine",
						offset = -130,
					},
					-- row 4 - class / subClass
					{
						type = "Dropdown",
						key = "classDropdown",
						label = L["Item Class"],
						list = itemClasses,
						points = {{"TOPLEFT", 5, -132}, {"TOPRIGHT", BFC.PARENT, "TOP", 0, -132}},
						scripts = {"OnValueChanged"},
					},
					{
						type = "Dropdown",
						key = "subClassDropdown",
						label = L["Item SubClass"],
						list = {},
						points = {{"TOPLEFT", BFC.PARENT, "TOP", 5, -132}, {"TOPRIGHT", 0, -132}},
					},
					{
						type = "HLine",
						offset = -180,
					},
					-- row 6 - rarity
					{
						type = "Dropdown",
						key = "rarityDropdown",
						label = L["Minimum Rarity"],
						list = rarityList,
						points = {{"TOPLEFT", 5, -182}, {"TOPRIGHT", -5, -182}},
					},
					-- row 5 - subClass
					{
						type = "HLine",
						offset = -235,
					},
					-- row 6 - max quantity
					{
						type = "Text",
						text = L["Maximum Quantity to Buy:"],
						size = {0, 20},
						points = {{"TOPLEFT", 5, -240}},
					},
					{
						type = "InputBox",
						key = "maxQtyBox",
						numeric = true,
						size = {0, 20},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"TOPRIGHT", -5, -240}},
					},
					{
						type = "HLine",
						offset = -265,
					},
					-- row 7 - usable / exact
					{
						type = "CheckBox",
						key = "usableCheckBox",
						label = USABLE_ITEMS,
						tooltip = L["If set, only items which are usable by your character will be included in the results."],
						size = {200, 30},
						points = {{"TOPLEFT", 5, -272}},
					},
					{
						type = "CheckBox",
						key = "exactCheckBox",
						label = AH_EXACT_MATCH,
						tooltip = L["If set, only items which exactly match the search filter you have set will be included in the results."],
						size = {200, 30},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}},
					},
					{
						type = "HLine",
						offset = -300,
					},
					-- row 8 - buttons
					{
						type = "Button",
						key = "clearBtn",
						text = L["Reset Filters"],
						textHeight = 20,
						size = {0, 25},
						points = {{"BOTTOMLEFT", 5, 5}, {"BOTTOMRIGHT", BFC.PARENT, "BOTTOM", -2, 5}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "startBtn",
						text = L["Start Search"],
						textHeight = 20,
						size = {0, 25},
						points = {{"BOTTOMLEFT", BFC.PARENT, "BOTTOM", 2, 5}, {"BOTTOMRIGHT", -5, 5}},
						scripts = {"OnClick"},
					},
				},
			},
			{
				type = "VLine",
				size = {4, 0},
				points = {{"TOP"}, {"BOTTOM"}},
			},
			{
				type = "Frame",
				key = "other",
				points = {{"TOPLEFT", BFC.PARENT, "TOP"}, {"BOTTOMRIGHT"}},
				children = {
					{
						type = "Text",
						text = L["Other Searches"],
						textHeight = 18,
						justify = {"CENTER", "MIDDLE"},
						size = {0, 20},
						points = {{"TOPLEFT", 0, -5}, {"TOPRIGHT", 0, -5}},
					},
					{
						type = "HLine",
						offset = -30,
					},
					{
						type = "Button",
						key = "startVendorBtn",
						text = L["Start Vendor Search"],
						tooltip = L["The vendor search looks for items on the AH below their vendor sell price."],
						textHeight = 18,
						size = {0, 25},
						points = {{"TOPLEFT", 5, -35}, {"TOPRIGHT", -5, -35}},
						scripts = {"OnClick"},
					},
					{
						type = "HLine",
						offset = -65,
					},
					{
						type = "Button",
						key = "startDisenchantBtn",
						text = L["Start Disenchant Search"],
						tooltip = L["The disenchant search looks for items on the AH below their disenchant value. You can set the maximum percentage of disenchant value to search for in the Shopping General options"],
						textHeight = 18,
						size = {0, 25},
						points = {{"TOPLEFT", 5, -70}, {"TOPRIGHT", -5, -70}},
						scripts = {"OnClick"},
					},
					{
						type = "HLine",
						offset = -100,
					},
					{
						type = "Button",
						key = "sniperStartBtn",
						text = L["Start Sniper"],
						tooltip = L["The Sniper feature will look in real-time for items that have recently been posted to the AH which are worth snatching! You can configure the parameters of Sniper in the Shopping options."],
						textHeight = 18,
						size = {0, 25},
						points = {{"TOPLEFT", 5, -105}, {"TOPRIGHT", -5, -105}},
						scripts = {"OnClick"},
					},
					{
						type = "HLine",
						offset = -135,
					},
					{
						type = "HLine",
						offset = -230,
					},
					{
						type = "Frame",
						key = "appData",
						points = {{"TOPLEFT", 0, -230}, {"BOTTOMRIGHT"}},
						children = {
							{
								type = "Text",
								text = L["Desktop App Searches"],
								textHeight = 18,
								justify = {"CENTER", "MIDDLE"},
								size = {0, 20},
								points = {{"TOPLEFT", 0, -5}, {"TOPRIGHT", 0, -5}},
							},
							{
								type = "HLine",
								offset = -30,
							},
							{
								type = "Button",
								key = "greatDealsBtn",
								text = L["Great Deals"],
								tooltip = L["This searches the AH for all items found on the TSM Great Deals page (http://tradeskillmaster.com/great-deals)."],
								textHeight = 18,
								size = {0, 25},
								points = {{"TOPLEFT", 5, -35}, {"TOPRIGHT", -5, -35}},
								scripts = {"OnClick"},
							},
							{
								type = "HLine",
								offset = -65,
							},
							{
								type = "Button",
								key = "itemNotificationsBtn",
								text = L["Item Notifications"],
								tooltip = L["This searches the AH for your current deals as displayed on the TSM website."],
								textHeight = 18,
								size = {0, 25},
								points = {{"TOPLEFT", 5, -70}, {"TOPRIGHT", -5, -70}},
								scripts = {"OnClick"},
							},
						},
					},
				},
			},
		},
		handlers = {
			OnShow = function(self)
				private.frame = self
				private:ResetFilters()
				private.frame.filter.filterInputBox:SetFocus()
				for itemID in pairs(TSMAPI:ModuleAPI("AuctionDB", "lastCompleteScan") or {}) do
					TSMAPI.Item:FetchInfo(TSMAPI.Item:ToItemString(itemID))
				end
				local appData = TSMAPI.AppHelper and TSMAPI.AppHelper:FetchData("SHOPPING_SEARCHES")
				if appData then
					for _, info in pairs(appData) do
						local realmName, data = unpack(info)
						if TSMAPI.AppHelper:IsCurrentRealm(realmName) then
							private.appData = assert(loadstring(data))()
							break
						end
					end
				end
				if private.appData then
					private.frame.other.appData:Show()
					if private.appData.greatDeals then
						-- populate item info cache
						for _, item in ipairs({(";"):split(private.appData.greatDeals)}) do
							item = ("/"):split(item)
							TSMAPI.Item:FetchInfo(item)
						end
					else
						private.frame.other.appData.greatDealsBtn:Disable()
					end
					if not private.appData.itemNotifications then
						private.frame.other.appData.itemNotificationsBtn:Disable()
					end
				else
					private.frame.other.appData:Hide()
				end
			end,
			filter = {
				classDropdown = {
					OnValueChanged = function(_, value)
						private.frame.filter.subClassDropdown:SetValue()
						private.frame.filter.subClassDropdown:SetList(TSMAPI.Item:GetItemSubClasses(TSMAPI.Item:GetClassIdFromClassString(itemClasses[value])))
						private.frame.filter.subClassDropdown:SetDisabled(false)
					end,
				},
				clearBtn = {
					OnClick = private.ResetFilters,
				},
				startBtn = {
					OnClick = private.StartFilterSearch,
				},
			},
			other = {
				startVendorBtn = {
					OnClick = private.StartVendorSearch,
				},
				startDisenchantBtn = {
					OnClick = private.StartDisenchantSearch,
				},
				sniperStartBtn = {
					OnClick = private.StartSniperSearch,
				},
				appData = {
					greatDealsBtn = {
						OnClick = private.StartGreatDealsSearch,
					},
					itemNotificationsBtn = {
						OnClick = private.StartItemNotificationsSearch,
					},
				},
			},
		},
	}
	return frameInfo
end
