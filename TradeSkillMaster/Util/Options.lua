-- This file contains all the code for the stuff that shows under the "Status" icon in the main TSM window.

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local lib = TSMAPI

local function LoadHelpPage(parent)
	local resourceText = ""..
		"Official TSM Forum:"..lib.Design:GetInlineColor("link").." http://stormspire.net/official-tradeskillmaster-development-forum/|r\n"..
		"Official IRC Channel:"..lib.Design:GetInlineColor("link").." http://tradeskillmaster.com/index.php/chat|r\n"..
		"Official Website:"..lib.Design:GetInlineColor("link").." http://tradeskillmaster.com|r"

	local moduleText = {
		lib.Design:GetInlineColor("link").."Accounting".."|r - "..L["Keeps track of all your sales and purchases from the auction house allowing you to easily track your income and expendatures and make sure you're turning a profit."].."\n",
		lib.Design:GetInlineColor("link").."AuctionDB".."|r - "..L["Performs scans of the auction house and calculates the market value of items as well as the minimum buyout. This information can be shown in items' tooltips as well as used by other modules."].."\n",
		lib.Design:GetInlineColor("link").."Auctioning".."|r - "..L["Posts and cancels your auctions to / from the auction house accorder to pre-set rules. Also, this module can show you markets which are ripe for being reset for a profit."].."\n",
		lib.Design:GetInlineColor("link").."Crafting".."|r - "..L["Allows you to build a queue of crafts that will produce a profitable, see what materials you need to obtain, and actually craft the items."].."\n",
		lib.Design:GetInlineColor("link").."Destroying".."|r - "..L["Mills, prospects, and disenchants items at super speed!"].."\n",
		lib.Design:GetInlineColor("link").."ItemTracker".."|r - "..L["Tracks and manages your inventory across multiple characters including your bags, bank, and guild bank."].."\n",
		lib.Design:GetInlineColor("link").."Mailing".."|r - "..L["Allows you to quickly and easily empty your mailbox as well as automatically send items to other characters with the single click of a button."].."\n",
		lib.Design:GetInlineColor("link").."Shopping".."|r - "..L["Provides interfaces for efficiently searching for items on the auction house. When an item is found, it can easily be bought, canceled (if it's yours), or even posted from your bags."].."\n",
		lib.Design:GetInlineColor("link").."Warehousing".."|r - "..L["Manages your inventory by allowing you to easily move stuff between your bags, bank, and guild bank."].."\n",
		lib.Design:GetInlineColor("link").."WoWuction".."|r - "..L["Allows you to use data from http://wowuction.com in other TSM modules and view its various price points in your item tooltips."].."\n",
	}

	local page = {
		{
			type = "ScrollFrame",
			layout = "flow",
			children = {
				{
					type = "InlineGroup",
					title = "Resources:",
					layout = "List",
					fullWidth = true,
					noBorder = true,
					children = {
						{
							type = "Label",
							text = resourceText,
							fullWidth = true,
						},
					},
				},
				{
					type = "Spacer",
				},
				{
					type = "InlineGroup",
					title = "Module Information:",
					layout = "List",
					fullWidth = true,
					noBorder = true,
					children = {},
				},
			},
		},
	}
	
	for _, text in ipairs(moduleText) do
		tinsert(page[1].children[3].children, {
				type = "Label",
				text = text,
				fullWidth = true,
			})
	end

	lib:BuildPage(parent, page)
end

