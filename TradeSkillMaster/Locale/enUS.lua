-- TradeSkillMaster Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkill-Master/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster", "enUS", true)
if not L then return end

-- TradeSkillMaster.lua

L["%sLeft-Click%s to open the main window"] = true
L["%sDrag%s to move this button"] = true
L["Provides the main central frame as well as APIs for all TSM modules."] = true
L["Status"] = true
L["|cffffff00Important Note:|rYou do not currently have any modules installed / enabled for TradeSkillMaster! |cff77ccffYou must download modules for TradeSkillMaster to have some useful functionality!|r\n\nPlease visit http://wow.curse.com/downloads/wow-addons/details/tradeskill-master.aspx and check the project description for links to download modules."] = true
L["I'll Go There Now!"] = true
L["Just incase you didn't read this the first time:"] = true
L["|cffffff00Important Note:|r You do not currently have any modules installed / enabled for TradeSkillMaster! |cff77ccffYou must download modules for TradeSkillMaster to have some useful functionality!|r\n\nPlease visit http://wow.curse.com/downloads/wow-addons/details/tradeskill-master.aspx and check the project description for links to download modules."] = true
L["Welcome to the release version of TradeSkillMaster!\n\nIf you ever need help with TSM, check out the resources listed on the first page of the main TSM window (type /tsm or click the minimap icon)!"] = true
L["Thanks!"] = true
L["TradeSkillMaster Info:"] = true
L["Slash Commands:"] = true
L["/tsm|r - opens the main TSM window."] = true
L["/tsm help|r - Shows this help listing"] = true
L["Module \"%s\" is out of date. Please update."] = true
L["No help provided."] = true
L["Tip:"] = true
L["TSM Help Resources"] = true
L["Need help with TSM? Check out the following resources!"] = true
L["Official TradeSkillMaster Forum:"] = true
L["TradeSkillMaster IRC Channel:"] = true
L["TradeSkillMaster Website:"] = true
L["TradeSkillMaster currently has 10 modules (not including the core addon) each of which can be used completely independantly of the others and have unique features."] = true
L["Keeps track of all your sales and purchases from the auction house allowing you to easily track your income and expendatures and make sure you're turning a profit."] = true
L["Performs scans of the auction house and calculates the market value of items as well as the minimum buyout. This information can be shown in items' tooltips as well as used by other modules."] = true
L["Posts and cancels your auctions to / from the auction house accorder to pre-set rules. Also, this module can show you markets which are ripe for being reset for a profit."] = true
L["Allows you to build a queue of crafts that will produce a profitable, see what materials you need to obtain, and actually craft the items."] = true
L["Mills, prospects, and disenchants items at super speed!"] = true
L["Tracks and manages your inventory across multiple characters including your bags, bank, and guild bank."] = true
L["Allows you to quickly and easily empty your mailbox as well as automatically send items to other characters with the single click of a button."] = true
L["Provides interfaces for efficiently searching for items on the auction house. When an item is found, it can easily be bought, canceled (if it's yours), or even posted from your bags."] = true
L["Manages your inventory by allowing you to easily move stuff between your bags, bank, and guild bank."] = true
L["Allows you to use data from http://wowuction.com in other TSM modules and view its various price points in your item tooltips."] = true
L["Installed Modules"] = true
L["Credits"] = true
L["TradeSkillMaster Team:"] = true
L["Lead Developer and Project Manager:"] = true
L["Active Developers:"] = true
L["Testers (Special Thanks):"] = true
L["Past Contributors:"] = true
L["Translators:"] = true
L["Module:"] = true
L["Version:"] = true
L["Author(s):"] = true
L["Description:"] = true
L["No modules are currently loaded.  Enable or download some for full functionality!"] = true
L["Visit %s for information about the different TradeSkillMaster modules as well as download links."] = true
L["General Settings"] = true
L["Hide Minimap Icon"] = true
L["New Tip"] = true
L["Changes the tip showing at the bottom of the main TSM window."] = true
L["Restore Default Colors"] = true
L["Restores all the color settings below to their default values."] = true
L["Auction House Tab Settings"] = true
L["Make TSM Default Auction House Tab"] = true
L["Show Bids in Auction Results Table (Requires Reload)"] = true
L["If checked, all tables listing auctions will display the bid as well as the buyout of the auctions. This will not take effect immediately and may require a reload."] = true
L["Make Auction Frame Movable"] = true
L["Auction Frame Scale"] = true
L["Changes the size of the auction frame. The size of the detached TSM auction frame will always be the same as the main auction frame."] = true
L["Detach TSM Tab by Default"] = true
L["Open All Bags with Auction House"] = true
L["If checked, your bags will be automatically opened when you open the auction house."] = true
L["Light (by Ravanys - The Consortium)"] = true
L["Goblineer (by Sterling - The Consortium)"] = true
L["Jaded (by Ravanys - The Consortium)"] = true
L["TSMDeck (by Jim Younkin - Power Word: Gold)"] = true
L["TSM Classic (by Jim Younkin - Power Word: Gold)"] = true
L["TSM Appearance Options"] = true
L["Use the options below to change and tweak the appearance of TSM."] = true
L["Import Appearance Settings"] = true
L["This allows you to import appearance settings which other people have exported."] = true
L["Export Appearance Settings"] = true
L["This allows you to export your appearance settings to share with others."] = true
L["Import Preset TSM Theme"] = true
L["Select a theme from this dropdown to import one of the preset TSM themes."] = true
L["Appearance Data"] = true
L["Invalid appearance data."] = true
L["Frame Background - Backdrop"] = true
L["Frame Background - Border"] = true
L["Region - Backdrop"] = true
L["Region - Border"] = true
L["Content - Backdrop"] = true
L["Content - Border"] = true
L["Icon Region"] = true
L["Title"] = true
L["Label Text - Enabled"] = true
L["Label Text - Disabled"] = true
L["Content Text - Enabled"] = true
L["Content Text - Disabled"] = true
L["Link Text (Requires Reload)"] = true
L["Link Text 2 (Requires Reload)"] = true
L["Category Text (Requires Reload)"] = true
L["Category Text 2 (Requires Reload)"] = true
L["Small Text Size (Requires Reload)"] = true
L["Normal Text Size (Requires Reload)"] = true
L["Border Thickness (Requires Reload)"] = true
L["TSM Info / Help"] = true
L["Status / Credits"] = true
L["Options"] = true

