-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- TradeSkillMaster_Shopping Locale - koKR
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Shopping/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Shopping", "koKR")
if not L then return end

L["Added '%s' to your favorite searches."] = "'%s'을(를) 즐겨찾기 검색에 추가합니다." -- Needs review
-- L["Alts"] = ""
-- L["Auction Bid:"] = ""
--[==[ L[ [=[Auction Bid
(per item)]=] ] = "" ]==]
--[==[ L[ [=[Auction Bid
(per stack)]=] ] = "" ]==]
-- L["Auction Buyout"] = ""
L["Auction Buyout:"] = "경매 구매가"
--[==[ L[ [=[Auction Buyout
(per item)]=] ] = "" ]==]
--[==[ L[ [=[Auction Buyout
(per stack)]=] ] = "" ]==]
-- L["auctioning"] = ""
L["Auctions"] = "경매"
-- L["Below Custom Price ('0c' to disable)"] = ""
-- L["Below Vendor Sell Price"] = ""
L["Bid Percent"] = "입찰가 백분율"
-- L["Canceling Auction:"] = ""
-- L["|cff99ffff[Crafting]|r "] = ""
-- L["|cff99ffff[Normal]|r "] = ""
-- L["Could not find crafting info for the specified item."] = ""
-- L["Could not find this item on the AH. Removing it."] = ""
-- L["Could not lookup item info for '%s' so skipping it."] = ""
-- L["Ctrl-Left-Click to rename this search."] = ""
L["Custom Filter"] = "사용자 필터" -- Needs review
-- L["Custom Filter / Other Searches"] = ""
-- L["%d auctions found below vendor price for a potential profit of %s!"] = ""
L["Default Post Undercut Amount"] = "기본 등록 에누리 금액" -- Needs review
-- L["Desktop App Searches"] = ""
-- L["% DE Value"] = ""
-- L["disenchant search"] = ""
-- L["Disenchant Search Options"] = ""
L["Done Scanning"] = "검색 완료" -- Needs review
-- L["Duration:"] = ""
L["Enter what you want to search for in this box. You can also use the following options for more complicated searches."] = "이 상자에 검색어를 입력합니다. 또한, 더 복잡한 검색을 위해서 다음과 같은 옵션을 사용할 수 있습니다." -- Needs review
L["Even (5/10/15/20) Stacks Only"] = "맞춤(5/10/15/20) 묶음만" -- Needs review
-- L["Failed to bid on this auction. Skipping it."] = ""
-- L["Failed to buy this auction. Skipping it."] = ""
-- L["Failed to cancel auction because somebody has bid on it."] = ""
L["Favorite Searches"] = "즐겨찾기 검색" -- Needs review
-- L["Found Auction Sound"] = ""
-- L["gathering"] = ""
L["General"] = "일반" -- Needs review
L["General Operation Options"] = "일반 작업 옵션" -- Needs review
L["General Options"] = "일반 옵션"
L["General Settings"] = "일반 설정" -- Needs review
-- L["great deals"] = ""
-- L["Great Deals"] = ""
-- L["group search"] = ""
L["If checked, auctions above the max price will be shown."] = "선택하면, 최대 가격 이상의 경매 물품도 표시됩니다." -- Needs review
-- L["If checked, auctions below the max price will be shown while sniping."] = ""
L["If checked, only auctions posted in even quantities will be considered for purchasing."] = "선택하면, 맞춤 수량으로 등록된 물품만 구매 대상이 됩니다." -- Needs review
-- L["If checked, the maximum shopping price will be shown in the tooltip for the item."] = ""
L["If set, only items which are usable by your character will be included in the results."] = "설정하면, 현재 캐릭터가 사용할 수 있는 아이템만 검색 결과에 포함됩니다." -- Needs review
L["If set, only items which exactly match the search filter you have set will be included in the results."] = "설정하면, 검색 필터와 정확하게 일치하는 아이템만 검색 결과에 포함됩니다." -- Needs review
L["Import"] = "불러오기" -- Needs review
L["Import Favorite Search"] = "즐겨찾기 검색 불러오기" -- Needs review
-- L["Include in Sniper Searches"] = ""
L["Inline Filters:|r You can easily add common search filters to your search such as rarity, level, and item type. For example '%sarmor/leather/epic/85/i350/i377|r' will search for all leather armor of epic quality that requires level 85 and has an ilvl between 350 and 377 inclusive. Also, '%sinferno ruby/exact|r' will display only raw inferno rubys (none of the cuts)."] = "인라인 필터:|r 희귀성, 레벨, 아이템 형식 등과 같은 일반 검색 필터를 쉽게 추가할 수 있습니다. 예를 들면, '%sarmor/leather/epic/85/i350/i377|r'은 에픽 가죽 방어구 중 레벨 제한이 85이고 아이템 레벨이 350 에서 377 사이인 모든 아이템을 검색합니다. 또한 '%sinferno ruby/exact|r'는 지옥 루비(세공되지 않은)만을 검색합니다." -- Needs review
L["Invalid custom price source for %s. %s"] = "잘못된 사용자 가격 출처 %s. %s" -- Needs review
L["Invalid Even Only Filter"] = "잘못된 필터" -- Needs review
L["Invalid Exact Only Filter"] = "잘못된 필터"
L["Invalid Filter"] = "잘못된 필터"
-- L["Invalid Item Inventory Type"] = ""
L["Invalid Item Level"] = "잘못된 아이템 레벨"
L["Invalid Item Rarity"] = "잘못된 아이템 품질"
L["Invalid Item SubType"] = "잘못된 보조 형식"
L["Invalid Item Type"] = "잘못된 아이템 형식"
L["Invalid Max Quantity"] = "잘못된 최대 수량" -- Needs review
L["Invalid Min Level"] = "잘못된 최소 레벨"
L["Invalid Usable Only Filter"] = "잘못된 필터"
-- L["Item Buyout"] = ""
L["Item Class"] = "아이템 종류" -- Needs review
L["Item Level Range:"] = "아이템 레벨 범위:" -- Needs review
-- L["item notifications"] = ""
-- L["Item Notifications"] = ""
L["Item SubClass"] = "아이템 하위 종류" -- Needs review
-- L["Items which are below their vendor sell price will be displayed in Sniper searches."] = ""
-- L["Items which are below this custom price will be displayed in Sniper searches."] = ""
L["Left-Click to run this search."] = "Left-Click으로 이 검색을 수행합니다." -- Needs review
L["% Market Value"] = "시장가의 %"
L["Market Value Price Source"] = "시장 가치 가격 출처" -- Needs review
-- L["% Mat Price"] = ""
-- L["Max Disenchant Level"] = ""
-- L["Max Disenchant Search Percent"] = ""
L["Maximum Auction Price (per item)"] = "최대 경매 가격 (아이템당)" -- Needs review
L["Maximum Quantity to Buy:"] = "최대 구매 수량:" -- Needs review
L["% Max Price"] = "최대가의 %"
-- L["Max Restock Quantity"] = ""
-- L["Max Shopping Price:"] = ""
-- L["Min Disenchant Level"] = ""
-- L["Minimum Bid:"] = ""
L["Minimum Rarity"] = "최소 품질" -- Needs review
L["Multiple Search Terms:|r You can search for multiple things at once by simply separated them with a ';'. For example '%selementium ore; obsidium ore|r' will search for both elementium and obsidium ore."] = "다중 검색어:|r 검색어를 세미콜론(;)으로 분리하여 입력하면 여러 가지 물품을 한 번에 검색할 수 있습니다. 예를 들면, '%s엘레멘티움 광석; 흑요암 광석|r'은 엘레멘티움과 흑요암 광석을 동시에 검색합니다." -- Needs review
L["No recent AuctionDB scan data found."] = "최근 AuctionDB 검색 데이터가 없습니다." -- Needs review
-- L["Normal"] = ""
L["Normal Post Price"] = "일반 등록 가격" -- Needs review
-- L["Nothing to search for!"] = ""
-- L["Only exporting normal mode searches is allows."] = ""
-- L["Other Searches"] = ""
L["Paste the search you'd like to import into the box below."] = "불러올 검색을 아래 상자에 붙여 넣으세요." -- Needs review
-- L["Play the selected sound when a new auction is found to snipe."] = ""
L["Post"] = "등록"
-- L["Posting auctions..."] = ""
L["Posting Options"] = "등록 옵션"
-- L["Preparing Filters..."] = ""
L["Press Ctrl-C to copy this saved search."] = "Ctrl-C를 눌러서 저장된 검색을 복사하세요." -- Needs review
-- L["Price Per Item:"] = ""
-- L["Purchased the maximum quantity of this item!"] = ""
-- L["Purchasing Auction:"] = ""
L["Recent Searches"] = "최근 검색"
L["Removed '%s' from your favorite searches."] = "즐겨찾기 검색에서 '%s'을(를) 제거하였습니다." -- Needs review
L["Removed '%s' from your recent searches."] = "최근 검색에서 '%s'을(를) 제거하였습니다." -- Needs review
L["Required Level Range:"] = "요구 레벨 범위" -- Needs review
L["Reset Filters"] = "필터 리셋" -- Needs review
L["Right-Click to favorite this recent search."] = "Right-Click으로 이 검색을 즐겨찾기에 등록합니다." -- Needs review
L["Right-Click to remove from favorite searches."] = "Right-Click으로 츨겨찾기 검색에서 제거합니다." -- Needs review
-- L["Saved Searches / TSM Groups"] = ""
L["Scanning %d / %d (Page %d / %d)"] = "검색 중 %d / %d (페이지 %d / %d)" -- Needs review
-- L["Scanning Last Page..."] = ""
L["Search Filter:"] = "검색 필터:" -- Needs review
-- L["Searching for auction..."] = ""
-- L["Search Mode:"] = ""
-- L["Search Results"] = ""
L["Select the groups which you would like to include in the search."] = "검색에 포함할 그룹을 선택하세요." -- Needs review
L["'%s' has a Shopping operation of '%s' which no longer exists. Shopping will ignore this group until this is fixed."] = "'%s'은(는) 존재하지 않는 쇼핑 작업 '%s'을(를) 가지고 있습니다. 문제가 해결될 때까지 이 그룹은 무시됩니다." -- Needs review
-- L["Shift-Click to run sniper again."] = ""
-- L["Shift-Click to run the next favorite search."] = ""
L["Shift-Left-Click to export this search."] = "Shift-Left-Click으로 이 검색을 내보냅니다." -- Needs review
L["Shift-Right-Click to remove this recent search."] = "Shift-Right-Click으로 이 검색을 제거합니다." -- Needs review
L["Shopping for auctions including those above the max price."] = "최대 가격 이상을 포함한 경매 쇼핑" -- Needs review
L["Shopping for auctions with a max price set."] = "최대 가격 설정 경매 쇼핑" -- Needs review
L["Shopping for even stacks including those above the max price"] = "최대 가격 이상을 포함한 맞춤 묶음 경매 쇼핑" -- Needs review
L["Shopping for even stacks with a max price set."] = "최대 가격 설정 맞춤 묶음 쇼핑" -- Needs review
L["Shopping operations contain settings items which you regularly buy from the auction house."] = "쇼핑 작업은 경매장에서 정기적으로 구매하는 아이템 설정을 포함하고 있습니다." -- Needs review
-- L["Shopping will only search for enough items to restock your bags to the specific quantity. Set this to 0 to disable this feature."] = ""
L["Show Auctions Above Max Price"] = "최대 가격 이상의 경매 표시" -- Needs review
-- L["Show Shopping Max Price in Tooltip"] = ""
L["Skipped the following search term because it's invalid."] = "다음 검색어는 유효하지 않으므로 건너뜁니다." -- Needs review
L["Skipped the following search term because it's too long. Blizzard does not allow search terms over 63 characters."] = "검색어가 너무 길어서 건너뜁니다. 63글자 이상의 검색어는 블리자드에서 허용하지 않습니다."
-- L["sniper"] = ""
-- L["Sniper Options"] = ""
-- L["Sources to Include in Restock"] = ""
-- L["stack(s) of"] = ""
-- L["Start Disenchant Search"] = ""
L["Start Search"] = "검색 시작" -- Needs review
-- L["Start Sniper"] = ""
L["Start Vendor Search"] = "상점 검색 시작" -- Needs review
L["Stop"] = "중지" -- Needs review
--[==[ L[ [=[Target Price
(per item)]=] ] = "" ]==]
--[==[ L[ [=[Target Price
(per stack)]=] ] = "" ]==]
L["% Target Value"] = "대상가격 %" -- Needs review
-- L["Test Selected Sound"] = ""
-- L["The disenchant search looks for items on the AH below their disenchant value. You can set the maximum percentage of disenchant value to search for in the Shopping General options"] = ""
L["The highest price per item you will pay for items in affected by this operation."] = "이 작업에서 아이템당 지급할 수 있는 최고 금액입니다." -- Needs review
-- L["The Sniper feature will look in real-time for items that have recently been posted to the AH which are worth snatching! You can configure the parameters of Sniper in the Shopping options."] = ""
L["The vendor search looks for items on the AH below their vendor sell price."] = "상점 검색은 상점 판매 금액보다 낮은 경매장 물품을 검색합니다." -- Needs review
L["This is how Shopping calculates the '% Market Value' column in the search results."] = "검색 결과에서 '시장가 %'를 계산하는 방법입니다." -- Needs review
-- L["This is not a valid target item."] = ""
L["This is the default price Shopping will suggest to post items at when there's no others posted."] = "쇼핑에서 아이템을 등록할 때 경매장에 등록된 같은 아이템이 없다면 쇼핑은 여기서 지정한 가격을 제안합니다." -- Needs review
-- L["This is the main content area which will change depending on which button is selected above."] = ""
-- L["This is the maximum item level that the Other > Disenchant search will display results for."] = ""
-- L["This is the maximum percentage of disenchant value that the Other > Disenchant search will display results for."] = ""
-- L["This is the minimum item level that the Other > Disenchant search will display results for."] = ""
L["This is the percentage of your buyout price that your bid will be set to when posting auctions with Shopping."] = "쇼핑에서 아이템을 등록할 때 여기서 설정한 즉시 구매가의 백분율로 입찰 가격이 지정됩니다." -- Needs review
-- L["This searches the AH for all items found on the TSM Great Deals page (http://tradeskillmaster.com/great-deals)."] = ""
-- L["This searches the AH for your current deals as displayed on the TSM website."] = ""
-- L["Total Deposit:"] = ""
-- L["Type in the new name for this saved search and hit the 'Save' button."] = ""
-- L["Unexpected filters (only '/even' or '/ignorede' or '/x<MAX_QUANTITY>' is supported in crafting mode): %s"] = ""
L["Unknown Filter"] = "알수 없는 필터"
-- L["Use these buttons to change what is shown below."] = ""
-- L["vendor search"] = ""
-- L["% Vendor Value"] = ""
-- L["Warning: The max disenchant level must be higher than the min disenchant level."] = ""
-- L["Warning: The min disenchant level must be lower than the max disenchant level."] = ""
L["What to set the default undercut to when posting items with Shopping."] = "쇼핑에서 아이템을 등록할 때 사용할 기본 에누리 값을 설정하세요." -- Needs review
-- L["When in crafting mode, the search results will include materials which can be used to craft the item which you search for. This includes milling, prospecting, and disenchanting."] = ""
L["When in normal mode, you may run simple and filtered searches of the auction house."] = "일반 모드에서는 간단하고 필터링 된 경매장 검색을 수행할 수 있습니다." -- Needs review
-- L["You can change the search mode here. Crafting mode will include items which can be crafted into the specific items (through professions, milling, prospecting, disenchanting, and more) in the search."] = ""
-- L["You can type search filters into the search bar and click on the 'SEARCH' button to quickly search the auction house. Refer to the tooltip of the search bar for details on more advanced filters."] = ""
-- L["You must enter a search filter before starting the search."] = ""
