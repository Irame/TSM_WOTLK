-- This file contains all the APIs regarding TSM's help frame.

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local helpData
local lib = TSMAPI

--[[
tags used:
	general, accounting, auctiondb, auctioning, crafting, destroying, itemtracker, mailing, shopping, warehousing, wowuction,
	automail, shop_import, reset, manage, craft_mats, auc_import
]]

local TSM_GUIDES = {
	{tags="general auctioning crafting shopping mailing", desc="Video Guides by Faid", link="bit.ly/I2ErFG"},
	{tags="general auctiondb crafting shopping auctioning", desc="Video Guides by Manthieus", link="bit.ly/I2L1Qn"},
	{tags="general auctioning crafting auctiondb shopping", desc="'How to Set Up Enchanting in TSM Like a Boss' by Reverb", link="bit.ly/IeHEiB"},
	
	{tags="auctioning", desc="'Setting up TradeSkillMaster Groups' by Power Word: Gold", link="youtu.be/a83a_-aUzZQ"},
	
	{tags="mailing automail", desc="'Setting up Mass Mailing' Video by WoWMarketeer", link="youtu.be/EXmxZMb4LVE"},
	{tags="auctioning", desc="'Making Lists for Posting and Canceling Auctions' by WoWMarketeer", link="youtu.be/frlPVtf-sHY"},
	{tags="shop_import", desc="'Importing Shopping Lists' Video by WoWMarketeer", link="youtu.be/BlcZAYZ3s5A"},
	
	{tags="auctioning", desc="'Posting Auctions and Group Creation with TradeSkillMaster' by Faid", link="youtu.be/DURYVmHnVTo"},
	{tags="crafting", desc="'Crafting with TradeSkillMaster' Video by Faid", link="youtu.be/btFUnLr1q9k"},
	{tags="shopping", desc="'Shopping, Dealfinding, and Destroying with TradeSkillMaster' Video by Faid", link="youtu.be/1wd8jcP0RsM"},
	{tags="mailing automail", desc="'Mailing with TradeSkillMaster' Video by Faid", link="youtu.be/bu4_CrNEYb4"},
	{tags="auctioning reset", desc="'Reset Scanning with TradeSkillMaster' Video by Faid", link="youtu.be/ln9Mnt7u0Hw"},
	{tags="shop_import", desc="'Importing TSM Shoppging Lists' Video by Faid", link="youtu.be/5YFX7EK9Y5s"},
	
	{tags="auctioning", desc="'Setting up TSM for Posting' Video by Manthieus", link="youtu.be/n1QicS3U0es"},
	{tags="auctioning manage", desc="'Managing your Auctions' Video by Manthieus", link="youtu.be/B19hVuNOrbk"},
	{tags="craft_mats", desc="'Buying of Materials using TSM' Video by Manthieus", link="youtu.be/PMONOAjNcWw"},
	
	{tags="auc_import", desc="'Importing and Exporting Auctioning Groups' Guide by Sapu", link="bit.ly/JnsL2Y"},
	{tags="warehousing", desc="'How Warehousing Works and How to Set It Up' Guide by Reverb", link="bit.ly/I3ql9X"},
}


function lib:SetCurrentHelpInfo(title, desc, tags)
	helpData = {}
	if not tags then
		helpData.tags = "general"
		helpData.title = "TSM Help Window - General TSM Help"
		helpData.desc = "Below you will find more general TSM guides that cover multiple modules.\n\nBe sure to check out the other links listed in the 'TSM Info' tab of the Status screen in the main TSM window (opened by typing /tsm)."
	else
		helpData.tags = tags
		helpData.title = "TSM Help Window" .. (title and (" - "..title) or "")
		helpData.desc = helpData.desc or "Use the links below to get help with this area of TradeSkillMaster."
	end
	
	helpData.desc = "|cff88ffff"..helpData.desc.."|r"
end


-- get all the guides that contain the current tags
-- the table returned lists the guides in a random order
local function GetGuides()
	local guides, currentTags, result = {}, {}, {}
	
	-- get the current tags
	for _, tag in ipairs({(" "):split(helpData.tags)}) do
		currentTags[tag] = true
	end
	
	-- get the guides with at least one of the current tags
	for _, guide in ipairs(TSM_GUIDES) do
		local num = 0
		local guideTags = {(" "):split(guide.tags)}
		for _, tag in ipairs(guideTags) do
			if currentTags[tag] then
				num = num + 1
			end
		end
		if num > 0 then
			tinsert(guides, {guide=guide, weight=num/#guideTags})
		end
	end
	
	local temp = {guides={}, weights={}}
	for _, guide in ipairs(guides) do
		if not temp.guides[guide.weight] then
			temp.guides[guide.weight] = {}
			tinsert(temp.weights, guide.weight)
		end
		tinsert(temp.guides[guide.weight], guide.guide)
	end
	sort(temp.weights, function(a, b) return a > b end)
	
	for _, weight in ipairs(temp.weights) do
		-- randomize the order of the guides of the same weights
		local num = #temp.guides[weight]
		for i=1, num do
			local index = random(1, #temp.guides[weight])
			tinsert(result, temp.guides[weight][index])
			tremove(temp.guides[weight], index)
		end
	end
	
	return result
end

local function ShowHelpWindow()
	if not helpData then
		lib:SetCurrentHelpInfo()
	end
	
	local window = AceGUI:Create("TSMWindow")
	window:SetWidth(450)
	window:SetHeight(500)
	window:SetTitle(helpData.title)
	window:SetLayout("Fill")
	window.frame:SetFrameStrata("TOOLTIP")
	window:SetCallback("OnClose", function(self) self:ReleaseChildren() end)

	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					title = "Help",
					layout = "List",
					children = {
						{
							type = "Label",
							fullWidth = true,
							text = helpData.desc,
						},
					},
				},
			},
		},
	}
	
	local guides = GetGuides()
	
	if #guides > 0 then
		local widgets = {
			{
				type = "InlineGroup",
				title = "Relevant Guides and Videos",
				layout = "Flow",
				children = {},
			},
		}
		
		for i, data in ipairs(guides) do
			tinsert(widgets[1].children, {
					type = "EditBox",
					label = "|cff88ffff"..data.desc.."|r",
					value = "|cffAAAAAA"..data.link.."|r",
					relativeWidth = 1,
					callback = function(self) self:SetText("|cffAAAAAA"..data.link.."|r") end,
				})
			
			if i ~= #guides then
				tinsert(widgets[1].children, {type = "Spacer"})
			end
		end
		
		foreachi(widgets, function(_,v) tinsert(page[1].children, v) end)
	end

	TSMAPI:BuildPage(window, page)
end

function TSM:CreateHelpButton()
	local btn = TSMAPI.GUI:CreateButton(TSM.Frame.frame, 18)
	btn:SetPoint("TOPRIGHT", -80, 0)
	btn:SetHeight(15)
	btn:SetWidth(80)
	btn:SetText("|cffff0000".."HELP".."|r")
	btn:SetScript("OnClick", ShowHelpWindow)
	return btn
end