local function LoadStatusPage(parent)
	local page = {
		{
			type = "ScrollFrame",
			layout = "flow",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Installed Modules"],
					children = {},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Credits"],
					children = {
						{
							type = "Label",
							text = L["TradeSkillMaster Team:"],
							relativeWidth = 1,
							fontObject = GameFontHighlightLarge,
						},
						{
							type = "Label",
							text = lib.Design:GetInlineColor("link")..L["Lead Developer and Project Manager:"].."|r Sapu94",
							relativeWidth = 1,
						},
						{
							type = "Label",
							text = lib.Design:GetInlineColor("link")..L["Active Developers:"].."|r Geemoney, Drethic, Bart39",
							relativeWidth = 1,
						},
						{
							type = "Label",
							text = lib.Design:GetInlineColor("link")..L["Testers (Special Thanks):"].."|r Acry, Vith, Quietstrm07, Cryan",
							relativeWidth = 1,
						},
						{
							type = "Label",
							text = lib.Design:GetInlineColor("link")..L["Past Contributors:"].."|r Cente, Mischanix, Xubera, cduhn, cjo20",
							relativeWidth = 1,
						},
					},
				},
			},
		},
	}
	
	for i, module in ipairs(TSM.registeredModules) do
		local moduleWidgets = {
			type = "SimpleGroup",
			relativeWidth = 0.49,
			layout = "list",
			children = {
				{
					type = "Label",
					text = lib.Design:GetInlineColor("link")..L["Module:"].."|r"..module.name,
					fullWidth = true,
					fontObject = GameFontNormalLarge,
				},
				{
					type = "Label",
					text = lib.Design:GetInlineColor("link")..L["Version:"].."|r"..module.version,
					fullWidth = true,
				},
				{
					type = "Label",
					text = lib.Design:GetInlineColor("link")..L["Author(s):"].."|r"..module.authors,
					fullWidth = true,
				},
				{
					type = "Label",
					text = lib.Design:GetInlineColor("link")..L["Description:"].."|r"..module.desc,
					fullWidth = true,
				},
			},
		}
		
		if i > 2 then
			tinsert(moduleWidgets.children, 1, {type = "Spacer"})
		end
		tinsert(page[1].children[1].children, moduleWidgets)
	end
	
	if #TSM.registeredModules == 1 then
		local warningText = {
			type = "Label",
			text = "\n|cffff0000"..L["No modules are currently loaded.  Enable or download some for full functionality!"].."\n\n|r",
			fullWidth = true,
			fontObject = GameFontNormalLarge,
		}
		tinsert(page[1].children[1].children, warningText)
		
		local warningText2 = {
			type = "Label",
			text = "\n|cffff0000"..format(L["Visit %s for information about the different TradeSkillMaster modules as well as download links."], "http://www.curse.com/addons/wow/tradeskill-master").."|r",
			fullWidth = true,
			fontObject = GameFontNormalLarge,
		}
		tinsert(page[1].children[1].children, warningText2)
	end
	
	lib:BuildPage(parent, page)
end

local function GetSubStr(str)
	if not str then return end
	local startIndex, endIndex
	local balance = 0
	
	for i=1, #str do
		local c = strsub(str, i, i)
		if c == '{' then
			if startIndex then
				balance = balance + 1
			else
				startIndex = i
			end
		elseif c == '}' then
			if balance > 0 then
				balance = balance - 1
			else
				endIndex = i
				break
			end
		end
	end
	
	if not startIndex or not endIndex then return end
	return strsub(str, startIndex+1, endIndex-1), startIndex, endIndex
end

