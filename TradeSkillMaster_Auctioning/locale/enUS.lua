-- ------------------------------------------------------------------------------------- --
--   TradeSkillMaster_Auctioning - AddOn by Sapu94                                       --
--   http://www.curse.com/addons/wow/TradeSkillMaster_Auctioning                         --
--                                                                                       --
--   This addon is licensed under the CC BY-NC-ND 3.0 license as described at the        --
--   following url: http://creativecommons.org/licenses/by-nc-nd/3.0/                    --
--   Please contact the author via email at sapu94@gmail.com with any questions or       --
--   concerns regarding this license.                                                    --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Auctioning Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkill-Master/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Auctioning", "enUS", true)
if not L then return end

-- TradeSkillMaster_Auctioning.lua

L["Auctioning Groups/Options"] = true
L["Group named \"%s\" already exists! Item not added."] = true
L["Group named \"%s\" does not exist! Item not added."] = true
L["Item failed to add to group."] = true
L["Fixed invalid groups."] = true
L["If you are using a % of something for threshold / fallback, every item in a group must evalute to the exact same amount. For example, if you are using % of crafting cost, every item in the group must have the same mats. If you are using % of auctiondb value, no items will ever have the same market price or min buyout. So, these items must be split into separate groups."] = true
L["Click on the \"Fix\" button to have Auctioning turn this group into a category and create appropriate groups inside the category to fix this issue. This is recommended unless you'd like to fix the group yourself. You will only be prompted with this popup once per session."] = true
L["Auctioning has found %s group(s) with an invalid threshold/fallback. Check your chat log for more info. Would you like Auctioning to fix these groups for you?"] = true
L["Fix (Recommended)"] = true
L["Ignore"] = true
L["Auctioning Group:"] = true
L["Threshold/Fallback:"] = true
L["Add Item to TSM_Auctioning"] = true
L["TSM_Auctioning Group to Add Item to:"] = true
L["Which group in TSM_Auctioning to add this item to."] = true
L["Add Item to Selected Group"] = true
L["Name of New Group to Add Item to:"] = true
L["Add Item to New Group"] = true
L["This item is already in the \"%s\" Auctioning group."] = true


-- CancelScan.lua

L["Seller name of lowest auction for item %s was not returned from server. Skipping this item."] = true
L["Invalid scan data for item %s. Skipping this item."] = true

-- Config.lua