-- ErrorHandler.lua

L["TradeSkillMaster Error Window"] = true
L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by copying the entire error below and following the instructions for reporting bugs listed here (unless told elsewhere by the author):"] = true
L["Error Info:"] = true
L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by following the instructions shown."] = true
L["Additional error suppressed"] = true

-- ItemData.lua

L["Auctioneer - Appraiser"] = true
L["Auctioneer - Minimum Buyout"] = true
L["Auctioneer - Market Value"] = true
L["Auctionator - Auction Value"] = true
L["ItemAuditor - Cost"] = true
L["TheUndermineJournal - Market Price"] = true
L["TheUndermineJournal - Mean"] = true
L["AuctionDB - Market Value"] = true
L["AuctionDB - Minimum Buyout"] = true
L["Crafting Cost"] = true
L["Vendor Sell Price"] = true

-- AuctionFrame.lua

L["Click this button to detach the TradeSkillMaster tab from the rest of the auction house."] = true
L["Click this button to re-attach the TradeSkillMaster tab to the auction house."] = true
L["Detach TSM Tab"] = true
L["Attach TSM Tab"] = true
L["Show stacks as price per item"] = true

-- AuctionGUI.lua

L["Show stacks as price per item"] = true
L["Careful where you click!"] = true
L["TradeSkillMaster Human Check - Click on the Correct Button!"] = true
L["I am human!"] = true
L["I am a bot!"] = true

-- AuctionScrollingTable.lua

L["Double-click to expand this item and show all the auctions.\n\nRight-click to open the quick action menu."] = true
L["Double-click to collapse this item and show only the cheapest auction.\n\nRight-click to open the quick action menu."] = true
L["There is only one price level and seller for this item.\n\nRight-click to open the quick action menu."] = true
L["Quick Action Menu:"] = true

-- Destroying.lua

L["Common Inks"] = true
L["Uncommon Inks"] = true
L["BC Gems"] = true
L["BC - Green Quality"] = true
L["Uncommon Gems"] = true
L["BC - Blue Quality"] = true
L["Rare Gems"] = true
L["Wrath Gems"] = true
L["Wrath - Green Quality"] = true
L["Wrath - Blue Quality"] = true
L["Wrath - Epic Quality"] = true
L["Epic Gems"] = true
L["Cata Gems"] = true
L["Cata - Green Quality"] = true
L["Cata - Blue Quality"] = true
L["Dust"] = true
L["Essences"] = true
L["Shards"] = true
L["Crystals"] = true
L["Elemental - Motes"] = true
L["Elemental - Eternals"] = true