-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Options = TSM:NewModule("Options", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {}



-- ============================================================================
-- Module Options
-- ============================================================================

function Options:Load(container)
	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["General Options"],
					children = {
						{
							type = "EditBox",
							label = L["Market Value Price Source"],
							settingInfo = { TSM.db.global, "marketValueSource" },
							acceptCustom = true,
							tooltip = L["This is how Shopping calculates the '% Market Value' column in the search results."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Disenchant Search Options"],
					children = {
						{
							type = "Slider",
							label = L["Min Disenchant Level"],
							settingInfo = { TSM.db.global, "minDeSearchLvl" },
							min = 1,
							max = 905,
							step = 1,
							isPercent = false,
							callback = function(self, _, value)
								if value > TSM.db.global.maxDeSearchLvl then
									TSM:Print(TSMAPI.Design:GetInlineColor("link2") .. L["Warning: The min disenchant level must be lower than the max disenchant level."] .. "|r")
								end
								TSM.db.global.minDeSearchLvl = min(value, TSM.db.global.maxDeSearchLvl)
							end,
							tooltip = L["This is the minimum item level that the Other > Disenchant search will display results for."],
						},
						{
							type = "Slider",
							label = L["Max Disenchant Level"],
							settingInfo = { TSM.db.global, "maxDeSearchLvl" },
							min = 1,
							max = 905,
							step = 1,
							isPercent = false,
							callback = function(self, _, value)
								if value < TSM.db.global.minDeSearchLvl then
									TSM:Print(TSMAPI.Design:GetInlineColor("link2") .. L["Warning: The max disenchant level must be higher than the min disenchant level."] .. "|r")
								end
								TSM.db.global.maxDeSearchLvl = max(value, TSM.db.global.minDeSearchLvl)
							end,
							tooltip = L["This is the maximum item level that the Other > Disenchant search will display results for."],
						},
						{
							type = "Slider",
							label = L["Max Disenchant Search Percent"],
							settingInfo = { TSM.db.global, "maxDeSearchPercent" },
							min = .1,
							max = 1,
							step = .01,
							isPercent = true,
							tooltip = L["This is the maximum percentage of disenchant value that the Other > Disenchant search will display results for."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Posting Options"],
					children = {
						{
							type = "EditBox",
							label = L["Default Post Undercut Amount"],
							settingInfo = { TSM.db.global, "postUndercut" },
							acceptCustom = true,
							tooltip = L["What to set the default undercut to when posting items with Shopping."],
						},
						{
							type = "Slider",
							label = L["Bid Percent"],
							settingInfo = { TSM.db.global, "postBidPercent" },
							min = .1,
							max = 1,
							step = .01,
							isPercent = true,
							tooltip = L["This is the percentage of your buyout price that your bid will be set to when posting auctions with Shopping."],
						},
						{
							type = "EditBox",
							label = L["Normal Post Price"],
							settingInfo = { TSM.db.global, "normalPostPrice" },
							acceptCustom = true,
							tooltip = L["This is the default price Shopping will suggest to post items at when there's no others posted."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Sniper Options"],
					children = {
						{
							type = "Dropdown",
							label = L["Found Auction Sound"],
							list = TSMAPI:GetSounds(),
							settingInfo = { TSM.db.global, "sniperSound" },
							tooltip = L["Play the selected sound when a new auction is found to snipe."],
						},
						{
							type = "Button",
							text = L["Test Selected Sound"],
							callback = function() TSMAPI:DoPlaySound(TSM.db.global.sniperSound) end,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["Below Vendor Sell Price"],
							settingInfo = { TSM.db.global, "sniperVendorPrice" },
							tooltip = L["Items which are below their vendor sell price will be displayed in Sniper searches."],
						},
						{
							type = "EditBox",
							label = L["Below Custom Price ('0c' to disable)"],
							settingInfo = { TSM.db.global, "sniperCustomPrice" },
							acceptCustom = true,
							tooltip = L["Items which are below this custom price will be displayed in Sniper searches."],
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
	local description = L["Shopping operations contain settings items which you regularly buy from the auction house."]
	local tabInfo = {
		{ text = L["General"], callback = private.DrawOperationGeneral},
	}
	local relationshipInfo = {
		{
			label = L["General Settings"],
			{ key = "maxPrice", label = L["Maximum Auction Price (per item)"] },
			{ key = "showAboveMaxPrice", label = L["Show Auctions Above Max Price"] },
			{ key = "evenStacks", label = L["Even (5/10/15/20) Stacks Only"] },
			{ key = "includeInSniper", label = L["Include in Sniper Searches"] },
			{ key = "restockQuantity", label = L["Max Restock Quantity"] },
			{ key = "restockSources", label = L["Sources to Include in Restock"] },
		},
	}
	return description, tabInfo, relationshipInfo
end

function private.DrawOperationGeneral(container, operationName)
	local operation = TSM.operations[operationName]
	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["General Operation Options"],
					children = {
						{
							type = "EditBox",
							label = L["Maximum Auction Price (per item)"],
							settingInfo = { operation, "maxPrice" },
							relativeWidth = 0.5,
							acceptCustom = true,
							disabled = operation.relationships.maxPrice,
							tooltip = L["The highest price per item you will pay for items in affected by this operation."],
						},
						{
							type = "CheckBox",
							label = L["Show Auctions Above Max Price"],
							settingInfo = { operation, "showAboveMaxPrice" },
							relativeWidth = 0.49,
							disabled = operation.relationships.showAboveMaxPrice,
							tooltip = L["If checked, auctions above the max price will be shown."],
						},
						{
							type = "CheckBox",
							label = L["Even (5/10/15/20) Stacks Only"],
							settingInfo = { operation, "evenStacks" },
							relativeWidth = 0.5,
							disabled = operation.relationships.evenStacks,
							tooltip = L["If checked, only auctions posted in even quantities will be considered for purchasing."],
						},
						{
							type = "CheckBox",
							label = L["Include in Sniper Searches"],
							settingInfo = { operation, "includeInSniper" },
							relativeWidth = 0.49,
							disabled = operation.relationships.includeInSniper,
							tooltip = L["If checked, auctions below the max price will be shown while sniping."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Slider",
							label = L["Max Restock Quantity"],
							settingInfo = { operation, "restockQuantity" },
							disabled = operation.relationships.restockQuantity,
							min = 0,
							max = 5000,
							step = 1,
							relativeWidth = 0.5,
							tooltip = L["Shopping will only search for enough items to restock your bags to the specific quantity. Set this to 0 to disable this feature."],
						},
						{
							type = "Dropdown",
							label = L["Sources to Include in Restock"],
							disabled = operation.relationships.restockSources,
							relativeWidth = 0.5,
							list = {bank=BANK, guild=GUILD, alts=L["Alts"], auctions = L["Auctions"]},
							value = operation.restockSources,
							multiselect = true,
							callback = function(_, _, key, value)
								operation.restockSources[key] = value
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
					label = L["Show Shopping Max Price in Tooltip"],
					settingInfo = { options, "maxPrice" },
					tooltip = L["If checked, the maximum shopping price will be shown in the tooltip for the item."],
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end