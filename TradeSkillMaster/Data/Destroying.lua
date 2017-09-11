local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster")

TSMAPI.DestroyingData = {}
local destroyingData = TSMAPI.DestroyingData
local modes = {"mill", "prospect", "disenchant", "transform"}
local WEAPON, ARMOR = GetAuctionItemClasses()

do
	-- get all the GetItemInfo data into the local cache
	local function UpdateCache()
		local cacheComplete = true
		
		for i=1, #modes do
			for j=1, #destroyingData[modes[i]] do
				for item, data in pairs(destroyingData[modes[i]][j]) do
					if item ~= "desc" then
						if not data.name then
							cacheComplete = false
							data.name = GetItemInfo(item)
						end
						if modes[i] == "mill" then
							if not GetItemInfo(data.pigment) then
								cacheComplete = false
							end
							for k=1, #data.herbs do
								if not GetItemInfo(data.herbs[k].itemID) then
									cacheComplete = false
								end
							end
						elseif modes[i] == "transform" then
							if not GetItemInfo(data.otherItemID) then
								cacheComplete = false
							end
						elseif modes[i] == "prospect" then
							for k=1, #data.gems do
								if not GetItemInfo(data.gems[k]) then
									cacheComplete = false
								end
							end
							for k=1, #data.ore do
								if not GetItemInfo(data.ore[k].itemID) then
									cacheComplete = false
								end
							end
						end
					end
				end
			end
		end
		
		if cacheComplete then
			TSMAPI:CancelFrame("destroyingCache")
		end
	end
	
	TSMAPI:CreateTimeDelay("destroyingCache", 1, UpdateCache, 1)
end

