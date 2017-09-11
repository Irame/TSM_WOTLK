-- ------------------------------------------------------------------------------------- --
--   TradeSkillMaster_Shopping - AddOn by Sapu94                                         --
--   http://www.curse.com/addons/wow/TradeSkillMaster_Shopping                           --
--                                                                                       --
--   This addon is licensed under the CC BY-NC-ND 3.0 license as described at the        --
--   following url: http://creativecommons.org/licenses/by-nc-nd/3.0/                    --
--   Please contact the author via email at sapu94@gmail.com with any questions or       --
--   concerns regarding this license.                                                    --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Shopping Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkill-Master/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Shopping", "enUS", true)
if not L then return end

-- TradeSkillMaster_Shopping.lua

L["Shopping Options"] = true
L["Add item to shopping list"] = true
L["Add item to dealfinding list"] = true
L["Add Item to Shopping List"] = true
L["List to Add Item to:"] = true
L["Which list to add this item to."] = true
L["Add Item to Selected List"] = true
L["Name of New List to Add Item to:"] = true
L["Add Item to New List"] = true
L["Add Item to Dealfinding List"] = true
L["This item is already in the \"%s\" Dealfinding List."] = true

-- AuctionControl.lua

L["Purchasing"] = true
L["Canceling"] = true
L["Post"] = true
L["Posting"] = true
L["Searching for item..."] = true
L["You currently have %s of this item and it stacks up to %s."] = true
L["Item Buyout:"] = true
L["Auction Buyout:"] = true
L["Cannot create auction with 0 buyout."] = true
L["Auction Buyout (Stack Price):"] = true
L["Stack Info:"] = true
L["MAX"] = true
L["stacks of"] = true
L["Auction Duration"] = true
L["12 hours"] = true
L["24 hours"] = true
L["48 hours"] = true
L["Use this checkbox to temporarily modify the post duration. You can change the default value in the Shopping options."] = true
L["Auction not found. Skipped."] = true

-- Automatic.lua

L["Crafting Mats"] = true
L["Shop for materials required by the Crafting queue."] = true
L["Shopping - Crafting Mats"] = true
L["Cannot change current item while scanning."] = true
L["Click to shop for this item."] = true
L["Milling"] = true
L["Prospecting"] = true
L["Disenchanting"] = true
L["Transforming"] = true
L["Professions to Buy Materials for:"] = true
L["Select all the professions for which you would like to buy materials."] = true
L["Additional Options:"] = true
L["Destroying Modes to Use:"] = true
L["Here you can choose in which situations Shopping should run a destroying search rather than a regular search for the target item."] = true
L["Even Stacks Only (Ore/Herbs)"] = true
L["If checked, only 5/10/15/20 stacks of ore and herbs will be shown. Note that this setting is the same as the one that shows up when you run a Destroying search."] = true
L["Shopping for:"] = true
L["Crafting Cost:"] = true
L["Quantity Needed:"] = true
L["Search Mode: %sDestroying Search|r"] = true
L["Search Mode: %sRegular Search|r"] = true

-- Config.lua