L["<Uncategorized Groups>"] = true
L["Would you like to load these options in beginner or advanced mode? If you have not used APM, QA3, or ZA before, beginner is recommended. Your selection can always be changed using the \"Hide advanced options\" checkbox in the \"Options\" page."] = true
L["Beginner"] = true
L["Advanced"] = true
L["Options"] = true
L["Categories / Groups"] = true
L["General"] = true
L["Whitelist"] = true
L["Blacklist"] = true
L["Profiles"] = true
L["Auction Defaults"] = true
L["Create Category / Group"] = true
L["Quick Group Creation"] = true
L["Group Overrides"] = true
L["Add/Remove Items"] = true
L["<none>"] = true
L["Management"] = true
L["Category Overrides"] = true
L["Add/Remove Groups"] = true
L["Hide help text"] = true
L["Hides auction setting help text throughout the options."] = true
L["Hide advanced options"] = true
L["Hides advanced auction settings. Provides for an easier learning curve for new users."] = true
L["Hide poor quality items"] = true
L["Hides all poor (gray) quality items from the 'Add items' pages."] = true
L["Enable sounds"] = true
L["Plays the ready check sound when a post / cancel scan is complete and items are ready to be posting / canceled (the gray bar is all the way across)."] = true
L["Show group name in tooltip"] = true
L["Shows the name of the group an item belongs to in that item's tooltip."] = true
L["Smart group creation"] = true
L["If enabled, when you create a new group, your bags will be scanned for items with names that include the name of the new group. If such items are found, they will be automatically added to the new group."] = true
L["Match whitelist prices"] = true
L["If enabled, when the lowest auction is by somebody on your whitelist, it will post your auction at the same price. If disabled, it won't post the item at all."] = true
L["First Tab in Group / Category Settings"] = true
L["Add/Remove"] = true
L["Overrides"] = true
L["Determines which order the group / category settings tabs will appear in."] = true
L["Max Scan Retries (Advanced)"] = true
L["This controls how many times Auctioning will retry a query before giving up and moving on. Each retry takes about 2-3 seconds."] = true
L["Canceling"] = true
L["Cancel auctions with bids"] = true
L["Will cancel auctions even if they have a bid on them, you will take an additional gold cost if you cancel an auction with bid."] = true
L["Cancel to repost higher"] = true
L["If checked, will cancel auctions that can be reposted for a higher amount (ie you haven't been undercut and the auction you originally undercut has expired)."] = true
L["Smart canceling"] = true
L["Disables canceling of auctions which can not be reposted (ie the market price is below your threshold)."] = true
L["Macro Help"] = true
L["There are two ways of making clicking the Post / Cancel Auction button easier. You can put %s and %s in a macro (on separate lines), or use the utility below to have a macro automatically made and bound to scrollwheel for you."] = true
L["ScrollWheel Direction (both recommended):"] = true
L["Up"] = true
L["Will bind ScrollWheelUp (plus modifiers below) to the macro created."] = true
L["Down"] = true
L["Will bind ScrollWheelDown (plus modifiers below) to the macro created."] = true
L["Modifiers:"] = true
L["ALT"] = true
L["CTRL"] = true
L["SHIFT"] = true
L["Create Macro and Bind ScrollWheel (with selected options)"] = true
L["Macro created and keybinding set!"] = true
L["Block Auctioneer while scanning"] = true
L["Right click to override this setting."] = true
L["Right click to remove the override of this setting."] = true
L["Fixed Gold Amount"] = true
L["%% of %s"] = true
L["Items in this group will not be posted or canceled automatically."] = true
L["When posting, ignore auctions with more than %s items or less than %s items in them. Items in this group will not be canceled automatically."] = true
L["When posting and canceling, ignore auctions with more than %s item(s) or less than %s item(s) in them."] = true
L["Auctions will be posted for %s hours in stacks of up to %s. A maximum of %s auctions will be posted."] = true
L["Auctions will be posted for %s hours in stacks of %s. A maximum of %s auctions will be posted."] = true
L["Auctioning will undercut your competition by %s. When posting, the bid of your auctions will be set to %s percent of the buyout."] = true
L["Auctioning will never post your auctions for below %s."] = true
L["Auctioning will follow the 'Advanced Price Settings' when the market goes below %s."] = true
L["Auctioning will post at %s when you are the only one posting below %s."] = true
L["Auctions will not be posted when the market goes below your threshold."] = true
L["Auctions will be posted at your threshold price of %s when the market goes below your threshold."] = true
L["Auctions will be posted at your fallback price of %s when the market goes below your threshold."] = true
L["Auctions will be posted at %s when the market goes below your threshold."] = true
L["Auctioning will reset items where you can make a profit of at least %s per item by buying at most %s items for a maximum of %s, paying no more than %s for any single item."] = true
L["This item will not be included in the reset scan."] = true
L["Invalid money format entered, should be \"#g#s#c\", \"25g4s50c\" is 25 gold, 4 silver, 50 copper."] = true
L["Invalid percent format entered, should be \"#%\", \"105%\" is 105 percent."] = true
L["%s removed from '%s' as a result of converting the current group to itemIDs."] = true
L["Help"] = true
L["The below are fallback settings for groups, if you do not override a setting in a group then it will use the settings below.\n\nWarning! All auction prices are per item, not overall. If you set it to post at a fallback of 1g and you post in stacks of 20 that means the fallback will be 20g."] = true
L["General Settings"] = true
L["Ignore stacks under"] = true
L["Items that are stacked beyond the set amount are ignored when calculating the lowest market price."] = true
L["Ignore stacks over"] = true
L["Ignore low duration auctions"] = true
L["short (less than 30 minutes)"] = true
L["medium (less than 2 hours)"] = true
L["long (less than 12 hours)"] = true
L["Any auctions at or below the selected duration will be ignored. Selecting \"<none>\" will cause no auctions to be ignored based on duration."] = true
L["Disable auto cancelling"] = true
L["Disable automatically cancelling of items in this group if undercut."] = true
L["Disable posting and canceling"] = true
L["Completely disables this group. This group will not be scanned for and will be effectively invisible to Auctioning."] = true
L["Common Search Term"] = true
L["If all items in this group have the same phrase in their name, use this phrase instead to speed up searches. For example, if this group contains only glyphs, you could put \"glyph of\" and Auctioning will search for that instead of each glyph name individually. Leave empty for default behavior."] = true
L["Add Items by ItemID"] = true
L["If checked, items in this group will be added as itemIDs rather than itemStrings. This is useful if you'd like to ignore random enchants on items.\n\nNote: Any common search term will be ignored for groups with this box checked."] = true
L["Post Settings (Quantity / Duration)"] = true
L["Post time"] = true
L["12 hours"] = true
L["24 hours"] = true
L["48 hours"] = true
L["How long auctions should be up for."] = true
L["Post cap"] = true
L["How many auctions at the lowest price tier can be up at any one time."] = true
L["Per auction"] = true
L["How many items should be in a single auction, 20 will mean they are posted in stacks of 20."] = true
L["Use per auction as cap"] = true
L["If you don't have enough items for a full post, it will post with what you have."] = true
L["General Price Settings (Undercut / Bid)"] = true
L["Undercut by"] = true
L["How much to undercut other auctions by, format is in \"#g#s#c\" but can be in any order, \"50g30s\" means 50 gold, 30 silver and so on."] = true
L["Bid percent"] = true
L["Percentage of the buyout as bid, if you set this to 90% then a 100g buyout will have a 90g bid."] = true
L["Minimum Price Settings (Threshold)"] = true
L["Price threshold"] = true
L["How low the market can go before an item should no longer be posted. The minimum price you want to post an item for."] = true
L["Set threshold as a"] = true
L["You can set a fixed threshold, or have it be a percentage of some other value."] = true
L["Maximum Price Settings (Fallback)"] = true
L["Fallback price"] = true
L["Price to fallback too if there are no other auctions up, the lowest market price is too high."] = true
L["Set fallback as a"] = true
L["You can set a fixed fallback price for this group, or have the fallback price be automatically calculated to a percentage of a value. If you have multiple different items in this group and use a percentage, the highest value will be used for the entire group."] = true
L["Maximum price"] = true
L["If the market price is above fallback price * maximum price, items will be posted at the fallback * maximum price instead.\n\nEffective for posting prices in a sane price range when someone is posting an item at 5000g when it only goes for 100g."] = true
L["Advanced Price Settings (Reset Method)"] = true
L["Reset Method"] = true
L["Don't Post Items"] = true
L["Post at Threshold"] = true
L["Post at Fallback"] = true
L["Custom Value"] = true
L["This dropdown determines what Auctioning will do when the market for an item goes below your threshold value. You can either not post the items or post at your fallback/threshold/a custom value."] = true
L["Custom Reset Price (gold)"] = true
L["Custom market reset price. If the market goes below your threshold, items will be posted at this price."] = true
L["Custom percentage change of market price. If the market price changes by this percentage, your items will be reposted at the fallback value."] = true
L["Custom percentage change of market price. If the market price changes by this percentage, your items will be reposted at the threshold value."] = true
L["Custom percentage change of market price. If the market price changes by this percentage, your items will be reposted at the %s value."] = true
L["Price resolution for %s"] = true
L["Price resolution for fallback"] = true
L["Price resolution for threshold"] = true
L["Reset Scan Settings"] = true
L["Include in reset scan"] = true
L["If checked, the items in this group will be included when running a reset scan and the reset scan options will be shown."] = true
L["Max reset cost"] = true
L["The maximum amount that you want to spend in order to reset a particular item. This is the total amount, not a per-item amount."] = true
L["Set max reset cost as a"] = true
L["You can set a fixed max reset cost, or have it be a percentage of some other value."] = true
L["Min reset profit"] = true
L["The minimum profit you would want to make from doing a reset. This is a per-item price where profit is the price you reset to minus the average price you spent per item."] = true
L["Set min reset price as a"] = true
L["You can set a fixed min reset price, or have it be a percentage of some other value."] = true
L["Max quantity to buy"] = true
L["This is the maximum number of items you're willing to buy in order to perform a reset."] = true
L["Price resolution"] = true
L["This determines what size range of prices should be considered a single price point for the reset scan. For example, if this is set to 1s, an auction at 20g50s20c and an auction at 20g49s45c will both be considered to be the same price level."] = true
L["Max price per item"] = true
L["This is the maximum amount you want to pay for a single item when reseting."] = true
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
L["Group/Category named \"%s\" already exists!"] = true
L["Invalid group name."] = true
L["Added %s items to %s automatically because they contained the group name in their name. You can turn this off in the options."] = true
L["Added the following items to %s automatically because they contained the group name in their name. You can turn this off in the options."] = true
L["Invalid category name."] = true
L["Add group"] = true
L["A group contains items that you wish to sell with similar conditions (stack size, fallback price, etc).  Default settings may be overridden by a group's individual settings."] = true
L["Group name"] = true
L["Name of the new group, this can be whatever you want and has no relation to how the group itself functions."] = true
L["Import Auctioning Group"] = true
L["This feature can be used to import groups from outside of the game. For example, if somebody exported their group onto a blog, you could use this feature to import that group and Auctioning would create a group with the same settings / items."] = true
L["Make another after this one."] = true
L["Add category"] = true
L["A category contains groups with similar settings and acts like an organizational folder. You may override default settings by category (and then override category settings by group)."] = true
L["Category name"] = true
L["Name of the new category, this can be whatever you want and has no relation to how the category itself functions."] = true
L["Items to be added:"] = true
L["No name entered."] = true
L["The player \"%s\" is already on your whitelist."] = true
L["You can not whitelist characters whom are on your blacklist."] = true
L["You do not need to add \"%s\", alts are whitelisted automatically."] = true
L["Whitelists allow you to set other players besides you and your alts that you do not want to undercut; however, if somebody on your whitelist matches your buyout but lists a lower bid it will still consider them undercutting."] = true
L["Add player"] = true
L["Player name"] = true
L["Add a new player to your whitelist."] = true
L["Delete"] = true
L["You do not have any players on your whitelist yet."] = true
L["The player \"%s\" is already on your blacklist."] = true
L["You can not blacklist characters whom are on your whitelist."] = true
L["You can not blacklist yourself."] = true
L["Blacklists allows you to undercut a competitor no matter how low their threshold may be. If the lowest auction of an item is owned by somebody on your blacklist, your threshold will be ignored for that item and you will undercut them regardless of whether they are above or below your threshold."] = true
L["Add a new player to your blacklist."] = true
L["You do not have any players on your blacklist yet."] = true
L["Are you SURE you want to delete this group?"] = true
L["Failed to create shopping list."] = true
L["Created new shopping list: "] = true
L["Create Shopping List from Group"] = true
L["Creates a shopping list that contains all the items which are in this group. There is no confirmation or popup window for this."] = true
L["Rename"] = true
L["New group name"] = true
L["Rename this group to something else!"] = true
L["Delete group"] = true
L["Delete this group, this cannot be undone!"] = true
L["Export"] = true
L["Export Group Data"] = true
L["Exports the data for this group. This allows you to share your group data with other TradeSkillMaster_Auctioning users."] = true
L["Items not in any group:"] = true
L["Items in this group:"] = true
L["Select Matches:"] = true
L["Selects all items in either list matching the entered filter. Entering \"Glyph of\" will select any item with \"Glyph of\" in the name."] = true
L["Are you SURE you want to delete this category?"] = true
L["Are you SURE you want to delete all the groups in this category?"] = true
L["New category name"] = true
L["Rename this category to something else!"] = true
L["Delete category"] = true
L["Delete this category, this cannot be undone!"] = true
L["Delete All Groups In Category"] = true
L["Delete all groups inside this category. This cannot be undone!"] = true
L["Create Shopping List from Category"] = true
L["Creates a shopping list that contains all the items which are in this category. There is no confirmation or popup window for this."] = true
L["Uncategorized Groups:"] = true
L["Groups in this Category:"] = true