destroyingData.mill = {
	{
		desc = L["Common Inks"],
		[37101] = { -- Ivory Ink
			name = GetItemInfo(37101) or GetSpellInfo(52738),
			herbs = {
				{itemID = 2449, pigmentPerMill = 3},
				{itemID = 2447, pigmentPerMill = 3},
				{itemID = 765, pigmentPerMill = 2.5},
			},
			pigment = 39151,
			pigmentPerInk = 1,
		},
		[39469] = { -- Moonglow Ink
			name = GetItemInfo(39469) or GetSpellInfo(52843),
			herbs = {
				{itemID = 2449, pigmentPerMill = 3},
				{itemID = 2447, pigmentPerMill = 3},
				{itemID = 765, pigmentPerMill = 2.5},
			},
			pigment = 39151,
			pigmentPerInk = 2,
		},
		[39774] = { -- Midnight Ink
			name = GetItemInfo(39774) or GetSpellInfo(53462),
			herbs = {
				{itemID = 785, pigmentPerMill = 2.5},
				{itemID = 2450, pigmentPerMill = 2.5},
				{itemID = 2452, pigmentPerMill = 2.5},
				{itemID = 2453, pigmentPerMill = 3},
				{itemID = 3820, pigmentPerMill = 3},
			},
			pigment = 39334,
			pigmentPerInk = 2,
		},
		[43116] = { -- Lion's Ink
			name = GetItemInfo(43116) or GetSpellInfo(57704),
			herbs = {
				{itemID = 3355, pigmentPerMill = 2.5},
				{itemID = 3369, pigmentPerMill = 2.5},
				{itemID = 3356, pigmentPerMill = 3},
				{itemID = 3357, pigmentPerMill = 3},
			},
			pigment = 39338,
			pigmentPerInk = 2,
		},
		[43118] = { -- Jadefire Ink
			name = GetItemInfo(43118) or GetSpellInfo(57707),
			herbs = {
				{itemID = 3819, pigmentPerMill = 3},
				{itemID = 3818, pigmentPerMill = 2.5},
				{itemID = 3821, pigmentPerMill = 2.5},
				{itemID = 3358, pigmentPerMill = 3},
			},
			pigment = 39339,
			pigmentPerInk = 2,
		},
		[43120] = { -- Celestial Ink
			name = GetItemInfo(43120) or GetSpellInfo(57709),
			herbs = {
				{itemID = 4625, pigmentPerMill = 2.5},
				{itemID = 8831, pigmentPerMill = 2.5},
				{itemID = 8836, pigmentPerMill = 2.5},
				{itemID = 8838, pigmentPerMill = 2.5},
				{itemID = 8839, pigmentPerMill = 3},
				{itemID = 8845, pigmentPerMill = 3},
				{itemID = 8846, pigmentPerMill = 3},
			},
			pigment = 39340,
			pigmentPerInk = 2,
		},
		[43122] = { -- Shimmering Ink
			name = GetItemInfo(43122) or GetSpellInfo(57711),
			herbs = {
				{itemID = 13464, pigmentPerMill = 2.5},
				{itemID = 13463, pigmentPerMill = 2.5},
				{itemID = 13465, pigmentPerMill = 3},
				{itemID = 13466, pigmentPerMill = 3},
				{itemID = 13467, pigmentPerMill = 3},
			},
			pigment = 39341,
			pigmentPerInk = 2,
		},
		[43124] = { -- Ethereal Ink
			name = GetItemInfo(43124) or GetSpellInfo(57713),
			herbs = {
				{itemID = 22786, pigmentPerMill = 2.5},
				{itemID = 22785, pigmentPerMill = 2.5},
				{itemID = 22789, pigmentPerMill = 2.5},
				{itemID = 22787, pigmentPerMill = 2.5},
				{itemID = 22790, pigmentPerMill = 3},
				{itemID = 22793, pigmentPerMill = 3},
				{itemID = 22791, pigmentPerMill = 3},
				{itemID = 22792, pigmentPerMill = 3},
			},
			pigment = 39342,
			pigmentPerInk = 2,
		},
		[43126] = { -- Ink of the Sea
			name = GetItemInfo(43126) or GetSpellInfo(57715),
			herbs = {
				{itemID = 37921, pigmentPerMill = 2.5},
				{itemID = 36901, pigmentPerMill = 2.5},
				{itemID = 36907, pigmentPerMill = 2.5},
				{itemID = 36904, pigmentPerMill = 2.5},
				{itemID = 39970, pigmentPerMill = 2.5}, -- Fire Leaf, not sure about the pigment in these two
				{itemID = 39969, pigmentPerMill = 2.5}, -- Fire Seed
				{itemID = 36903, pigmentPerMill = 3},
				{itemID = 36906, pigmentPerMill = 3},
				{itemID = 36905, pigmentPerMill = 3},
			},
			pigment = 39343,
			pigmentPerInk = 2,
		},
		[61978] = { -- Blackfallow Ink
			name = GetItemInfo(61978) or GetSpellInfo(86004),
			herbs = {
				{itemID = 52983, pigmentPerMill = 2.5},
				{itemID = 52984, pigmentPerMill = 2.5},
				{itemID = 52985, pigmentPerMill = 2.5},
				{itemID = 52986, pigmentPerMill = 2.5},
				{itemID = 52987, pigmentPerMill = 3},
				{itemID = 52988, pigmentPerMill = 3},
			},
			pigment = 61979,
			pigmentPerInk = 2,
		},
		[79254] = { -- Ink of Dreams
			name = GetItemInfo(79254) or GetSpellInfo(111645),
			herbs = {
				{itemID = 72237, pigmentPerMill = 2.5},
				{itemID = 72234, pigmentPerMill = 2.5},
				{itemID = 79010, pigmentPerMill = 2.5},
				{itemID = 72235, pigmentPerMill = 3},
				{itemID = 79011, pigmentPerMill = 3},
			},
			pigment = 79251,
			pigmentPerInk = 2,
		},
	},
	{
		desc = L["Uncommon Inks"],
		[61981] = { -- Inferno Ink
			name = GetItemInfo(61981) or GetSpellInfo(86005),
			herbs = {
				{itemID = 52983, pigmentPerMill = 0.5},
				{itemID = 52984, pigmentPerMill = 0.5},
				{itemID = 52985, pigmentPerMill = 0.5},
				{itemID = 52986, pigmentPerMill = 0.5},
				{itemID = 52987, pigmentPerMill = 0.8},
				{itemID = 52988, pigmentPerMill = 0.8},
			},
			pigment = 61980,
			pigmentPerInk = 2,
		},
		[79255] = { -- Starlight Ink
			name = GetItemInfo(79255) or GetSpellInfo(111646),
			herbs = {
				{itemID = 72237, pigmentPerMill = 0.5},
				{itemID = 72234, pigmentPerMill = 0.5},
				{itemID = 79010, pigmentPerMill = 0.5},
				{itemID = 72235, pigmentPerMill = 0.8},
				{itemID = 79011, pigmentPerMill = 0.8},
			},
			pigment = 79253,
			pigmentPerInk = 2,
		},
	},
}

