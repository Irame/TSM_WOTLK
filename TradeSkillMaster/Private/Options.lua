-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for the stuff that shows under the "Status" icon in the main TSM window.

local TSM = select(2, ...)
local Options = TSM:NewModule("Options")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {operationInfo=TSM.moduleOperationInfo, treeGroup=nil, moduleOptions={}}
local presetThemes = {
	light = { L["Light (by Ravanys - The Consortium)"], "inlineColors{link{49,56,133,1}link2{153,255,255,1}category{36,106,36,1}category2{85,180,8,1}}textColors{iconRegion{enabled{105,105,105,1}}title{enabled{49,56,85,1}}label{enabled{45,44,40,1}disabled{150,148,140,1}}text{enabled{245,244,240,1}disabled{95,98,90,1}}link{enabled{49,56,133,1}}}fontSizes{normal{15}medium{13}small{12}}edgeSize{1.5}frameColors{frameBG{backdrop{219,219,219,1}border{30,30,30,1}}content{backdrop{60,60,60,1}border{40,40,40,1}}frame{backdrop{228,228,228,1}border{199,199,199,1}}}" },
	goblineer = { L["Goblineer (by Sterling - The Consortium)"], "inlineColors{link{153,255,255,1}link2{153,255,255,1}category{36,106,36,1}category2{85,180,8,1}}textColors{iconRegion{enabled{249,255,247,1}}title{enabled{132,219,9,1}}label{enabled{216,225,211,1}disabled{150,148,140,1}}text{enabled{255,254,250,1}disabled{147,151,139,1}}link{enabled{49,56,133,1}}}fontSizes{normal{15}medium{13}small{12}}edgeSize{1.5}frameColors{frameBG{backdrop{24,24,24,0.93}border{50,50,50,1}}content{backdrop{45,45,45,1}border{0,0,0,0}}frame{backdrop{24,24,24,1}border{100,100,100,0.3}}}" },
	jaded = { L["Jaded (by Ravanys - The Consortium)"], "frameColors{frameBG{backdrop{0,0,0,0.6}border{0,0,0,0.4}}content{backdrop{62,62,62,1}border{72,72,72,1}}frame{backdrop{32,32,32,1}border{2,2,2,0.48}}}textColors{text{enabled{99,219,136,1}disabled{95,98,90,1}}iconRegion{enabled{43,255,156,1}}title{enabled{75,255,150,1}}label{enabled{99,219,136,1}disabled{177,176,168,1}}}edgeSize{1}fontSizes{normal{15}medium{13}small{12}}" },
	tsmdeck = { L["TSMDeck (by Jim Younkin - Power Word: Gold)"], "inlineColors{link2{153,255,255,1}category2{85,180,8,1}link{89,139,255,1}category{80,222,22,1}}textColors{iconRegion{enabled{117,117,122,1}}title{enabled{247,248,255,1}}label{enabled{238,249,237,1}disabled{110,110,110,1}}text{enabled{245,240,251,1}disabled{115,115,115,1}}link{enabled{49,56,133,1}}}fontSizes{normal{14}medium{13}small{12}}edgeSize{1}frameColors{frameBG{backdrop{29,29,29,1}border{20,20,20,1}}content{backdrop{27,27,27,1}border{67,67,65,1}}frame{backdrop{39,39,40,1}border{20,20,20,1}}}" },
	tsmclassic = { L["TSM Classic (by Jim Younkin - Power Word: Gold)"], "inlineColors{link{89,139,255,1}link2{153,255,255,1}category{80,222,22,1}category2{85,180,8,1}}textColors{text{enabled{245,240,251,1}disabled{115,115,115,1}}iconRegion{enabled{216,216,224,1}}title{enabled{247,248,255,1}}label{enabled{238,249,237,1}disabled{110,110,110,1}}}fontSizes{normal{14}medium{13}small{12}}edgeSize{1}frameColors{frameBG{backdrop{8,8,8,1}border{4,2,147,1}}content{backdrop{18,18,18,1}border{102,108,105,1}}frame{backdrop{2,2,2,1}border{4,2,147,1}}}" },
	functional = { L["The Functional Gold Maker (by Xsinthis - The Golden Crusade)"], "inlineColors{category{3,175,222,1}link2{153,255,255,1}tooltip{130,130,250}link{89,139,255,1}category2{6,24,180,1}}textColors{iconRegion{enabled{216,216,224,1}}title{enabled{247,248,255,1}}label{enabled{238,249,237,1}disabled{110,110,110,1}}text{enabled{245,240,251,1}disabled{115,115,115,1}}link{enabled{49,56,133,1}}}fontSizes{normal{14}small{12}}edgeSize{0.5}frameColors{frameBG{backdrop{28,28,28,1}border{74,5,0,1}}content{backdrop{18,18,18,0.64000001549721}border{84,7,3,1}}frame{backdrop{2,2,2,0.48000001907349}border{72,9,4,1}}}" },
}
local defaultTheme = presetThemes.goblineer



