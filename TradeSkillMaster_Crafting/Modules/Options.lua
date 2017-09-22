-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Options = TSM:NewModule("Options", "AceEvent-3.0", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local private = {filters={}}



-- ============================================================================
-- Module Options
-- ============================================================================

function Options:Load(container)
	local tg = AceGUI:Create("TSMTabGroup")
	tg:SetLayout("Fill")
	tg:SetFullHeight(true)
	tg:SetFullWidth(true)
	tg:SetTabs({{value=1, text=L["General"]}, {value=2, text=L["Gathering"]}})
	tg:SetCallback("OnGroupSelected", function(self, _, value)
		self:ReleaseChildren()
		if value == 1 then
			private:DrawGeneralSettings(self)
		elseif value == 2 then
			private:DrawGatheringSettings(self)
		end
	end)
	container:AddChild(tg)
	tg:SelectTab(1)
end

function private:DrawGeneralSettings(container)
	-- inventory tracking characters / guilds
	local altCharacters, altGuilds = {}, {}
	for name in pairs(TSMAPI.Player:GetCharacters()) do
		altCharacters[name] = name
	end
	for name in pairs(TSMAPI.Player:GetGuilds()) do
		altGuilds[name] = name
	end

	local page = {
		{
			-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["General Settings"],
					children = {
						{
							-- slider to set the scale of the professions frame
							type = "Slider",
							label = L["Profession Frame Scale"],
							value = TSMCraftingTradeSkillFrame and TSMCraftingTradeSkillFrame:GetFrameScale() or 1,
							isPercent = true,
							relativeWidth = 0.5,
							min = 0.1,
							max = 2,
							step = 0.05,
							disabled = not TSMCraftingTradeSkillFrame,
							callback = function(_, _, value)
								if TSMCraftingTradeSkillFrame then
									TSMCraftingTradeSkillFrame:SetFrameScale(value)
								end
							end,
							tooltip = TSMCraftingTradeSkillFrame and L["Changes the scale of the profession frame."] or L["Changes the scale of the profession frame. \n\nOpen the profession window to enable."],
						},
						{
							-- slider to set the % to deduct from profits
							type = "Slider",
							label = L["Profit Deduction"],
							settingInfo = {TSM.db.global, "profitPercent"},
							isPercent = true,
							min = 0,
							max = 0.25,
							step = 0.01,
							relativeWidth = 0.5,
							tooltip = L["Percent to subtract from buyout when calculating profits (5% will compensate for AH cut)."],
						},
						{
							type = "Dropdown",
							relativeWidth = 1,
							label = L["Queue Sorting Method"],
							list = {L["Can Craft At Least One, Profit, Craftable Quantity"], L["Profit, Craftable Quantity"], L["Craftable Quantity, Profit"]},
							settingInfo = {TSM.db.global, "queueSort"},
							tooltip = L["The queue will be sorted based on this option, from left to right."],
						},
						{
							type = "CheckBox",
							label = L["Enable Smart Crafting for Quests"],
							settingInfo = {TSM.db.global, "questSmartCrafting" },
							relativeWidth = 1,
							tooltip = L["Crafting can automatically prompt you to craft your quest required items when you open the profession with the necessary materials on-hand or automatically add them to your queue if you don't have the necessary materials on-hand."],
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Inventory Settings"],
					children = {
						{
							type = "Dropdown",
							label = L["Characters (Bags/Bank/AH/Mail) to Ignore:"],
							value = TSM.db.global.ignoreCharacters,
							list = altCharacters,
							relativeWidth = 0.49,
							multiselect = true,
							callback = function(self, _, key, value)
								TSM.db.global.ignoreCharacters[key] = value
							end,
						},
						{
							type = "Dropdown",
							label = L["Guilds (Guild Banks) to Ignore:"],
							value = TSM.db.global.ignoreGuilds,
							list = altGuilds,
							relativeWidth = 0.49,
							multiselect = true,
							callback = function(_, _, key, value)
								TSM.db.global.ignoreGuilds[key] = value
							end,
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Default Price Settings"],
					children = {
						{
							type = "EditBox",
							label = L["Default Material Cost Method"],
							settingInfo = {TSM.db.global, "defaultMatCostMethod"},
							relativeWidth = 1,
							acceptCustom = "matprice",
							tooltip = L["This is the default method Crafting will use for determining material cost."],
						},
						{
							type = "Button",
							text = L["Reset Material Cost Method to Default"],
							relativeWidth = 1,
							callback = function(self)
								StaticPopupDialogs["TSM_CRAFTING_RESET_MAT_COST_METHOD"] = StaticPopupDialogs["TSM_CRAFTING_RESET_MAT_COST_METHOD"] or {
									text = L["Are you sure you want to reset the 'Default Material Cost Method' back to the default value?"],
									button1 = YES,
									button2 = CANCEL,
									timeout = 0,
									hideOnEscape = true,
									OnAccept = function(self)
										TSM.db.global.defaultMatCostMethod = TSM.defaultMatCostMethod
										if container.frame:IsVisible() then
											container:Reload()
										end
									end,
									preferredIndex = 3,
								}
								TSMAPI.Util:ShowStaticPopupDialog("TSM_CRAFTING_RESET_MAT_COST_METHOD")
								container:Reload()
							end,
							tooltip = L["Reset the Material Cost Method to the default TSM value."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "EditBox",
							label = L["Default Craft Value Method"],
							settingInfo = {TSM.db.global, "defaultCraftPriceMethod"},
							relativeWidth = 1,
							acceptCustom = "crafting",
							tooltip = L["This is the default method Crafting will use for determining the value of crafted items."],
						},
						{
							type = "Button",
							text = L["Reset Craft Value Method to Default"],
							relativeWidth = 1,
							callback = function(self)
								StaticPopupDialogs["TSM_CRAFTING_RESET_CRAFT_VALUE_METHOD"] = StaticPopupDialogs["TSM_CRAFTING_RESET_CRAFT_VALUE_METHOD"] or {
									text = L["Are you sure you want to reset the 'Default Craft Value Method' back to the default value?"],
									button1 = YES,
									button2 = CANCEL,
									timeout = 0,
									hideOnEscape = true,
									OnAccept = function(self)
										TSM.db.global.defaultCraftPriceMethod = TSM.defaultCraftPriceMethod
										if container.frame:IsVisible() then
											container:Reload()
										end
									end,
									preferredIndex = 3,
								}
								TSMAPI.Util:ShowStaticPopupDialog("TSM_CRAFTING_RESET_CRAFT_VALUE_METHOD")
								container:Reload()
							end,
							tooltip = L["Reset the Craft Value Method to the default TSM value."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["Exclude Crafts with a Cooldown from Craft Cost"],
							settingInfo = { TSM.db.global, "ignoreCDCraftCost" },
							relativeWidth = 1,
							tooltip = L["If checked, if there is more than one way to craft the item then the craft cost will exclude any craft with a daily cooldown when calculating the lowest craft cost."],
						},
					},
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end

function private:DrawGatheringSettings(container)
	local professions = {}
	for player, info in pairs(TSM.db.factionrealm.playerProfessions) do
		for profession, data in pairs(info) do
			professions[profession] = professions[profession] or {}
			tinsert(professions[profession], player)
		end
	end

	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "SimpleGroup",
					layout = "Flow",
					children = {
						{
							type = "Label",
							text = L["You can set the global default gathering options here, some of these can be overriden per gathering session."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine",
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Auction House"],
					children = {
						{
							type = "CheckBox",
							label = L["Disable Crafting AH Search"],
							relativeWidth = 0.33,
							tooltip = L["Toggle to switch between Crafting and Normal searches at the Auction House. A Crafting search will look for any disenchantable / prospectable / millable / craftable items that will provide the target item wheras a normal search will look just for the target item"],
							settingInfo = { TSM.db.factionrealm, "disableCheckBox" },
						},
						{
							type = "CheckBox",
							label = L["Disable DE Search"],
							relativeWidth = 0.33,
							tooltip = L["If enabled the crafting search at the Auction House will ignore Disenchantable Items."],
							settingInfo = { TSM.db.factionrealm, "ignoreDECheckBox" },
						},
						{
							type = "CheckBox",
							label = L["Even Stacks Only"],
							relativeWidth = 0.34,
							tooltip = L["If enabled the crafting search will only search for multiples of 5."],
							settingInfo = { TSM.db.factionrealm, "evenStacks" },
						},
						{
							type = "CheckBox",
							label = L["Always Buy from AH"],
							relativeWidth = 0.34,
							tooltip = L["If enabled, buying from AH will always be suggested even if you have enough via other sources. If disabled only short items will be searched for at the AH"],
							settingInfo = { TSM.db.factionrealm, "buyAH" },
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Characters"],
					children = {
						{
							type = "CheckBox",
							label = L["Ignore Alts"],
							relativeWidth = 1,
							tooltip = L["Toggle to ignore gathering from Alts and only gather from the crafter."],
							settingInfo = { TSM.db.factionrealm, "ignoreAlts" },
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Intermediate Crafting"],
					children = {
						{
							type = "CheckBox",
							label = L["Ignore Intermediate Crafting"],
							relativeWidth = 1,
							tooltip = L["Toggle to ignore intermediate crafting."],
							settingInfo = { TSM.db.factionrealm, "ignoreIntermediate" },
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Ink Trader"],
					children = {
						{
							type = "CheckBox",
							label = L["Trade Inks at the vendor"],
							relativeWidth = 1,
							tooltip = L["Toggle to suggest trading inks at the vendor."],
							settingInfo = { TSM.db.factionrealm, "inkTrade" },
						},
					},
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end


-- ============================================================================
-- Operation Options
-- ============================================================================

function Options:GetOperationOptionsInfo()
	local description = L["Crafting operations contain settings for restocking the items in a group. Type the name of the new operation into the box below and hit 'enter' to create a new Crafting operation."]
	local tabInfo = {
		{ text = L["General"], callback = private.DrawOperationGeneral},
	}
	local relationshipInfo = {
		{
			label = L["Restock Settings"],
			{key="maxRestock", label=L["Max Restock Quantity"]},
			{key="minRestock", label=L["Min Restock Quantity"]},
			{key="minProfit", label=L["Minimum Profit"]},
		},
		{
			label = L["Price Settings"],
			{key="craftPriceMethod", label=L["Craft Value Method"]},
		},
	}
	return description, tabInfo, relationshipInfo
end

function private.DrawOperationGeneral(container, operationName)
	local operationSettings = TSM.operations[operationName]

	local page = {
		{
			-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Restock Quantity Settings"],
					children = {
						{
							-- slider to set the stock number
							type = "Slider",
							value = operationSettings.minRestock,
							label = L["Min Restock Quantity"],
							isPercent = false,
							min = 1,
							max = 2000,
							step = 1,
							relativeWidth = 0.49,
							disabled = operationSettings.relationships.minRestock,
							callback = function(self, _, value)
								if value > operationSettings.maxRestock then
									TSM:Print(TSMAPI.Design:GetInlineColor("link2") .. L["Warning: The min restock quantity must be lower than the max restock quantity."] .. "|r")
								end
								operationSettings.minRestock = min(value, operationSettings.maxRestock)
							end,
							tooltip = L["Items will only be added to the queue if the number being added is greater than this number. This is useful if you don't want to bother with crafting singles for example."],
						},
						{
							-- slider to set the stock number
							type = "Slider",
							value = operationSettings.maxRestock,
							label = L["Max Restock Quantity"],
							isPercent = false,
							min = 1,
							max = 2000,
							step = 1,
							relativeWidth = 0.49,
							disabled = operationSettings.relationships.maxRestock,
							callback = function(self, _, value)
								if value < operationSettings.minRestock then
									TSM:Print(TSMAPI.Design:GetInlineColor("link2") .. L["Warning: The min restock quantity must be lower than the max restock quantity."] .. "|r")
								end
								operationSettings.maxRestock = max(value, operationSettings.minRestock)
							end,
							tooltip = L["When you click on the \"Restock Queue\" button enough of each craft will be queued so that you have this maximum number on hand. For example, if you have 2 of item X on hand and you set this to 4, 2 more will be added to the craft queue."],
						},
						{
							type = "CheckBox",
							value = operationSettings.minProfit,
							label = L["Set Minimum Profit"],
							relativeWidth = 0.5,
							disabled = operationSettings.relationships.minProfit,
							callback = function(_, _, value)
								if value then
									operationSettings.minProfit = TSM.operationDefaults.minProfit
								else
									operationSettings.minProfit = nil
								end
								container:Reload()
							end,
						},
						{
							type = "EditBox",
							label = L["Minimum Profit"],
							disabled = not operationSettings.minProfit or operationSettings.relationships.minProfit,
							settingInfo = {operationSettings, "minProfit"},
							relativeWidth = 0.49,
							acceptCustom = true,
							callback = function(self, _, value)
								if TSMAPI:MoneyFromString(value) == 0 then
									TSM:Print(L["A minimum profit of 0g is not allowed."])
									operationSettings.minProfit = TSM.operationDefaults.minProfit
									container:Reload()
								end
							end,
							tooltip = L["Crafting will not queue any items affected by this operation with a profit below this value. As an example, a min profit of 'max(10g, 10% crafting)' would ensure a profit of at least 10g or 10% of the craft cost, whichever is highest."],
						},
					},
				},
				{
					type = "Spacer",
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Price Settings"],
					children = {
						{
							type = "CheckBox",
							value = operationSettings.craftPriceMethod,
							label = L["Override Default Craft Value Method"],
							relativeWidth = 1,
							disabled = operationSettings.relationships.craftPriceMethod,
							callback = function(_, _, value)
								if value then
									operationSettings.craftPriceMethod = TSM.db.global.defaultCraftPriceMethod
								else
									operationSettings.craftPriceMethod = nil
								end
								container:Reload()
							end,
						},
						{
							type = "EditBox",
							label = L["Craft Value Method"],
							disabled = not operationSettings.craftPriceMethod or operationSettings.relationships.craftPriceMethod,
							settingInfo = {operationSettings, "craftPriceMethod"},
							relativeWidth = 1,
							acceptCustom = "crafting",
							tooltip = L["This is the default method Crafting will use for determining the value of crafted items."],
						},
					},
				},
			},
		},
	}
	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Tooltip Options
-- ============================================================================

function Options:LoadTooltipOptions(container, options)
	local page = {
		{
			type = "SimpleGroup",
			layout = "Flow",
			fullHeight = true,
			children = {
				{
					type = "CheckBox",
					label = L["Show Crafting Cost in Tooltip"],
					settingInfo = { options, "craftingCost" },
					tooltip = L["If checked, the crafting cost of items will be shown in the tooltip for the item."],
				},
				{
					type = "CheckBox",
					label = L["Show Material Cost in Tooltip"],
					settingInfo = { options, "matPrice" },
					tooltip = L["If checked, the material cost of items will be shown in the tooltip for the item."],
				},
				{
					type = "CheckBox",
					label = L["List Mats in Tooltip"],
					settingInfo = { options, "detailedMats" },
					tooltip = L["If checked, the mats needed to craft an item and their prices will be shown in item tooltips."],
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Main Window Pgae
-- ============================================================================

function Options:LoadCrafting(parent)
	local tg = AceGUI:Create("TSMTabGroup")
	tg:SetLayout("Fill")
	tg:SetFullHeight(true)
	tg:SetFullWidth(true)
	tg:SetTabs({ { value = 1, text = L["Crafts"] }, { value = 2, text = L["Materials"] } , { value = 3, text = L["Cooldowns"] }})
	tg:SetCallback("OnGroupSelected", function(self, _, value)
		tg:ReleaseChildren()
		if Options.OpenWindow then Options.OpenWindow:Hide() end
		if Options.OpenGatherWindow then Options.OpenGatherWindow:Hide() end
		parent:DoLayout()

		if value == 1 then
			Options:LoadCraftsPage(tg)
		elseif value == 2 then
			Options:LoadMaterialsPage(tg)
		elseif value == 3 then
			Options:LoadCooldownPage(tg)
		end
		tg.children[1]:DoLayout()
	end)
	tg:SetCallback("OnRelease", function()
			if Options.OpenWindow then Options.OpenWindow:Hide() end
		end)
	parent:AddChild(tg)
	tg:SelectTab(1)
end

function Options:UpdateCraftST()
	if private.craftSTDisabled then return end
	local stData = {}
	local bagTotal, auctionTotal, otherTotal = TSM:GetInventoryTotals()
	for spellID, data in pairs(TSM.db.factionrealm.crafts) do
		local isFiltered
		local name = TSMAPI.Item:GetName(data.itemString)
		local link = TSMAPI.Item:GetLink(data.itemString)
		local ilvl = TSMAPI.Item:GetItemLevel(data.itemString)
		local lvl = TSMAPI.Item:GetMinLevel(data.itemString)

		if not name or not link then
			isFiltered = true
		elseif private.filters.profession ~= "" and private.filters.profession ~= data.profession then
			isFiltered = true
		elseif private.filters.minLevel and lvl < private.filters.minLevel then
			isFiltered = true
		elseif private.filters.maxLevel and lvl > private.filters.maxLevel then
			isFiltered = true
		elseif private.filters.minILevel and ilvl < private.filters.minILevel then
			isFiltered = true
		elseif private.filters.maxILevel and ilvl > private.filters.maxILevel then
			isFiltered = true
		elseif private.filters.filter ~= "" and not strmatch(strlower(name), private.filters.filter) then
			isFiltered = true
		elseif private.filters.haveMats then
			for itemString, quantity in pairs(data.mats) do
				if (bagTotal[itemString] or 0) < quantity and not TSMAPI.Item:GetVendorCost(itemString) then
					isFiltered = true
					break
				end
			end
		end

		if not isFiltered then
			local itemString = TSMAPI.Item:ToBaseItemString(data.itemString)
			local bags, auctions, other = bagTotal[itemString] or 0, auctionTotal[itemString] or 0, otherTotal[itemString] or 0
			local cost, buyout, profit = TSM.Cost:GetSpellCraftPrices(spellID)
			local operationName = TSMAPI.Operations:GetFirstByItem(data.itemString, "Crafting")
			if not operationName or not TSM.operations[operationName] then
				operationName = "---"
			end
			local percent = nil
			local percentStr = nil
			local profitStr = nil
			if profit then
				percent = TSMAPI.Util:Round(100*profit/cost)
				if profit >= 0 then
					profitStr = TSMAPI:MoneyToString(profit, "|cff00ff00")
					percentStr = "|cff00ff00"..percent.."%|r"
				else
					profitStr = TSMAPI:MoneyToString(-profit, "|cffff0000")
					percentStr = "|cff00ff00"..(-percent).."%|r"
				end
			else
				profit = -math.huge
				percent = -math.huge
				profitStr = "---"
				percentStr = "---"
			end
			local row = {
				cols = {
					{
						value = TSM.Queue:Get(spellID),
						sortArg = TSM.Queue:Get(spellID),
					},
					{
						value = link,
						sortArg = strlower(name),
					},
					{
						value = operationName,
						sortArg = operationName,
					},
					{
						value = bags,
						sortArg = bags,
					},
					{
						value = auctions,
						sortArg = auctions,
					},
					{
						value = other,
						sortArg = other,
					},
					{
						value = TSMAPI:MoneyToString(cost) or "---",
						sortArg = cost or -math.huge,
					},
					{
						value = TSMAPI:MoneyToString(buyout) or "---",
						sortArg = buyout or -math.huge,
					},
					{
						value = profitStr,
						sortArg = profit,
					},
					{
						value = percentStr,
						sortArg = percent,
					},
				},
				name = data.name,
				itemString = data.itemString,
				spellID = spellID,
			}
			tinsert(stData, row)
		end
	end

	TSMAPI.GUI:UpdateTSMScrollingTableData("TSM_CRAFTING_CRAFTS", stData)
end

-- Crafts Page
function Options:LoadCraftsPage(container)
	private.filters = {filter="", profession="", dpSelection="all", haveMats=nil, queueIncr=1, minLevel=nil, maxLevel=nil, minILevel=nil, maxILevel=nil}

	local professionList = { [""] = L["<None>"] }
	for _, data in pairs(TSM.db.factionrealm.crafts) do
		professionList[data.profession] = data.profession
	end

	local stCols = {
		{
			name = L["Queue"],
			width = 0.06,
			align = "CENTER",
			headAlign = "CENTER",
		},
		{
			name = L["Craft Name"],
			width = 0.25,
			align = "LEFT",
			headAlign = "CENTER",
		},
		{
			name = L["Operation"],
			width = 0.12,
			align = "CENTER",
			headAlign = "CENTER",
		},
		{
			name = L["Bags"],
			width = 0.05,
			align = "CENTER",
			headAlign = "CENTER",
		},
		{
			name = L["AH"],
			width = 0.05,
			align = "CENTER",
			headAlign = "CENTER",
		},
		{
			name = OTHER,
			width = 0.05,
			align = "CENTER",
			headAlign = "CENTER",
		},
		{
			name = L["Crafting Cost"],
			width = 0.12,
			align = "LEFT",
			headAlign = "CENTER",
		},
		{
			name = L["Item Value"],
			width = 0.12,
			align = "LEFT",
			headAlign = "CENTER",
		},
		{
			name = L["Profit"],
			width = 0.12,
			align = "LEFT",
			headAlign = "CENTER",
		},
		{
			name = "%",
			width = 0.06,
			align = "LEFT",
			headAlign = "CENTER",
		},
	}
	local stHandlers = {
		OnClick = function(st, data, self, button)
			if not data then return end
			if button == "LeftButton" then
				TSM.Queue:Add(data.spellID, private.filters.queueIncr)
			elseif button == "RightButton" then
				TSM.Queue:Remove(data.spellID, private.filters.queueIncr)
			end
			data.cols[1].value = TSM.Queue:Get(data.spellID)
			data.cols[1].sortArg = TSM.Queue:Get(data.spellID)
			st:RefreshRows()
			private.craftSTDisabled = true
			TSM.TradeSkill.Queue:Update()
			private.craftSTDisabled = nil
		end,
		OnEnter = function(_, data, self)
			if not data then return end

			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			TSMAPI.Util:SafeTooltipLink(data.itemString)
			GameTooltip:Show()
		end,
		OnLeave = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end
	}

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
							label = L["Search"],
							relativeWidth = 0.3,
							onTextChanged = true,
							callback = function(_, _, value)
								local parts = {("/"):split(strlower(value:trim()))}
								private.filters.minLevel = nil
								private.filters.maxLevel = nil
								private.filters.minILevel = nil
								private.filters.maxILevel = nil
								for i, part in ipairs(parts) do
									local lvl = tonumber(part)
									local ilvl = tonumber(strmatch(part, "^i([0-9]+)$"))
									if i == 1 then
										private.filters.filter = part
									elseif lvl then
										if private.filters.minLevel then
											private.filters.maxLevel = lvl
										else
											private.filters.minLevel = lvl
										end
									elseif ilvl then
										if private.filters.minILevel then
											private.filters.maxILevel = ilvl
										else
											private.filters.minILevel = ilvl
										end
									end
								end
								Options:UpdateCraftST()
							end,
						},
						{
							type = "Dropdown",
							label = L["Profession Filter"],
							relativeWidth = 0.2,
							list = professionList,
							settingInfo = {private.filters, "profession"},
							callback = Options.UpdateCraftST,
						},
						{
							type = "CheckBox",
							label = L["Have Mats"],
							relativeWidth = 0.19,
							settingInfo = {private.filters, "haveMats"},
							callback = Options.UpdateCraftST,
							tooltip = L["If checked, only crafts which you can craft with items in your bags (ignoring vendor items) will be shown below."],
						},
						{
							type = "Slider",
							label = L["Queue Increment"],
							relativeWidth = 0.29,
							settingInfo = {private.filters, "queueIncr"},
							min = 1,
							max = 20,
							step = 1,
							tooltip = L["This slider sets the quantity to add/remove from the queue when left/right clicking on a row below."],
						},
						{
							type = "Label",
							text = L["You can left/right click on a row to add/remove a craft from the crafting queue."],
							relativeWidth = 1,
						},
					},
				},
				{
					type = "HeadingLine",
				},
				{
					type = "ScrollingTable",
					tag = "TSM_CRAFTING_CRAFTS",
					colInfo = stCols,
					handlers = stHandlers,
					selectionDisabled = true,
					defaultSort = 2,
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
	Options:UpdateCraftST()
end

function Options:ResetDefaultPrice()
	for itemString, data in pairs(TSM.db.factionrealm.mats) do
		if data.customValue then
			data.customValue = nil
		end
	end
	Options:UpdateMatST()
end

function Options:UpdateMatST()
	local items = {}
	for _, data in pairs(TSM.db.factionrealm.crafts) do
		if private.filters.ddSelection == "none" or data.profession == private.filters.ddSelection then
			for itemString in pairs(data.mats) do
				if private.filters.dpSelection == "all" or (private.filters.dpSelection == "default" and not TSM.db.factionrealm.mats[itemString].customValue) or (private.filters.dpSelection == "custom" and TSM.db.factionrealm.mats[itemString].customValue) then
					if TSM.db.factionrealm.mats[itemString] and TSM.db.factionrealm.mats[itemString].name then -- sanity check
						items[itemString] = TSM.db.factionrealm.mats[itemString].name
					end
				end
			end
		end
	end

	local stData = {}
	for itemString, name in pairs(items) do
		if strfind(strlower(name), private.filters.filter) then
			local professions = {}
			local professionList = {}
			for _, data in pairs(TSM.db.factionrealm.crafts) do
				if data.mats[itemString] then
					if not professions[data.profession] then
						professions[data.profession] = true
						tinsert(professionList, data.profession)
					end
				end
			end
			sort(professionList)
			local professionsUsed = table.concat(professionList, ",")

			local mat = TSM.db.factionrealm.mats[itemString]
			local cost = TSMAPI:GetCustomPriceValue(mat.customValue or TSM.db.global.defaultMatCostMethod, itemString) or 0
			local quantity = TSMAPI.Inventory:GetTotalQuantity(itemString)
			tinsert(stData, {
				cols = {
					{
						value = TSMAPI.Item:GetLink(itemString) or name,
						sortArg = name,
					},
					{
						value = cost > 0 and TSMAPI:MoneyToString(cost) or "---",
						sortArg = cost,
					},
					{
						value = professionsUsed,
						sortArg = professionsUsed,
					},
					{
						value = quantity,
						sortArg = quantity,
					},
				},
				itemString = itemString,
				name = name,
			})
		end
	end

	TSMAPI.GUI:UpdateTSMScrollingTableData("TSM_CRAFTING_MATS", stData)
end

-- Materials Page
function Options:LoadMaterialsPage(container)
	private.filters = {filter="", ddSelection="none", dpSelection="all"}

	local ddList = { ["none"] = L["<None>"] }
	for _, data in pairs(TSM.db.factionrealm.crafts) do
		ddList[data.profession] = data.profession
	end

	local dpList = { ["all"] = L["All"], ["default"] = L["Default Price"], ["custom"] = L["Custom Price"] }

	local stCols = {
		{
			name = L["Item Name"],
			width = 0.3,
			align = "LEFT",
			headAlign = "LEFT",
		},
		{
			name = L["Mat Price"],
			width = 0.12,
			align = "LEFT",
			headAlign = "LEFT",
		},
		{
			name = L["Professions Used In"],
			width = 0.48,
			align = "LEFT",
			headAlign = "LEFT",
		},
		{
			name = L["Num Owned"],
			width = 0.10,
			align = "RIGHT",
			headAlign = "RIGHT",
		},
	}
	local stHandlers = {
		OnClick = function(_, data, self)
			if not data then return end
			Options:ShowMatOptionsWindow(self, data.itemString)
		end,
		OnEnter = function(_, data, self)
			if not data then return end

			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			TSMAPI.Util:SafeTooltipLink(data.itemString)
			GameTooltip:Show()
		end,
		OnLeave = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end
	}

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
							label = L["Search"],
							relativeWidth = 0.41,
							onTextChanged = true,
							callback = function(_, _, value)
								private.filters.filter = TSMAPI.Util:StrEscape(strlower(value:trim()))
								Options:UpdateMatST()
							end,
						},
						{
							type = "Dropdown",
							label = L["Profession Filter"],
							relativeWidth = 0.29,
							list = ddList,
							value = "none",
							callback = function(_, _, value)
								private.filters.ddSelection = value
								Options:UpdateMatST()
							end,
						},
						{
							type = "Dropdown",
							label = L["Price Source Filter"],
							relativeWidth = 0.29,
							list = dpList,
							value = "all",
							callback = function(_, _, value)
								private.filters.dpSelection = value
								Options:UpdateMatST()
							end,
						},
						{
							type = "Button",
							text = L["Reset All Custom Prices to Default"],
							relativeWidth = .5,
							callback = function(self)
								StaticPopupDialogs["TSM_CRAFTING_RESET_MAT_PRICES"] = StaticPopupDialogs["TSM_CRAFTING_RESET_MAT_PRICES"] or {
									text = L["Are you sure you want to reset all material prices to the default value?"],
									button1 = YES,
									button2 = CANCEL,
									timeout = 0,
									hideOnEscape = true,
									OnAccept = Options.ResetDefaultPrice,
									preferredIndex = 3,
								}
								TSMAPI.Util:ShowStaticPopupDialog("TSM_CRAFTING_RESET_MAT_PRICES")
							end,
							tooltip = L["Reset all Custom Prices to Default Price Source."],
						},
						{
							type = "Label",
							text = L["You can click on one of the rows of the scrolling table below to view or adjust how the price of a material is calculated."],
							relativeWidth = 1,
						},
					},
				},
				{
					type = "HeadingLine",
				},
				{
					type = "ScrollingTable",
					tag = "TSM_CRAFTING_MATS",
					colInfo = stCols,
					handlers = stHandlers,
					selectionDisabled = true,
					defaultSort = 1,
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
	Options:UpdateMatST()
end

-- Material Options Window
function Options:ShowMatOptionsWindow(parent, itemString)
	if Options.OpenWindow then Options.OpenWindow:Hide() end
	local mat = TSM.db.factionrealm.mats[itemString]
	if not mat then return end
	local link = TSMAPI.Item:GetLink(itemString)
	local cost = TSMAPI:GetCustomPriceValue(mat.customValue or TSM.db.global.defaultMatCostMethod, itemString) or 0

	local window = AceGUI:Create("TSMWindow")
	window.frame:SetParent(parent)
	window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	window:SetWidth(600)
	window:SetHeight(545)
	window:SetTitle(L["Material Cost Options"])
	window:SetLayout("Flow")
	window.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
	window:SetCallback("OnClose", function(self)
		self:ReleaseChildren()
		Options.OpenWindow = nil
		window.frame:Hide()
		Options:UpdateMatST()
	end)
	Options.OpenWindow = window

	local RefreshPage

	local page = {
		{
			type = "InteractiveLabel",
			text = link,
			fontObject = GameFontHighlight,
			relativeWidth = 0.6,
			callback = function() TSMAPI.Util:SafeItemRef(link) end,
			tooltip = itemString,
		},
		{
			type = "Label",
			text = TSMAPI.Design:GetInlineColor("link") .. L["Price:"] .. " |r" .. (TSMAPI:MoneyToString(cost, "OPT_ICON") or "---"),
			relativeWidth = 0.39,
		},
		{
			type = "HeadingLine",
		},
		{
			type = "ScrollFrame",
			layout = "Flow",
			fullHeight = true,
			children = {},
		},
	}

	TSMAPI.GUI:BuildOptions(window, page)

	local sPage = {
		{
			type = "SimpleGroup",
			layout = "Flow",
			children = {
				{
					type = "Label",
					text = L["Here you can view and adjust how Crafting is calculating the price for this material."],
					relativeWidth = 1,
				},
				{
					type = "HeadingLine",
				},
				{
					type = "EditBox",
					value = TSMAPI:MoneyToString(mat.customValue) or mat.customValue or TSM.db.global.defaultMatCostMethod,
					label = L["Custom Price per Item"],
					relativeWidth = 1,
					acceptCustom = true,
					callback = function(self, _, value)
						mat.customValue = value
						Options:ShowMatOptionsWindow(parent, itemString)
					end,
					tooltip = L["Custom Price for this item."],
				},
				{
					type = "Spacer",
				},
				{
					type = "Button",
					text = L["Reset to Default"],
					relativeWidth = .5,
					callback = function(self)
						mat.customValue = nil
						Options:ShowMatOptionsWindow(parent, itemString)
					end,
					tooltip = L["Resets the material price for this item to the defualt value."],
				},
			},
		},
	}

	if window.children[4] then
		window.children[4]:ReleaseChildren()
	end
	TSMAPI.GUI:BuildOptions(window.children[4], sPage)
end

function Options:UpdateCooldownST()
	local stData = {}
	for spellID, craft in pairs(TSM.db.factionrealm.crafts) do
		if craft.hasCD then
			for player in pairs(craft.players) do
				local timeLeftText = nil
				local cooldownData = craft.cooldownTimes and craft.cooldownTimes[player]
				if cooldownData then
					local remaining = cooldownData.endTime - time()
					if remaining <= 0 then
						timeLeftText = "|cff00ff00"..L["Ready"].."|r"
					elseif remaining > 60 * 60 * 24 then -- remaining cooldown is greater than 1 day
						timeLeftText = "|cffff0000"..SecondsToTime(remaining, true, false, 1, true).."|r"
					else
						timeLeftText = "|cffff0000"..SecondsToTime(remaining).."|r"
					end
					tinsert(stData, {
						cols = {
							{
								value = player,
								sortArg = player,
							},
							{
								value = craft.profession,
								sortArg = craft.profession,
							},
							{
								value = craft.name,
								sortArg = craft.name,
							},
							{
								value = timeLeftText,
								sortArg = timeLeftText,
							},
							{
								value = cooldownData.prompt and ("|cff00ff00"..YES.."|r") or ("|cffff0000"..NO.."|r"),
								sortArg = cooldownData.prompt and 1 or 2,
							},
						},
						spellID = spellID,
						craft = craft,
						player = player,
					})
				end
			end
		end
	end

	TSMAPI.GUI:UpdateTSMScrollingTableData("TSM_CRAFTING_COOLDOWNS", stData)
end

-- Cooldowns Page
function Options:LoadCooldownPage(container)
	local stCols = {
		{
			name = L["Player"],
			width = 0.2,
			align = "LEFT",
			headAlign = "LEFT",
		},
		{
			name = L["Profession"],
			width = 0.2,
			align = "LEFT",
			headAlign = "LEFT",
		},
		{
			name = L["Name"],
			width = 0.3,
			align = "LEFT",
			headAlign = "LEFT",
		},
		{
			name = L["Status"],
			width = 0.15,
			align = "LEFT",
			headAlign = "LEFT",
		},
		{
			name = L["Smart"],
			width = 0.15,
			align = "LEFT",
			headAlign = "LEFT",
		},
	}
	local stHandlers = {
		OnEnter = function(_, data, self)
			if not data then return end
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetSpellByID(data.spellID)
			GameTooltip:Show()
		end,
		OnLeave = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end,
		OnClick = function(_, data)
			if not data then return end
			data.craft[data.player] = nil
			data.craft.cooldownTimes[data.player].prompt = not data.craft.cooldownTimes[data.player].prompt
			Options:UpdateCooldownST()
		end,
	}

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
							type = "Label",
							text = L["Crafting can automatically prompt you to craft your cooldowns when you open the profession with the necessary materials on-hand or automatically add them to your queue if you don't have the necessary materials on-hand. Click on rows below to toggle this smart behavior on/off for your cooldowns."],
							relativeWidth = 1,
						},
					},
				},
				{
					type = "HeadingLine",
				},
				{
					type = "ScrollingTable",
					tag = "TSM_CRAFTING_COOLDOWNS",
					colInfo = stCols,
					handlers = stHandlers,
					selectionDisabled = true,
					defaultSort = 1,
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
	Options:UpdateCooldownST()
end