destroyingData.prospect = {
	{
		desc = L["BC Gems"],
		[L["BC - Green Quality"]] = {
			name = L["Uncommon Gems"],
			gems = {23117, 23077, 23079, 21929, 23112, 23107},
			ore = {
				{itemID = 23424, gemPerProspect = 1.08},
				{itemID = 23425, gemPerProspect = 1.08},
			},
		},
		[L["BC - Blue Quality"]] = {
			name = L["Rare Gems"],
			gems = {23440, 23436, 23441, 23439, 23438, 23437},
			ore = {
				{itemID = 23424, gemPerProspect = 0.072},
				{itemID = 23425, gemPerProspect = 0.24},
			},
		},
	},
	{
		desc = L["Wrath Gems"],
		[L["Wrath - Green Quality"]] = {
			name = L["Uncommon Gems"],
			gems = {36917, 36923, 36932, 36929, 36926, 36920},
			ore = {
				{itemID = 36909, gemPerProspect = 1.44},
				{itemID = 36912, gemPerProspect = 1.08},
				{itemID = 36910, gemPerProspect = 1.44},
			},
		},
		[L["Wrath - Blue Quality"]] = {
			name = L["Rare Gems"],
			gems = {36921, 36933, 36930, 36918, 36924, 36927},
			ore = {
				{itemID = 36909, gemPerProspect = 0.072},
				{itemID = 36912, gemPerProspect = 0.24},
				{itemID = 36910, gemPerProspect = 0.24},
			},
		},
		[L["Wrath - Epic Quality"]] = {
			name = L["Epic Gems"],
			gems = {36931, 36919, 36928, 36934, 36922, 36925},
			ore = {
				{itemID = 36910, gemPerProspect = 0.30},
			},
		},
	},
	{
		desc = L["Cata Gems"],
		[L["Cata - Green Quality"]] = {
			name = L["Uncommon Gems"],
			gems = {52182, 52180, 52178, 52179, 52177, 52181},
			ore = {
				{itemID = 53038, gemPerProspect = 1.488},
				{itemID = 52185, gemPerProspect = 1.116},
				{itemID = 52183, gemPerProspect = 1.02},
			},
		},
		[L["Cata - Blue Quality"]] = {
			name = L["Rare Gems"],
			gems = {52192, 52193, 52190, 52195, 52194, 52191},
			ore = {
				{itemID = 53038, gemPerProspect = 0.072},
				{itemID = 52185, gemPerProspect = 0.288},
				{itemID = 52183, gemPerProspect = 0.4568},
			},
		},
	},
}

