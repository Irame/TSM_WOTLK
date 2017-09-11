-- TradeSkillMaster_Mailing Locale - zhCN
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/tradeskillmaster_mailing/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Mailing", "zhCH")
if not L then return end

L["Add Mail Target"] = "添加收件人"
L["After the initial mailing, the auto-mail feature will automatically restart after however many minutes this slider is set to."] = "初次邮寄后，自动邮寄功能将在滑动条设置的分钟数后自动重启。" -- Needs review
L["Are you sure you want to remove %s as a mail target?"] = "你确定想要移除邮件收件人 %s ?" -- Needs review
L["Auto mailing will let you setup groups and specific items that should be mailed to another characters."] = "自动邮寄会将你设定的分组和特定物品邮寄给另一个角色。" -- Needs review
L["AutoMail Restart Delay (minutes)"] = "自动邮件重启延迟 (分钟)" -- Needs review
L["AutoMail Send Delay"] = "自动邮件发送延迟" -- Needs review
L[ [=[Automatically rechecks mail every 60 seconds when you have too much mail.

If you loot all mail with this enabled, it will wait and recheck then keep auto looting.]=] ] = [=[当你有过多邮件时，每60秒自动重新检查邮件。

若你启用此功能时打开所有邮件，插件将等待并重新检查以保持自动拾取。]=] -- Needs review
L["Automatically Restart AutoMail"] = "自动重启自动邮件" -- Needs review
L["Auto Recheck Mail"] = "自动重新检查邮件" -- Needs review
L["Below you can change an existing mail target to a new one without losing the items."] = "在下面你可以更改一个已有邮件收件人为别人而不会丢失物品设置。" -- Needs review
L["Cannot finish auto looting, inventory is full or too many unique items."] = "自动打开邮件无法完成，背包已满或者拥有过多唯一物品。" -- Needs review
L["Change Mail Target"] = "更改邮件收件人" -- Needs review
L["Checking this will stop TradesSkillMaster_Mailing from displaying money collected from your mailbox after auto looting"] = "选中此项将不再显示自动打开邮件后从邮件中所获得金钱的提示。" -- Needs review
L["Check your spelling! If you typo a name, it will send to the wrong person."] = "检查你的输入！如果你写错名字，邮件将会发给错误的收件人。" -- Needs review
L["%d mail"] = "%d 邮件"
L["Don't Display Money Received"] = "不显示收到的金钱。" -- Needs review
L["How many seconds until the mailbox will retrieve new data and you can continue looting mail."] = "多少秒后可以重新检索邮箱数据，以使得可以继续拾取邮件。" -- Needs review
L["If checked, after the initial mailing, the auto-mail feature will automatically restart after a certain period of time. This is useful if you're crafting a lot of items and want auto-mail to automatically mail items off while you craft."] = "如选中，初次邮寄后，自动邮寄功能会在指定时间后自动重启。此功能在你制作大量物品并想要使用自动邮寄功能将物品自动寄送出去时会相当有用。" -- Needs review
L["Items/Groups to Add:"] = "要添加的物品/分组:" -- Needs review
L["Items/Groups to remove:"] = "要移除的物品/分组:" -- Needs review
L["Mailed items off to %s!"] = "物品邮寄到 %s！" -- Needs review
L["Mailing Options"] = "邮寄选项"
L["New Player Name"] = "新的玩家名字" -- Needs review
L["No player name entered."] = "未输入玩家名。" -- Needs review
L["Nothing to mail!"] = "无邮寄物品！" -- Needs review
L["Old Player Name"] = "老的玩家名字" -- Needs review
L["Open All"] = "打开所有"
L["Opening..."] = "打开中..."
L["Options"] = "选项"
L["Player Name"] = "玩家名"
L["Player \"%s\" is already a mail target."] = "玩家\"%s\"已是收件人。" -- Needs review
L["Please wait until you are done opening mail before sending mail."] = "请稍等，完成打开邮件后再发送邮件。" -- Needs review
L["Remove Mail Target"] = "移除收件人"
L["Restarting AutoMail in %s minutes."] = "%s 分钟后重启自动邮件功能。" -- Needs review
L[ [=[Runs TradeSkillMaster_Mailing's auto mailer, the last patch of mails will take ~10 seconds to send.

[WARNING!] You will not get any confirmation before it starts to send mails, it is your own fault if you mistype your bankers name.]=] ] = [=[使用TradeSkillMaster_Mailing自动邮寄功能，只要10秒，邮件轻松发送。

[警告!] 在开始发送邮件前你不会得到任何确认信息，如果您输错收件人，后果自负。]=] -- Needs review
L["%s Collected"] = "%s 已收集" -- Needs review
L["Send Items Individually"] = "单独邮件发送每种物品" -- Needs review
L["Sends each unique item in a seperate mail."] = "使用单独的邮件发送每个唯一物品" -- Needs review
L[ [=[The name of the player to send items to.

Check your spelling!]=] ] = [=[发送物品的收件人名字。

请确认收件人输入无误！]=] -- Needs review
L["This slider controls how long the AutoMailing code waits in between mails. If this is set too low, you will run into internal mailbox errors."] = "此滑动条控制两封邮件之间的自动邮寄编码间隔时间。若设置数值太低，会出现内部邮箱错误。" -- Needs review
L["TradeSkillMaster_Mailing: Auto-Mail"] = "TradeSkillMaster_Mailing: 自动邮寄"
L[ [=[TradeSkillMaster_Mailing - Sending...

(the last mail may take several moments)]=] ] = [=[TradeSkillMaster_Mailing - 发送中...

(最后一封邮件可能会花些时间)]=] -- Needs review
L["Waiting..."] = "等待中..." -- Needs review
