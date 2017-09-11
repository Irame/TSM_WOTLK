-- ------------------------------------------------------------------------------------- --
--   TradeSkillMaster_Mailing - AddOn by Sapu94                                          --
--   http://www.curse.com/addons/wow/TradeSkillMaster_Mailing                            --
--                                                                                       --
--   This addon is licensed under the CC BY-NC-ND 3.0 license as described at the        --
--   following url: http://creativecommons.org/licenses/by-nc-nd/3.0/                    --
--   Please contact the author via email at sapu94@gmail.com with any questions or       --
--   concerns regarding this license.                                                    --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Mailing Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkill-Master/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Mailing", "enUS", true)
if not L then return end

-- TradeSkillMaster_Mailing.lua

L["Mailing Options"] = true
L["Open All"] = true
L["How many seconds until the mailbox will retrieve new data and you can continue looting mail."] = true
L["Waiting..."] = true
L["Opening..."] = true
L["Cannot finish auto looting, inventory is full or too many unique items."] = true
L["%s Collected"] = true
L["%d mail"] = true

-- AutoMail.lua

L["TradeSkillMaster_Mailing: Auto-Mail"] = true
L["Runs TradeSkillMaster_Mailing's auto mailer, the last patch of mails will take ~10 seconds to send.\n\n[WARNING!] You will not get any confirmation before it starts to send mails, it is your own fault if you mistype your bankers name."] = true
L["TradeSkillMaster_Mailing - Sending...\n\n(the last mail may take several moments)"] = true
L["Please wait until you are done opening mail before sending mail."] = true
L["Nothing to mail!"] = true
L["Mailed items off to %s!"] = true
L["Restarting AutoMail in %s minutes."] = true

-- Config.lua

L["Options"] = true
L["No player name entered."] = true
L["Player \"%s\" is already a mail target."] = true
L["Auto Recheck Mail"] = true
L["Automatically rechecks mail every 60 seconds when you have too much mail.\n\nIf you loot all mail with this enabled, it will wait and recheck then keep auto looting."] = true
L["Don't Display Money Received"] = true
L["Checking this will stop TradesSkillMaster_Mailing from displaying money collected from your mailbox after auto looting"] = true
L["Send Items Individually"] = true
L["Sends each unique item in a seperate mail."] = true
L["AutoMail Send Delay"] = true
L["This slider controls how long the AutoMailing code waits in between mails. If this is set too low, you will run into internal mailbox errors."] = true
L["Automatically Restart AutoMail"] = true
L["If checked, after the initial mailing, the auto-mail feature will automatically restart after a certain period of time. This is useful if you're crafting a lot of items and want auto-mail to automatically mail items off while you craft."] = true
L["AutoMail Restart Delay (minutes)"] = true
L["After the initial mailing, the auto-mail feature will automatically restart after however many minutes this slider is set to."] = true
L["Add Mail Target"] = true
L["Auto mailing will let you setup groups and specific items that should be mailed to another characters."] = true
L["Check your spelling! If you typo a name, it will send to the wrong person."] = true
L["Player Name"] = true
L["The name of the player to send items to.\n\nCheck your spelling!"] = true
L["Change Mail Target"] = true
L["Below you can change an existing mail target to a new one without losing the items."] = true
L["Old Player Name"] = true
L["New Player Name"] = true
L["Remove Mail Target"] = true
L["Are you sure you want to remove %s as a mail target?"] = true
L["Items/Groups to Add:"] = true
L["Items/Groups to remove:"] = true