destroyingData.disenchant  = {
	{
		desc = L["Dust"],
		[10940] = { -- Strange Dust
			name = GetItemInfo(10940),
			minLevel = 0,
			maxLevel = 24,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 5,
							maxItemLevel = 15,
							amountOfMats = 1.2
						},
						{
							minItemLevel = 16,
							maxItemLevel = 20,
							amountOfMats = 1.875
						},
						{
							minItemLevel = 21,
							maxItemLevel = 25,
							amountOfMats = 3.75
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 5,
							maxItemLevel = 15,
							amountOfMats = 0.3
						},
						{
							minItemLevel = 16,
							maxItemLevel = 20,
							amountOfMats = 0.5
						},
						{
							minItemLevel = 21,
							maxItemLevel = 25,
							amountOfMats = 0.75
						},
					},
				},
			},
		},
		[11083] = { -- Soul Dust
			name = GetItemInfo(11083),
			minLevel = 20,
			maxLevel = 30,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 26,
							maxItemLevel = 30,
							amountOfMats = 1.125
						},
						{
							minItemLevel = 31,
							maxItemLevel = 35,
							amountOfMats = 2.625
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 26,
							maxItemLevel = 30,
							amountOfMats = 0.3
						},
						{
							minItemLevel = 31,
							maxItemLevel = 35,
							amountOfMats = 0.7
						},
					},
				},
			},
		},
		[11137] = { -- Vision Dust
			name = GetItemInfo(11137),
			minLevel = 30,
			maxLevel = 40,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 1.125
						},
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 2.625
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 0.3
						},
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 0.7
						},
					},
				},
			},
		},
		[11176] = { -- Dream Dust
			name = GetItemInfo(11176),
			minLevel = 41,
			maxLevel = 50,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 1.125
						},
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 2.625
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 0.3
						},
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 0.77
						},
					},
				},
			},
		},
		[16204] = { -- Illusion Dust
			name = GetItemInfo(16204),
			minLevel = 51,
			maxLevel = 60,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 56,
							maxItemLevel = 60,
							amountOfMats = 1.125
						},
						{
							minItemLevel = 61,
							maxItemLevel = 65,
							amountOfMats = 2.625
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 56,
							maxItemLevel = 60,
							amountOfMats = 0.33 
						},
						{
							minItemLevel = 61,
							maxItemLevel = 65,
							amountOfMats = 0.77
						},
					},
				},
			},
		},
		[22445] = { -- Arcane Dust
			name = GetItemInfo(22445),
			minLevel = 57,
			maxLevel = 70,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 79,
							maxItemLevel = 79,
							amountOfMats = 1.5
						},
						{
							minItemLevel = 80,
							maxItemLevel = 99,
							amountOfMats = 1.875
						},
						{
							minItemLevel = 100,
							maxItemLevel = 120,
							amountOfMats = 2.625
						},
					},
				},
				[WEAPON] = {
						[2] = {
						{
							minItemLevel = 80,
							maxItemLevel = 99,
							amountOfMats = 0.55
						},
						{
							minItemLevel = 100,
							maxItemLevel = 120,
							amountOfMats = 0.77
						},
					},
				},
			},
		},
		[34054] = { -- Infinite Dust
			name = GetItemInfo(34054),
			minLevel = 67,
			maxLevel = 80,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 130,
							maxItemLevel = 151,
							amountOfMats = 1.5
						},
						{
							minItemLevel = 152,
							maxItemLevel = 200,
							amountOfMats = 3.375
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 130,
							maxItemLevel = 151,
							amountOfMats = 0.55
						},
						{
							minItemLevel = 152,
							maxItemLevel = 200,
							amountOfMats = 1.1
						},
					},
				},
			},
		},
		[52555] = { -- Hypnotic Dust
			name = GetItemInfo(52555),
			minLevel = 77,
			maxLevel = 85,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 272,
							maxItemLevel = 275,
							amountOfMats = 1.125
						},
						{
							minItemLevel = 276,
							maxItemLevel = 290,
							amountOfMats = 1.5
						},
						{
							minItemLevel = 291,
							maxItemLevel = 305,
							amountOfMats = 1.875
						},
						{
							minItemLevel = 306,
							maxItemLevel = 315,
							amountOfMats = 2.25
						},
						{
							minItemLevel = 316,
							maxItemLevel = 325,
							amountOfMats = 2.625
						},
						{
							minItemLevel = 333,
							maxItemLevel = 400,
							amountOfMats = 3
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 272,
							maxItemLevel = 275,
							amountOfMats = 0.375
						},
						{
							minItemLevel = 276,
							maxItemLevel = 290,
							amountOfMats = 0.5
						},
						{
							minItemLevel = 291,
							maxItemLevel = 305,
							amountOfMats = 0.625
						},
						{
							minItemLevel = 306,
							maxItemLevel = 315,
							amountOfMats = 0.75
						},
						{
							minItemLevel = 316,
							maxItemLevel = 325,
							amountOfMats = 0.875
						},
						{
							minItemLevel = 326,
							maxItemLevel = 400,
							amountOfMats = 1
						},
					},
				},
			},
		},
	},
	{
		desc = L["Essences"],
		[10939] = { -- Greater Magic Essence
			name = GetItemInfo(10939),
			minLevel = 1,
			maxLevel = 15,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 5,
							maxItemLevel = 15,
							amountOfMats = 0.1
						},
						{
							minItemLevel = 16,
							maxItemLevel = 20,
							amountOfMats = 0.3
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 5,
							maxItemLevel = 15,
							amountOfMats = 0.4
						},
						{
							minItemLevel = 16,
							maxItemLevel = 20,
							amountOfMats = 1.125
						},
					},
				},
			},
		},

		[11082] = { -- Greater Astral Essence
			name = GetItemInfo(11082),
			minLevel = 16,
			maxLevel = 25,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 21,
							maxItemLevel = 25,
							amountOfMats = .075
						},
						{
							minItemLevel = 26,
							maxItemLevel = 30,
							amountOfMats = 0.3
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 21,
							maxItemLevel = 25,
							amountOfMats = 0.375
						},
						{
							minItemLevel = 26,
							maxItemLevel = 30,
							amountOfMats = 1.125
						},
					},
				},
			},
		},
		[11135] = { -- Greater Mystic Essence
			name = GetItemInfo(11135),
			minLevel = 26,
			maxLevel = 35,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 31,
							maxItemLevel = 35,
							amountOfMats = 0.1
						},
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 0.3
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 31,
							maxItemLevel = 35,
							amountOfMats = 0.375
						},
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 1.125
						},
					},
				},
			},
		},
		[11175] = { -- Greater Nether Essence
			name = GetItemInfo(11175),
			minLevel = 36,
			maxLevel = 45,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 0.1
						},
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 0.3
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 0.375
						},
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 1.125
						},
					},
				},
			},
		},

		[16203] = { -- Greater Eternal Essence
			name = GetItemInfo(16203),
			minLevel = 46,
			maxLevel = 60,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 0.1
						},
						{
							minItemLevel = 56,
							maxItemLevel = 60,
							amountOfMats = 0.3
						},
						{
							minItemLevel = 61,
							maxItemLevel = 65,
							amountOfMats = 0.5
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 0.375
						},	
						{
							minItemLevel = 56,
							maxItemLevel = 60,
							amountOfMats = 0.125
						},
						{
							minItemLevel = 61,
							maxItemLevel = 65,
							amountOfMats = 1.875
						},
					},
				},
			},
		},
		[22446] = { -- Greater Planar Essence
			name = GetItemInfo(22446),
			minLevel = 58,
			maxLevel = 70,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 66,
							maxItemLevel = 99,
							amountOfMats = 0.167
						},
						{
							minItemLevel = 100,
							maxItemLevel = 120,
							amountOfMats = 0.3
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 79,
							maxItemLevel = 79,
							amountOfMats = 0.625
						},
						{
							minItemLevel = 80,
							maxItemLevel = 99,
							amountOfMats = 0.625
						},
						{
							minItemLevel = 100,
							maxItemLevel = 120,
							amountOfMats = 1.125
						},
					},
				},
			},
		},
		[34055] = { -- Greater Cosmic Essence
			name = GetItemInfo(34055),
			minLevel = 67,
			maxLevel = 80,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 130,
							maxItemLevel = 151,
							amountOfMats = 0.1
						},
						{
							minItemLevel = 152,
							maxItemLevel = 200,
							amountOfMats = 0.3
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 130,
							maxItemLevel = 151,
							amountOfMats = 0.375
						},
						{
							minItemLevel = 152,
							maxItemLevel = 200,
							amountOfMats = 1.125
						},
					},
				},
			},
		},
		[52719] = { -- Greater Celestial Essence
			name = GetItemInfo(52719),
			minLevel = 77,
			maxLevel = 85,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 201,
							maxItemLevel = 275,
							amountOfMats = 0.125
						},
						{
							minItemLevel = 276,
							maxItemLevel = 290,
							amountOfMats = 0.167
						},
						{
							minItemLevel = 291,
							maxItemLevel = 305,
							amountOfMats = 0.208
						},
						{
							minItemLevel = 306,
							maxItemLevel = 315,
							amountOfMats = 0.375
						},
						{
							minItemLevel = 316,
							maxItemLevel = 325,
							amountOfMats = 0.625
						},
						{
							minItemLevel = 326,
							maxItemLevel = 400,
							amountOfMats = 0.75
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 201,
							maxItemLevel = 275,
							amountOfMats = 0.375
						},
						{
							minItemLevel = 276,
							maxItemLevel = 290,
							amountOfMats = 0.5
						},
						{
							minItemLevel = 291,
							maxItemLevel = 305,
							amountOfMats = 0.625
						},
						{
							minItemLevel = 306,
							maxItemLevel = 315,
							amountOfMats = 1.125
						},
						{
							minItemLevel = 316,
							maxItemLevel = 325,
							amountOfMats = 1.875
						},
						{
							minItemLevel = 326,
							maxItemLevel = 400,
							amountOfMats = 2.25
						},
					},
				},
			},
		},
	},
	{
		desc = L["Shards"],
		[10978] = { -- Small Glimmering Shard
			name = GetItemInfo(10978),
			minLevel = 1,
			maxLevel = 20,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 1,
							maxItemLevel = 20,
							amountOfMats = 0.05
						},
						{
							minItemLevel = 21,
							maxItemLevel = 25,
							amountOfMats = 0.1
						},
					},
					[3] = {
						{
							minItemLevel = 1,
							maxItemLevel = 25,
							amountOfMats = 1.000
						},
					},
				},
				[WEAPON] = {
					[3] = {
						{
							minItemLevel = 1,
							maxItemLevel = 25,
							amountOfMats = 1.000
						},
					},
				},
			},
		},
		[11084] = { -- Large Glimmering Shard
			name = GetItemInfo(11084),
			minLevel = 16,
			maxLevel = 25,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 26,
							maxItemLevel = 30,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 26,
							maxItemLevel = 30,
							amountOfMats = 1.000
						},
					},
				},
				[WEAPON] = {
					[3] = {
						{
							minItemLevel = 26,
							maxItemLevel = 30,
							amountOfMats = 1.000
						},
					},
				},
			},
		},
		[11138] = { -- Small Glowing Shard
			name = GetItemInfo(11138),
			minLevel = 26,
			maxLevel = 30,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 31,
							maxItemLevel = 35,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 31,
							maxItemLevel = 35,
							amountOfMats = 1.000
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 31,
							maxItemLevel = 35,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 31,
							maxItemLevel = 35,
							amountOfMats = 1.000
						},
					},
				},
			},
		},
		[11139] = { -- Large Glowing Shard
			name = GetItemInfo(11139),
			minLevel = 31,
			maxLevel = 35,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 1.000
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 1.000
						},
					},
				},
			},
		},
		[11177] = { -- Small Radiant Shard
			name = GetItemInfo(11177),
			minLevel = 36,
			maxLevel = 40,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 1.000
						},
					},
					[4] = {
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 3
						},	
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 3.5
						},	
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 1.000
						},	
					},
					[4] = {
						{
							minItemLevel = 36,
							maxItemLevel = 40,
							amountOfMats = 3
						},	
						{
							minItemLevel = 41,
							maxItemLevel = 45,
							amountOfMats = 3.5
						},	
					},
				},
			},
		},
		[11178] = { -- Large Radiant Shard
			name = GetItemInfo(11178),
			minLevel = 41,
			maxLevel = 45,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 1.000
						},
					},
					[4] = {
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 3.5
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 1.000
						},	
					},
					[4] = {
						{
							minItemLevel = 46,
							maxItemLevel = 50,
							amountOfMats = 3.5
						},
					},
				},
			},
		},
		[14343] = { -- Small Brilliant Shard 
			name = GetItemInfo(14343),
			minLevel = 46,
			maxLevel = 50,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 1.000
						},
					},
					[4] = {
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 3.5
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 1.000
						},	
					},
					[4] = {
						{
							minItemLevel = 51,
							maxItemLevel = 55,
							amountOfMats = 3.5
						},
					},
				},
			},
		},
		[14344] = { -- Large Brilliant Shard
			name = GetItemInfo(14344),
			minLevel = 56,
			maxLevel = 75,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 56,
							maxItemLevel = 65,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 56,
							maxItemLevel = 65,
							amountOfMats = 0.995
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 56,
							maxItemLevel = 65,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 56,
							maxItemLevel = 65,
							amountOfMats = 0.995
						},
					},
				},
			},
		},
		[22449] = { -- Large Prismatic Shard
			name = GetItemInfo(22449),
			minLevel = 56,
			maxLevel = 70,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 66,
							maxItemLevel = 99,
							amountOfMats = 0.0167
						},
						{
							minItemLevel = 100,
							maxItemLevel = 120,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 66,
							maxItemLevel = 99,
							amountOfMats = 0.33
						},
						{
							minItemLevel = 100,
							maxItemLevel = 120,
							amountOfMats = 1
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 66,
							maxItemLevel = 99,
							amountOfMats = 0.0167
						},
						{
							minItemLevel = 100,
							maxItemLevel = 120,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 66,
							maxItemLevel = 99,
							amountOfMats = 0.33
						},
						{
							minItemLevel = 100,
							maxItemLevel = 120,
							amountOfMats = 1
						},
					},
				},
			},
		},
		[34052] = { -- Dream Shard
			name = GetItemInfo(34052),
			minLevel = 68,
			maxLevel = 80,
			itemTypes = {
				[ARMOR] = {
					[2] = {
						{
							minItemLevel = 121,
							maxItemLevel = 151,
							amountOfMats = 0.0167
						},
						{
							minItemLevel = 152,
							maxItemLevel = 200,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 121,
							maxItemLevel = 164,
							amountOfMats = 0.33
						},
						{
							minItemLevel = 165,
							maxItemLevel = 200,
							amountOfMats = 1
						},
					},
				},
				[WEAPON] = {
					[2] = {
						{
							minItemLevel = 121,
							maxItemLevel = 151,
							amountOfMats = 0.0167
						},
						{
							minItemLevel = 152,
							maxItemLevel = 200,
							amountOfMats = 0.05
						},
					},
					[3] = {
						{
							minItemLevel = 121,
							maxItemLevel = 164,
							amountOfMats = 0.33
						},
						{
							minItemLevel = 165,
							maxItemLevel = 200,
							amountOfMats = 1
						},
					},
				},
			},
		},
		[52721] = { -- Heavenly Shard
			name = GetItemInfo(52721),
			minLevel = 78,
			maxLevel = 85,
			itemTypes = {
				[ARMOR] = {
					[3] = {
						{
							minItemLevel = 201,
							maxItemLevel = 316,
							amountOfMats = 0.33
						},
						{
							minItemLevel = 317,
							maxItemLevel = 400,
							amountOfMats = 1
						},
					},
				},
				[WEAPON] = {
					[3] = {
						{
							minItemLevel = 201,
							maxItemLevel = 316,
							amountOfMats = 0.33
						},
						{
							minItemLevel = 317,
							maxItemLevel = 400,
							amountOfMats = 1
						},
					},
				},
			},
		},
	},
	{
		desc = L["Crystals"],
		[20725] = { -- Nexus Crystal
			name = GetItemInfo(20725),
			minLevel = 56,
			maxLevel = 60,
			itemTypes = {
				[ARMOR] = {
					[4] = {
						{
							minItemLevel = 56,
							maxItemLevel = 60,
							amountOfMats = 1.000
						},
						{
							minItemLevel = 61,
							maxItemLevel = 94,
							amountOfMats = 1.5
						},
					},
				},
				[WEAPON] = {
					[4] = {
						{
							minItemLevel = 56,
							maxItemLevel = 60,
							amountOfMats = 1.000
						},
						{
							minItemLevel = 61,
							maxItemLevel = 94,
							amountOfMats = 1.5
						},
					},
				},
			},
		},
		[22450] = { -- Void Crystal
			name = GetItemInfo(22450),
			minLevel = 70,
			maxLevel = 70,
			itemTypes = {
				[ARMOR] = {
					[4] = {
						{
							minItemLevel = 95,
							maxItemLevel = 99,
							amountOfMats = 1
						},
						{
							minItemLevel = 100,
							maxItemLevel = 164,
							amountOfMats = 1.5
						},
					},
				},
				[WEAPON] = {
					[4] = {
						{
							minItemLevel = 95,
							maxItemLevel = 99,
							amountOfMats = 1
						},
						{
							minItemLevel = 100,
							maxItemLevel = 164,
							amountOfMats = 1.5
						},
					},
				},
			},
		},
		[34057] = { -- Abyss Crystal
			name = GetItemInfo(34057),
			minLevel = 80,
			maxLevel = 80,
			itemTypes = {
				[ARMOR] = {
					[4] = {
						{
							minItemLevel = 165,
							maxItemLevel = 299,
							amountOfMats = 1.000
						},
					},
				},
				[WEAPON] = {
					[4] = {
						{
							minItemLevel = 165,
							maxItemLevel = 299,
							amountOfMats = 1.000
						},
					},
				},
			},
		},
		[52722] = { -- Maelstrom Crystal 
			name = GetItemInfo(52722),
			minLevel = 85,
			maxLevel = 85,
			itemTypes = {
				[ARMOR] = {
					[4] = {
						{
							minItemLevel = 300,
							maxItemLevel = 400,
							amountOfMats = 1.000
						},
					},
				},
				[WEAPON] = {
					[4] = {
						{
							minItemLevel = 285,
							maxItemLevel = 400,
							amountOfMats = 1.000
						},
					},
				},
			},
		},
	},
}

