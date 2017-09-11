-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Accounting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_Accounting.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Accounting Locale - zhTW
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Accounting/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Accounting", "zhTW")
if not L then return end

L["Accounting"] = "統計" -- Needs review
L["Activity Log"] = "活動日誌"
L["Activity Type"] = "活動類型"
L["Auctions"] = "拍賣"
L["Average Prices:"] = "平均價格:"
L["Avg Buy Price"] = "平均購買價"
L["Avg Resale Profit"] = "平均轉售價"
L["Avg Sell Price"] = "平均出售價"
L["Back to Previous Page"] = "返回上一頁"
L["Bought"] = "購買"
L["Buyer/Seller"] = "購買者/出售者"
-- L["Clear Old Data"] = ""
L["Click for a detailed report on this item."] = "點擊察看詳細訊息。"
-- L["Click this button to permanently remove data older than the number of days selected in the dropdown."] = ""
L["Common Quality Items"] = "普通品質"
-- L["Data older than this many days will be deleted when you click on the button to the right."] = ""
-- L["Days:"] = ""
L["DD/MM/YY HH:MM"] = "日/月/年 時:分"
L["Earned Per Day:"] = "日收入"
L["Epic Quality Items"] = "史詩品質"
L["General Options"] = "一般設置"
L["Gold Earned:"] = "收入"
L["Gold Spent:"] = "支出"
L["_ Hr _ Min ago"] = "_ 小時 _ 分鐘之前"
-- L["If checked, the average purchase price that shows in the tooltip will be the average price for the most recent X you have purchased, where X is the number you have in your bags / bank / gbank using data from the ItemTracker module. Otherwise, a simple average of all purchases will be used."] = ""
L["If checked, the number you have purchased and the average purchase price will show up in an item's tooltip."] = "如果勾選，購買數和平均購買價會顯示在物品的提示中"
L["If checked, the number you have sold and the average sale price will show up in an item's tooltip."] = "如果勾選，出售數和平均購買價會顯示在物品的提示中"
L["Item Name"] = "物品名稱"
L["Items"] = "物品"
L["Items in an Auctioning Group"] = "在拍賣群組裡的物品"
L["Items NOT in an Auctioning Group"] = "不在拍賣群組裡的物品"
-- L["Items/Resale Price Format"] = ""
L["Last 30 Days:"] = "30天內:"
L["Last 7 Days:"] = "7天內:"
L["Last Purchase"] = "上次購買"
L["Last Sold"] = "上次賣出"
L["Market Value"] = "市場價"
L["Market Value Source"] = "市場價值資料來源"
L["MM/DD/YY HH:MM"] = "月/日/年 時:分"
-- L["MySales Import Complete! Imported %s sales. Was unable to import %s sales."] = ""
-- L["MySales Import Progress"] = ""
-- L["MySales is currently disabled. Would you like Accounting to enable it and reload your UI so it can transfer settings?"] = ""
-- L["none"] = ""
L["Options"] = "設置"
L["Price Per Item"] = "單價"
L["Purchase"] = "購買"
L["Purchase Data"] = "購買數據"
L["Purchased (Avg Price): %s (%s)"] = "已購買(平均價格)：%s (%s)"
-- L["Purchased (Smart Avg): %s (%s)"] = ""
L["Purchases"] = "購入"
L["Quantity"] = "數量"
L["Quantity Bought:"] = "購買數量"
L["Quantity Sold:"] = "銷售數量"
L["Rare Quality Items"] = "精良品質"
-- L["Removed a total of %s old records and %s items with no remaining records."] = ""
-- L["Remove Old Data (No Confirmation)"] = ""
L["Resale"] = "轉售"
L["%s ago"] = "%s 之前"
L["Sale"] = "交易"
L["Sale Data"] = "交易數據"
L["Sales"] = "賣出"
L["Search"] = "搜索"
-- L["Select how you would like prices to be shown in the \"Items\" and \"Resale\" tabs; either average price per item or total value."] = ""
L["Select what format Accounting should use to display times in applicable screens."] = "選擇TSM Accounting如何顯示資數於申請視窗中"
L["Select where you want Accounting to get market value info from to show in applicable screens."] = "選擇你想要TSM Accounting取得市場價值的資料來源於申請視窗中"
L["Show purchase info in item tooltips"] = "游標提示顯示購買訊息"
L["Show sale info in item tooltips"] = "游標提示顯示出售訊息"
L["Sold"] = "賣出"
L["Sold (Avg Price): %s (%s)"] = "賣出(平均價格)：%s (%s)" -- Needs review
L["Special Filters"] = "特殊過濾"
L["Spent Per Day:"] = "日支出"
L["Stack Size"] = "數量"
-- L["Starting to import MySales data. This requires building a large cache of item names which will take about 20-30 seconds. Please be patient."] = ""
L["Summary"] = "摘要"
L["There is no purchase data for this item."] = "沒有這個物品的購買資料"
L["There is no sale data for this item."] = "沒有這個物品的出售資料"
L["Time"] = "時間"
L["Time Format"] = "時間格式"
L["Tooltip Options"] = "提示設置"
L["Top Buyers:"] = "依購買人排名："
L["Top Item by Gold:"] = "最高價錢："
L["Top Item by Quantity:"] = "依品質排名："
L["Top Sellers:"] = "最佳銷售員："
L["Total:"] = "全部:"
L["Total Buy Price"] = "總購買價" -- Needs review
L["Total Price"] = "總價"
L["Total Sale Price"] = "總出售價"
L["Total Spent:"] = "總花費："
-- L["Total Value"] = ""
-- L["TradeSkillMaster_Accounting has detected that you have MySales installed. Would you like to transfer your data over to Accounting?"] = ""
L["Uncommon Quality Items"] = "優秀品質"
-- L["Use smart average for purchase price"] = ""
--[==[ L[ [=[You can use the options below to clear old data. It is recommened to occasionally clear your old data to keep Accounting running smoothly. Select the minimum number of days old to be removed in the dropdown, then click the button.

NOTE: There is no confirmation.]=] ] = "" ]==]
L["YY/MM/DD HH:MM"] = "年/月/日 時:分"
 