local function StringToTable(data)
	local result = {}
	while true do
		local value, s, e = GetSubStr(data, {'{', '}'})
		if not value then return end
		local key = strsub(data, 1, s-1)
		value = tonumber(value) or value
		
		if type(value) == "string" and strfind(value, "{") then
			value = StringToTable(value)
		elseif type(value) == "string" and strfind(value, ",") then
			value = {(","):split(value)}
			for i=1, 4 do
				value[i] = tonumber(value[i])
			end
		end
		
		if type(value) == "nil" then
			return
		end
		
		result[key] = value
		if e+1 > #data then
			break
		end
		data = strsub(data, e+1, #data)
	end
	return result
end

local function DecodeAppearanceData(encodedData)
	if not encodedData then return end
	encodedData = gsub(encodedData, " ", "")
	
	local result = StringToTable(encodedData, 1)
	if not result then return TSM:Print(L["Invalid appearance data."]) end
	
	for key in pairs(TSM.db.profile.design) do
		if result[key] then
			TSM.db.profile.design[key] = result[key]
		end
	end
	TSMAPI:UpdateDesign()
end

local function ShowImportFrame()
	local data
	
	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TradeSkillMaster - "..L["Import Appearance Settings"])
	f:SetLayout("Flow")
	f:SetHeight(200)
	f:SetHeight(300)
	
	local spacer = AceGUI:Create("Label")
	spacer:SetFullWidth(true)
	spacer:SetText(" ")
	f:AddChild(spacer)
	
	local btn = AceGUI:Create("TSMButton")
	
	local eb = AceGUI:Create("MultiLineEditBox")
	eb:SetLabel(L["Appearance Data"])
	eb:SetFullWidth(true)
	eb:SetMaxLetters(0)
	eb:SetCallback("OnEnterPressed", function(_,_,val) btn:SetDisabled(false) data = val end)
	f:AddChild(eb)
	
	btn:SetDisabled(true)
	btn:SetText(L["Import Appearance Settings"])
	btn:SetFullWidth(true)
	btn:SetCallback("OnClick", function() DecodeAppearanceData(data) f:Hide() end)
	f:AddChild(btn)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end

local function TblToStr(tbl)
	local tmp = {}
	for key, value in pairs(tbl) do
		tinsert(tmp, key.."{")
		if tonumber(value) then
			tinsert(tmp, value)
		elseif #value == 0 then
			tinsert(tmp, TblToStr(value))
		else
			for _, colorVal in ipairs(value) do
				tinsert(tmp, tostring(colorVal))
				tinsert(tmp, ",")
			end
			tremove(tmp, #tmp)
		end
		tinsert(tmp, "}")
	end
	return table.concat(tmp, "")
end

local function EncodeAppearanceData()
	local keys = {"frameColors", "textColors", "inlineColors", "edgeSize", "fontSizes"}
	local testTbl = {}
	for _, key in ipairs(keys) do
		testTbl[key] = TSM.db.profile.design[key]
	end
	return TblToStr(testTbl)
end

local function ShowExportFrame()
	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TradeSkillMaster - "..L["Export Appearance Settings"])
	f:SetLayout("Fill")
	f:SetHeight(300)
	
	local eb = AceGUI:Create("TSMMultiLineEditBox")
	eb:SetLabel(L["Appearance Data"])
	eb:SetMaxLetters(0)
	eb:SetText(EncodeAppearanceData())
	f:AddChild(eb)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end

local function LoadOptionsPage(parent)
	local presetThemes = {
		light = {L["Light (by Ravanys - The Consortium)"], "inlineColors{link{49,56,133,1}link2{153,255,255,1}category{36,106,36,1}category2{85,180,8,1}}textColors{iconRegion{enabled{105,105,105,1}}title{enabled{49,56,85,1}}label{enabled{45,44,40,1}disabled{150,148,140,1}}text{enabled{245,244,240,1}disabled{95,98,90,1}}link{enabled{49,56,133,1}}}fontSizes{normal{15}small{12}}edgeSize{1.5}frameColors{frameBG{backdrop{219,219,219,1}border{30,30,30,1}}content{backdrop{60,60,60,1}border{40,40,40,1}}frame{backdrop{228,228,228,1}border{199,199,199,1}}}"},
		goblineer = {L["Goblineer (by Sterling - The Consortium)"], "inlineColors{link{153,255,255,1}link2{153,255,255,1}category{36,106,36,1}category2{85,180,8,1}}textColors{iconRegion{enabled{249,255,247,1}}title{enabled{132,219,9,1}}label{enabled{216,225,211,1}disabled{150,148,140,1}}text{enabled{255,254,250,1}disabled{147,151,139,1}}link{enabled{49,56,133,1}}}fontSizes{normal{15}small{12}}edgeSize{1.5}frameColors{frameBG{backdrop{24,24,24,0.93}border{30,30,30,1}}content{backdrop{42,42,42,1}border{0,0,0,0}}frame{backdrop{24,24,24,1}border{255,255,255,0.03}}}"},
		jaded = {L["Jaded (by Ravanys - The Consortium)"], "frameColors{frameBG{backdrop{0,0,0,0.6}border{0,0,0,0.4}}content{backdrop{62,62,62,1}border{72,72,72,1}}frame{backdrop{32,32,32,1}border{2,2,2,0.48}}}textColors{text{enabled{99,219,136,1}disabled{95,98,90,1}}iconRegion{enabled{43,255,156,1}}title{enabled{75,255,150,1}}label{enabled{99,219,136,1}disabled{177,176,168,1}}}edgeSize{1}fontSizes{normal{15}small{12}}"},
		tsmdeck = {L["TSMDeck (by Jim Younkin - Power Word: Gold)"], "inlineColors{link{89,139,255,1}link2{153,255,255,1}category{80,222,22,1}category2{85,180,8,1}}textColors{text{enabled{245,240,251,1}disabled{115,115,115,1}}iconRegion{enabled{216,216,224,1}}title{enabled{247,248,255,1}}label{enabled{238,249,237,1}disabled{110,110,110,1}}}fontSizes{normal{14}small{12}}edgeSize{1}frameColors{frameBG{backdrop{29,29,29,1}border{20,20,20,1}}content{backdrop{27,27,27,1}border{67,67,65,1}}frame{backdrop{39,39,40,1}border{20,20,20,1}}}"},
		tsmclassic = {L["TSM Classic (by Jim Younkin - Power Word: Gold)"], "inlineColors{link{89,139,255,1}link2{153,255,255,1}category{80,222,22,1}category2{85,180,8,1}}textColors{text{enabled{245,240,251,1}disabled{115,115,115,1}}iconRegion{enabled{216,216,224,1}}title{enabled{247,248,255,1}}label{enabled{238,249,237,1}disabled{110,110,110,1}}}fontSizes{normal{14}small{12}}edgeSize{1}frameColors{frameBG{backdrop{8,8,8,1}border{4,2,147,1}}content{backdrop{18,18,18,1}border{102,108,105,1}}frame{backdrop{2,2,2,1}border{4,2,147,1}}}"},
	}
	
	local presetThemeList = {}
	for key, tbl in pairs(presetThemes) do
		presetThemeList[key] = tbl[1]
	end

	local page = {
		{
			type = "ScrollFrame",
			layout = "flow",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["General Settings"],
					children = {
						{
							type = "CheckBox",
							label = L["Hide Minimap Icon"],
							quickCBInfo = {TSM.db.profile.minimapIcon, "hide"},
							relativeWidth = 0.5,
							callback = function(_,_,value)
									if value then
										TSM.LDBIcon:Hide("TradeSkillMaster")
									else
										TSM.LDBIcon:Show("TradeSkillMaster")
									end
								end,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Auction House Tab Settings"],
					children = {
						{
							type = "CheckBox",
							label = L["Make TSM Default Auction House Tab"],
							quickCBInfo = {TSM.db.profile, "isDefaultTab"},
							relativeWidth = 0.5,
						},
						{
							type = "CheckBox",
							label = L["Show Bids in Auction Results Table (Requires Reload)"],
							quickCBInfo = {TSM.db.profile, "showBids"},
							relativeWidth = 0.5,
							tooltip = L["If checked, all tables listing auctions will display the bid as well as the buyout of the auctions. This will not take effect immediately and may require a reload."],
						},
						{
							type = "CheckBox",
							label = L["Make Auction Frame Movable"],
							quickCBInfo = {TSM.db.profile, "auctionFrameMovable"},
							relativeWidth = 0.5,
							callback = function(_,_,value) AuctionFrame:SetMovable(value) end,
						},
						{
							type = "Slider",
							label = L["Auction Frame Scale"],
							value = TSM.db.profile.auctionFrameScale,
							isPercent = true,
							relativeWidth = 0.5,
							min = 0.1,
							max = 2,
							step = 0.05,
							callback = function(_,_,value)
									TSM.db.profile.auctionFrameScale = value
									if AuctionFrame then
										AuctionFrame:SetScale(value)
									end
								end,
							tooltip = L["Changes the size of the auction frame. The size of the detached TSM auction frame will always be the same as the main auction frame."],
						},
						{
							type = "CheckBox",
							label = L["Detach TSM Tab by Default"],
							quickCBInfo = {TSM.db.profile, "detachByDefault"},
							relativeWidth = 0.5,
						},
						{
							type = "CheckBox",
							label = L["Open All Bags with Auction House"],
							quickCBInfo = {TSM.db.profile, "openAllBags"},
							relativeWidth = 0.5,
							tooltip = L["If checked, your bags will be automatically opened when you open the auction house."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["TSM Appearance Options"],
					children = {
						{
							type = "Label",
							text = L["Use the options below to change and tweak the appearance of TSM."],
							fullWidth = 1,
						},
						{
							type = "Dropdown",
							label = L["Import Preset TSM Theme"],
							list = presetThemeList,
							relativeWidth = 1,
							callback = function(_, _, key)
									if presetThemes[key] then
										DecodeAppearanceData(presetThemes[key][2])
									end
								end,
							tooltip = L["Select a theme from this dropdown to import one of the preset TSM themes."],
						},
						{
							type = "Button",
							text = L["Restore Default Colors"],
							relativeWidth = 1,
							callback = function() TSM:RestoreDesignDefaults() parent:SelectTab(3) end,
							tooltip = L["Restores all the color settings below to their default values."],
						},
						{
							type = "Button",
							text = L["Import Appearance Settings"],
							relativeWidth = 0.5,
							callback = ShowImportFrame,
							tooltip = L["This allows you to import appearance settings which other people have exported."],
						},
						{
							type = "Button",
							text = L["Export Appearance Settings"],
							relativeWidth = 0.5,
							callback = ShowExportFrame,
							tooltip = L["This allows you to export your appearance settings to share with others."],
						},
						{
							type = "HeadingLine"
						},
					},
				},
			},
		},
	}
	
	local function expandColor(tbl)
		return {tbl[1]/255, tbl[2]/255, tbl[3]/255, tbl[4]}
	end
	local function compressColor(r, g, b, a)
		return {r*255, g*255, b*255, a}
	end
	
	local frameColorOptions = {
		{L["Frame Background - Backdrop"], "frameBG", "backdrop"},
		{L["Frame Background - Border"], "frameBG", "border"},
		{L["Region - Backdrop"], "frame", "backdrop"},
		{L["Region - Border"], "frame", "border"},
		{L["Content - Backdrop"], "content", "backdrop"},
		{L["Content - Border"], "content", "border"},
	}
	for _, optionInfo in ipairs(frameColorOptions) do
		local label, key, subKey = unpack(optionInfo)
		
		local widget = {
			type = "ColorPicker",
			label = label,
			relativeWidth = 0.5,
			hasAlpha = true,
			value = expandColor(TSM.db.profile.design.frameColors[key][subKey]),
			callback = function(_, _, ...)
					TSM.db.profile.design.frameColors[key][subKey] = compressColor(...)
					TSMAPI:UpdateDesign()
				end,
		}
		tinsert(page[1].children[3].children, widget)
	end
	
	tinsert(page[1].children[3].children, {type="HeadingLine"})
	
	local textColorOptions = {
		{L["Icon Region"], "iconRegion", "enabled"},
		{L["Title"], "title", "enabled"},
		{L["Label Text - Enabled"], "label", "enabled"},
		{L["Label Text - Disabled"], "label", "disabled"},
		{L["Content Text - Enabled"], "text", "enabled"},
		{L["Content Text - Disabled"], "text", "disabled"},
	}
	for _, optionInfo in ipairs(textColorOptions) do
		local label, key, subKey = unpack(optionInfo)
		
		local widget = {
			type = "ColorPicker",
			label = label,
			relativeWidth = 0.5,
			hasAlpha = true,
			value = expandColor(TSM.db.profile.design.textColors[key][subKey]),
			callback = function(_, _, ...)
					TSM.db.profile.design.textColors[key][subKey] = compressColor(...)
					TSMAPI:UpdateDesign()
				end,
		}
		tinsert(page[1].children[3].children, widget)
	end
	
	tinsert(page[1].children[3].children, {type="HeadingLine"})
	
	local inlineColorOptions = {
		{L["Link Text (Requires Reload)"], "link"},
		{L["Link Text 2 (Requires Reload)"], "link2"},
		{L["Category Text (Requires Reload)"], "category"},
		{L["Category Text 2 (Requires Reload)"], "category2"},
	}
	for _, optionInfo in ipairs(inlineColorOptions) do
		local label, key = unpack(optionInfo)
		
		local widget = {
			type = "ColorPicker",
			label = label,
			relativeWidth = 0.5,
			hasAlpha = true,
			value = expandColor(TSM.db.profile.design.inlineColors[key]),
			callback = function(_, _, ...)
					TSM.db.profile.design.inlineColors[key] = compressColor(...)
					TSMAPI:UpdateDesign()
				end,
		}
		tinsert(page[1].children[3].children, widget)
	end
	
	tinsert(page[1].children[3].children, {type="HeadingLine"})
	
	local miscWidgets = {
		{
			type = "Slider",
			relativeWidth = 0.5,
			label = L["Small Text Size (Requires Reload)"],
			min = 6,
			max = 30,
			step = 1,
			value = TSM.db.profile.design.fontSizes.small,
			callback = function(_, _, value) TSM.db.profile.design.fontSizes.small = value end,
		},
		{
			type = "Slider",
			relativeWidth = 0.5,
			label = L["Normal Text Size (Requires Reload)"],
			min = 6,
			max = 30,
			step = 1,
			value = TSM.db.profile.design.fontSizes.normal,
			callback = function(_, _, value) TSM.db.profile.design.fontSizes.normal = value end,
		},
		{
			type = "Slider",
			relativeWidth = 0.5,
			label = L["Border Thickness (Requires Reload)"],
			min = 0,
			max = 3,
			step = .1,
			value = TSM.db.profile.design.edgeSize,
			callback = function(_, _, value)	TSM.db.profile.design.edgeSize = value end,
		},
	}
	for _, widget in ipairs(miscWidgets) do
		tinsert(page[1].children[3].children, widget)
	end
	
	lib:BuildPage(parent, page)
end


function TSM:LoadOptions(parent)
	lib:SetCurrentHelpInfo()
	
	local tg = AceGUI:Create("TSMTabGroup")
	tg:SetLayout("Fill")
	tg:SetFullWidth(true)
	tg:SetFullHeight(true)
	tg:SetTabs({{value=1, text=L["TSM Info / Help"]}, {value=2, text=L["Status / Credits"]}, {value=3, text=L["Options"]}})
	tg:SetCallback("OnGroupSelected", function(self,_,value)
		tg:ReleaseChildren()
		
		if value == 1 then
			LoadHelpPage(self)
		elseif value == 2 then
			LoadStatusPage(self)
		elseif value == 3 then
			LoadOptionsPage(self)
		end
	end)
	parent:AddChild(tg)
	tg:SelectTab(1)
end