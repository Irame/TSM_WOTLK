-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for the new tooltip options

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local FeaturesGUI = TSM:NewModule("FeaturesGUI")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {inventoryFilters={characters={}, guilds={}, name="", group=nil}}



-- ============================================================================
-- Module Functions
-- ============================================================================

function FeaturesGUI:LoadGUI(parent)
	local tabGroup = AceGUI:Create("TSMTabGroup")
	tabGroup:SetLayout("Fill")
	tabGroup:SetTabs({{text=L["Info"], value=1}, {text=L["Inventory Viewer"], value=2}, {text=L["Macro Setup"], value=3}, {text=L["Custom Price Sources"], value=4}})
	tabGroup:SetCallback("OnGroupSelected", function(_, _, value)
		tabGroup:ReleaseChildren()
		if value == 1 then
			private:LoadInfo(tabGroup)
		elseif value == 2 then
			private:LoadInventoryViewer(tabGroup)
		elseif value == 3 then
			private:LoadMacroCreation(tabGroup)
		elseif value == 4 then
			private:LoadCustomPriceSources(tabGroup)
		end
	end)
	parent:AddChild(tabGroup)
	tabGroup:SelectTab(1)
end



-- ============================================================================
-- Info Tab
-- ============================================================================

function private:LoadInfo(parent)
	local color = TSMAPI.Design:GetInlineColor("link")
	local moduleText = {
		TSMAPI.Design:ColorText("Accounting", "link") .. " - " .. L["Keeps track of all your sales and purchases from the auction house allowing you to easily track your income and expenditures and make sure you're turning a profit."],
		TSMAPI.Design:ColorText("AppHelper", "link") .. " - " .. L["Acts as a link between the other TradeSkillMaster modules and the TSM Desktop Application."],
		TSMAPI.Design:ColorText("AuctionDB", "link") .. " - " .. L["Performs scans of the auction house and calculates the market value of items as well as the minimum buyout. This information can be shown in items' tooltips as well as used by other modules."],
		TSMAPI.Design:ColorText("Auctioning", "link") .. " - " .. L["Posts and cancels your auctions to / from the auction house according to pre-set rules. Also, this module can show you markets which are ripe for being reset for a profit."],
		TSMAPI.Design:ColorText("Crafting", "link") .. " - " .. L["Allows you to build a queue of crafts that will produce a profitable, see what materials you need to obtain, and actually craft the items."],
		TSMAPI.Design:ColorText("Destroying", "link") .. " - " .. L["Mills, prospects, and disenchants items at super speed!"],
		TSMAPI.Design:ColorText("Mailing", "link") .. " - " .. L["Allows you to quickly and easily empty your mailbox as well as automatically send items to other characters with the single click of a button."],
		TSMAPI.Design:ColorText("Shopping", "link") .. " - " .. L["Provides interfaces for efficiently searching for items on the auction house. When an item is found, it can easily be bought, canceled (if it's yours), or even posted from your bags."],
		TSMAPI.Design:ColorText("Vendoring", "link") .. " - " .. L["Enhances the vendor frame by allowing you to easily buy and sell items."],
		TSMAPI.Design:ColorText("Warehousing", "link") .. " - " .. L["Manages your inventory by allowing you to easily move stuff between your bags, bank, and guild bank."],
	}

	local page = {
		{
			type = "ScrollFrame",
			layout = "flow",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Resources:"],
					noBorder = true,
					children = {
						{
							type = "Label",
							relativeWidth = 0.5,
							text = L["Using our website you can get help with TSM, suggest features, and give feedback."].."\n",
						},
						{
							type = "Image",
							sizeRatio = .15625,
							relativeWidth = 0.5,
							image = "Interface\\Addons\\TradeSkillMaster\\Media\\banner",
						},
						{
							type = "HeadingLine"
						},
						{
							type = "Image",
							sizeRatio = .15628,
							relativeWidth = 1,
							image = "Interface\\Addons\\TradeSkillMaster\\Media\\AppBanner",
						},
						{
							type = "Label",
							relativeWidth = 1,
							text = format("\n" .. L["Check out our completely free, desktop application which has tons of features including deal notification emails, automatic updating of AuctionDB prices, automatic TSM setting backup, and more! You can find this app by going to %s."], TSMAPI.Design:ColorText("http://tradeskillmaster.com/app/overview", "link")),
						}
					},
				},
				{
					type = "Spacer",
				},
				{
					type = "InlineGroup",
					layout = "List",
					title = L["Module Information:"],
					noBorder = true,
					children = {},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["TradeSkillMaster Team"],
					noBorder = true,
					children = {
						{
							type = "Label",
							text = TSMAPI.Design:ColorText(L["Active Contributors:"], "link") .. " Sapu94 (Project Manager), Bart39 (Developer), Sigsig (Developer), MuffinPvEHero (Developer), DawnValentine (Social and Community Coordinator), Gumdrops (Support Manager and User Evangelist)",
							relativeWidth = 1,
						},
						{
							type = "Label",
							text = TSMAPI.Design:ColorText(L["Past Contributers (Special Thanks):"], "link") .. " Cente (Co-Founder), Drethic (Website), Geemoney (Addon), Mischanix (Addon), Xubera (Addon), cduhn (Addon), cjo20 (Addon), Pwnstein (Logo/Graphics), PsyTech (Addon)",
							relativeWidth = 1,
						},
					},
				},
			},
		},
	}

	for _, text in ipairs(moduleText) do
		tinsert(page[1].children[#page[1].children-1].children, {
			type = "Label",
			text = text.."\n",
			relativeWidth = 1,
		})
	end

	TSMAPI.GUI:BuildOptions(parent, page)