-- ============================================================================
-- Module Functions
-- ============================================================================

function Options:RegisterModuleOptions(moduleName, callback)
	private.moduleOptions[moduleName] = callback
end

function Options:Load(parent)
	private.treeGroup = AceGUI:Create("TSMTreeGroup")
	private.treeGroup:SetLayout("Fill")
	private.treeGroup:SetCallback("OnGroupSelected", private.SelectTree)
	if not next(TSM.db.global.optionsTreeStatus) then
		-- set defaults
		TSM.db.global.optionsTreeStatus.groups = { module = true, tooltip = true }
	end
	private.treeGroup:SetStatusTable(TSM.db.global.optionsTreeStatus)
	parent:AddChild(private.treeGroup)

	local moduleChildren = {}
	for name, callback in pairs(private.moduleOptions) do
		tinsert(moduleChildren, {value=name, text=name})
	end
	sort(moduleChildren, function(a, b) return a.value < b.value end)

	-- update the tree items
	local treeInfo = {
		{
			value = "module",
			text = L["Module Options"],
			children = moduleChildren,
		},
		TSM.Tooltips:GetTreeInfo("tooltip"),
	}
	private.treeGroup:SetTree(treeInfo)
	private.treeGroup:SelectByPath("module")
end

function private.SelectTree(treeGroup, _, selection)
	treeGroup:ReleaseChildren()
	StaticPopup_Hide("TSM_GLOBAL_OPERATIONS")

	local major, minor = ("\001"):split(selection)
	if major == "module" then
		if not minor then
			private:LoadOptions(treeGroup)
		else
			private.moduleOptions[minor](treeGroup)
		end
	elseif major == "tooltip" then
		TSM.Tooltips:LoadOptions(treeGroup, minor)
	end
end

function Options:SetDesignDefaults(src, dest)
	for i, v in pairs(src) do
		if dest[i] then
			if type(v) == "table" then
				Options:SetDesignDefaults(v, dest[i])
			end
		else
			if type(v) == "table" then
				dest[i] = CopyTable(v)
			else
				dest[i] = v
			end
		end
	end
end

function Options:LoadDefaultDesign()
	private:DecodeAppearanceData(defaultTheme[2])
end



-- ============================================================================
-- General Options Page
-- ============================================================================

function private:LoadOptions(parent)
	local tg = AceGUI:Create("TSMTabGroup")
	tg:SetLayout("Fill")
	tg:SetFullHeight(true)
	tg:SetFullWidth(true)
	tg:SetTabs({{value=1, text=L["General"]}, {value=2, text=L["Appearance"]}, {value=3, text=L["Profiles"]}, {value=4, text=L["Account Syncing"]}, {value=5, text=L["Misc. Features"]}})
	tg:SetCallback("OnGroupSelected", function(self, _, value)
		self:ReleaseChildren()
		if value == 1 then
			private:LoadOptionsPage(self)
		elseif value == 2 then
			private:LoadAppearancePage(self)
		elseif value == 3 then
			private:LoadProfilesPage(self)
		elseif value == 4 then
			private:LoadMultiAccountPage(self)
		elseif value == 5 then
			private:LoadMiscFeatures(self)
		end
	end)
	parent:AddChild(tg)
	tg:SelectTab(1)
end

