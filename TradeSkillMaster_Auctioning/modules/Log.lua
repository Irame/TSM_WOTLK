-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Auctioning - AddOn by Sapu94							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_auctioning.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


local TSM = select(2, ...)
local Log = TSM:NewModule("Log", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning")

local records = {}

local RED = "|cffff2211"
local ORANGE = "|cffff8811"
local GREEN = "|cff22ff22"
local CYAN = "|cff99ffff"

local info = {
	post = {
		invalid = {L["Item/Group is invalid."], RED},
		notEnough = {L["Not enough items in bags."], ORANGE},
		belowThreshold = {L["Cheapest auction below threshold."], ORANGE},
		tooManyPosted = {L["Maximum amount already posted."], CYAN},
		posting = {L["Posting this item."], GREEN},
		postingFallback = {L["Posting at fallback."], GREEN},
		postingReset = {L["Posting at reset price."], GREEN},
		postingPlayer = {L["Posting at your current price."], GREEN},
		postingWhitelist = {L["Posting at whitelisted player's price."], GREEN},
		notPostingWhitelist = {L["Lowest auction by whitelisted player."], ORANGE},
		postingUndercut = {L["Undercutting competition."], GREEN},
		invalidSeller = {L["Invalid seller data returned by server."], RED},
	},
	cancel = {
		bid = {L["Auction has been bid on."], CYAN},
		atReset = {L["Not canceling auction at reset price."], GREEN},
		reset = {L["Canceling to repost at reset price."], CYAN},
		belowThreshold = {L["Not canceling auction below threshold."], ORANGE},
		undercut = {L["You've been undercut."], RED},
		whitelistUndercut = {L["Undercut by whitelisted player."], RED},
		atFallback = {L["At fallback price and not undercut."], GREEN},
		repost = {L["Canceling to repost at higher price."], CYAN},
		notUndercut = {L["Your auction has not been undercut."], GREEN},
		cancelAll = {L["Canceling all auctions."], CYAN},
		notLowest = {L["Canceling auction which you've undercut."], CYAN},
		invalidSeller = {L["Invalid seller data returned by server."], RED},
	},
}

function Log:GetInfo(mode, reason)
	return info[mode][reason] and info[mode][reason][1]
end

function Log:GetColor(mode, reason)
	return mode and reason and info[mode] and info[mode][reason] and info[mode][reason][2]
end

function Log:AddLogRecord(itemString, mode, action, reason, data, activeAuctions)
	local info = Log:GetInfo(mode, reason)
	local record = {itemString=itemString, info=info, action=action, data=data, mode=mode, reason=reason, activeAuctions=activeAuctions}
	tinsert(records, record)
end

function Log:GetInfoForItem(itemString)
	for _, record in ipairs(records) do
		if record.itemString == itemString then
			return record.info
		end
	end
end

function Log:GetData()
	return records
end

function Log:Clear()
	wipe(records)
end