L["This item is already in this group."] = true
L["The item you entered was invalid. See the tooltip for the \"%s\" editbox for info about how to add items."] = true
L["Item to Add"] = true
L["Item is already in dealfinding list: %s"] = true
L["Invalid list name. A list with this name may already exist."] = true
L["Shopping/Dealfinding list with name \"%s\" already exists. Creating group under name \"%s\" instead."] = true
L["Options"] = true
L["Profiles"] = true
L["Dealfinding Lists"] = true
L["Shopping Lists"] = true
L["Items"] = true
L["List Management"] = true
L["General Options"] = true
L["Below are some general options for the Shopping module."] = true
L["Search Results Default Sort (requires reload)"] = true
L["Item"] = true
L["Item Level"] = true
L["Auctions"] = true
L["Stack Size"] = true
L["Time Left"] = true
L["Seller"] = true
L["Price Per Item/Stack"] = true
L["% Market Value"] = true
L["Specifies the default sorting for results in the \"Search\" feature."] = true
L["Destroying Results Default Sort (requires reload)"] = true
L["Price Per Target Item"] = true
L["Specifies the default sorting for results in the \"Destroying\" feature."] = true
L["Automatically Expand Single Result"] = true
L["If the results of a search only contain one unique item, it will be automatically expanded to show all auctions of that item if this option is enabled."] = true
L["Show Results Above Dealfinding Price"] = true
L["If checked, the results of a dealfinding scan will include items above the maximum price. This can be useful if you sometimes want to buy items that are just above your max price."] = true
L["Posting Options"] = true
L["The options below control the \"Post\" button that is shown at the bottom of the auction frame inside the \"Search\" feature."] = true
L["Auction Duration"] = true
L["12 hours"] = true
L["24 hours"] = true
L["48 hours"] = true
L["How long auctions should be posted for."] = true
L["Default Undercut"] = true
L["Invalid money format entered, should be \"#g#s#c\", \"25g4s50c\" is 25 gold, 4 silver, 50 copper."] = true
L["How much to undercut other auctions by, format is in \"#g#s#c\", \"50g30s\" means 50 gold, 30 silver."] = true
L["Bid Percent"] = true
L["Determines what percent of the buyout price Shopping will use for the starting bid when posting auctions."] = true
L["Fallback Price Source"] = true
L["If there are none of an item on the auction house, Shopping will use this price source for the default post price."] = true
L["Fallback Price Percent"] = true
L["If there are none of an item on the auction house, Shopping will use this percentage of the fallback price source for the default post price."] = true
L["Use the box below to create a new shopping list. A shopping list is a list of items and search terms you frequently search for."] = true
L["Shopping List Name"] = true
L["Name of the new shopping list."] = true
L["Import Shopping List"] = true
L["Opens a new window that allows you to import a shopping list."] = true
L["New Dealfinding List"] = true
L["Use the box below to create a new dealfinding list. A dealfinding list is a list of items along with a max price you'd like to pay for each item. This is the equivalent of a \"snatch list\"."] = true
L["Dealfinding List Name"] = true
L["Name of the new dealfinding list."] = true
L["Import Dealfinding List"] = true
L["Opens a new window that allows you to import a dealfinding list."] = true
L["Default"] = true
L["You can change the active database profile, so you can have different settings for every character."] = true
L["Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over."] = true
L["Reset Profile"] = true
L["You can either create a new profile by entering a name in the editbox, or choose one of the already exisiting profiles."] = true
L["New"] = true
L["Create a new empty profile."] = true
L["Existing Profiles"] = true
L["Copy the settings from one existing profile into the currently active profile."] = true
L["Copy From"] = true
L["Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file."] = true
L["Delete a Profile"] = true
L["Current Profile:"] = true
L["Are you sure you want to delete the selected profile?"] = true
L["Accept"] = true
L["Cancel"] = true
L["Here, you can set the maximum price you want to pay for each item in this list."] = true
L["Max Price Per Item"] = true
L["This is the maximum price you want to pay per item (NOT per stack) for this item. You will be prompted to buy all items on the AH that are below this price."] = true
L["Even Stacks Only"] = true
L["Only even stacks (5/10/15/20) of this item will be purchased. This is useful for buying herbs / ore to mill / prospect."] = true
L["Remove"] = true
L["Add Item"] = true
L["Here you can add an item to this dealfinding list."] = true
L["You can either drag an item into this box, paste (shift click) an item link into this box, or enter an itemID."] = true
L["Item Settings"] = true
L["Invalid search term."] = true
L["Did not add search term \"%s\". Already in this list."] = true
L["Here, you can remove items from this list."] = true
L["Here, you can remove search terms from this list."] = true
L["Add Item / Search Term"] = true
L["Here you can add an item or a search term to this shopping list."] = true
L["Add Search Term"] = true
L["Enter the search term you would list to add below. You can add multiple search terms at once by separating them with semi-colons. For example, \"elementium ore; volatile\""] = true
L["Remove Item"] = true
L["Remove Search Term"] = true
L["%s is already in a dealfinding list and has been removed from this list."] = true
L["Invalid folder name. A folder with this name may already exist."] = true
L["Use the button below to convert this list from a Dealfinding list to a Shopping list.\n\nNOTE: Doing so will remove all item settings from the list! This cannot be undone."] = true
L["Use the button below to convert this list from a Shopping list to a Dealfinding list.\n\nNOTE: Doing so will remove all search terms from this list as well as any items that are already in a dealfinding list! This cannot be undone."] = true
L["%s item(s) will be removed (already in a dealfinding list)"] = true
L["Rename List"] = true
L["New List Name"] = true
L["Switch List Type"] = true
L["Switch Type"] = true
L["Delete / Export List"] = true
L["Delete List"] = true
L["Search Results Market Value Price Source"] = true
L["Specifies the market value price source for results in the \"Search\" feature."] = true

-- Destroying.lua

L["Mode:"] = true
L["Even Stacks (Ore/Herbs)"] = true
L["If checked, only 5/10/15/20 stacks of ore and herbs will be shown."] = true
L["Click on this icon to enter milling mode."] = true
L["Click on this icon to enter prospecting mode."] = true
L["Click on this icon to enter disenchanting mode."] = true
L["Click on this icon to enter transformation mode."] = true
L["Primary Filter"] = true
L["Secondary Filter"] = true
L["Select Mode"] = true
L["Select Primary Filter"] = true
L["Auction Item Price"] = true
L["Auction Stack Price"] = true
L["Item"] = true
L["Auctions"] = true
L["Stack Size"] = true
L["Seller"] = true
L["Price Per Target Item"] = true
L["% Market Value"] = true
L["Price Per Crafting Mat"] = true
L["% Expected Cost"] = true
L["Price Per Enchanting Mat"] = true
L["Price Per Gem"] = true
L["Price Per Ink"] = true
L["Scanning page %s of %s for filter %s of %s..."] = true
L["No items found that can be turned into:"] = true
L["Summary of all %s auctions that can be turned into:"] = true

-- ImportExport.lua