destroyingData.transform = {
	{
		desc = L["Essences"],
		[52719] = { -- Greater Celestial Essence
			name = GetItemInfo(52719) or GetSpellInfo(74186),
			otherItemID = 52718,
			numNeeded = 3,
		},
		[52718] = { -- Lesser Celestial Essence
			name = GetItemInfo(52718) or GetSpellInfo(74187),
			otherItemID = 52719,
			numNeeded = 1/3,
		},
		[34055] = { -- Greater Cosmic Essence
			name = GetItemInfo(34055) or GetSpellInfo(44123),
			otherItemID = 34056,
			numNeeded = 3,
		},
		[34056] = { -- Lesser Cosmic Essence
			name = GetItemInfo(34056) or GetSpellInfo(44122),
			otherItemID = 34055,
			numNeeded = 1/3,
		},
		[22446] = { -- Greater Planar Essence
			name = GetItemInfo(22446) or GetSpellInfo(32977),
			otherItemID = 22447,
			numNeeded = 3,
		},
		[22447] = { -- Lesser Planar Essence
			name = GetItemInfo(22447) or GetSpellInfo(32978),
			otherItemID = 22446,
			numNeeded = 1/3,
		},
		[16203] = { -- Greater Eternal Essence
			name = GetItemInfo(16203) or GetSpellInfo(20039),
			otherItemID = 16202,
			numNeeded = 3,
		},
		[16202] = { -- Lesser Eternal Essence
			name = GetItemInfo(16202) or GetSpellInfo(20040),
			otherItemID = 16203,
			numNeeded = 1/3,
		},
		[11175] = { -- Greater Nether Essence
			name = GetItemInfo(11175) or GetSpellInfo(13739),
			otherItemID = 11174,
			numNeeded = 3,
		},
		[11174] = { -- Lesser Nether Essence
			name = GetItemInfo(11174) or GetSpellInfo(13740),
			otherItemID = 11175,
			numNeeded = 1/3,
		},
		[11135] = { -- Greater Mystic Essence
			name = GetItemInfo(11135) or GetSpellInfo(13632),
			otherItemID = 11134,
			numNeeded = 3,
		},
		[11134] = { -- Lesser Mystic Essence
			name = GetItemInfo(11134) or GetSpellInfo(13633),
			otherItemID = 11135,
			numNeeded = 1/3,
		},
		[11082] = { -- Greater Astral Essence
			name = GetItemInfo(11082) or GetSpellInfo(13497),
			otherItemID = 10998,
			numNeeded = 3,
		},
		[10998] = { -- Lesser Astral Essence
			name = GetItemInfo(10998) or GetSpellInfo(13498),
			otherItemID = 11082,
			numNeeded = 1/3,
		},
		[10939] = { -- Greater Magic Essence
			name = GetItemInfo(10939) or GetSpellInfo(13361),
			otherItemID = 10938,
			numNeeded = 3,
		},
		[10938] = { -- Lesser Magic Essence
			name = GetItemInfo(10938) or GetSpellInfo(13362),
			otherItemID = 10939,
			numNeeded = 1/3,
		},
	},
	{
		desc = L["Shards"],
		[52721] = { -- Heavenly Shard
			name = GetItemInfo(52721),
			otherItemID = 52720,
			numNeeded = 3,
		},
		[34052] = { -- Dream Shard
			name = GetItemInfo(34052),
			otherItemID = 34053,
			numNeeded = 3,
		},
	},
	{
		desc = L["Elemental - Motes"],
		[22578] = { -- Mote of Water
			name = GetItemInfo(22578),
			otherItemID = 21885,
			numNeeded = 1/10,
		},
		[22577] = { -- Mote of Shadow
			name = GetItemInfo(22577),
			otherItemID = 22456,
			numNeeded = 1/10,
		},
		[22576] = { -- Mote of Mana
			name = GetItemInfo(22576),
			otherItemID = 22457,
			numNeeded = 1/10,
		},
		[22575] = { -- Mote of Life
			name = GetItemInfo(22575),
			otherItemID = 21886,
			numNeeded = 1/10,
		},
		[22574] = { -- Mote of Fire
			name = GetItemInfo(22574),
			otherItemID = 21884,
			numNeeded = 1/10,
		},
		[22573] = { -- Mote of Earth
			name = GetItemInfo(22573),
			otherItemID = 22452,
			numNeeded = 1/10,
		},
		[22572] = { -- Mote of Air
			name = GetItemInfo(22572),
			otherItemID = 22451,
			numNeeded = 1/10,
		},
	},
	{
		desc = L["Elemental - Eternals"],
		[37700] = { -- Crystallized Air
			name = GetItemInfo(37700),
			otherItemID = 35623,
			numNeeded = 1/10,
		},
		[35623] = { -- Eternal Air
			name = GetItemInfo(35623),
			otherItemID = 37700,
			numNeeded = 10,
		},
		[37701] = { -- Crystallized Earth
			name = GetItemInfo(37701),
			otherItemID = 35624,
			numNeeded = 1/10,
		},
		[35624] = { -- Eternal Earth
			name = GetItemInfo(35624),
			otherItemID = 37701,
			numNeeded = 10,
		},
		[37702] = { -- Crystallized Fire
			name = GetItemInfo(37702),
			otherItemID = 36860,
			numNeeded = 1/10,
		},
		[36860] = { -- Eternal Fire
			name = GetItemInfo(36860),
			otherItemID = 37702,
			numNeeded = 10,
		},
		[37703] = { -- Crystallized Shadow
			name = GetItemInfo(37703),
			otherItemID = 35627,
			numNeeded = 1/10,
		},
		[35627] = { -- Eternal Shadow
			name = GetItemInfo(35627),
			otherItemID = 37703,
			numNeeded = 10,
		},
		[37704] = { -- Crystallized Life
			name = GetItemInfo(37704),
			otherItemID = 35625,
			numNeeded = 1/10,
		},
		[35625] = { -- Eternal Life
			name = GetItemInfo(35625),
			otherItemID = 37704,
			numNeeded = 10,
		},
		[37705] = { -- Crystallized Water
			name = GetItemInfo(37705),
			otherItemID = 35622,
			numNeeded = 1/10,
		},
		[35622] = { -- Eternal Water
			name = GetItemInfo(35622),
			otherItemID = 37705,
			numNeeded = 10,
		},
	},
}