-- GUI.lua

L["Post Auctions"] = true
L["Posts items on the auction house according to the rules setup in Auctioning."] = true
L["Right click to do a custom post scan."] = true
L["Cancel Auctions"] = true
L["Cancels auctions you've been undercut on according to the rules setup in Auctioning."] = true
L["Right click to do a custom cancel scan."] = true
L["Reset Auctions"] = true
L["Resets the price of items according to the rules setup in Auctioning by buying other's auctions and canceling your own as necessary."] = true
L["Right click to do a custom reset scan."] = true
L["Enable All"] = true
L["Disable All"] = true
L["Use the checkboxes to the left to select which groups you'd like to include in this scan."] = true
L["Start Scan of Selected Groups"] = true
L["Cancel ALL Current Auctions"] = true
L["Cancel Filter"] = true
L["Enter a filter into this box and click the button below it to cancel all of your auctions that contain that filter (without scanning)."] = true
L["Cancel Auctions Matching Filter"] = true
L["Duration"] = true
L["Short (30 minutes)"] = true
L["Medium (2 hours)"] = true
L["Long (12 hours)"] = true
L["All auctions of this duration and below will be canceled when you press the \"Cancel Low Duration Auctions\" button"] = true
L["Cancel Low Duration Auctions"] = true
L["Check this box to include this group in the scan."] = true
L["Toggle this box to enable / disable all groups in this category."] = true
L["You don't any groups set to be included in a reset scan."] = true
L["You don't any groups set up."] = true
L["Post"] = true
L["Cancel"] = true
L["Skip Item"] = true
L["Stop Scan"] = true
L["Show All Auctions"] = true
L["Show Item Auctions"] = true
L["Show Log"] = true
L["Edit Post Price"] = true
L["Auction Buyout (Stack Price):"] = true
L["Save New Price"] = true
L["Currently Owned:"] = true
L["%s item(s) to buy/cancel"] = true
L["Target Price:"] = true
L["Profit:"] = true
L["Bid:"] = true
L["Buyout:"] = true
L["Price Per Item"] = true
L["Price Per Stack"] = true
L["Auctions"] = true
L["Stack Size"] = true
L["Time Left"] = true
L["Seller"] = true
L["% Market Value"] = true
L["Group:"] = true
L["Threshold:"] = true
L["Fallback:"] = true
L["Lowest Buyout:"] = true
L["Log Info:"] = true
L["Click to show auctions for this item."] = true
L["Right-Click to add %s to your friends list."] = true
L["Shift-Right-Click to show the options for this item's Auctioning group."] = true
L["Auctioning Groups/Options"] = true
L["Could not find item's group."] = true
L["This item does not have any seller data."] = true
L["Item"] = true
L["Lowest Buyout"] = true
L["Info"] = true
L["Done Posting\n\nTotal value of your auctions: %s\nIncoming Gold: %s"] = true
L["Post Scan Finished"] = true
L["Done Canceling"] = true
L["Cancel Scan Finished"] = true
L["No Items to Reset"] = true
L["Reset Scan Finished"] = true