L["Import List"] = true
L["List Name"] = true
L["Ignore Existing Items"] = true
L["List Data"] = true
L["The data you are trying to import is invalid."] = true
L["The list you are trying to import is not a dealfinding list. Please use the shopping list import feature instead."] = true
L["The list you are trying to import is not a shopping list. Please use the dealfinding list import feature instead."] = true
L["Imported List"] = true
L["Data Imported to Group: %s"] = true
L["Export List"] = true
L["List Data (just select all and copy the data from inside this box)"] = true

-- Search.lua

L["Invalid Filter"] = true
L["Invalid Min Level"] = true
L["Invalid Item Level"] = true
L["Invalid Item Type"] = true
L["Invalid Item SubType"] = true
L["Invalid Item Rarity"] = true
L["Invalid Usable Only Filter"] = true
L["Invalid Exact Only Filter"] = true
L["Unknown Filter"] = true
L["Skipped the following search term because it's invalid."] = true
L["Skipped the following search term because it's too long. Blizzard does not allow search terms over 63 characters."] = true
L["No valid search terms. Aborting search."] = true
L["Performing a full scan due to no recent scan data being available. This may take several minutes."] = true
L["Nothing below vendor price from last scan."] = true
L["% Vendor Price"] = true
L["Nothing worth disechanting from last scan."] = true
L["Nothing below dealfinding price from last scan."] = true
L["Disenchantable Weapons"] = true
L["Disenchantable Armor"] = true
L["% Disenchant Value"] = true
L["% Market Value"] = true
L["Nothing to search for."] = true
L["% Max Price"] = true
L["% Expected Cost"] = true
L["Showing summary of all %s auctions for list \"%s\""] = true
L["Showing summary of all %s auctions for \"%sDealfinding Search|r\""] = true
L["Showing summary of all %s auctions that match filter \"%s\""] = true
L["Auction not found. Restarting search."] = true

-- SearchGUI.lua

L["Scanning"] = true
L["Hide Saved Searches"] = true
L["Show Saved Searches"] = true
L["Hide Special Searches"] = true
L["Show Special Searches"] = true
L["Below are various special searches that TSM_Shopping can perform. The scans will use data from your most recent scan (or import) if the data is less than an hour old. Data can come from TSM_AuctionDB or TSM_WoWuction. Otherwise, they will do a scan of the entire AH which may take several minutes."] = true
L["Unknown"] = true
L["%s minute(s), %s second(s) ago with %s"] = true
L["Over an hour ago"] = true
L["Last Scan"] = true
L["WARNING: No recent scan data found. Scans may take several minutes."] = true
L["Vendor Search"] = true
L["A vendor search will look for auctions which can be purchased and then sold to a vendor for a profit."] = true
L["Disenchant Search"] = true
L["A disenchant search will look for auctions which can be purchased and disenchanted for a profit."] = true
L["Dealfinding Search"] = true
L["Starts a dealfinding search which searches for all your dealfinding lists at once."] = true
L["%s removed from recent searches."] = true
L["Left-Click: |cffffffffRun this recent search.|r"] = true
L["Right-Click: |cffffffffCreate shopping list from this recent search.|r"] = true
L["Shift-Right-Click: |cffffffffRemove from recent searches.|r"] = true
L["Recent Searches"] = true
L["|cffffbb11No dealfinding or shopping lists found. You can create shopping/dealfinding lists through the TSM_Shopping options.\n\nTIP: You can search for multiple items at a time by separating them with a semicolon. For example: \"volatile life; volatile earth; volatile water\"|r"] = true
L["Left-Click: |cffffffffRun this shopping/dealfinding list.|r"] = true
L["Right-Click: |cffffffffOpen the options for this shopping/dealfinding list|r"] = true
L["Shift-Right-Click: |cffffffffDelete this shopping/dealfinding list. Cannot be undone!|r"] = true
L["Shopping list deleted: \"%s\""] = true
L["Dealfinding list deleted: \"%s\""] = true
L["Shopping/Dealfinding Lists"] = true
L["Enter what you want to search for in this box. You can also use the following options for more complicated searches.\n"] = true
L["|cffffff00Multiple Search Terms:|r You can search for multiple things at once by simply separated them with a ';'. For example '%selementium ore; obsidium ore|r' will search for both elementium and obsidium ore.\n"] = true
L["|cffffff00Inline Filters:|r You can easily add common search filters to your search such as rarity, level, and item type. For example '%sarmor/leather/epic/85/i350/i377|r' will search for all leather armor of epic quality that requires level 85 and has an ilvl between 350 and 377 inclusive. Also, '%sinferno ruby/exact|r' will display only raw inferno rubys (none of the cuts).\n"] = true
L["Show/Hide the saved searches frame. This frame shows all your recent searches as well as your shopping and dealfinding lists."] = true
L["Show/Hide the special searches frame. This frame shows all the special searches such as vendor, disenchanting, resale, and more."] = true
L["Price Per Item"] = true
L["Price Per Stack"] = true
L["Item Level"] = true
L["Auctions"] = true
L["Stack Size"] = true
L["Time Left"] = true
L["Seller"] = true
L["% Market Value"] = true
L["Scanning page %s of %s for filter %s of %s: %s"] = true
L["Total value of your auctions: %s\nIncoming gold: %s"] = true