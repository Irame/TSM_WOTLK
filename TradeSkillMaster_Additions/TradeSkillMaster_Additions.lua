-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Additions                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_additions           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_Additions", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Additions") -- loads the localization table
TSM.version = GetAddOnMetadata("TradeSkillMaster_Additions","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster_Additions", "Version") -- current version of the addon

local savedDBDefaults = {
	global = {
		enableAuctionSales = true,
		enableVendorBuying = true,
	},
	char = {
		auctionMessages = {},
		auctionPrices = {},
	},
}

-- Called once the player has loaded WOW.
function TSM:OnInitialize()
	-- load the savedDB into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMaster_AdditionsDB", savedDBDefaults, true)
	
	for module in pairs(TSM.modules) do
		TSM[module] = TSM.modules[module]
	end
	
	-- register with TSM
	TSM:RegisterModule()
	
	TSM:UpdateFeatureStates()
end

-- registers this module with TSM by first setting all fields and then calling TSMAPI:NewModule().
function TSM:RegisterModule()
	TSMAPI:RegisterReleasedModule("TradeSkillMaster_Additions", TSM.version, GetAddOnMetadata("TradeSkillMaster_Additions", "Author"),
		GetAddOnMetadata("TradeSkillMaster_Additions", "Notes"), TSM.versionKey)
		
	TSMAPI:RegisterIcon("Additions", "Interface\\Icons\\Inv_Misc_Coin_08",
		function(...) TSM.Options:Load(...) end, "TradeSkillMaster_Additions")
end

-- enable / disable features according to the options
function TSM:UpdateFeatureStates()
	if TSM.db.global.enableAuctionSales then
		TSM.AuctionSales:Enable()
	else
		TSM.AuctionSales:Disable()
	end
	
	if TSM.db.global.enableVendorBuying then
		TSM.VendorBuying:Enable()
	else
		TSM.VendorBuying:Disable()
	end
end