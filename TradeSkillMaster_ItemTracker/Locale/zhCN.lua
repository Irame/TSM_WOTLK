-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_ItemTracker.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_ItemTracker Locale - zhCN
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_ItemTracker/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_ItemTracker", "zhCN")
if not L then return end

L["Delete Character:"] = "删除角色:" -- Needs review
L["Full"] = "完整" -- Needs review
L["Here, you can choose what ItemTracker info, if any, to show in tooltips. \"Simple\" will show only show totals for bags/banks and for guild banks. \"Full\" will show detailed information for every character and guild."] = "此处，你可以选择在鼠标提示中显示 ItemTracker 的什么信息，如果有的话。“简单”显示且只显示背包/银行和公会银行的总数。“完整”将显示每个角色和公会的详细信息。" -- Needs review
L["If you previously used TSM_Gathering, note that inventory data was not transfered to TSM_ItemTracker and will not show up until you log onto each character and visit the bank / gbank / auction house."] = "请注意，如果你之前用过TSM_Gathering模块，物品存货数据不会转换到TSM_ItemTracker，并且只有你登录到每个角色并访问银行/公会银行/拍卖行后才会显示。" -- Needs review
L["If you rename / transfer / delete one of your characters, use this dropdown to remove that character from ItemTracker. There is no confirmation. If you accidentally delete a character that still exists, simply log onto that character to re-add it to ItemTracker."] = "如果你改名/转移/删除了某个角色，使用此下拉菜单从ItemTracker中移除该角色。此操作无确认提示。如果你意外删除了某个仍然存在的角色，只需登录该角色即可重新添加到ItemTracker。" -- Needs review
L["ItemTracker: %s on player, %s on alts, %s in guild banks, %s on AH"] = "ItemTracker: %s 角色, %s 小号, %s 公会银行, %s 拍卖行" -- Needs review
L["No Tooltip Info"] = "无鼠标提示信息" -- Needs review
L["Options"] = "选项" -- Needs review
L["Simple"] = "简单" -- Needs review
L["\"%s\" removed from ItemTracker."] = "\"%s\" 已从 ItemTracker 移除。" -- Needs review
L["%s: %s in guild bank"] = "%s: %s 公会银行" -- Needs review
L["%s: %s (%s in bags, %s in bank, %s on AH)"] = "%s: %s (%s 背包, %s 银行, %s 拍卖行)" -- Needs review
-- L["trackerMessage"] = ""
