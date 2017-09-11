-- This file is created automatically by the TradeSkillMaster - Auction Data application.
local TSM = select(2, ...)

function TSM:CheckNewAuctionData()
	local data = TSM.NewAuctionData
	if data and data.lastUpdate > TSM.db.factionrealm.lastAutoUpdate and data.server == GetRealmName() then
		local faction = strlower(UnitFactionGroup("player"))
		TSM.Scan:ProcessImportedData(TSM.NewAuctionData[faction])
		TSM.db.factionrealm.lastAutoUpdate = data.lastUpdate
		TSM:Print("Imported new auction data!")
	end
end

-- Data will be in the following form:
--[[
TSM.NewAuctionData = {
	server = SERVER_NAME,
	lastUpdate = UPDATE_TIME,

	horde = {
		[ITEMID] = {
			{BUYOUT, QUANTITY},
			...
		},
		...
	},
	
	alliance = {
		...
	},
}
]]

--$$$ all text after this line is automatically filled in
