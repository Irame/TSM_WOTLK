-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- TradeSkillMaster_Shopping Locale - zhCN
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Shopping/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Shopping", "zhCN")
if not L then return end

L["Added '%s' to your favorite searches."] = "添加'%s'到你最喜欢的搜索"
L["Alts"] = "角色"
L["Auction Bid:"] = "竞标价："
L[ [=[Auction Bid
(per item)]=] ] = [=[竞标价
（每件）]=]
L[ [=[Auction Bid
(per stack)]=] ] = [=[竞标价
（每组）]=]
L["Auction Buyout"] = "一口价"
L["Auction Buyout:"] = "一口价："
L[ [=[Auction Buyout
(per item)]=] ] = [=[一口价
（每件）]=]
L[ [=[Auction Buyout
(per stack)]=] ] = [=[一口价
（每组）]=]
L["auctioning"] = "拍卖"
L["Auctions"] = "拍卖" -- Needs review
L["Below Custom Price ('0c' to disable)"] = "低于用户价格（忽略“0C”）"
L["Below Vendor Sell Price"] = "低于贩卖价"
L["Bid Percent"] = "竞价百分比"
L["Canceling Auction:"] = "取消拍卖："
L["|cff99ffff[Crafting]|r "] = "制造"
L["|cff99ffff[Normal]|r "] = "|cff99ffff[普通]|r"
L["Could not find crafting info for the specified item."] = "找不到指定物品的crafting信息。"
L["Could not find this item on the AH. Removing it."] = "拍卖行中找不到物品。正在移除。"
L["Could not lookup item info for '%s' so skipping it."] = "找不到'%s'的物品信息，忽略之。"
L["Ctrl-Left-Click to rename this search."] = "Ctrl+左键点击来重命名这个搜索。"
L["Custom Filter"] = "自定义筛选器"
L["Custom Filter / Other Searches"] = "自定义筛选/其他搜索"
L["%d auctions found below vendor price for a potential profit of %s!"] = "%d 的拍卖被找到低于卖店价 %s 的预期利润!"
L["Default Post Undercut Amount"] = "默认发布压价金额"
L["Desktop App Searches"] = "桌面插件搜索"
L["% DE Value"] = "%的DE值"
L["disenchant search"] = "分解搜索"
L["Disenchant Search Options"] = "分解搜索选项" -- Needs review
L["Done Scanning"] = "完成扫描"
L["Duration:"] = "持续时间："
L["Enter what you want to search for in this box. You can also use the following options for more complicated searches."] = "在此框中输入你想要搜索的物品，您还可以使用下列选项来进行更复杂精确的搜索"
L["Even (5/10/15/20) Stacks Only"] = "只买成(5/10/15/20)的堆叠"
L["Failed to bid on this auction. Skipping it."] = "拍卖失败。忽略之。"
L["Failed to buy this auction. Skipping it."] = "购买失败。忽略之。"
L["Failed to cancel auction because somebody has bid on it."] = "取消拍卖操作失败因为已经有人买下物品。"
L["Favorite Searches"] = "最喜欢的搜索"
L["Found Auction Sound"] = "找到拍卖音效"
L["gathering"] = "收集"
L["General"] = "常规"
L["General Operation Options"] = "常规操作选项"
L["General Options"] = "常规选项"
L["General Settings"] = "常规设置"
L["great deals"] = "完美交易"
L["Great Deals"] = "伟大的交易" -- Needs review
L["group search"] = "分组搜索"
L["If checked, auctions above the max price will be shown."] = "如果勾选,将显示高于最高价格的拍卖品。"
L["If checked, auctions below the max price will be shown while sniping."] = "如果勾选，以下最高价的拍卖将在狙击中显示。"
L["If checked, only auctions posted in even quantities will be considered for purchasing."] = "如果勾选, 只有数量合适的发布物品才会考虑购买"
L["If checked, the maximum shopping price will be shown in the tooltip for the item."] = "如果勾选，每件物品最大购买价格将显示在提示栏"
L["If set, only items which are usable by your character will be included in the results."] = "如果设置,只有对你角色可用的物品将在结果中显示。"
L["If set, only items which exactly match the search filter you have set will be included in the results."] = "如果设置, 只有严格匹配你设置的筛选条件的物品才会被显示在结果中。"
L["Import"] = "导入"
L["Import Favorite Search"] = "导入最喜欢的搜索"
L["Include in Sniper Searches"] = "包括狙击搜索"
L["Inline Filters:|r You can easily add common search filters to your search such as rarity, level, and item type. For example '%sarmor/leather/epic/85/i350/i377|r' will search for all leather armor of epic quality that requires level 85 and has an ilvl between 350 and 377 inclusive. Also, '%sinferno ruby/exact|r' will display only raw inferno rubys (none of the cuts)."] = "|cffffff00在线过滤:|r 你可以通过添加 稀有度,等级,物品类型 来过滤物品. 例如 '%sarmor/leather/epic/85/i350/i377|r' 将会查找所有皮甲并且满足(史诗级，85级，物品等级在355~377. 再如, '%sinferno ruby/exact|r' 将只会显示原始的地狱炎石而不包括切割后的产品"
L["Invalid custom price source for %s. %s"] = "无效的价格来源%s. %s"
L["Invalid Even Only Filter"] = "无效唯一筛选"
L["Invalid Exact Only Filter"] = "无效的唯一精确筛选"
L["Invalid Filter"] = "无效筛选"
L["Invalid Item Inventory Type"] = "无效的物品库存类型" -- Needs review
L["Invalid Item Level"] = "无效的物品等级"
L["Invalid Item Rarity"] = "无效的物品品质"
L["Invalid Item SubType"] = "无效的物品子类型"
L["Invalid Item Type"] = "无效物品类型"
L["Invalid Max Quantity"] = "无效的最大数量"
L["Invalid Min Level"] = "无效的最低等级"
L["Invalid Usable Only Filter"] = "无效的唯一可用筛选"
L["Item Buyout"] = "物品买入"
L["Item Class"] = "物品种类"
L["Item Level Range:"] = "物品等级范围:"
L["item notifications"] = "物品提示"
L["Item Notifications"] = "物品通知"
L["Item SubClass"] = "物品子类型"
L["Items which are below their vendor sell price will be displayed in Sniper searches."] = "下列物品的NPC价将显示在狙击搜索中"
L["Items which are below this custom price will be displayed in Sniper searches."] = "下列自定义价格物品将显示在狙击搜索中"
L["Left-Click to run this search."] = "左键点击来进行这个搜索"
L["% Market Value"] = "%s 市场价"
L["Market Value Price Source"] = "市场价来源"
L["% Mat Price"] = "%原材料价格"
L["Max Disenchant Level"] = "最高分解级别"
L["Max Disenchant Search Percent"] = "最大分解搜索百分比"
L["Maximum Auction Price (per item)"] = "最高价(每件)"
L["Maximum Quantity to Buy:"] = "最大购买量"
L["% Max Price"] = "%最高价"
L["Max Restock Quantity"] = "最大堆叠数量"
L["Max Shopping Price:"] = "最高购买价"
L["Min Disenchant Level"] = "最低分解级别"
L["Minimum Bid:"] = "最低出价："
L["Minimum Rarity"] = "最低品质"
L["Multiple Search Terms:|r You can search for multiple things at once by simply separated them with a ';'. For example '%selementium ore; obsidium ore|r' will search for both elementium and obsidium ore."] = "|cffffff00多重查询条件:|r 你可以一次查询多个物品通过使用';'符号分割开来. 例如 '%s铁矿石; 铜矿石|r' 将会同时查找铁矿石和铜矿石。"
L["No recent AuctionDB scan data found."] = "没有发现最近的 AuctionDB扫描数据"
L["Normal"] = "常规"
L["Normal Post Price"] = "回跌价格"
L["Nothing to search for!"] = "未搜索到任何物品！"
L["Only exporting normal mode searches is allows."] = "仅导出普通搜索"
L["Other Searches"] = "其他搜索"
L["Paste the search you'd like to import into the box below."] = "在下面的框体粘贴导入你想要的搜索"
L["Play the selected sound when a new auction is found to snipe."] = "当找到新的狙击拍卖时播放选中声音。"
L["Post"] = "发布" -- Needs review
L["Posting auctions..."] = "正在发布拍卖…"
L["Posting Options"] = "上架选项" -- Needs review
L["Preparing Filters..."] = "正在准备筛选…"
L["Press Ctrl-C to copy this saved search."] = "Ctrl+C复制这个保存的搜索"
L["Price Per Item:"] = "物品单价："
L["Purchased the maximum quantity of this item!"] = "物品的最大数量购买！" -- Needs review
L["Purchasing Auction:"] = "拍卖购买："
L["Recent Searches"] = "最近搜索"
L["Removed '%s' from your favorite searches."] = "从您最喜欢的搜索里移除'%s' "
L["Removed '%s' from your recent searches."] = "从您最近的搜索里移除'%s' "
L["Required Level Range:"] = "物品等级范围:"
L["Reset Filters"] = "重置筛选器"
L["Right-Click to favorite this recent search."] = "右键点击 保存到最喜欢的搜索"
L["Right-Click to remove from favorite searches."] = "右键点击 从最喜欢的搜索里移除"
L["Saved Searches / TSM Groups"] = "保存搜索/TSM分组"
L["Scanning %d / %d (Page %d / %d)"] = "扫描 %d / %d(页面 %d / %d)"
L["Scanning Last Page..."] = "正在扫描最后一页..."
L["Search Filter:"] = "搜索筛选器:"
L["Searching for auction..."] = "正在搜索拍卖..."
L["Search Mode:"] = "搜索模式："
L["Search Results"] = "搜索结果"
L["Select the groups which you would like to include in the search."] = "选择你想搜索的分组"
L["'%s' has a Shopping operation of '%s' which no longer exists. Shopping will ignore this group until this is fixed."] = "分组'%s'(包含操作 '%s')已不再存在. Shopping会忽略这个分组直到该问题被修复。"
L["Shift-Click to run sniper again."] = "Shift点击再次运行狙击。"
L["Shift-Click to run the next favorite search."] = "Shift点击以运行下个最爱的搜索。"
L["Shift-Left-Click to export this search."] = "Shift+左键 导出这个搜索。"
L["Shift-Right-Click to remove this recent search."] = "Shift+右键 移除最近的搜索。"
L["Shopping for auctions including those above the max price."] = "购买拍卖品(包括那些高于最高价格的)。"
L["Shopping for auctions with a max price set."] = "购买拍卖品(在最高价格限定下)。"
L["Shopping for even stacks including those above the max price"] = "购买整组,忽视最高价格选定。"
L["Shopping for even stacks with a max price set."] = "购买整组,在最高价格限定下。"
L["Shopping operations contain settings items which you regularly buy from the auction house."] = "Shopping操作包括设置你经常在拍卖行购买的物品"
L["Shopping will only search for enough items to restock your bags to the specific quantity. Set this to 0 to disable this feature."] = "Shopping将只搜索能够补充背包货物的特定数量拍卖。设定选项从0到取消。"
L["Show Auctions Above Max Price"] = "显示高于最高价格的拍卖品"
L["Show Shopping Max Price in Tooltip"] = "在鼠标提示中显示最高购买价"
L["Skipped the following search term because it's invalid."] = "已跳过下一不可用的扫描。"
L["Skipped the following search term because it's too long. Blizzard does not allow search terms over 63 characters."] = "跳过下面的搜索项,因为它太长了。暴雪不允许超过63字符的搜索条件。"
L["sniper"] = "狙击"
L["Sniper Options"] = "狙击设置"
L["Sources to Include in Restock"] = "来源包括补货" -- Needs review
L["stack(s) of"] = "成组的"
L["Start Disenchant Search"] = "开始分解搜索"
L["Start Search"] = "开始搜索"
L["Start Sniper"] = "开始狙击"
L["Start Vendor Search"] = "开始NPC价格查询"
L["Stop"] = "停止"
L[ [=[Target Price
(per item)]=] ] = [=[目标价格
（每件）]=]
L[ [=[Target Price
(per stack)]=] ] = [=[目标价格
（每组）]=]
L["% Target Value"] = "% 目标物品价格"
L["Test Selected Sound"] = "测试选中的声音"
L["The disenchant search looks for items on the AH below their disenchant value. You can set the maximum percentage of disenchant value to search for in the Shopping General options"] = ""
L["The highest price per item you will pay for items in affected by this operation."] = "你希望购买每件物品的最高价(不是每组的价格),拍卖行中所有低于此价格的物品将会提示你购买"
L["The Sniper feature will look in real-time for items that have recently been posted to the AH which are worth snatching! You can configure the parameters of Sniper in the Shopping options."] = ""
L["The vendor search looks for items on the AH below their vendor sell price."] = "狙击特征将实时关注拍卖行中值得狙击的项目！你可以在购物选项中设置狙击参数"
L["This is how Shopping calculates the '% Market Value' column in the search results."] = "这是快速拍卖模块物品市场价的来源，通常显示在模块里物品的右侧"
L["This is not a valid target item."] = "这是无效的目标物品。"
L["This is the default price Shopping will suggest to post items at when there's no others posted."] = "这是当没有别的出售者出售该物品时，将以回跌价出售上架该物品"
L["This is the main content area which will change depending on which button is selected above."] = "这是根据上面选择按钮改变的主要满足区域。" -- Needs review
L["This is the maximum item level that the Other > Disenchant search will display results for."] = "其他>分解 搜索的最高物品等级将显示在这里。" -- Needs review
L["This is the maximum percentage of disenchant value that the Other > Disenchant search will display results for."] = "这是最大分解搜索价值百分比，其他>分解搜索将显示结果"
L["This is the minimum item level that the Other > Disenchant search will display results for."] = "其他>分解 搜索的最低物品等级将显示在这里。"
L["This is the percentage of your buyout price that your bid will be set to when posting auctions with Shopping."] = "这是你发布物品的竞标价和一口价百分比。"
L["This searches the AH for all items found on the TSM Great Deals page (http://tradeskillmaster.com/great-deals)."] = "这次拍卖行搜索找到的TSM完美交易页面 (http://tradeskillmaster.com/great-deals)。" -- Needs review
L["This searches the AH for your current deals as displayed on the TSM website."] = "指定拍卖交易的搜索结果将显示在TSM网站。" -- Needs review
L["Total Deposit:"] = "总利润："
L["Type in the new name for this saved search and hit the 'Save' button."] = "为这个搜索输入新名字并点击“保存”按钮。"
L["Unexpected filters (only '/even' or '/ignorede' or '/x<MAX_QUANTITY>' is supported in crafting mode): %s"] = "解除筛选（在crafting模式里只支持'/even' 或 '/ignorede' 或 '/x<MAX_QUANTITY>' 参数）：%s" -- Needs review
L["Unknown Filter"] = "未知的筛选"
L["Use these buttons to change what is shown below."] = "用这些按钮来改变以下显示内容。"
L["vendor search"] = "卖店价搜索"
L["% Vendor Value"] = "%卖店价"
L["Warning: The max disenchant level must be higher than the min disenchant level."] = "警告：最高分解级别必须高于最低分解级别。"
L["Warning: The min disenchant level must be lower than the max disenchant level."] = "警告：最低分解级别必须低于最高分解级别。"
L["What to set the default undercut to when posting items with Shopping."] = "设置发布和购买的默认削价"
L["When in crafting mode, the search results will include materials which can be used to craft the item which you search for. This includes milling, prospecting, and disenchanting."] = "在制造模式下，搜索结果包含那些通过研磨，选矿和分解可以制作成搜索目标的东西。"
L["When in normal mode, you may run simple and filtered searches of the auction house."] = "在常规模式下,你可以在拍卖行进行简单筛选的搜索。"
L["You can change the search mode here. Crafting mode will include items which can be crafted into the specific items (through professions, milling, prospecting, disenchanting, and more) in the search."] = "你可以在这个改变搜索模式。Crafting模式能够搜索可制造的物品（通过专业，研磨，选矿，分解，和其他方式）。"
L["You can type search filters into the search bar and click on the 'SEARCH' button to quickly search the auction house. Refer to the tooltip of the search bar for details on more advanced filters."] = "你可以在搜索栏中输入筛选条件并点击“立即搜索”按钮来快速搜索拍卖行。并可以在鼠标提示中显示更多筛选细节。" -- Needs review
L["You must enter a search filter before starting the search."] = "在开始搜索前必须输入筛选条件。"