-- ImportExport.lua

L["Import Group Data"] = true
L["Group name"] = true
L["Don't Import Already Grouped Items"] = true
L["Group Data"] = true
L["Import Auctioning Group"] = true
L["The data you are trying to import is invalid."] = true
L["Data Imported to Group: %s"] = true
L["Export Group Data"] = true

-- Log.lua

L["Item/Group is invalid."] = true
L["Not enough items in bags."] = true
L["Cheapest auction below threshold."] = true
L["Maximum amount already posted."] = true
L["Posting this item."] = true
L["Posting at fallback."] = true
L["Posting at reset price."] = true
L["Posting at your current price."] = true
L["Posting at whitelisted player's price."] = true
L["Lowest auction by whitelisted player."] = true
L["Undercutting competition."] = true
L["Invalid seller data returned by server."] = true
L["Auction has been bid on."] = true
L["Not canceling auction at reset price."] = true
L["Canceling to repost at reset price."] = true
L["Not canceling auction below threshold."] = true
L["You've been undercut."] = true
L["Undercut by whitelisted player."] = true
L["At fallback price and not undercut."] = true
L["Canceling to repost at higher price."] = true
L["Your auction has not been undercut."] = true
L["Canceling all auctions."] = true
L["Canceling auction which you've undercut."] = true