function private:LoadOptionsPage(container)
	local auctionTabs, auctionTabOrder
	if AuctionFrame and AuctionFrame.numTabs then
		auctionTabs, auctionTabOrder = {}, {}
		for i = 1, AuctionFrame.numTabs do
			local text = gsub(_G["AuctionFrameTab" .. i]:GetText(), "|r", "")
			text = gsub(text, "|c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]", "")
			auctionTabs[text] = text
			tinsert(auctionTabOrder, text)
		end
	end

	local characterList = {}
	for character in pairs(TSMAPI.Player:GetCharacters(true)) do
		if character ~= UnitName("player") then
			tinsert(characterList, character)
		end
	end



	local guildList, guildValues = {}, {}
	for guild in pairs(TSMAPI.Player:GetGuilds(true)) do
		tinsert(guildList, guild)
		tinsert(guildValues, TSM.db.factionrealm.ignoreGuilds[guild])
	end

	local chatFrameList = {}
	local chatFrameValue, defaultValue
	for i=1, NUM_CHAT_WINDOWS do
		if DEFAULT_CHAT_FRAME == _G["ChatFrame"..i] then
			defaultValue = i
		end
		local name = strlower(GetChatWindowInfo(i) or "")
		if name ~= "" then
			if name == TSM.db.global.chatFrame then
				chatFrameValue = i
			end
			tinsert(chatFrameList, name)
		end
	end
	chatFrameValue = chatFrameValue or defaultValue

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
							settingInfo = { TSM.db.profile.minimapIcon, "hide" },
							relativeWidth = 0.5,
							callback = function(_, _, value)
								if value then
									TSM.LDBIcon:Hide("TradeSkillMaster")
								else
									TSM.LDBIcon:Show("TradeSkillMaster")
								end
							end,
						},
						{
							type = "CheckBox",
							label = L["Store Operations Globally"],
							value = TSM.db.global.globalOperations,
							relativeWidth = 0.5,
							callback = function(_, _, value)
								StaticPopupDialogs["TSM_GLOBAL_OPERATIONS"] = StaticPopupDialogs["TSM_GLOBAL_OPERATIONS"] or {
									text = L["If you have multiple profile set up with operations, enabling this will cause all but the current profile's operations to be irreversibly lost. Are you sure you want to continue?"],
									button1 = YES,
									button2 = CANCEL,
									timeout = 0,
									hideOnEscape = true,
									OnAccept = function()
										-- we shouldn't be running the OnProfileUpdated callback while switching profiles
										TSM.Modules.ignoreProfileUpdated = true
										TSM.db.global.globalOperations = StaticPopupDialogs["TSM_GLOBAL_OPERATIONS"].newValue
										if TSM.db.global.globalOperations then
											-- move current profile to global
											TSM.db.global.operations = CopyTable(TSM.db.profile.operations)
											-- clear out old operations
											for profile in TSMAPI:GetTSMProfileIterator() do
												TSM.db.profile.operations = nil
											end
										else
											-- move global to all profiles
											for profile in TSMAPI:GetTSMProfileIterator() do
												TSM.db.profile.operations = CopyTable(TSM.db.global.operations)
											end
											-- clear out old operations
											TSM.db.global.operations = nil
										end
										TSM.Modules.ignoreProfileUpdated = false
										TSM.Modules:ProfileUpdated()
										if container.frame:IsVisible() then
											container:Reload()
										end
									end,
								}
								StaticPopupDialogs["TSM_GLOBAL_OPERATIONS"].newValue = value
								container:Reload()
								TSMAPI.Util:ShowStaticPopupDialog("TSM_GLOBAL_OPERATIONS")
							end,
							tooltip = L["If checked, operations will be stored globally rather than by profile. TSM groups are always stored by profile. Note that if you have multiple profiles setup already with separate operation information, changing this will cause all but the current profile's operations to be lost."],
						},
						{
							type = "Dropdown",
							label = L["Chat Tab"],
							list = chatFrameList,
							value = chatFrameValue,
							callback = function(_, _, value)
								TSM.db.global.chatFrame = chatFrameList[value]
							end,
							relativeWidth = 0.5,
							tooltip = L["This option sets which tab TSM and its modules will use for printing chat messages."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Dropdown",
							label = L["Forget Characters"],
							list = characterList,
							relativeWidth = 0.5,
							callback = function(_, _, value)
								local name = characterList[value]
								TSM.Inventory:RemoveCharacterData(name)
								TSM:Printf(L["%s removed."], name)
								container:Reload()
							end,
							tooltip = L["If you delete, rename, or transfer a character off the current faction/realm, you should remove it from TSM's list of characters using this dropdown."],
						},
						{
							type = "Dropdown",
							label = L["Ignore Guilds"],
							list = guildList,
							value = guildValues,
							relativeWidth = 0.5,
							multiselect = true,
							callback = function(_, _, key, value)
								local guild = guildList[key]
								TSM.db.factionrealm.ignoreGuilds[guild] = value
							end,
							tooltip = L["Any guilds which are selected will be ignored for inventory tracking purposes."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["BankUI Settings"],
					children = {
						{
							type = "Dropdown",
							label = L["Default BankUI Tab"],
							list = TSM:getBankTabs(),
							settingInfo = { TSM.db.global, "bankUITab" },
							relativeWidth = 0.5,
							tooltip = L["The default tab shown in the 'BankUI' frame."],
						},
						{
							type = "Slider",
							value = TSM.db.global.moveDelay,
							label = L["BankUI Move Delay"],
							min = 0,
							max = 2,
							step = 0.1,
							relativeWidth = 0.49,
							disabled = not TSM.db.global.moveDelay,
							callback = function(self, _, value)
								if value > 2 then value = 2 end
								self:SetValue(value)
								TSM.db.global.moveDelay = value
							end,
							tooltip = L["This slider controls how long the BankUI code will sleep betwen individual moves, default of 0 should be fine but increase it if you run into problems."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["Clean Bags Automatically"],
							settingInfo = { TSM.db.profile, "cleanBags" },
							relativeWidth = 0.5,
							tooltip = L["If checked, after moving items using BankUI your bags will be automatically sorted / re-stacked."],
						},
						{
							type = "CheckBox",
							label = L["Clean Bank Automatically"],
							settingInfo = { TSM.db.profile, "cleanBank" },
							relativeWidth = 0.5,
							tooltip = L["If checked, after moving items using BankUI at the bank your bank bags will be automatically sorted / re-stacked."],
						},
						{
							type = "CheckBox",
							label = L["Clean Reagent Bank Automatically"],
							settingInfo = { TSM.db.profile, "cleanReagentBank" },
							relativeWidth = 0.5,
							tooltip = L["If checked, after moving items using BankUI at the bank your reagent bank bags will be automatically sorted / re-stacked."],
						},
					}
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Auction House Tab Settings"],
					children = {
						{
							type = "Dropdown",
							label = auctionTabs and L["Default Tab"] or L["Default Tab (Open Auction House to Enable)"],
							list = auctionTabs or {},
							order = auctionTabOrder,
							disabled = not auctionTabs,
							settingInfo = { TSM.db.profile, "defaultAuctionTab" },
							relativeWidth = 0.5,
						},
						{
							type = "CheckBox",
							label = L["Open All Bags with Auction House"],
							settingInfo = { TSM.db.profile, "openAllBags" },
							relativeWidth = 0.5,
							tooltip = L["If checked, your bags will be automatically opened when you open the auction house."],
						},
						{
							type = "CheckBox",
							label = L["Protect AH Frame (Requires Reload)"],
							settingInfo = { TSM.db.profile, "protectAH" },
							tooltip = L["If checked, TSM will provent WoW from closing the auction house frame when other UI frames are opened."],
						},
						{
							type = "CheckBox",
							label = L["Make Auction Frame Movable"],
							settingInfo = { TSM.db.profile, "auctionFrameMovable" },
							callback = function(_, _, value)
								if AuctionFrame then
									AuctionFrame:SetMovable(value)
								end
							end,
						},
						{
							type = "Slider",
							label = L["Auction Rows (Requires Reload)"],
							settingInfo = { TSM.db.profile, "auctionResultRows" },
							relativeWidth = 0.5,
							min = 8,
							max = 25,
							step = 1,
							tooltip = L["Changes how many rows are shown in the auction results tables."],
						},
						{
							type = "Slider",
							label = L["Auction Frame Scale"],
							settingInfo = { TSM.db.profile, "auctionFrameScale" },
							isPercent = true,
							relativeWidth = 0.5,
							min = 0.1,
							max = 2,
							step = 0.05,
							callback = function(_, _, value) if AuctionFrame then AuctionFrame:SetScale(value) end end,
							tooltip = L["Changes the size of the auction frame. The size of the detached TSM auction frame will always be the same as the main auction frame."],
						},
					},
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Appearance Tab
-- ============================================================================

function private:LoadAppearancePage(parent)
	local presetThemeList = {}
	for key, tbl in pairs(presetThemes) do
		presetThemeList[key] = tbl[1]
	end
	local savedThemeList = {}
	for _, info in ipairs(TSM.db.profile.savedThemes) do
		tinsert(savedThemeList, info.name)
	end
	local themeName = ""

	local page = {
		{
			type = "ScrollFrame",
			layout = "flow",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Appearance Settings"],
					children = {
						{
							type = "Label",
							text = L["Use the options below to change and tweak the appearance of TSM."],
							relativeWidth = 1,
						},
						{
							type = "Dropdown",
							label = L["Import Preset TSM Theme"],
							list = presetThemeList,
							relativeWidth = 1,
							callback = function(_, _, key)
								if presetThemes[key] then
									private:DecodeAppearanceData(presetThemes[key][2])
								end
							end,
							tooltip = L["Select a theme from this dropdown to import one of the preset TSM themes."],
						},
						{
							type = "Dropdown",
							label = L["Load Saved Theme"],
							list = savedThemeList,
							relativeWidth = 1,
							callback = function(_, _, index)
								private:DecodeAppearanceData(TSM.db.profile.savedThemes[index].theme)
							end,
							tooltip = L["Select a theme from this dropdown to import one of your saved TSM themes."],
						},
						{
							type = "EditBox",
							label = L["Theme Name"],
							relativeWidth = 0.5,
							callback = function(_, _, value) themeName = value:trim() end,
						},
						{
							type = "Button",
							text = L["Save Theme"],
							relativeWidth = 0.5,
							callback = function(_, _, value)
								if themeName == "" then
									return TSM:Print(L["Theme name is empty."])
								end
								TSM:Printf(L["Saved theme: %s."], themeName)
								tinsert(TSM.db.profile.savedThemes, { name = themeName, theme = private:EncodeAppearanceData() })
								parent:Reload()
							end,
						},
						{
							type = "Button",
							text = L["Restore Default Colors"],
							relativeWidth = 1,
							callback = function() Options:LoadDefaultDesign() parent:Reload() end,
							tooltip = L["Restores all the color settings below to their default values."],
						},
						{
							type = "Button",
							text = L["Import Appearance Settings"],
							relativeWidth = 0.5,
							callback = private.ShowImportFrame,
							tooltip = L["This allows you to import appearance settings which other people have exported."],
						},
						{
							type = "Button",
							text = L["Export Appearance Settings"],
							relativeWidth = 0.5,
							callback = private.ShowExportFrame,
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
		return { tbl[1] / 255, tbl[2] / 255, tbl[3] / 255, tbl[4] }
	end

	local function compressColor(r, g, b, a)
		return { r * 255, g * 255, b * 255, a }
	end

	local frameColorOptions = {
		{ L["Frame Background - Backdrop"], "frameBG", "backdrop" },
		{ L["Frame Background - Border"], "frameBG", "border" },
		{ L["Region - Backdrop"], "frame", "backdrop" },
		{ L["Region - Border"], "frame", "border" },
		{ L["Content - Backdrop"], "content", "backdrop" },
		{ L["Content - Border"], "content", "border" },
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
				TSM:UpdateDesign()
			end,
		}
		tinsert(page[1].children[1].children, widget)
	end

	tinsert(page[1].children[1].children, { type = "HeadingLine" })

	local textColorOptions = {
		{ L["Icon Region"], "iconRegion", "enabled" },
		{ L["Title"], "title", "enabled" },
		{ L["Label Text - Enabled"], "label", "enabled" },
		{ L["Label Text - Disabled"], "label", "disabled" },
		{ L["Content Text - Enabled"], "text", "enabled" },
		{ L["Content Text - Disabled"], "text", "disabled" },
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
				TSM:UpdateDesign()
			end,
		}
		tinsert(page[1].children[1].children, widget)
	end

	tinsert(page[1].children[1].children, { type = "HeadingLine" })

	local inlineColorOptions = {
		{ L["Link Text (Requires Reload)"], "link" },
		{ L["Link Text 2 (Requires Reload)"], "link2" },
		{ L["Category Text (Requires Reload)"], "category" },
		{ L["Category Text 2 (Requires Reload)"], "category2" },
		{ L["Item Tooltip Text"], "tooltip" },
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
				TSM:UpdateDesign()
			end,
		}
		tinsert(page[1].children[1].children, widget)
	end

	tinsert(page[1].children[1].children, { type = "HeadingLine" })

	local miscWidgets = {
		{
			type = "Slider",
			relativeWidth = 0.5,
			label = L["Small Text Size (Requires Reload)"],
			min = 6,
			max = 30,
			step = 1,
			settingInfo = { TSM.db.profile.design.fontSizes, "small" },
		},
		{
			type = "Slider",
			relativeWidth = 0.5,
			label = L["Medium Text Size (Requires Reload)"],
			min = 6,
			max = 30,
			step = 1,
			settingInfo = { TSM.db.profile.design.fontSizes, "medium" },
		},
		{
			type = "Slider",
			relativeWidth = 0.5,
			label = L["Normal Text Size (Requires Reload)"],
			min = 6,
			max = 30,
			step = 1,
			settingInfo = { TSM.db.profile.design.fontSizes, "normal" },
		},
		{
			type = "Slider",
			relativeWidth = 0.5,
			label = L["Border Thickness (Requires Reload)"],
			min = 0,
			max = 3,
			step = .1,
			settingInfo = { TSM.db.profile.design, "edgeSize" },
		},
	}
	for _, widget in ipairs(miscWidgets) do
		tinsert(page[1].children[1].children, widget)
	end

	TSMAPI.GUI:BuildOptions(parent, page)
end



-- ============================================================================
-- Profiles Tab
-- ============================================================================

function private:LoadProfilesPage(container)
	-- Popup Confirmation Window used in this module
	StaticPopupDialogs["TSMDeleteConfirm"] = StaticPopupDialogs["TSMDeleteConfirm"] or {
		text = L["Are you sure you want to delete the selected profile?"],
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnCancel = false,
		-- OnAccept defined later
	}
	StaticPopupDialogs["TSMCopyProfileConfirm"] = StaticPopupDialogs["TSMCopyProfileConfirm"] or {
		text = L["Are you sure you want to overwrite the current profile with the selected profile?"],
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnCancel = false,
		-- OnAccept defined later
	}

	local profiles = {}
	for _, profileName in ipairs(TSM.db:GetProfiles()) do
		if profileName ~= TSM.db:GetCurrentProfile() then
			profiles[profileName] = profileName
		end
	end

	local page = {
		{
			-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "Flow",
			children = {
				{
					type = "Label",
					text = L["You can change the active database profile, so you can have different settings for every character."],
					relativeWidth = 1,
				},
				{
					type = "Spacer"
				},
				{
					type = "Label",
					text = L["Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over."],
					relativeWidth = 1,
				},
				{
					type = "Button",
					text = L["Reset Profile"],
					relativeWidth = 0.5,
					callback = function() TSM.db:ResetProfile() end,
				},
				{
					type = "Label",
					text = L["Current Profile:"].." "..TSMAPI.Design:ColorText(TSM.db:GetCurrentProfile(), "link"),
					relativeWidth = 0.5,
				},
				{
					type = "HeadingLine",
				},
				{
					type = "Label",
					text = L["You can either create a new profile by entering a name in the editbox, or choose one of the already exisiting profiles."],
					relativeWidth = 1,
				},
				{
					type = "EditBox",
					label = L["New"],
					value = "",
					relativeWidth = 0.5,
					callback = function(_, _, value)
						value = value:trim()
						if not TSM.db:IsValidProfileName(value) then
							return TSM:Print(L["This is not a valid profile name. Profile names must be at least one character long and may not contain '@' characters."])
						end
						TSM.db:SetProfile(value)
						container:Reload()
					end,
				},
				{
					type = "Dropdown",
					label = L["Existing Profiles"],
					list = profiles,
					value = TSM.db:GetCurrentProfile(),
					disabled = not next(profiles),
					relativeWidth = 0.5,
					callback = function(_, _, value)
						if value == TSM.db:GetCurrentProfile() then return end
						TSM.db:SetProfile(value)
						container:Reload()
					end,
				},
				{
					type = "HeadingLine",
				},
				{
					type = "Label",
					text = L["Copy the settings from one existing profile into the currently active profile."],
					relativeWidth = 1,
				},
				{
					type = "Dropdown",
					label = L["Copy From"],
					list = profiles,
					disabled = not next(profiles),
					value = "",
					callback = function(_, _, value)
						if value == TSM.db:GetCurrentProfile() then return end
						StaticPopupDialogs["TSMCopyProfileConfirm"].OnAccept = function()
							TSM.db:CopyProfile(value)
							container:Reload()
						end
						TSMAPI.Util:ShowStaticPopupDialog("TSMCopyProfileConfirm")
					end,
				},
				{
					type = "HeadingLine",
				},
				{
					type = "Label",
					text = L["Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file."],
					relativeWidth = 1,
				},
				{
					type = "Dropdown",
					label = L["Delete a Profile"],
					list = profiles,
					disabled = not next(profiles),
					value = "",
					callback = function(_, _, value)
						if TSM.db:GetCurrentProfile() == value then return end
						StaticPopupDialogs["TSMDeleteConfirm"].OnAccept = function()
							TSM.db:DeleteProfile(value)
							container:Reload()
						end
						TSMAPI.Util:ShowStaticPopupDialog("TSMDeleteConfirm")
					end,
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Multi-Account Tab
-- ============================================================================

function private:LoadMultiAccountPage(parent)
	local page = {
		{
			type = "ScrollFrame",
			layout = "flow",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Various modules can sync their data between multiple accounts automatically whenever you're logged into both accounts."],
						},
						{
							type = "Spacer",
						},
						{
							type = "Label",
							relativeWidth = 1,
							text = L["First, log into a character on the same realm (and faction) on both accounts. Type the name of the OTHER character you are logged into in the box below. Once you have done this on both accounts, TSM will do the rest automatically. Once setup, syncing will automatically happen between the two accounts while on any character on the account (not only the one you entered during this setup)."],
						},
						{
							type = "EditBox",
							relativeWidth = 1,
							label = L["Character Name on Other Account"],
							callback = function(self, _, value)
								value = value:trim()
								local function OnSyncSetup()
									TSM:Print(L["Connection established!"])
									if value == self:GetText() then
										parent:Reload()
									end
								end
								if TSM.Sync:DoSetup(value:trim(), OnSyncSetup) then
									TSM:Printf(L["Establishing connection to %s. Make sure that you've entered this character's name on the other account."], value)
								else
									self:SetText("")
								end
							end,
							tooltip = L["See instructions above this editbox."],
						},
					},
				},
			},
		},
	}

	if next(TSM.db.factionrealm.syncAccounts) then
		local widgets = {
			{
				type = "HeadingLine",
			},
			{
				type = "Button",
				text = L["Refresh Sync Status"],
				relativeWidth = 1,
				callback = function() parent:Reload() end,
			},
		}
		for _, widget in ipairs(widgets) do
			tinsert(page[1].children[1].children, widget)
		end
	end

	-- extra multi-account syncing widgets
	for account in pairs(TSM.db.factionrealm.syncAccounts) do
		local playerList = {}
		for player in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters, account) do
			tinsert(playerList, player)
		end
		local widget = {
			type = "InlineGroup",
			layout = "flow",
			children = {
				{
					type = "Label",
					relativeWidth = 0.7,
					text = L["Status: "]..TSM.Sync:GetConnectionStatus(account),
				},
				{
					type = "Label",
					relativeWidth = 0.05,
				},
				{
					type = "Button",
					text = L["Remove Account"],
					relativeWidth = 0.24,
					callback = function()
						TSM.Sync:RemoveSync(account)
						TSM:Print(L["Sync removed. Make sure you remove the sync from the other account as well."])
						parent:Reload()
					end,
				},
				{
					type = "Label",
					relativeWidth = 1,
					text = L["Known Characters: "]..TSMAPI.Design:GetInlineColor("link")..table.concat(playerList, ", ").."|r",
				},
			},
		}
		tinsert(page[1].children, widget)
	end

	TSMAPI.GUI:BuildOptions(parent, page)
end



-- ============================================================================
-- Multi-Account Tab
-- ============================================================================

function private:PromptToReload()
	StaticPopupDialogs["TSMReloadPrompt"] = StaticPopupDialogs["TSMReloadPrompt"] or {
		text = L["You must reload your UI for these settings to take effect. Reload now?"],
		button1 = YES,
		button2 = NO,
		timeout = 0,
		OnAccept = ReloadUI,
	}
	TSMAPI.Util:ShowStaticPopupDialog("TSMReloadPrompt")
end

function private:LoadMiscFeatures(container)
	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "Flow",
					title = L["Auction Buys"],
					children = {
						{
							type = "Label",
							text = L["The auction buys feature will change the 'You have won an auction of XXX' text into something more useful which contains the link, stack size, and price of the item you bought."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = L["Enable Auction Buys Feature"],
							relativeWidth = 1,
							settingInfo = {TSM.db.global, "auctionBuyEnabled"},
							callback = private.PromptToReload,
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "Flow",
					title = L["Auction Sales"],
					children = {
						{
							type = "Label",
							text = L["The auction sales feature will change the 'A buyer has been found for your auction of XXX' text into something more useful which contains a link to the item and, if possible, the amount the auction sold for."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = L["Enable Auction Sales Feature"],
							relativeWidth = 1,
							settingInfo = {TSM.db.global, "auctionSaleEnabled"},
							callback = private.PromptToReload,
						},
						{
							type = "Dropdown",
							label = L["Enable Sound"],
							relativeWidth = 0.5,
							list = TSMAPI:GetSounds(),
							settingInfo = {TSM.db.global, "auctionSaleSound"},
							tooltip = L["Play the selected sound when one of your auctions sells."],
						},
						{
							type = "Button",
							text = L["Test Selected Sound"],
							relativeWidth = 0.49,
							callback = function() TSMAPI:DoPlaySound(TSM.db.global.auctionSaleSound) end,
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "Flow",
					title = L["Twitter Integration"],
					children = {
						{
							type = "Label",
							text = L["If you have WoW's Twitter integration setup, TSM will add a share link to its enhanced auction sale / purchase messages (enabled above) as well as replace the URL in item tweets with a TSM link."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = L["Enable Tweet Enhancement (Only Works if WoW Twitter Integration is Setup)"],
							relativeWidth = 1,
							disabled = not C_Social.IsSocialEnabled(),
							settingInfo = {TSM.db.global, "tsmItemTweetEnabled"},
							callback = private.PromptToReload,
						},
					},
				},
			},
		},
	}
	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:GetSubStr(str)
	if not str then return end
	local startIndex, endIndex
	local balance = 0

	for i = 1, #str do
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
	return strsub(str, startIndex + 1, endIndex - 1), startIndex, endIndex
end

function private:StringToTable(data)
	local result = {}
	while true do
		local value, s, e = private:GetSubStr(data, { '{', '}' })
		if not value then return end
		local key = strsub(data, 1, s - 1)
		value = tonumber(value) or value

		if type(value) == "string" and strfind(value, "{") then
			value = private:StringToTable(value)
		elseif type(value) == "string" and strfind(value, ",") then
			value = { (","):split(value) }
			for i = 1, 4 do
				value[i] = tonumber(value[i])
			end
		end

		if type(value) == "nil" then
			return
		end

		result[key] = value
		if e + 1 > #data then
			break
		end
		data = strsub(data, e + 1, #data)
	end
	return result
end

function private:DecodeAppearanceData(encodedData)
	if not encodedData then return end
	encodedData = gsub(encodedData, " ", "")

	local result = private:StringToTable(encodedData, 1)
	if not result then return TSM:Print(L["Invalid appearance data."]) end
	TSM.db.profile.design = result
	Options:SetDesignDefaults(TSM.designDefaults, TSM.db.profile.design)
	TSM:UpdateDesign()
end

function private:ShowImportFrame()
	local data

	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TradeSkillMaster - " .. L["Import Appearance Settings"])
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
	eb:SetCallback("OnEnterPressed", function(_, _, val) btn:SetDisabled(false) data = val end)
	f:AddChild(eb)

	btn:SetDisabled(true)
	btn:SetText(L["Import Appearance Settings"])
	btn:SetFullWidth(true)
	btn:SetCallback("OnClick", function() private:DecodeAppearanceData(data) f:Hide() end)
	f:AddChild(btn)

	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end

function private:TblToStr(tbl)
	local tmp = {}
	for key, value in pairs(tbl) do
		tinsert(tmp, key .. "{")
		if tonumber(value) then
			tinsert(tmp, value)
		elseif #value == 0 then
			tinsert(tmp, private:TblToStr(value))
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

function private:EncodeAppearanceData()
	local keys = { "frameColors", "textColors", "inlineColors", "edgeSize", "fontSizes" }
	local testTbl = {}
	for _, key in ipairs(keys) do
		testTbl[key] = TSM.db.profile.design[key]
	end
	return private:TblToStr(testTbl)
end

function private:ShowExportFrame()
	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TradeSkillMaster - " .. L["Export Appearance Settings"])
	f:SetLayout("Fill")
	f:SetHeight(300)

	local eb = AceGUI:Create("TSMMultiLineEditBox")
	eb:SetLabel(L["Appearance Data"])
	eb:SetMaxLetters(0)
	eb:SetText(private:EncodeAppearanceData())
	f:AddChild(eb)

	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end
