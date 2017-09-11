-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Accounting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_Accounting.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Accounting Locale - zhCN
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Accounting/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Accounting", "zhCN")
if not L then return end

L["Accounting"] = "Accounting" -- Needs review
L["Activity Log"] = "活动日志" -- Needs review
L["Activity Type"] = "活动类别" -- Needs review
L["Auctions"] = "拍卖数量" -- Needs review
L["Average Prices:"] = "均价："
L["Avg Buy Price"] = "买入均价" -- Needs review
L["Avg Resale Profit"] = "转卖平均利润"
L["Avg Sell Price"] = "出售均价" -- Needs review
L["Back to Previous Page"] = "返回上一页"
L["Bought"] = "已买入" -- Needs review
L["Buyer/Seller"] = "买家/卖家"
L["Clear Old Data"] = "清除旧数据" -- Needs review
L["Click for a detailed report on this item."] = "点击生成该物品的详细报告。"
L["Click this button to permanently remove data older than the number of days selected in the dropdown."] = "点击这个按钮来永久性删除旧于下拉列表中的天数的数据." -- Needs review
L["Common Quality Items"] = "普通品质物品（白色）"
L["Data older than this many days will be deleted when you click on the button to the right."] = "当你点击右侧的按钮时旧于这个天数的数据将被删除." -- Needs review
L["Days:"] = "天数:" -- Needs review
L["DD/MM/YY HH:MM"] = "日/月/年 时:分"
L["Earned Per Day:"] = "每天赚取："
L["Epic Quality Items"] = "史诗品质物品（紫色）"
L["General Options"] = "基本选项"
L["Gold Earned:"] = "赚取金币："
L["Gold Spent:"] = "花费金币："
L["_ Hr _ Min ago"] = "_ 小时 _ 分钟之前"
-- L["If checked, the average purchase price that shows in the tooltip will be the average price for the most recent X you have purchased, where X is the number you have in your bags / bank / gbank using data from the ItemTracker module. Otherwise, a simple average of all purchases will be used."] = ""
L["If checked, the number you have purchased and the average purchase price will show up in an item's tooltip."] = "如果勾选，物品的鼠标提示中将显示该物品你的购买数量与购买均价。"
L["If checked, the number you have sold and the average sale price will show up in an item's tooltip."] = "如果勾选，物品的鼠标提示中将显示该物品你的销售数量与销售均价。"
L["Item Name"] = "物品名称"
L["Items"] = "物品"
L["Items in an Auctioning Group"] = "物品在销售部群组中"
L["Items NOT in an Auctioning Group"] = "物品不在销售部群组中"
L["Items/Resale Price Format"] = "物品/转售价格格式" -- Needs review
L["Last 30 Days:"] = "最近30天："
L["Last 7 Days:"] = "最近7天："
L["Last Purchase"] = "最近购买" -- Needs review
L["Last Sold"] = "最近售出" -- Needs review
L["Market Value"] = "市场价"
L["Market Value Source"] = "市场价来源"
L["MM/DD/YY HH:MM"] = "月/日/年 时:分"
L["MySales Import Complete! Imported %s sales. Was unable to import %s sales."] = "MySales导入完成! 已导入%s个出售. 不能导入%s个出售." -- Needs review
L["MySales Import Progress"] = "MySales导入进度" -- Needs review
L["MySales is currently disabled. Would you like Accounting to enable it and reload your UI so it can transfer settings?"] = "MySales当前已禁用.你是否想要启用Accounting并重载界面以转移设置?" -- Needs review
L["none"] = "无" -- Needs review
L["Options"] = "选项"
L["Price Per Item"] = "物品单价"
L["Purchase"] = "购买"
L["Purchase Data"] = "购买数据"
L["Purchased (Avg Price): %s (%s)"] = "已购入（均价）：%s（%s）"
L["Purchased (Smart Avg): %s (%s)"] = "已购买  (智能均价): %s (%s)" -- Needs review
L["Purchases"] = "购买数量" -- Needs review
L["Quantity"] = "数量"
L["Quantity Bought:"] = "买入数量"
L["Quantity Sold:"] = "售出数量"
L["Rare Quality Items"] = "精良品质物品（蓝色）"
L["Removed a total of %s old records and %s items with no remaining records."] = "已移除 %s 条旧记录 和  %s 个无剩余记录的物品." -- Needs review
L["Remove Old Data (No Confirmation)"] = "移除旧的数据 (无确认)" -- Needs review
L["Resale"] = "转卖"
L["%s ago"] = "%s 之前" -- Needs review
L["Sale"] = "出售"
L["Sale Data"] = "出售数据"
L["Sales"] = "出售数量" -- Needs review
L["Search"] = "搜索"
L["Select how you would like prices to be shown in the \"Items\" and \"Resale\" tabs; either average price per item or total value."] = "选择物品和转售标签里价格的显示方式; 可以是每个物品的平均价格或总价格." -- Needs review
L["Select what format Accounting should use to display times in applicable screens."] = "请选择财务部以何种格式显示时间。"
L["Select where you want Accounting to get market value info from to show in applicable screens."] = "请选择你希望财务部显示的市场价从何处获取。"
L["Show purchase info in item tooltips"] = "在物品的鼠标提示中显示购买信息"
L["Show sale info in item tooltips"] = "在物品的鼠标提示中显示销售信息"
L["Sold"] = "已售出"
L["Sold (Avg Price): %s (%s)"] = "已出售（均价）：%s（%s）"
L["Special Filters"] = "指定过滤条件"
L["Spent Per Day:"] = "每天花费："
L["Stack Size"] = "堆叠数量"
L["Starting to import MySales data. This requires building a large cache of item names which will take about 20-30 seconds. Please be patient."] = "开始导入 MySales 数据. 这个操作需构建大量物品名称缓存，约费时20-30秒. 请耐心等待." -- Needs review
L["Summary"] = "摘要" -- Needs review
L["There is no purchase data for this item."] = "该物品无购买数据。"
L["There is no sale data for this item."] = "该物品无销售数据。"
L["Time"] = "时间"
L["Time Format"] = "时间格式"
L["Tooltip Options"] = "鼠标提示选项"
L["Top Buyers:"] = "最高出价买家：" -- Needs review
L["Top Item by Gold:"] = "最高物品价值" -- Needs review
L["Top Item by Quantity:"] = "最多物品数量：" -- Needs review
L["Top Sellers:"] = "卖家排名" -- Needs review
L["Total:"] = "总计：" -- Needs review
L["Total Buy Price"] = "买入总价" -- Needs review
L["Total Price"] = "总价" -- Needs review
L["Total Sale Price"] = "出售总价" -- Needs review
L["Total Spent:"] = "总花费"
L["Total Value"] = "总价格" -- Needs review
L["TradeSkillMaster_Accounting has detected that you have MySales installed. Would you like to transfer your data over to Accounting?"] = "TradeSkillMaster_Accounting 已检测到你已安装了Mysales. 你是否想要转换你的数据到本插件?" -- Needs review
L["Uncommon Quality Items"] = "优秀品质物品（绿色）"
L["Use smart average for purchase price"] = "购买价格使用智能均价" -- Needs review
L[ [=[You can use the options below to clear old data. It is recommened to occasionally clear your old data to keep Accounting running smoothly. Select the minimum number of days old to be removed in the dropdown, then click the button.

NOTE: There is no confirmation.]=] ] = [=[你可以使用以下的选项来清除旧的数据. 推荐你定期清除数据来保持插件流畅运行. 选择你要清除的旧数据的天数, 然后点击按钮.

注意: 这个操作没有确认提示。]=] -- Needs review
L["YY/MM/DD HH:MM"] = "年/月/日 时:分"
 