destroyingData.vendorTrades = {
	[37101] = { -- Ivory Ink
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 1,
	},
	[39469] = { -- Moonglow Ink
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 1,
	},
	[39774] = { -- Midnight Ink
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 1,
	},
	[43116] = { -- Lion's Ink
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 1,
	},
	[43118] = { -- Jadefire Ink
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 1,
	},
	[43120] = { -- Celestial Ink
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 1,
	},
	[43122] = { -- Shimmering Ink
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 1,
	},
	[43124] = { -- Ethereal Ink
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 1,
	},
	[43126] = { -- Ink of the Sea
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 1,
	},
	[61981] = { -- Inferno Ink
		matID = 79254,
		mat = destroyingData.mill[1][79254],
		num = 10,
	},
}

destroyingData.notDisenchantable = {
	[20406] = true,
	[20407] = true,
	[20408] = true,
	[11287] = true,
	[11288] = true,
	[11289] = true,
	[11290] = true,
}

function TSMAPI:GetDestroyingConversionNum(mode, targetID, matID)
	local altID, altNeeded
	if destroyingData.vendorTrades[targetID] and targetID ~= 61981 then -- Inferno Ink is special
		altNeeded = destroyingData.vendorTrades[targetID].num
		altID = destroyingData.vendorTrades[targetID].matID
	end
	
	if targetID == matID then return 1 end
	if altID == matID then return altNeeded end
	
	if mode == "mill" then
		for i=1, #destroyingData.mill do
			local data = destroyingData.mill[i][targetID]
			if data then
				if data.pigment == matID then
					return data.pigmentPerInk
				end
				for j=1, #data.herbs do
					if data.herbs[j].itemID == matID then
						return (5 / data.herbs[j].pigmentPerMill) * data.pigmentPerInk
					end
				end
			end
			local altData = destroyingData.mill[i][altID]
			if altData then
				if altData.pigment == matID then
					return altNeeded * altData.pigmentPerInk
				end
				for j=1, #altData.herbs do
					if altData.herbs[j].itemID == matID then
						return altNeeded * (5 / altData.herbs[j].pigmentPerMill) * altData.pigmentPerInk
					end
				end
			end
		end
	elseif mode == "prospect" then
		for i=1, #destroyingData.prospect do
			local data = destroyingData.prospect[i][targetID]
			if data then
				for j=1, #data.gems do
					if data.gems[j] == matID then
						return 1
					end
				end
				for j=1, #data.ore do
					if data.ore[j].itemID == matID then
						return (5 / data.ore[j].gemPerProspect), true
					end
				end
			end
		end
	elseif mode == "disenchant" then
		if destroyingData.notDisenchantable[matID] then return end
		local rarity, ilvl, _, class = select(3, GetItemInfo(matID))
		for i=1, #destroyingData.disenchant do
			local data = destroyingData.disenchant[i][targetID]
			if data and data.itemTypes and data.itemTypes[class] and data.itemTypes[class][rarity] then
				for _, iData in ipairs(data.itemTypes[class][rarity]) do
					if ilvl >= iData.minItemLevel and ilvl <= iData.maxItemLevel then
						return TSMAPI:SafeDivide(1, iData.amountOfMats)
					end
				end
			end
		end
	elseif mode == "transform" then
		for i=1, #destroyingData.transform do
			local data = destroyingData.transform[i][targetID]
			if data and matID == data.otherItemID then
				return data.numNeeded
			end
		end
	end
end