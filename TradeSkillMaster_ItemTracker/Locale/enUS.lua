-- ------------------------------------------------------------------------------------- --
--   TradeSkillMaster_ItemTracker - AddOn by Sapu94undefined                                       --
--   http://www.curse.com/addons/wow/undefined                         --
--                                                                                       --
--   This addon is licensed under the CC BY-NC-ND 3.0 license as described at the        --
--   following url: http://creativecommons.org/licenses/by-nc-nd/3.0/                    --
--   Please contact the author via email at sapu94@gmail.com with any questions or       --
--   concerns regarding this license.                                                    --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_ItemTracker Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkill-Master/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_ItemTracker", "enUS", true)
if not L then return end

-- TradeSkillMaster_ItemTracker.lua

L["trackerMessage"] = true
L["If you previously used TSM_Gathering, note that inventory data was not transfered to TSM_ItemTracker and will not show up until you log onto each character and visit the bank / gbank / auction house."] = true
L["ItemTracker: %s on player, %s on alts, %s in guild banks, %s on AH"] = true
L["%s: %s (%s in bags, %s in bank, %s on AH)"] = true
L["%s: %s in guild bank"] = true

-- config.lua

L["Inventory Viewer"] = true
L["Options"] = true
L["Item Name"] = true
L["Bags"] = true
L["Bank"] = true
L["Guild Bank"] = true
L["AH"] = true
L["Total"] = true
L["Item Search"] = true
L["Characters"] = true
L["Guilds"] = true
L["No Tooltip Info"] = true
L["Simple"] = true
L["Full"] = true
L["Here, you can choose what ItemTracker info, if any, to show in tooltips. \"Simple\" will show only show totals for bags/banks and for guild banks. \"Full\" will show detailed information for every character and guild."] = true
L["Delete Character:"] = true
L["\"%s\" removed from ItemTracker."] = true
L["If you rename / transfer / delete one of your characters, use this dropdown to remove that character from ItemTracker. There is no confirmation. If you accidentally delete a character that still exists, simply log onto that character to re-add it to ItemTracker."] = true
L["Multiple Account Sync"] = true
L["Enter the name of the characters on your other account which you'd like to sync ItemTracker with below. You must also enter the name of this character in their ItemTracker settings in order to be able to sync. Also, these characters must be on your friends list (ItemTracker will add them if they aren't). All character and guild data will be synced, but only via the characters listed.\n\nEvery time it's loaded, ItemTracker will automatically attempt to sync data with the characters listed below. You can also force a manual sync via the button below."] = true
L["Characters on other account to sync with (comma separated)"] = true
L["List the characters which are not on this account (but on the same realm and faction) that you want ItemTracker to sync with. Separate character names with a single comma."] = true
L["Manually Sync ItemTracker Data"] = true

-- comm.lua
L["Could not sync with %s since they are not on your friends list and you friends list is full."] = true
L["Sending data to %s complete!"] = true
L["Compressing and sending ItemTracker data to %s. This will take approximately %s seconds. Please wait..."] = true
L["Ignored ItemTracker data from %s since you haven't added him to the list of characters in this character's ItemTracker options. You'll only see this message once per session per sender."] = true
L["Successfully got %s bytes of ItemTracker data from %s! Updated %s characters and %s guilds."] = true
L["Got invalid ItemTracker data from %s."] = true