-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_AuctionDB                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctiondb           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- TradeSkillMaster_AuctionDB Locale - koKR
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_AuctionDB/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_AuctionDB", "koKR")
if not L then return end

L["A full auction house scan will scan every item on the auction house but is far slower than a GetAll scan. Expect this scan to take several minutes or longer."] = "전체 검색은 경매장 내의 모든 아이템을 검색하지만 GetAll 검색보다는 훨씬 느립니다. 이 검색은 몇 분 정도 또는 그 이상의 시간이 소요됩니다."
-- L["A full scan is a slow, manual scan of the entire auction house."] = ""
-- L["A 'GetAll' scan is an extremely fast way to manually scan the entire AH, but may run into bugs on Blizzard's end such as disconnection issues. It also has a 15 minute cooldown."] = ""
L["A GetAll scan is the fastest in-game method for scanning every item on the auction house. However, there are many possible bugs on Blizzard's end with it including the chance for it to disconnect you from the game. Also, it has a 15 minute cooldown."] = "GetAll 검색은 게임 내에서 경매장의 모든 아이템을 검색하기 위한 가장 빠른 검색 방법입니다. 하지만 블리자드 쪽에 많은 버그가 존재하며 게임의 접속이 끊길 가능성도 있습니다. 또한, 15분의 쿨다운이 존재합니다." -- Needs review
-- L["AuctionDB - Global Historical Price (via TSM App)"] = ""
-- L["AuctionDB - Global Market Value Average (via TSM App)"] = ""
-- L["AuctionDB - Global Minimum Buyout Average (via TSM App)"] = ""
-- L["AuctionDB - Global Sale Average (via TSM App)"] = ""
-- L["AuctionDB - Historical Price (via TSM App)"] = ""
L["AuctionDB - Market Value"] = "AuctionDB - 시장 가격"
L["AuctionDB - Minimum Buyout"] = "AuctionDB - 최소 구매가격"
-- L["AuctionDB - Region Historical Price (via TSM App)"] = ""
-- L["AuctionDB - Region Market Value Average (via TSM App)"] = ""
-- L["AuctionDB - Region Minimum Buyout Average (via TSM App)"] = ""
-- L["AuctionDB - Region Sale Average (via TSM App)"] = ""
L["Can't run a GetAll scan right now."] = "지금은 GetAll 검색을 실행할 수 없습니다." -- Needs review
-- L["|cffff0000WARNING:|r TSM_AuctionDB doesn't currently have any pricing data for your realm. Either download the TSM Desktop Application from |cff99ffffhttp://tradeskillmaster.com|r to automatically update TSM_AuctionDB's data, or run a manual scan in-game."] = ""
-- L["%d auctions"] = ""
-- L["Display global historical price (via TSM Application) in the tooltip."] = ""
-- L["Display global market value avg (via TSM Application) in the tooltip."] = ""
-- L["Display global min buyout avg (via TSM Application) in the tooltip."] = ""
-- L["Display global sale avg (via TSM Application) in the tooltip."] = ""
-- L["Display historical price (via TSM Application) in the tooltip."] = ""
L["Display market value in tooltip."] = "시장 가격을 툴팁에 표시합니다." -- Needs review
-- L["Display min buyout in tooltip."] = ""
-- L["Display region average daily sold quantity (via TSM Application) in the tooltip."] = ""
-- L["Display region historical price (via TSM Application) in the tooltip."] = ""
-- L["Display region market value avg (via TSM Application) in the tooltip."] = ""
-- L["Display region min buyout avg (via TSM Application) in the tooltip."] = ""
-- L["Display region sale avg (via TSM Application) in the tooltip."] = ""
-- L["Display region sale rate (via TSM Application) in the tooltip."] = ""
L["Done Scanning"] = "검색 완료"
L["Download the FREE TSM desktop application which will automatically update your TSM_AuctionDB prices using Blizzard's online APIs (and does MUCH more). Visit %s for more info and never scan the AH again! This is the best way to update your AuctionDB prices."] = "무료 TSM 데스크톱 애플리케이션을 다운로드하면 TSM_AuctionDB 가격을 블리자드의 온라인 API를 이용해 자동으로 업데이트합니다. %s을 방문하여 더 많은 정보를 얻고 더 이상은 경매장 검색을 하지 마세요! 이것은 AuctionDB 가격을 업데이트하는 최고의 방법입니다." -- Needs review
L["General Options"] = "일반 옵션"
-- L["Global Historical Price:"] = ""
-- L["Global Historical Price x%s:"] = ""
-- L["Global Market Value Avg:"] = ""
-- L["Global Market Value Avg x%s:"] = ""
-- L["Global Min Buyout Avg:"] = ""
-- L["Global Min Buyout Avg x%s:"] = ""
-- L["Global Sale Avg:"] = ""
-- L["Global Sale Avg x%s:"] = ""
-- L["Historical Price:"] = ""
-- L["Historical Price x%s:"] = ""
-- L["If checked, AuctionDB will add a tab to the AH to allow for in-game scans. If you are using the TSM app exclusively for your scans, you may want to hide it by unchecking this option. This option requires a reload to take effect."] = ""
-- L["If checked, the global historical price of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If checked, the global market value average of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If checked, the global minimum buyout average of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If checked, the global sale average of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If checked, the historical price of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
L["If checked, the lowest buyout value seen in the last scan of the item will be displayed."] = "선택하면, 최근 검색에서 본 아이템의 최소 구매 가격을 표시합니다." -- Needs review
L["If checked, the market value of the item will be displayed"] = "선택하면, 아이템의 시장 가격을 표시합니다." -- Needs review
-- L["If checked, the region average daily sold quantity of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If checked, the region historical price of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If checked, the region market value average of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If checked, the region minimum buyout average of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If checked, the region sale average of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If checked, the region sale rate of the item will be displayed. This is provided exclusively via the TradeSkillMaster Application."] = ""
-- L["If you have created TSM groups, they will be listed here for selection."] = ""
L["Last updated from in-game scan %s ago."] = "게임 내 검색의 최근 업데이트 %s 전." -- Needs review
L["Last updated from the TSM Application %s ago."] = "TSM 애플리케이션의 최근 업데이트 %s 전." -- Needs review
-- L["Last Update Time"] = ""
L["Market Value:"] = "시장가격:"
L["Market Value x%s:"] = "시장 가격  x%s:" -- Needs review
L["Min Buyout:"] = "최소 구매가격:"
L["Min Buyout x%s:"] = "최소 구매가 x%s:" -- Needs review
L["No scans found."] = "검색을 찾을 수 없습니다." -- Needs review
L["Not Ready"] = "준비 안 됨" -- Needs review
L["Not Scanned"] = "검색 안 됨" -- Needs review
-- L["Preparing Filters..."] = ""
L["Processing data..."] = "데이터 처리 중..." -- Needs review
L["Ready"] = "준비 됨"
-- L["Region Avg Daily Sold:"] = ""
-- L["Region Avg Daily Sold x%s:"] = ""
-- L["Region Historical Price:"] = ""
-- L["Region Historical Price x%s:"] = ""
-- L["Region Market Value Avg:"] = ""
-- L["Region Market Value Avg x%s:"] = ""
-- L["Region Min Buyout Avg:"] = ""
-- L["Region Min Buyout Avg x%s:"] = ""
-- L["Region Sale Avg:"] = ""
-- L["Region Sale Avg x%s:"] = ""
-- L["Region Sale Rate:"] = ""
-- L["Region Sale Rate x%s:"] = ""
L["Run Full Scan"] = "전체 검색"
L["Run GetAll Scan"] = "GetAll 검색"
L["Running query..."] = "쿼리 실행 중..." -- Needs review
L["%s ago"] = "%s 전"
-- L["Scanning %d / %d (Page %d / %d)"] = ""
L["Scanning page %s/%s"] = "페이지 검색 %s/%s" -- Needs review
-- L["Scanning page %s/%s - Approximately %s remaining"] = ""
-- L["Scanning results..."] = ""
L["Scanning the auction house in game is no longer necessary!"] = "이제는 게임 내에서 경매장을 검색할 필요가 없습니다!" -- Needs review
-- L["Scan Selected Groups"] = ""
-- L["Show AuctionDB AH Tab (Requires Reload)"] = ""
-- L["The scan did not run successfully due to issues on Blizzard's end. Using the TSM desktop application for your scans is recommended."] = ""
-- L["This button will scan just the items in the groups you have selected."] = ""
-- L["This will do a slow auction house scan of every item in the selected groups and update their AuctionDB prices. This may take several minutes."] = ""
-- L["You must select at least one group before starting the group scan."] = ""
 