end



-- ============================================================================
-- Inventory Viewer Tab
-- ============================================================================

function private:LoadInventoryViewer(container)
	local playerList, guildList = {}, {}
	for name in pairs(TSMAPI.Player:GetCharacters()) do
		playerList[name] = name
		private.inventoryFilters.characters[name] = true
	end
	for name in pairs(TSMAPI.Player:GetGuilds()) do
		guildList[name] = name
		private.inventoryFilters.guilds[name] = true
	end
	private.inventoryFilters.group = nil

	local stCols = {
		{
			name = L["Item Name"],
			width = 0.35,
		},
		{
			name = L["Bags"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["Bank"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["Mail"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["GVault"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["AH"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["Total"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["Total Value"],
			width = 0.17,
			align = "RIGHT",
		}
	}
	local stHandlers = {
		OnEnter = function(_, data, self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			TSMAPI.Util:SafeTooltipLink(data.itemString)
			GameTooltip:Show()
		end,
		OnLeave = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end
	}

	local totalValue = 0
	local playerData, guildData = TSM.Inventory:GetAllData()
	for _, data in pairs(playerData) do
		for itemString, quantity in pairs(data.bag) do
			totalValue = totalValue + (TSMAPI:GetCustomPriceValue(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0) * quantity
		end
		for itemString, quantity in pairs(data.bank) do
			totalValue = totalValue + (TSMAPI:GetCustomPriceValue(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0) * quantity
		end
		for itemString, quantity in pairs(data.reagentBank) do
			totalValue = totalValue + (TSMAPI:GetCustomPriceValue(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0) * quantity
		end
		for itemString, quantity in pairs(data.auction) do
			totalValue = totalValue + (TSMAPI:GetCustomPriceValue(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0) * quantity
		end
		for itemString, quantity in pairs(data.mail) do
			totalValue = totalValue + (TSMAPI:GetCustomPriceValue(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0) * quantity
		end
	end
	for _, data in pairs(guildData) do
		for itemString, quantity in pairs(data) do
			totalValue = totalValue + (TSMAPI:GetCustomPriceValue(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0) * quantity
		end
	end

	local page = {
		{
			type = "SimpleGroup",
			layout = "TSMFillList",
			children = {
				{
					type = "SimpleGroup",
					layout = "Flow",
					children = {
						{
							type = "EditBox",
							label = L["Item Search"],
							relativeWidth = 0.2,
							onTextChanged = true,
							callback = function(_, _, value)
								private.inventoryFilters.name = value:trim()
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "GroupBox",
							label = L["Group"],
							relativeWidth = 0.2,
							callback = function(_, _, value)
								private.inventoryFilters.group = value
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "Dropdown",
							label = L["Characters"],
							relativeWidth = 0.2,
							list = playerList,
							value = private.inventoryFilters.characters,
							multiselect = true,
							callback = function(_, _, key, value)
								private.inventoryFilters.characters[key] = value
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "Dropdown",
							label = L["Guilds"],
							relativeWidth = 0.2,
							list = guildList,
							value = private.inventoryFilters.guilds,
							multiselect = true,
							callback = function(_, _, key, value)
								private.inventoryFilters.guilds[key] = value
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "EditBox",
							label = L["Value Price Source"],
							relativeWidth = 0.2,
							acceptCustom = true,
							settingInfo = {TSM.db.profile, "inventoryViewerPriceSource"},
							callback = function() container:Reload() end,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Label",
							relativeWidth = 1,
							text = format(L["The total value of all your items is %s!"], TSMAPI:MoneyToString(totalValue)),
						},
					},
				},
				{
					type = "HeadingLine",
				},
				{
					type = "ScrollingTable",
					tag = "TSM_INVENTORY_VIEWER",
					colInfo = stCols,
					handlers = stHandlers,
					defaultSort = 1,
					selectionDisabled = true,
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
	private:UpdateInventoryViewerST()
end

function private:AddInventoryItem(items, itemString, key, quantity)
	itemString = TSMAPI.Item:ToItemString(itemString)
	items[itemString] = items[itemString] or {total=0, bags=0, bank=0, guild=0, auctions=0, mail=0}
	items[itemString].total = items[itemString].total + quantity
	items[itemString][key] = items[itemString][key] + quantity
end

function private:UpdateInventoryViewerST()
	local items, rowData = {}, {}

	local playerData, guildData = TSM.Inventory:GetAllData()
	for playerName, selected in pairs(private.inventoryFilters.characters) do
		if selected and playerData[playerName] then
			for itemString, quantity in pairs(playerData[playerName].bag) do
				private:AddInventoryItem(items, itemString, "bags", quantity)
			end
			for itemString, quantity in pairs(playerData[playerName].bank) do
				private:AddInventoryItem(items, itemString, "bank", quantity)
			end
			for itemString, quantity in pairs(playerData[playerName].reagentBank) do
				private:AddInventoryItem(items, itemString, "bank", quantity)
			end
			for itemString, quantity in pairs(playerData[playerName].auction) do
				private:AddInventoryItem(items, itemString, "auctions", quantity)
			end
			for itemString, quantity in pairs(playerData[playerName].mail) do
				private:AddInventoryItem(items, itemString, "mail", quantity)
			end
		end
	end
	for guildName, selected in pairs(private.inventoryFilters.guilds) do
		if selected and guildData[guildName] then
			for itemString, quantity in pairs(guildData[guildName]) do
				private:AddInventoryItem(items, itemString, "guild", quantity)
			end
		end
	end

	for itemString, data in pairs(items) do
		local name = TSMAPI.Item:GetName(itemString)
		local itemLink = TSMAPI.Item:GetLink(itemString)
		local marketValue = TSMAPI:GetCustomPriceValue(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0
		local groupPath = TSMAPI.Groups:GetPath(itemString)
		if (not name or private.inventoryFilters.name == "" or strfind(strlower(name), private.inventoryFilters.name)) and (not private.inventoryFilters.group or groupPath and strfind(groupPath, "^" .. TSMAPI.Util:StrEscape(private.inventoryFilters.group))) then
			tinsert(rowData, {
				cols = {
					{
						value = itemLink or name or itemString,
						sortArg = name or "",
					},
					{
						value = data.bags,
						sortArg = data.bags,
					},
					{
						value = data.bank,
						sortArg = data.bank,
					},
					{
						value = data.mail,
						sortArg = data.mail,
					},
					{
						value = data.guild,
						sortArg = data.guild,
					},
					{
						value = data.auctions,
						sortArg = data.auctions,
					},
					{
						value = data.total,
						sortArg = data.total,
					},
					{
						value = TSMAPI:MoneyToString(data.total * marketValue) or "---",
						sortArg = data.total * marketValue,
					},
				},
				itemString = itemString,
				itemLink = itemLink,
			})
		end
	end

	sort(rowData, function(a, b) return a.cols[#a.cols].value > b.cols[#a.cols].value end)
	TSMAPI.GUI:UpdateTSMScrollingTableData("TSM_INVENTORY_VIEWER", rowData)
end



-- ============================================================================
-- Macro Setup Tab
-- ============================================================================

function private:LoadMacroCreation(container)
	-- set default buttons (or use current ones)
	local macroButtonNames = {}
	local macroButtons = {}
	local body = GetMacroBody(GetMacroIndexByName("TSMMacro") or 0)
	if TSMAPI:HasModule("Auctioning") then
		macroButtonNames.auctioningPost = "TSMAuctioningPostButton"
		macroButtonNames.auctioningCancel = "TSMAuctioningCancelButton"
		macroButtons.auctioningPost = (not body or strfind(body, macroButtonNames.auctioningPost)) and true or false
		macroButtons.auctioningCancel = (not body or strfind(body, macroButtonNames.auctioningCancel)) and true or false
	end
	if TSMAPI:HasModule("Crafting") then
		macroButtonNames.craftingCraftNext = "TSMCraftNextButton"
		macroButtons.craftingCraftNext = (not body or strfind(body, macroButtonNames.craftingCraftNext)) and true or false
	end
	if TSMAPI:HasModule("Destroying") then
		macroButtonNames.destroyingDestroyNext = "TSMDestroyButton"
		macroButtons.destroyingDestroyNext = (not body or strfind(body, macroButtonNames.destroyingDestroyNext)) and true or false
	end
	if TSMAPI:HasModule("Shopping") then
		macroButtonNames.shoppingBuyout = "TSMShoppingBuyoutButton"
		macroButtonNames.shoppingBuyoutConfirmation = "TSMShoppingBuyoutConfirmationButton"
		macroButtonNames.shoppingCancelConfirmation = "TSMShoppingCancelConfirmationButton"
		macroButtons.shoppingBuyout = (not body or strfind(body, macroButtonNames.shoppingBuyout)) and true or false
		macroButtons.shoppingBuyoutConfirmation = (not body or strfind(body, macroButtonNames.shoppingBuyoutConfirmation)) and true or false
		macroButtons.shoppingCancelConfirmation = (not body or strfind(body, macroButtonNames.shoppingCancelConfirmation)) and true or false
	end

	if TSMAPI:HasModule("Vendoring") then
		macroButtonNames.vendoringSellAll = "TSMVendoringSellAllButton"
		macroButtons.vendoringSellAll = (not body or strfind(body, macroButtonNames.vendoringSellAll)) and true or false
	end

	-- set default options (or use current ones)
	local macroOptions = nil
	local currentBindings = {GetBindingKey("MACRO TSMMacro")}
	if #currentBindings > 0 and #currentBindings <= 2 and strfind(currentBindings[1], "MOUSEWHEEL") then
		macroOptions = {}
		if #currentBindings == 2 then
			-- assume it's up/down
			macroOptions.up = true
			macroOptions.down = true
		else
			macroOptions.up = strfind(currentBindings[1], "MOUSEWHEELUP") and true or false
			macroOptions.down = strfind(currentBindings[1], "MOUSEWHEELDOWN") and true or false
		end
		-- use modifiers from the first binding
		macroOptions.ctrl = strfind(currentBindings[1], "CTRL") and true or false
		macroOptions.shift = strfind(currentBindings[1], "SHIFT") and true or false
		macroOptions.alt = strfind(currentBindings[1], "ALT") and true or false
	else
		macroOptions = {down=true, up=true, ctrl=true, shift=false, alt=false}
	end

	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					children = {
						{
							type = "Label",
							text = L["Many commonly-used buttons in TSM can be macro'd and bound to your scroll wheel. Below, select the buttons you would like to include in this macro and the modifier(s) you would like to use with the scroll wheel."],
							relativeWidth = 1,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					children = {
						{
							type = "CheckBox",
							label = L["TSM_Auctioning 'Post' Button"],
							settingInfo = { macroButtons, "auctioningPost" },
							disabled = not TSMAPI:HasModule("Auctioning"),
							tooltip = L["Will include the TSM_Auctioning 'Post' button in the macro."],
						},
						{
							type = "CheckBox",
							label = L["TSM_Auctioning 'Cancel' Button"],
							settingInfo = { macroButtons, "auctioningCancel" },
							disabled = not TSMAPI:HasModule("Auctioning"),
							tooltip = L["Will include the TSM_Auctioning 'Cancel' button in the macro."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["TSM_Crafting 'Craft Next' Button"],
							settingInfo = { macroButtons, "craftingCraftNext" },
							disabled = not TSMAPI:HasModule("Crafting"),
							tooltip = L["Will include the TSM_Crafting 'Craft Next' button in the macro."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["TSM_Destroying 'Destroy Next' Button"],
							settingInfo = { macroButtons, "destroyingDestroyNext" },
							disabled = not TSMAPI:HasModule("Destroying"),
							tooltip = L["Will include the TSM_Destroying 'Destroy Next' button in the macro."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["TSM_Shopping 'Buyout' Button"],
							settingInfo = { macroButtons, "shoppingBuyout" },
							disabled = not TSMAPI:HasModule("Shopping"),
							tooltip = L["Will include the TSM_Shopping 'Buyout' button in the macro."],
						},
						{
							type = "CheckBox",
							label = L["TSM_Shopping 'Buyout' (Confirmation) Button"],
							settingInfo = { macroButtons, "shoppingBuyoutConfirmation" },
							disabled = not TSMAPI:HasModule("Shopping"),
							tooltip = L["Will include the TSM_Shopping buyout confirmation window 'Buyout' button in the macro."],
						},
						{
							type = "CheckBox",
							label = L["TSM_Shopping 'Cancel' (Confirmation) Button"],
							settingInfo = { macroButtons, "shoppingCancelConfirmation" },
							disabled = not TSMAPI:HasModule("Shopping"),
							tooltip = L["Will include the TSM_Shopping cancel confirmation window 'Cancel' button in the macro."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["TSM_Vendoring 'Sell All' Button"],
							settingInfo = { macroButtons, "vendoringSellAll" },
							disabled = not TSMAPI:HasModule("Vendoring"),
							tooltip = L["Will include the TSM_Vendoring 'Sell All' button in the macro."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					children = {
						{
							type = "Label",
							text = L["Scroll Wheel Direction:"],
							relativeWidth = 0.4,
						},
						{
							type = "CheckBox",
							label = L["Up"],
							relativeWidth = 0.3,
							settingInfo = { macroOptions, "up" },
							tooltip = L["Will cause the macro to be triggered when the scroll wheel goes up (with the selected modifiers pressed)."],
						},
						{
							type = "CheckBox",
							label = L["Down"],
							relativeWidth = 0.3,
							settingInfo = { macroOptions, "down" },
							tooltip = L["Will cause the macro to be triggered when the scroll wheel goes down (with the selected modifiers pressed)."],
						},
						{
							type = "Label",
							text = L["Modifiers:"],
							relativeWidth = 0.4,
						},
						{
							type = "CheckBox",
							label = "ALT",
							relativeWidth = 0.2,
							settingInfo = { macroOptions, "alt" },
						},
						{
							type = "CheckBox",
							label = "CTRL",
							relativeWidth = 0.2,
							settingInfo = { macroOptions, "ctrl" },
						},
						{
							type = "CheckBox",
							label = "SHIFT",
							relativeWidth = 0.2,
							settingInfo = { macroOptions, "shift" },
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Button",
							relativeWidth = 1,
							text = L["Create Macro and Bind Scroll Wheel"],
							callback = function()
								-- delete old bindings
								for _, binding in ipairs({GetBindingKey("MACRO TSMAucBClick")}) do
									SetBinding(binding)
								end
								for _, binding in ipairs({GetBindingKey("MACRO TSMMacro")}) do
									SetBinding(binding)
								end

								-- delete old macros
								DeleteMacro("TSMAucBClick")
								DeleteMacro("TSMMacro")

								-- create the new macro
								local lines = {}
								for key, enabled in pairs(macroButtons) do
									if enabled then
										TSMAPI:Assert(macroButtonNames[key])
										tinsert(lines, "/click "..macroButtonNames[key])
									end
								end
								local macroText = table.concat(lines, "\n")
								CreateMacro("TSMMacro", "Achievement_Faction_GoldenLotus", macroText)

								-- create the scroll wheel binding
								local modifierStr = (macroOptions.ctrl and "CTRL-" or "")..(macroOptions.alt and "ALT-" or "")..(macroOptions.shift and "SHIFT-" or "")
								local bindingNum = (GetCurrentBindingSet() == 1) and 2 or 1
								if macroOptions.up then
									SetBinding(modifierStr.."MOUSEWHEELUP", nil, bindingNum)
									SetBinding(modifierStr.."MOUSEWHEELUP", "MACRO TSMMacro", bindingNum)
								end
								if macroOptions.down then
									SetBinding(modifierStr.."MOUSEWHEELDOWN", nil, bindingNum)
									SetBinding(modifierStr.."MOUSEWHEELDOWN", "MACRO TSMMacro", bindingNum)
								end
								SaveBindings(2)

								TSM:Print(L["Macro created and scroll wheel bound!"])
								if #macroText > 255 then
									TSM:Print(L["WARNING: The macro was too long, so was truncated to fit by WoW."])
								end
							end,
						},
					},
				},
			},
		},
	}
	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Custom Price Sources Tab
-- ============================================================================

function private:LoadCustomPriceSources(parent)
	private.treeGroup = AceGUI:Create("TSMTreeGroup")
	private.treeGroup:SetLayout("Fill")
	private.treeGroup:SetCallback("OnGroupSelected", private.SelectCustomPriceSourcesTree)
	private.treeGroup:SetStatusTable(TSM.db.profile.customPriceSourceTreeStatus)
	parent:AddChild(private.treeGroup)

	private:UpdateCustomPriceSourcesTree()
	private.treeGroup:SelectByPath(1)
end

function private:UpdateCustomPriceSourcesTree()
	if not private.treeGroup then return end

	local children = {}
	for name in pairs(TSM.db.global.customPriceSources) do
		tinsert(children, {value=name, text=name})
	end
	sort(children, function(a, b) return strlower(a.value) < strlower(b.value) end)
	private.treeGroup:SetTree({{value=1, text=L["Sources"], children=children}})
end

function private.SelectCustomPriceSourcesTree(treeGroup, _, selection)
	treeGroup:ReleaseChildren()

	selection = {("\001"):split(selection)}
	if #selection == 1 then
		private:DrawNewCustomPriceSource(treeGroup)
	else
		local name = selection[#selection]
		private:DrawCustomPriceSourceOptions(treeGroup, name)
	end
end

function private:DrawNewCustomPriceSource(container)
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["New Custom Price Source"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Custom price sources allow you to create more advanced custom prices throughout all of the TSM modules. Just as you can use the built-in price sources such as 'vendorsell' and 'vendorbuy' in your custom prices, you can use ones you make here (which themselves are custom prices)."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "EditBox",
							label = L["Custom Price Source Name"],
							relativeWidth = 1,
							callback = function(self,_,value)
								value = strlower((value or ""):trim())
								if value == "" then return end
								if gsub(value, "([a-z]+)", "") ~= "" then
									return TSM:Print(L["The name can ONLY contain letters. No spaces, numbers, or special characters."])
								end
								if TSM.db.global.customPriceSources[value] then
									return TSM:Printf(L["Error creating custom price source. Custom price source with name '%s' already exists."], value)
								end
								TSM:CreateCustomPriceSource(value, "")
								private:UpdateCustomPriceSourcesTree()
								if TSM.db.profile.gotoNewCustomPriceSource then
									private.treeGroup:SelectByPath(1, value)
								else
									self:SetText()
									self:SetFocus()
								end
							end,
							tooltip = L["Give your new custom price source a name. This is what you will type in to custom prices and is case insensitive (everything will be saved as lower case)."].."\n\n"..TSMAPI.Design:ColorText(L["The name can ONLY contain letters. No spaces, numbers, or special characters."], "link"),
						},
						{
							type = "CheckBox",
							label = L["Switch to New Custom Price Source After Creation"],
							relativeWidth = 1,
							settingInfo = {TSM.db.profile, "gotoNewCustomPriceSource"},
						},
					},
				},
			},
		},
	}
	TSMAPI.GUI:BuildOptions(container, page)
end

function private:DrawCustomPriceSourceOptions(container, customPriceName)
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Custom Price Source"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Below, set the custom price that will be evaluated for this custom price source."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "EditBox",
							label = L["Custom Price for this Source"],
							settingInfo = {TSM.db.global.customPriceSources, customPriceName},
							relativeWidth = 1,
							acceptCustom = true,
							tooltip = "",
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Management"],
					children = {
						{
							type = "EditBox",
							label = L["Rename Custom Price Source"],
							value = customPriceName,
							relativeWidth = 0.5,
							callback = function(self,_,name)
								name = strlower((name or ""):trim())
								if name == "" then return end
								if gsub(name, "([a-z]+)", "") ~= "" then
									return TSM:Print(L["The name can ONLY contain letters. No spaces, numbers, or special characters."])
								end
								if TSM.db.global.customPriceSources[name] then
									return TSM:Printf(L["Error renaming custom price source. Custom price source with name '%s' already exists."], name)
								end
								TSM:RenameCustomPriceSource(customPriceName, name)
								private:UpdateCustomPriceSourcesTree()
								private.treeGroup:SelectByPath(1, name)
							end,
							tooltip = L["Give your new custom price source a name. This is what you will type in to custom prices and is case insensitive (everything will be saved as lower case)."].."\n\n"..TSMAPI.Design:ColorText(L["The name can ONLY contain letters. No spaces, numbers, or special characters."], "link"),
						},
						{
							type = "Button",
							text = L["Delete Custom Price Source"],
							relativeWidth = 0.5,
							callback = function()
								TSM:DeleteCustomPriceSource(customPriceName)
								private:UpdateCustomPriceSourcesTree()
								private.treeGroup:SelectByPath(1)
								TSM:Printf(L["Removed '%s' as a custom price source. Be sure to update any custom prices that were using this source."], customPriceName)
							end,
						},
					},
				},
			},
		},
	}
	TSMAPI.GUI:BuildOptions(container, page)
end