-- Manage.lua

L["Invalid search term for group %s. Searching for items individually instead."] = true
L["Could not resolve search filters for item %s"] = true
L["Scanning"] = true
L["All Items Scanned"] = true
L["Posting %s / %s"] = true
L["Canceling %s / %s"] = true
L["Scanning Item %s / %s"] = true
L["Running Scan..."] = true
L["Processing Items..."] = true

-- PostScan.lua

L["Did not post %s because your threshold (%s) is invalid. Check your settings."] = true
L["Did not post %s because your fallback (%s) is invalid. Check your settings."] = true
L["Did not post %s because your fallback (%s) is lower than your threshold (%s). Check your settings."] = true
L["Post"] = true
L["Skip"] = true
L["Seller name of lowest auction for item %s was not returned from server. Skipping this item."] = true
L["Please don't move items around in your bags while a post scan is running! The item was skipped to avoid an incorrect item being posted."] = true

-- ResetScan.lua

L["Must wait for scan to finish before starting to reset."] = true
L["Click to reset this item to this target price."] = true
L["Item"] = true
L["Quantity (Yours)"] = true
L["Total Cost"] = true
L["Target Price"] = true
L["Profit Per Item"] = true
L["Seller"] = true
L["Stack Size"] = true
L["Auction Buyout"] = true
L["Buyout"] = true
L["Cancel"] = true
L["Stop Scan"] = true
L["Return to Summary"] = true
L["(whitelisted)"] = true
L["(blacklisted)"] = true
L["Done Scanning!\n\nCould potentially reset %d items for %s profit."] = true
L["Auction not found. Skipped."] = true
L["Max Cost:"] = true
L["Min Profit:"] = true
L["Max Quantity:"] = true
L["Max Price Per:"] = true
L["\nClick to reset this item to this target price."] = true
L["\nClick to show auctions for this item."] = true


-- ScanUtil.lua

L["Error with scan. Scanned item multiple times unexpectedly. You can try restarting the scan. Item:"] = true