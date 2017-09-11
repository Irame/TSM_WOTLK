-- ------------------------------------------------------------------------------------- --
--   TradeSkillMaster_AuctionDB - AddOn by Sapu94                                        --
--   http://www.curse.com/addons/wow/TradeSkillMaster_AuctionDB                          --
--                                                                                       --
--   This addon is licensed under the CC BY-NC-ND 3.0 license as described at the        --
--   following url: http://creativecommons.org/licenses/by-nc-nd/3.0/                    --
--   Please contact the author via email at sapu94@gmail.com with any questions or       --
--   concerns regarding this license.                                                    --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_AuctionDB Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkill-Master/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_AuctionDB", "enUS", true)
if not L then return end

-- TradeSkillMaster_AuctionDB.lua

L["Resets AuctionDB's scan data"] = true
L["AuctionDB - Market Value"] = true
L["AuctionDB - Minimum Buyout"] = true
L["AuctionDB Market Value:"] = true
L["AuctionDB Min Buyout:"] = true
L["AuctionDB Seen Count:"] = true
L["Are you sure you want to clear your AuctionDB data?"] = true
L["Reset Data"] = true

-- config.lua

L["Search"] = true
L["Options"] = true
L["No items found"] = true
L["Use the search box and category filters above to search the AuctionDB data."] = true
L["You can use this page to lookup an item or group of items in the AuctionDB database. Note that this does not perform a live search of the AH."] = true
L["Any items in the AuctionDB database that contain the search phrase in their names will be displayed."] = true
L["Item Type Filter"] = true
L["You can filter the results by item type by using this dropdown. For example, if you want to search for all herbs, you would select \"Trade Goods\" in this dropdown and \"Herbs\" as the subtype filter."] = true
L["Item SubType Filter"] = true
L["You can filter the results by item subtype by using this dropdown. For example, if you want to search for all herbs, you would select \"Trade Goods\" in the item type dropdown and \"Herbs\" in this dropdown."] = true
L["Refresh"] = true
L["Refreshes the current search results."] = true
L["Previous Page"] = true
L["Items %s - %s (%s total)"] = true
L["Next Page"] = true
L["Removed %s from AuctionDB."] = true
L["Shift-Right-Click to clear all data for this item from AuctionDB."] = true
L["Item Link"] = true
L["Num(Yours)"] = true
L["Minimum Buyout"] = true
L["Min Buyout"] = true
L["Market Value"] = true
L["Last Scanned"] = true
L["%s ago"] = true
L["General Options"] = true
L["Enable display of AuctionDB data in tooltip."] = true
L["Display disenchant value in tooltip."] = true
L["If checked, the disenchant value of the item will be shown. This value is calculated using the average market value of materials the item will disenchant into."] = true
L["Disenchant source:"] = true
L["Select whether to use market value or min buyout for calculating disenchant value."] = true
L["Search Options"] = true
L["Items per page"] = true
L["Invalid value entered. You must enter a number between 5 and 500 inclusive."] = true
L["This determines how many items are shown per page in results area of the \"Search\" tab of the AuctionDB page in the main TSM window. You may enter a number between 5 and 500 inclusive. If the page lags, you may want to decrease this number."] = true
L["Sort items by"] = true
L["Item MinLevel"] = true
L["Select how you would like the search results to be sorted. After changing this option, you may need to refresh your search results by hitting the \"Refresh\" button."] = true
L["Result Order:"] = true
L["Ascending"] = true
L["Descending"] = true
L["Select whether to sort search results in ascending or descending order."] = true
L["Hide poor quality items"] = true
L["If checked, poor quality items won't be shown in the search results."] = true

-- GUI.lua

L["Enchanting"] = true
L["Inscription"] = true
L["Jewelcrafting"] = true
L["Alchemy"] = true
L["Blacksmithing"] = true
L["Leatherworking"] = true
L["Tailoring"] = true
L["Engineering"] = true
L["Cooking"] = true
L["Run Scan"] = true
L["Scan the auction house with AuctionDB to update its market value and min buyout data."] = true
L["Ready in %s min and %s sec"] = true
L["Not Ready"] = true
L["Ready"] = true
L["A GetAll scan is the fastest in-game method for scanning every item on the auction house. However, it may disconnect you from the game and has a 15 minute cooldown."] = true
L["Run GetAll Scan"] = true
L["A full auction house scan will scan every item on the auction house but is far slower than a GetAll scan. Expect this scan to take several minutes or longer."] = true
L["Run Full Scan"] = true
L["A profession scan will scan items required/made by a certain profession."] = true
L["Professions:"] = true
L["Select professions to include in the profession scan."] = true
L["Run Profession Scan"] = true
L["Never scan the auction house again!"] = true
L["The author of TradeSkillMaster has created an application which uses blizzard's online auction house APIs to update your AuctionDB data automatically. Check it out at the link in TSM_AuctionDB's description on curse or at: %s"] = true

-- Scanning.lua

L["%s - Scanning page %s/%s of filter %s/%s"] = true
L["Waiting for data..."] = true
L["Scanning..."] = true
L["Scan interrupted."] = true
L["Done Scanning"] = true
L["|cffff0000WARNING:|r As of 4.0.1 there is a bug with GetAll scans only scanning a maximum of 42554 auctions from the AH which is less than your auction house currently contains. As a result, thousands of items may have been missed. Please use regular scans until blizzard fixes this bug."] = true
L["It is strongly recommended that you reload your ui (type '/reload') after running a GetAll scan. Otherwise, any other scans (Post/Cancel/Search/etc) will be much slower than normal."] = true