-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- TradeSkillMaster_Shopping Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/tradeskillmaster_shopping/localization/

local isDebug = false
--[===[@debug@
isDebug = true
--@end-debug@]===]
local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Shopping", "enUS", true, isDebug)
if not L then return end

L["Added '%s' to your favorite searches."] = true
L["Alts"] = true
L["Auction Bid:"] = true
L[ [=[Auction Bid
(per item)]=] ] = true
L[ [=[Auction Bid
(per stack)]=] ] = true
L["Auction Buyout"] = true
L["Auction Buyout:"] = true
L[ [=[Auction Buyout
(per item)]=] ] = true
L[ [=[Auction Buyout
(per stack)]=] ] = true
L["auctioning"] = true
L["Auctions"] = true
L["Below Custom Price ('0c' to disable)"] = true
L["Below Vendor Sell Price"] = true
L["Bid Percent"] = true
L["Canceling Auction:"] = true
L["|cff99ffff[Crafting]|r "] = true
L["|cff99ffff[Normal]|r "] = true
L["Could not find crafting info for the specified item."] = true
L["Could not find this item on the AH. Removing it."] = true
L["Could not lookup item info for '%s' so skipping it."] = true
L["Ctrl-Left-Click to rename this search."] = true
L["Custom Filter"] = true
L["Custom Filter / Other Searches"] = true
L["%d auctions found below vendor price for a potential profit of %s!"] = true
L["Default Post Undercut Amount"] = true
L["Desktop App Searches"] = true
L["% DE Value"] = true
L["disenchant search"] = true
L["Disenchant Search Options"] = true
L["Done Scanning"] = true
L["Duration:"] = true
L["Enter what you want to search for in this box. You can also use the following options for more complicated searches."] = true
L["Even (5/10/15/20) Stacks Only"] = true
L["Failed to bid on this auction. Skipping it."] = true
L["Failed to buy this auction. Skipping it."] = true
L["Failed to cancel auction because somebody has bid on it."] = true
L["Favorite Searches"] = true
L["Found Auction Sound"] = true
L["gathering"] = true
L["General"] = true
L["General Operation Options"] = true
L["General Options"] = true
L["General Settings"] = true
L["great deals"] = true
L["Great Deals"] = true
L["group search"] = true
L["If checked, auctions above the max price will be shown."] = true
L["If checked, auctions below the max price will be shown while sniping."] = true
L["If checked, only auctions posted in even quantities will be considered for purchasing."] = true
L["If checked, the maximum shopping price will be shown in the tooltip for the item."] = true
L["If set, only items which are usable by your character will be included in the results."] = true
L["If set, only items which exactly match the search filter you have set will be included in the results."] = true
L["Import"] = true
L["Import Favorite Search"] = true
L["Include in Sniper Searches"] = true
L["Inline Filters:|r You can easily add common search filters to your search such as rarity, level, and item type. For example '%sarmor/leather/epic/85/i350/i377|r' will search for all leather armor of epic quality that requires level 85 and has an ilvl between 350 and 377 inclusive. Also, '%sinferno ruby/exact|r' will display only raw inferno rubys (none of the cuts)."] = true
L["Invalid custom price source for %s. %s"] = true
L["Invalid Even Only Filter"] = true
L["Invalid Exact Only Filter"] = true
L["Invalid Filter"] = true
L["Invalid Item Inventory Type"] = true
L["Invalid Item Level"] = true
L["Invalid Item Rarity"] = true
L["Invalid Item SubType"] = true
L["Invalid Item Type"] = true
L["Invalid Max Quantity"] = true
L["Invalid Min Level"] = true
L["Invalid Usable Only Filter"] = true
L["Item Buyout"] = true
L["Item Class"] = true
L["Item Level Range:"] = true
L["item notifications"] = true
L["Item Notifications"] = true
L["Item SubClass"] = true
L["Items which are below their vendor sell price will be displayed in Sniper searches."] = true
L["Items which are below this custom price will be displayed in Sniper searches."] = true
L["Left-Click to run this search."] = true
L["% Market Value"] = true
L["Market Value Price Source"] = true
L["% Mat Price"] = true
L["Max Disenchant Level"] = true
L["Max Disenchant Search Percent"] = true
L["Maximum Auction Price (per item)"] = true
L["Maximum Quantity to Buy:"] = true
L["% Max Price"] = true
L["Max Restock Quantity"] = true
L["Max Shopping Price:"] = true
L["Min Disenchant Level"] = true
L["Minimum Bid:"] = true
L["Minimum Rarity"] = true
L["Multiple Search Terms:|r You can search for multiple things at once by simply separated them with a ';'. For example '%selementium ore; obsidium ore|r' will search for both elementium and obsidium ore."] = true
L["No recent AuctionDB scan data found."] = true
L["Normal"] = true
L["Normal Post Price"] = true
L["Nothing to search for!"] = true
L["Only exporting normal mode searches is allows."] = true
L["Other Searches"] = true
L["Paste the search you'd like to import into the box below."] = true
L["Play the selected sound when a new auction is found to snipe."] = true
L["Post"] = true
L["Posting auctions..."] = true
L["Posting Options"] = true
L["Preparing Filters..."] = true
L["Press Ctrl-C to copy this saved search."] = true
L["Price Per Item:"] = true
L["Purchased the maximum quantity of this item!"] = true
L["Purchasing Auction:"] = true
L["Recent Searches"] = true
L["Removed '%s' from your favorite searches."] = true
L["Removed '%s' from your recent searches."] = true
L["Required Level Range:"] = true
L["Reset Filters"] = true
L["Right-Click to favorite this recent search."] = true
L["Right-Click to remove from favorite searches."] = true
L["Saved Searches / TSM Groups"] = true
L["Scanning %d / %d (Page %d / %d)"] = true
L["Scanning Last Page..."] = true
L["Search Filter:"] = true
L["Searching for auction..."] = true
L["Search Mode:"] = true
L["Search Results"] = true
L["Select the groups which you would like to include in the search."] = true
L["'%s' has a Shopping operation of '%s' which no longer exists. Shopping will ignore this group until this is fixed."] = true
L["Shift-Click to run sniper again."] = true
L["Shift-Click to run the next favorite search."] = true
L["Shift-Left-Click to export this search."] = true
L["Shift-Right-Click to remove this recent search."] = true
L["Shopping for auctions including those above the max price."] = true
L["Shopping for auctions with a max price set."] = true
L["Shopping for even stacks including those above the max price"] = true
L["Shopping for even stacks with a max price set."] = true
L["Shopping operations contain settings items which you regularly buy from the auction house."] = true
L["Shopping will only search for enough items to restock your bags to the specific quantity. Set this to 0 to disable this feature."] = true
L["Show Auctions Above Max Price"] = true
L["Show Shopping Max Price in Tooltip"] = true
L["Skipped the following search term because it's invalid."] = true
L["Skipped the following search term because it's too long. Blizzard does not allow search terms over 63 characters."] = true
L["sniper"] = true
L["Sniper Options"] = true
L["Sources to Include in Restock"] = true
L["stack(s) of"] = true
L["Start Disenchant Search"] = true
L["Start Search"] = true
L["Start Sniper"] = true
L["Start Vendor Search"] = true
L["Stop"] = true
L[ [=[Target Price
(per item)]=] ] = true
L[ [=[Target Price
(per stack)]=] ] = true
L["% Target Value"] = true
L["Test Selected Sound"] = true
L["The disenchant search looks for items on the AH below their disenchant value. You can set the maximum percentage of disenchant value to search for in the Shopping General options"] = true
L["The highest price per item you will pay for items in affected by this operation."] = true
L["The Sniper feature will look in real-time for items that have recently been posted to the AH which are worth snatching! You can configure the parameters of Sniper in the Shopping options."] = true
L["The vendor search looks for items on the AH below their vendor sell price."] = true
L["This is how Shopping calculates the '% Market Value' column in the search results."] = true
L["This is not a valid target item."] = true
L["This is the default price Shopping will suggest to post items at when there's no others posted."] = true
L["This is the main content area which will change depending on which button is selected above."] = true
L["This is the maximum item level that the Other > Disenchant search will display results for."] = true
L["This is the maximum percentage of disenchant value that the Other > Disenchant search will display results for."] = true
L["This is the minimum item level that the Other > Disenchant search will display results for."] = true
L["This is the percentage of your buyout price that your bid will be set to when posting auctions with Shopping."] = true
L["This searches the AH for all items found on the TSM Great Deals page (http://tradeskillmaster.com/great-deals)."] = true
L["This searches the AH for your current deals as displayed on the TSM website."] = true
L["Total Deposit:"] = true
L["Type in the new name for this saved search and hit the 'Save' button."] = true
L["Unexpected filters (only '/even' or '/ignorede' or '/x<MAX_QUANTITY>' is supported in crafting mode): %s"] = true
L["Unknown Filter"] = true
L["Use these buttons to change what is shown below."] = true
L["vendor search"] = true
L["% Vendor Value"] = true
L["Warning: The max disenchant level must be higher than the min disenchant level."] = true
L["Warning: The min disenchant level must be lower than the max disenchant level."] = true
L["What to set the default undercut to when posting items with Shopping."] = true
L["When in crafting mode, the search results will include materials which can be used to craft the item which you search for. This includes milling, prospecting, and disenchanting."] = true
L["When in normal mode, you may run simple and filtered searches of the auction house."] = true
L["You can change the search mode here. Crafting mode will include items which can be crafted into the specific items (through professions, milling, prospecting, disenchanting, and more) in the search."] = true
L["You can type search filters into the search bar and click on the 'SEARCH' button to quickly search the auction house. Refer to the tooltip of the search bar for details on more advanced filters."] = true
L["You must enter a search filter before starting the search."] = true
