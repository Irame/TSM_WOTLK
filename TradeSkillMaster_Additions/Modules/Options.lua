-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Additions                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_additions           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Options = TSM:NewModule("Options")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Additions") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

function Options:Load(parent)
	local simpleGroup = AceGUI:Create("TSMSimpleGroup")
	simpleGroup:SetLayout("Fill")
	parent:AddChild(simpleGroup)
	Options:DrawSettings(simpleGroup)
end

function Options:DrawSettings(container)
	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
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
							settingInfo = {TSM.db.global, "enableAuctionSales"},
							quickCBInfo = {TSM.db.global, "enableAuctionSales"},
							callback = TSM.UpdateFeatureStates,
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "Flow",
					title = L["Vendor Buying"],
					children = {
						{
							type = "Label",
							text = L["The vendor buying feature will replace the default frame that is shown when you shift-right-click on a vendor item for purchasing with a small frame that allows you to buy more than one stacks worth at a time."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = L["Enable Vendor Buying Feature"],
							relativeWidth = 1,
							settingInfo = {TSM.db.global, "enableVendorBuying"},
							quickCBInfo = {TSM.db.global, "enableVendorBuying"},
							callback = TSM.UpdateFeatureStates,
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end