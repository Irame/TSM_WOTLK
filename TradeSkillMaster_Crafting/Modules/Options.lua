-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --



-- This file contains all the code for the Crafting options



-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Options = TSM:NewModule("Options", "AceEvent-3.0", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table


local function getIndex(t, value)
	for i, v in pairs(t) do
		if v == value then
			return i
		end
	end
end

function Options:OnEnable()
	-- Popup Confirmation Window used in this module
	StaticPopupDialogs["TSMCrafting.DeleteConfirm"] = {
		text = L["Are you sure you want to delete the selected profile?"],
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnCancel = false,
		-- OnAccept defined later
	}

	TSMAPI:RegisterIcon(L["Crafting Options"], "Interface\\Icons\\Inv_Jewelcrafting_DragonsEye02", function(parent) Options:LoadOptions(parent) end, "TradeSkillMaster_Crafting", "options")
end

-- Options Page
function Options:LoadOptions(container)
	local tg = AceGUI:Create("TSMTabGroup")
	tg:SetLayout("Fill")
	tg:SetFullHeight(true)
	tg:SetFullWidth(true)
	tg:SetTabs({{value=1, text=L["General Settings"]}, {value=2, text=L["Price / Inventory Settings"]}, {value=3, text=L["Queue Settings"]}, {value=4, text=L["Profiles"]}})
	container:AddChild(tg)

	local offsets = {}
	local previousTab = 1

	tg:SetCallback("OnGroupSelected", function(self,_,value)
			if tg.children and tg.children[1] and tg.children[1].localstatus then
				offsets[previousTab] = tg.children[1].localstatus.offset
			end
			tg:ReleaseChildren()
			if value == 1 then
				Options:LoadGeneralSettings(tg)
			elseif value == 2 then
				Options:LoadPriceInventorySettings(tg)
			elseif value == 3 then
				Options:LoadQueueSettings(tg)
			elseif value == 4 then
				Options:LoadProfileSettings(tg)
			end
			if tg.children and tg.children[1] and tg.children[1].localstatus then
				tg.children[1].localstatus.offset = (offsets[value] or 0)
			end
			previousTab = value
		end)
	tg:SelectTab(1)
end

function Options:LoadGeneralSettings(container)
	local unknownProfitList = {["unknown"]=L["Mark as Unknown (\"----\")"]}
	if not select(2, TSMAPI:GetData("auctioningFallback")) then
		unknownProfitList["fallback"] = L["Set Crafted Item Cost to Auctioning Fallback"]
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["General Settings"],
					children = {
						{
							type = "CheckBox",
							label = L["Show Crafting Cost in Tooltip"],
							quickCBInfo = {TSM.db.profile, "tooltip"},
							callback = function(_,_,value)
									if value then
										TSMAPI:RegisterTooltip("TradeSkillMaster_Crafting", function(...) return TSM:LoadTooltip(...) end)
									else
										TSMAPI:UnregisterTooltip("TradeSkillMaster_Crafting")
									end
								end,
							tooltip = L["If checked, the crafting cost of items will be shown in the tooltip for the item."],
						},
						{
							type = "CheckBox",
							label = L["Enable New TradeSkills"],
							quickCBInfo = {TSM.db.profile, "enableNewTradeskills"},
							tooltip = L["If checked, when Crafting scans a tradeskill for the first time (such as after you learn a new one), it will be enabled by default."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Craft Management Window Settings"],
					children = {
						{	-- dropdown to select the method for setting the Minimum profit for the main crafts page
							type = "Dropdown",
							label = L["Unknown Profit Queuing"],
							list = unknownProfitList,
							value = TSM.db.profile.unknownProfitMethod.default,
							relativeWidth = 0.49,
							callback = function(self,_,value)
									TSM.db.profile.unknownProfitMethod.default = value
								end,
							tooltip = L["This will determine how items with unknown profit are dealt with in the Craft Management Window. If you have the Auctioning module installed and an item is in an Auctioning group, the fallback for the item can be used as the market value of the crafted item (will show in light blue in the Craft Management Window)."],
						},
						{
							type = "CheckBox",
							label = L["Show Profit Percentages"],
							quickCBInfo = {TSM.db.profile, "showPercentProfit"},
							tooltip = L["If checked, the profit percent (profit/sell price) will be shown next to the profit in the craft management window."],
						},
						{	-- slider to set the stock number
							type = "Slider",
							value = TSM.db.profile.craftManagementWindowScale,
							label = L["Frame Scale"],
							isPercent = true,
							min = 0.5,
							max = 2,
							step = 0.01,
							relativeWidth = 0.49,
							callback = function(_,_,value)
									TSM.db.profile.craftManagementWindowScale = value
									if TSM.Crafting.frame and TSM.Crafting.openCloseButton then
										TSM.Crafting.openCloseButton:SetScale(value)
										TSM.Crafting.frame:SetScale(value)
									end
								end,
							tooltip = L["This will set the scale of the craft management window. Everything inside the window will be scaled by this percentage."],
						},
						{	-- slider to set the stock number
							type = "Slider",
							value = TSM.db.profile.doubleClick,
							label = L["Double Click Queue"],
							min = 2,
							max = 10,
							step = 1,
							relativeWidth = 0.49,
							callback = function(self,_,value)
									value = floor(value + 0.5)
									if value < 2 then value = 2 end
									if value > 10 then value = 10 end
									self:SetValue(value)
									TSM.db.profile.doubleClick = value
								end,
							tooltip = L["When you double click on a craft in the top-left portion (queuing portion) of the craft management window, it will increment/decrement this many times."],
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Options:LoadPriceInventorySettings(container)
	-- price sources
	local ddList1 = CopyTable(TSMAPI:GetPriceSources())
	ddList1["Crafting"] = nil
	ddList1["Vendor"] = nil
	local ddList2 = CopyTable(ddList1)
	local ddList3 = CopyTable(ddList1)
	ddList1["Manual"] = L["Manual Entry"]
	ddList3["none"] = L["<None>"]

	-- inventory tracking characters / guilds
	local altCharacters, altGuilds, altCharactersValue, altGuildsValue = {}, {}, {}, {}
	if TSM.db.profile.altAddon == "DataStore" and DataStore and DataStore.GetCharacters and DataStore.GetGuilds then
		if TSM.db.profile.altCharacters == nil then
			for account in pairs(DataStore:GetAccounts()) do
				for name, character in pairs(DataStore:GetCharacters(nil, account)) do
					TSM.db.profile.altCharacters[name] = true
				end
			end
		end
		for account in pairs(DataStore:GetAccounts()) do
			for name, character in pairs(DataStore:GetCharacters(nil, account)) do
				tinsert(altCharacters, name)
				tinsert(altCharactersValue, TSM.db.profile.altCharacters[name] or false)
			end
		end

		if TSM.db.profile.altGuilds == nil then
			for account in pairs(DataStore:GetAccounts()) do
				for name in pairs(DataStore:GetGuilds(nil, account)) do
					TSM.db.profile.altGuilds[name] = true
				end
			end
		end
		for account in pairs(DataStore:GetAccounts()) do
			for name in pairs(DataStore:GetGuilds(nil, account)) do
				tinsert(altGuilds, name)
				tinsert(altGuildsValue, TSM.db.profile.altGuilds[name] or false)
			end
		end
	elseif TSM.db.profile.altAddon == "ItemTracker" and select(4, GetAddOnInfo("TradeSkillMaster_ItemTracker")) == 1 then
		altCharacters = TSMAPI:GetData("playerlist")
		altGuilds = TSMAPI:GetData("guildlist")

		for _, name in pairs(altCharacters) do
			tinsert(altCharactersValue, TSM.db.profile.altCharacters[name] or false)
		end
		for _, name in pairs(altGuilds) do
			tinsert(altGuildsValue, TSM.db.profile.altGuilds[name] or false)
		end
	end
	
	-- inventory tracking addons
	local addonList, fullAddonList = {}, {["DataStore"] = L["DataStore"], ["ItemTracker"] = L["ItemTracker"]}
	if select(4, GetAddOnInfo("DataStore_Auctions")) == 1 and DataStore then
		addonList["DataStore"] = L["DataStore"]
	end
	if select(4, GetAddOnInfo("TradeSkillMaster_ItemTracker")) == 1 then
		addonList["ItemTracker"] = L["ItemTracker"]
	end
	
	local costCharacters, sendTarget = {}, TSM.db.profile.craftingCostTarget
	for player in pairs(TSM.db.profile.craftingCostSources) do
		tinsert(costCharacters, player)
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Price Settings"],
					children = {
						{	-- dropdown to select how to calculate material costs
							type = "Dropdown",
							label = L["Get Mat Prices From:"],
							list = ddList1,
							value = TSM.db.profile.matCostSource,
							relativeWidth = 0.49,
							callback = function(_,_,value)
									TSM.db.profile.matCostSource = value
								end,
							tooltip = L["This is where TradeSkillMaster_Crafting will get material prices. AuctionDB is TradeSkillMaster's auction house data module. Alternatively, prices can be entered manually in the \"Materials\" pages."],
						},
						{	-- dropdown to select how to calculate material costs
							type = "Dropdown",
							label = L["Get Craft Prices From:"],
							list = ddList2,
							value = TSM.db.profile.craftCostSource,
							relativeWidth = 0.49,
							callback = function(_,_,value)
									TSM.db.profile.craftCostSource = value
								end,
							tooltip = L["This is where TradeSkillMaster_Crafting will get prices for crafted items. AuctionDB is TradeSkillMaster's auction house data module."],
						},
						{	-- dropdown to select how to calculate material costs
							type = "Dropdown",
							label = L["Secondary Price Source"],
							list = ddList3,
							value = TSM.db.profile.secondaryPriceSource,
							relativeWidth = 0.49,
							callback = function(_,_,value)
									TSM.db.profile.secondaryPriceSource = value
									container:SelectTab(2)
								end,
							tooltip = L["If a price source is selected, Crafting will use the secondary price source for mat/craft prices if the price source set above doesn't return a valid price."],
						},
						{
							type = "CheckBox",
							label = L["Use Lower of Price Sources"],
							disabled = TSM.db.profile.secondaryPriceSource == "none",
							quickCBInfo = {TSM.db.profile, "lowestPriceSource"},
							tooltip = L["If checked and a secondary price source is selected, Crafting will use the secondary price source if it's a lower price than the main price source for mats/crafts."],
						},
						{	-- slider to set the % to deduct from profits
							type = "Slider",
							value = TSM.db.profile.profitPercent,
							label = L["Profit Deduction"],
							isPercent = true,
							min = 0,
							max = 0.25,
							step = 0.01,
							relativeWidth = 0.49,
							callback = function(_,_,value) TSM.db.profile.profitPercent = value end,
							tooltip = L["Percent to subtract from buyout when calculating profits (5% will compensate for AH cut)."],
						},
					},
				},
				{
					type = "Spacer"
				},
				{ 	-- holds the second group of options (profit deduction label + slider)
					type = "InlineGroup",
					layout = "flow",
					title = L["Inventory Settings"],
					children = {
						{
							type = "Label",
							text = L["TradeSkillMaster_Crafting can use TradeSkillMaster_ItemTracker or DataStore_Containers to provide data for a number of different places inside TradeSkillMaster_Crafting. Use the settings below to set this up."],
							fullWidth = true,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Dropdown",
							label = L["Addon to use for alt data:"],
							value = fullAddonList[TSM.db.profile.altAddon],
							list = addonList,
							relativeWidth = 0.49,
							callback = function(self,_,value)
									TSM.db.profile.altAddon = value
									container:SelectTab(2)
								end,
						},
						{
							type = "CheckBox",
							label = L["Include Items on AH"],
							quickCBInfo = {TSM.db.profile, "restockAH"},
							tooltip = L["If checked, Crafting will account for items you have on the AH."],
						},
						{
							type = "HeadingLine"
						},
						{
							type = "Dropdown",
							label = L["Characters to include:"],
							value = altCharactersValue,
							list = altCharacters,
							relativeWidth = 0.49,
							multiselect = true,
							disabled = not TSM.db.profile.altAddon,
							callback = function(self,_,key,value)
									TSM.db.profile.altCharacters[altCharacters[key]] = value
								end,
						},
						{
							type = "Dropdown",
							label = L["Guilds to include:"],
							value = altGuildsValue,
							list = altGuilds,
							relativeWidth = 0.49,
							multiselect = true,
							disabled = not TSM.db.profile.altAddon,
							callback = function(_,_,key, value)
									TSM.db.profile.altGuilds[altGuilds[key]] = value
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
					title = L["Crafting Cost Synchronization"],
					children = {
						{
							type = "Label",
							text = L["If you use multiple accounts, you can use the steps below to synchronize your crafting costs between your accounts. This can be useful if you craft on one account and would like to post on another account using % of crafting cost as the threshold/fallback. Read the tooltips of the options below for instructions."],
							fullWidth = true,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Label",
							text = "Step 1 (on Banking Account):",
							relativeWidth = 0.3,
						},
						{
							type = "EditBox",
							label = L["Character(s) (comma-separated if necessary):"],
							value = table.concat(costCharacters, ","),
							relativeWidth = 0.69,
							callback = function(self, _, value)
									TSM.db.profile.craftingCostSources = {}
									for _, player in ipairs({(","):split(value)}) do
										TSM.db.profile.craftingCostSources[strlower(player)] = true
									end
								end,
							tooltip = L["On the account that will be receiving the crafting cost data (ie the account that doesn't have the profession), list the characters that will be sending the crafting cost data below (ie the characters with the profession)."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Label",
							text = L["Step 2 (on Crafting Account):"],
							relativeWidth = 0.3,
						},
						{
							type = "EditBox",
							label = L["Character to Send Crafting Costs to:"],
							value = sendTarget,
							relativeWidth = 0.4,
							callback = function(self, _, value)
									sendTarget = strlower(value:trim())
									local i = getIndex(self.parent.children, self)
									self.parent.children[i+1]:SetDisabled(sendTarget == "")
									TSM.db.profile.craftingCostTarget = sendTarget
								end,
							tooltip = L["Type in the name of the player you want to send your crafting cost data to and hit the \"Send\" button. Remember to do step 1 on the character you're trying to send to first!"],
						},
						{
							type = "Button",
							text = L["Send Crafting Costs"],
							relativeWidth = 0.29,
							disabled = sendTarget == "",
							callback = function()
									TSM.Comm:SendCraftingCostData(sendTarget)
								end,
						}
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Options:LoadQueueSettings(container)
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Restock Queue Settings"],
					children = {
						{
							type = "Label",
							text = L["These options control the \"Restock Queue\" button in the craft management window. These settings can be overriden by profession or by item in the profession pages of the main TSM window."],
							fullWidth = true,
						},
						{
							type = "HeadingLine",
						},
						{	-- dropdown to select the method for setting the Minimum profit for the main crafts page
							type = "Dropdown",
							label = L["Minimum Profit Method"],
							list = {["gold"]=L["Gold Amount"], ["percent"]=L["Percent of Cost"],
								["none"]=L["No Minimum"], ["both"]=L["Percent and Gold Amount"]},
							value = TSM.db.profile.queueProfitMethod.default,
							relativeWidth = 0.49,
							callback = function(self,_,value)
									TSM.db.profile.queueProfitMethod.default = value
									container:SelectTab(3)
								end,
							tooltip = L["You can choose to specify a minimum profit amount (in gold or by " ..
								"percent of cost) for what crafts should be added to the craft queue."],
						},
						{
							type = "Label",
							text = "",
							relativeWidth = 0.5,
						},
						{	-- slider to set the stock number
							type = "Slider",
							value = TSM.db.profile.minRestockQuantity.default,
							label = L["Min Restock Quantity"],
							isPercent = false,
							min = 0,
							max = 20,
							step = 1,
							relativeWidth = 0.49,
							callback = function(self,_,value)
									if value > TSM.db.profile.maxRestockQuantity.default then
										TSM:Print("|cffffff00"..L["Warning: The min restock quantity must be lower than the max restock quantity."].."|r")
									end
									TSM.db.profile.minRestockQuantity.default = value
								end,
							tooltip = L["Items will only be added to the queue if the number being added " ..
									"is greater than this number. This is useful if you don't want to bother with " ..
									"crafting singles for example."],
						},
						{	-- slider to set the stock number
							type = "Slider",
							value = TSM.db.profile.maxRestockQuantity.default,
							label = L["Max Restock Quantity"],
							isPercent = false,
							min = 0,
							max = 20,
							step = 1,
							relativeWidth = 0.49,
							callback = function(self,_,value)
									if value < TSM.db.profile.minRestockQuantity.default then
										TSM:Print(TSMAPI.Design:GetInlineColor("link2")..L["Warning: The min restock quantity must be lower than the max restock quantity."])
									end
									TSM.db.profile.maxRestockQuantity.default = value
								end,
							tooltip = L["When you click on the \"Restock Queue\" button enough of each " ..
								"craft will be queued so that you have this maximum number on hand. For " ..
								"example, if you have 2 of item X on hand and you set this to 4, 2 more " ..
								"will be added to the craft queue."],
						},
						{
							type = "Slider",
							value = TSM.db.profile.queueMinProfitPercent.default,
							label = L["Minimum Profit (in %)"],
							tooltip = L["If enabled, any craft with a profit over this percent of the cost will be added to the craft queue when you use the \"Restock Queue\" button."],
							min = 0,
							max = 2,
							step = 0.01,
							relativeWidth = 0.49,
							isPercent = true,
							disabled = TSM.db.profile.queueProfitMethod.default == "none" or TSM.db.profile.queueProfitMethod.default == "gold",
							callback = function(_,_,value)
									TSM.db.profile.queueMinProfitPercent.default = floor(value*100)/100
								end,
						},
						{
							type = "Slider",
							value = TSM.db.profile.queueMinProfitGold.default,
							label = L["Minimum Profit (in gold)"],
							tooltip = L["If enabled, any craft with a profit over this value will be added to the craft queue when you use the \"Restock Queue\" button."],
							min = 0,
							max = 300,
							step = 1,
							relativeWidth = 0.49,
							disabled = TSM.db.profile.queueProfitMethod.default == "none" or TSM.db.profile.queueProfitMethod.default == "percent",
							callback = function(_,_,value)
									TSM.db.profile.queueMinProfitGold.default = floor(value)
								end,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							value = TSM.db.profile.seenCountFilterSource ~= "",
							label = L["Filter out items with low seen count."],
							relativeWidth = 1,
							callback = function(self, _, value)
									TSM.db.profile.seenCountFilterSource = (value and "AuctionDB") or ""
									local siblings = self.parent.children --aw how cute...siblings ;)
									local i = getIndex(siblings, self)
									siblings[i+1]:SetDisabled(not value)
									siblings[i+3]:SetDisabled(not value)
									siblings[i+4]:SetDisabled(not value)
									siblings[i+5]:SetDisabled(not value)
									siblings[i+1]:SetValue(TSM.db.profile.seenCountFilterSource)
								end,
							tooltip = L["When you use the \"Restock Queue\" button, it will ignore any items "
								.. "with a seen count below the seen count filter below. The seen count data "
								.. "can be retreived from either Auctioneer or TradeSkillMaster's AuctionDB module."],
						},
						{	-- dropdown to select the method for setting the Minimum profit for the main crafts page
							type = "Dropdown",
							label = L["Seen Count Source"],
							disabled = TSM.db.profile.seenCountFilterSource == "",
							list = {["AuctionDB"]=L["TradeSkillMaster_AuctionDB"], ["Auctioneer"]=L["Auctioneer"]},
							value = TSM.db.profile.seenCountFilterSource,
							relativeWidth = 0.49,
							callback = function(_, _, value)
									TSM.db.profile.seenCountFilterSource = value
									container:SelectTab(3)
								end,
							tooltip = L["This setting determines where seen count data is retreived from. The seen count data "
								.. "can be retreived from either Auctioneer or TradeSkillMaster's AuctionDB module."],
						},
						{
							type = "Label",
							text = "",
							relativeWidth = 0.1,
						},
						{
							type = "EditBox",
							label = L["Seen Count Filter"],
							value = TSM.db.profile.seenCountFilter,
							disabled = TSM.db.profile.seenCountFilterSource == "",
							relativeWidth = 0.2,
							callback = function(self, _, value)
									value = tonumber(value)
									if value and value >= 0 then
										TSM.db.profile.seenCountFilter = value
									end
								end,
							tooltip = L["If enabled, any item with a seen count below this seen count filter value will not be added to the craft queue when using the \"Restock Queue\" button. You can overrride this filter for individual items in the \"Additional Item Settings\"."],
						},
						{	-- plus sign for incrementing the number
							type = "Icon",
							image = "Interface\\Buttons\\UI-PlusButton-Up",
							width = 24,
							imageWidth = 24,
							imageHeight = 24,
							disabled = TSM.db.profile.seenCountFilterSource == "",
							callback = function(self)
									local value = TSM.db.profile.seenCountFilter + 1
									TSM.db.profile.seenCountFilter = value

									local i = getIndex(self.parent.children, self)
									self.parent.children[i-1]:SetText(value)
								end,
						},
						{	-- minus sign for decrementing the number
							type = "Icon",
							image = "Interface\\Buttons\\UI-MinusButton-Up",
							disabled = true,
							width = 24,
							imageWidth = 24,
							imageHeight = 24,
							disabled = TSM.db.profile.seenCountFilterSource == "",
							callback = function(self)
									local value = TSM.db.profile.seenCountFilter - 1
									if value < 0 then value = 0 end
									TSM.db.profile.seenCountFilter = value

									local i = getIndex(self.parent.children, self)
									self.parent.children[i-2]:SetText(value)
								end,
						},
					},
				},
				{
					type = "Spacer",
				},
				{
					type =  "InlineGroup",
					layout = "flow",
					title = L["On-Hand Queue"],
					children = {
						{
							type = "CheckBox",
							label = L["Ignore Vendor Items"],
							quickCBInfo = {TSM.db.profile, "assumeVendorInBags"},
							callback = function(self,_,value)
									local siblings = self.parent.children --aw how cute...siblings ;)
									local i = getIndex(siblings, self)
									siblings[i+1]:SetDisabled(not value)
									siblings[i+2]:SetDisabled(not value or not TSM.db.profile.limitVendorItemPrice)									
								end,
							tooltip = L["If checked, the on-hand queue will assume you have all vendor items when queuing crafts."],
						},
						{
							type = "CheckBox",
							disabled = not TSM.db.profile.assumeVendorInBags,
							label = L["Limit Vendor Item Price"],
							quickCBInfo = {TSM.db.profile, "limitVendorItemPrice"},
							callback = function(self,_,value)
									local siblings = self.parent.children --aw how cute...siblings ;)
									local i = getIndex(self.parent.children, self)
									self.parent.children[i+1]:SetDisabled(not value)
								end,
							tooltip = L["If checked, only vendor items below a maximum price will be ignored by the on-hand queue."],
						},
						{
							type = "EditBox",
							label = L["Maximum Price Per Vendor Item"],
							relativeWidth = 0.5,
							value = TSM:FormatTextMoney(TSM.db.profile.maxVendorPrice),
							disabled = not TSM.db.profile.limitVendorItemPrice or not TSM.db.profile.assumeVendorInBags,
							callback = function(self,_,value)
									local copper = TSM:GetMoneyValue(value)
									if not copper then
										TSM:Print(L["Invalid money format entered, should be \"#g#s#c\", \"25g4s50c\" is 25 gold, 4 silver, 50 copper."])
										self:SetFocus()
									else
										self:ClearFocus()
										TSM.db.profile.maxVendorPrice = copper
									end
								end,
							tooltip = L["All vendor items that cost more than this price will not be ignored by the on-hand queue."]
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Options:LoadProfileSettings(container)
	-- profiles page
	local text = {
		default = L["Default"],
		intro = L["You can change the active database profile, so you can have different settings for every character."],
		reset_desc = L["Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over."],
		reset = L["Reset Profile"],
		choose_desc = L["You can either create a new profile by entering a name in the editbox, or choose one of the already exisiting profiles."],
		new = L["New"],
		new_sub = L["Create a new empty profile."],
		choose = L["Existing Profiles"],
		copy_desc = L["Copy the settings from one existing profile into the currently active profile."],
		copy = L["Copy From"],
		delete_desc = L["Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file."],
		delete = L["Delete a Profile"],
		profiles = L["Profiles"],
		current = L["Current Profile:"] .. " " .. TSMAPI.Design:GetInlineColor("link") .. TSM.db:GetCurrentProfile() .. "|r",
	}

	-- Returns a list of all the current profiles with common and nocurrent modifiers.
	-- This code taken from AceDBOptions-3.0.lua
	local function GetProfileList(db, common, nocurrent)
		local profiles = {}
		local tmpprofiles = {}
		local defaultProfiles = {["Default"] = "Default"}

		-- copy existing profiles into the table
		local currentProfile = db:GetCurrentProfile()
		for i,v in pairs(db:GetProfiles(tmpprofiles)) do
			if not (nocurrent and v == currentProfile) then
				profiles[v] = v
			end
		end

		-- add our default profiles to choose from ( or rename existing profiles)
		for k,v in pairs(defaultProfiles) do
			if (common or profiles[k]) and not (nocurrent and k == currentProfile) then
				profiles[k] = v
			end
		end

		return profiles
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "Label",
					text = "TradeSkillMaster_Crafting" .. "\n",
					fontObject = GameFontNormalLarge,
					fullWidth = true,
					colorRed = 255,
					colorGreen = 0,
					colorBlue = 0,
				},
				{
					type = "Label",
					text = text["intro"] .. "\n" .. "\n",
					fullWidth = true,
				},
				{
					type = "Label",
					text = text["reset_desc"],
					fullWidth = true,
				},
				{	--simplegroup1 for the reset button / current profile text
					type = "SimpleGroup",
					layout = "flow",
					children = {
						{
							type = "Button",
							text = text["reset"],
							callback = function() TSM.db:ResetProfile() end,
						},
						{
							type = "Label",
							text = text["current"],
						},
					},
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Label",
					text = text["choose_desc"],
					fullWidth = true,
				},
				{	--simplegroup2 for the new editbox / existing profiles dropdown
					type = "SimpleGroup",
					layout = "flow",
					children = {
						{
							type = "EditBox",
							label = text["new"],
							value = "",
							callback = function(_,_,value)
									TSM.db:SetProfile(value)
									TSM.Data:Initialize()
									container:SelectTab(4)
								end,
						},
						{
							type = "Dropdown",
							label = text["choose"],
							list = GetProfileList(TSM.db, true, nil),
							value = TSM.db:GetCurrentProfile(),
							callback = function(_,_,value)
									if value ~= TSM.db:GetCurrentProfile() then
										TSM.db:SetProfile(value)
										TSM.Data:Initialize()
										container:SelectTab(4)
									end
								end,
						},
					},
				},
				{
					type = "Spacer",
					quantity = 1,
				},
				{
					type = "Label",
					text = text["copy_desc"],
					fullWidth = true,
				},
				{
					type = "Dropdown",
					label = text["copy"],
					list = GetProfileList(TSM.db, true, nil),
					value = "",
					disabled = not GetProfileList(TSM.db, true, nil) and true,
					callback = function(_,_,value)
							if value ~= TSM.db:GetCurrentProfile() then
								TSM.db:CopyProfile(value)
								TSM.Data:Initialize()
								container:SelectTab(4)
							end
						end,
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Label",
					text = text["delete_desc"],
					fullWidth = true,
				},
				{
					type = "Dropdown",
					label = text["delete"],
					list = GetProfileList(TSM.db, true, nil),
					value = "",
					disabled = not GetProfileList(TSM.db, true, nil) and true,
					callback = function(_,_,value)
							if TSM.db:GetCurrentProfile() == value then
								TSM:Print(L["Cannot delete currently active profile!"])
								return
							end
							StaticPopupDialogs["TSMCrafting.DeleteConfirm"].OnAccept = function()
									TSM.db:DeleteProfile(value)
									container:SelectTab(4)
								end
							TSMAPI:ShowStaticPopupDialog("TSMCrafting.DeleteConfirm")
						end,
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end