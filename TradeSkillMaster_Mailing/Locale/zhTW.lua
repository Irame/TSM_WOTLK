-- TradeSkillMaster_Mailing Locale - zhTW
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/tradeskillmaster_mailing/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Mailing", "zhTW")
if not L then return end

L["Add Mail Target"] = "添加送信人"
-- L["After the initial mailing, the auto-mail feature will automatically restart after however many minutes this slider is set to."] = ""
-- L["Are you sure you want to remove %s as a mail target?"] = ""
L["Auto mailing will let you setup groups and specific items that should be mailed to another characters."] = "自動郵寄會將你設定的群組和具體物品郵寄到另一個角色."
-- L["AutoMail Restart Delay (minutes)"] = ""
-- L["AutoMail Send Delay"] = ""
L[ [=[Automatically rechecks mail every 60 seconds when you have too much mail.

If you loot all mail with this enabled, it will wait and recheck then keep auto looting.]=] ] = [=[當你有過多郵件時,將每60秒複查郵件.

當開啟此項時若你正在拾取全部郵件,程式將等待並複查郵件但保持自動拾取。]=]
-- L["Automatically Restart AutoMail"] = ""
L["Auto Recheck Mail"] = "自動複查郵件"
-- L["Below you can change an existing mail target to a new one without losing the items."] = ""
L["Cannot finish auto looting, inventory is full or too many unique items."] = "無法完成自動拾取郵件,行囊已滿或者擁有過多唯一物品."
-- L["Change Mail Target"] = ""
L["Checking this will stop TradesSkillMaster_Mailing from displaying money collected from your mailbox after auto looting"] = "不顯示在自動打開郵件後從郵件中獲取金錢的提示."
L["Check your spelling! If you typo a name, it will send to the wrong person."] = "請檢查你的輸入!如果你輸入一個錯誤的名稱,郵件將發給一個錯誤的送信人."
L["%d mail"] = "%d 郵件"
L["Don't Display Money Received"] = "不顯示收到的金錢."
L["How many seconds until the mailbox will retrieve new data and you can continue looting mail."] = "直到信箱檢索新的資料數秒後，你可以繼續拾取郵件."
-- L["If checked, after the initial mailing, the auto-mail feature will automatically restart after a certain period of time. This is useful if you're crafting a lot of items and want auto-mail to automatically mail items off while you craft."] = ""
L["Items/Groups to Add:"] = "添加物品/群組:"
L["Items/Groups to remove:"] = "移除物品/群組:"
L["Mailed items off to %s!"] = "物品發送到 %s!"
L["Mailing Options"] = "送信選項"
-- L["New Player Name"] = ""
L["No player name entered."] = "沒有送信人的名稱"
-- L["Nothing to mail!"] = ""
-- L["Old Player Name"] = ""
L["Open All"] = "打開全部"
L["Opening..."] = "正在打開"
L["Options"] = "選項"
L["Player Name"] = "玩家名稱"
L["Player \"%s\" is already a mail target."] = "玩家 \"%s\" 已是送信目標."
-- L["Please wait until you are done opening mail before sending mail."] = ""
L["Remove Mail Target"] = "移除送信目標"
-- L["Restarting AutoMail in %s minutes."] = ""
L[ [=[Runs TradeSkillMaster_Mailing's auto mailer, the last patch of mails will take ~10 seconds to send.

[WARNING!] You will not get any confirmation before it starts to send mails, it is your own fault if you mistype your bankers name.]=] ] = [=[使用TradeSkillMaster_Mailing自動送信功能, 只需10秒,郵件輕鬆發送.

[警告!] 在開始送信前你不會得到任何確認資訊.如果您錯誤輸入送信人名稱,一切後果自負.]=]
-- L["%s Collected"] = ""
-- L["Send Items Individually"] = ""
-- L["Sends each unique item in a seperate mail."] = ""
L[ [=[The name of the player to send items to.

Check your spelling!]=] ] = [=[發送物品的送信人名稱.

請確認送信人名稱輸入無誤!]=]
-- L["This slider controls how long the AutoMailing code waits in between mails. If this is set too low, you will run into internal mailbox errors."] = ""
L["TradeSkillMaster_Mailing: Auto-Mail"] = "TradeSkillMaster_Mailing: 自動收遞"
--[==[ L[ [=[TradeSkillMaster_Mailing - Sending...

(the last mail may take several moments)]=] ] = "" ]==]
L["Waiting..."] = "請稍候..."
