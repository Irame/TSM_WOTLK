-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Warehousing - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_warehousing.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Warehousing Locale - zhTW
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Warehousing/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Warehousing", "zhTW")
if not L then return end

L["   1.1) You can delete a group by typing in its name and hitting okay."] = "1.1) 你可以經由輸入群組名稱後，再按下「okay」來刪除它。"
L["   1) Open up a bank (either the gbank or personal bank)"] = "1) 開啟銀行 (公會或是個人銀行)"
L["   1) Type a name in the textbox labeled \"Create New Group\", hit okay"] = "1) 在「建立新群組」文字欄中輸入名稱，按下「okay」"
L["   2) Select that group using the table on the left, you should then see a list of all the items currently in your bags with a quantity"] = "2) 在左方表格中選擇群組後，你應該可以看見你目前包包中的所有物品及品質。"
L["   2) You should see a window on your right with a list of groups"] = "2) 你應該可以在右邊視窗看見群組列表"
L["   3) Right click to increase, left click to decrease by the current increment"] = "3) 按右鍵增加、左減少目前的數量。"
L["   3) Select a group and hit either"] = "選擇群組並按下「任一」"
L["   Again warehousing will try to fill out the order, but if it is short, it will remember how much it is short by and adjust its counts. So then you can go to another bank or another character and warehousing will grab the difference. Once the order has been completely filled out, warehousing will reset the count back to the original total. You cannot move a Crafting Queue bags->bank, only bank->bags."] = "Warehousing會式著滿足訂單需求，如果材料短少，它會記得少了多少，並調整數量。你可以到另一個銀行或是角色，warehousing會取得不足量。當訂單全都做完後，warehousing會重置數量到初始值。你不能將製造佇列從包包->銀行，只能從銀行->包包"
L["Auctioning"] = "拍賣"
L["Crafting"] = "製造"
L["Create New Group"] = "建立新群組"
L["Delete Group"] = "刪除群組"
L["Empty Bags"] = "清空包包"
L["Empty Bags/Restore Bags"] = "清空/還原包包"
L["Group Behaviors"] = "群組方式"
L["Groups"] = "群組"
L["How To"] = "如何"
L["Inventory Manager"] = "庫存管理員"
L["Item"] = "物品"
L["Move Group to Bags"] = "將群組移到包包"
L["Move Group To Bags"] = "將群組移到包包"
L["Move Group to Bank"] = "將群組移到銀行"
L["Move Group To Bank"] = "將群組移到銀行"
L["New Group"] = "新群組"
L["or"] = "或"
L["Quantity"] = "品質"
L["Reset Crafting Queue"] = "重置製造佇列"
L["Restore Bags"] = "還原包包"
L["Set Increment"] = "設定增量"
L["   Simply hit empty bags, warehousing will remember what you had so that when you hit restore, it will grab all those items again. If you hit empty bags while your bags are empty it will overwrite the previous bag state, so you will not be able to use restore."] = "只要按下「清空包包」，當你按下還原時，warehousing將會記得你原本有什麼，它會再次取得所有的物品。如果你按下「清空包包」時，包包就是空的，它會覆寫原本的包包狀態，如此你就不能原成原本狀態。"
L["To create a Warehousing Group"] = "建立一個Warehousing群組"
L["To move a Group:"] = "移動群組："
L["TradeSkillMaster_InventoryManager"] = "TradeSkillMaster_InventoryManager"
L["Warehousing"] = "Warehousing"
L["Warehousing will only keep track of items that you have moved out of you bank and into your bags via the Inventory_Manager.  Finaly if you ever feel the need to reset the counts for a queue simply use the dropdown menu below."] = "Warehousing只追蹤你使用Inventory_Manager<庫存管理員>從銀行搬到包包的物品。如果你需要重置佇列，只要使用下方的下拉式選單即可。"
L["   Warehousing will simply move all of each of the items in the group from the source to the destination."] = "Warehousing將會把所有的物品從來源群組移到目標群組。"
L["   Warehousing will try to get the right number of items, if there are not enough in the bank to fill out order, it will grab all that there is."] = "Warehousing將會試著取得正確的物品數量，如果銀行中的數量不足，它將會拿取全部。"

