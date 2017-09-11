-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Warehousing") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local move = TSM:NewModule("move", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local m = {
    srcItem = nil, 
    destItem = nil, 
    need = nil,
    srcIndex = nil,
    srcBag = nil,   
    srcSlot = nil,
    srcQuan = nil,
    itemtype = nil,
    destIndex = nil, 
    stackSize = nil,
    maxSize = nil,
    destBag = nil,
    destSlot = nil,
    src = nil,
    dest = nil,
    grp = nil,
    grpIndex = 1,
    destString = nil,
    srcString = nil,
    count=1
}

function move:moveGroup(src, dest, grp)
    
    assert(src == "bank" or src == "guildbank" or src == "bags", "Invalid source name: "..src..". Expected \"bank\" or \"guildbank\" or \"bags\"")
    assert(dest == "bank" or dest == "guildbank" or dest == "bags", "Invalid source name: "..dest..". Expected \"bank\" or \"guildbank\" or \"bags\"")
    assert(src ~= dest,"Source and destination cannot be the same")
    
    m.destString = dest
    m.srcString = src
    
    local isGuildBank = false
    if dest == "guildbank" then
        isGuildBank = true
    else
        isGuildBank = false
    end
    
    TSM.util:setSrcBagFunctions(src)
    TSM.util:setDestBagFunctions(dest)   
    
    local src  = move:getContainerTable(src)
    local dest = move:getContainerTable(dest)
    
    --get src table
    --local srcData = move:ScanSrc( src )
    local emptySlots = move:GetEmptySlots(dest)

    local grpData,srcData = move:getGroupTable(grp,src,isGuildBank)
    
    if srcData and grpData and emptySlots then 
        TSM:Print("Begin")
        move:reset()
        move:moveStuff(grpData,srcData,emptySlots)
    end
    
end--move:moveGroup

function move:GetEmptySlots(container)
	local emptySlots = {}
	for i,bag in ipairs(container) do
		if TSM.util.getContainerNumSlotsDest(bag) > 0 then
			for slot=1, TSM.util.getContainerNumSlotsDest(bag) do
				if not TSM.util.getContainerItemIDDest(bag, slot) then
                    if not emptySlots[bag] then emptySlots[bag] = {} end
                    table.insert(emptySlots[bag],slot)
				end
			end
		end
	end
	return emptySlots
end

function move:printSrcTable(srcTable)
    for i,v in pairs(srcTable) do 
        print (i)
        for j,w in pairs(v) do
            print ("     ",w.bag, w.slot, w.quantity)
        end
    end 
end

local bagEvent = CreateFrame("frame")
bagEvent:Hide()
bagEvent.timeout = 1
bagEvent.type = nil
bagEvent:SetScript("OnHide",function(self)
    if  m.destString == "guildbank" or m.srcString == "guildbank" then 
        self:UnregisterEvent("GUILDBANKBAGSLOTS_CHANGED")
    else
        self:UnregisterEvent("BAG_UPDATE") 
    end
end)
bagEvent:SetScript("OnShow",function(self) 
    if  m.destString == "guildbank" or m.srcString == "guildbank" then
        self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
        self.timeout = TSM.db.global.DefaultTimeOut
    else
        self:RegisterEvent("BAG_UPDATE")
        self.timeout = .2
    end
    self.timeLeft = self.timeout     
end)
bagEvent:SetScript("OnEvent", function(self) 
    if not move:areBanksVisible() then 
        self:Hide()
        return 
    end
end)
bagEvent:SetScript("OnUpdate", function(self, elapsed)
    if elapsed then self.timeLeft = self.timeLeft - elapsed end
    if self.timeLeft <= 0 then 
        self:Hide()
        move:moveStuff(m.grp,m.src,m.dest) 
    end
end)

local timeout = CreateFrame("frame")
timeout:Hide()
timeout.timeout = 2
timeout.type = nil
timeout:SetScript("OnUpdate", function(self, elapsed)
		self.timeLeft = self.timeLeft - elapsed
		if self.timeLeft <= 0 then
			self:Hide()
            TSM:UpdatePlayerBagState()
            TSM:Print ("Done.")
		end
	end)
timeout:SetScript("OnHide",function(self)
    if  m.destString == "guildbank" or m.srcString == "guildbank" then 
        self:UnregisterEvent("GUILDBANKBAGSLOTS_CHANGED")
    else
        self:UnregisterEvent("BAG_UPDATE") 
    end
end)
timeout:SetScript("OnShow",function(self) 
    if  m.destString == "guildbank" or m.srcString == "guildbank" then
        self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
        self.timeout = 2
    else
        self:RegisterEvent("BAG_UPDATE")
        self.timeout = .2
    end
    self.timeLeft = self.timeout     
end)
timeout:SetScript("OnEvent", function(self) self.timeLeft = self.timeout end)

function move:moveItem()
    if not move:areBanksVisible() then return end
    
    local _, link = GetItemInfo( m.srcItem)
    
    if m.srcQuan > m.need then
    
        local destBag = TSM.util:canGoInBag(m.srcItem, m.dest)
        local destSlot = m.dest[destBag][#m.dest[destBag]] 
        TSM.util.splitContainerItemSrc(m.srcBag, m.srcSlot, m.need)
        TSM.util.pickupContainerItemDest(destBag, destSlot)
        
        if TSM.db.global.ShowLogData then TSM:Print (link, " ", m.need, "moved still need", 0)end
        
        m.need = 0
        
        table.remove (m.dest[destBag])
        if #m.dest[destBag] == 0 then m.dest[destBag] = nil end
    else 
        TSM.util.autoStoreItem(m.srcBag, m.srcSlot)
        m.need = m.need - m.srcQuan
        if TSM.db.global.ShowLogData then TSM:Print (link, " ", m.srcQuan, "moved still need", m.need)end
    end
   
    m.src[m.srcItem][m.srcIndex].quantity = m.src[m.srcItem][m.srcIndex].quantity - m.srcQuan
    if m.src[m.srcItem][m.srcIndex].quantity == 0 then m.src[m.srcItem][m.srcIndex] = nil end
    
    bagEvent:Show()

end

function move:moveStuff(grp,src,dest)
        
    if not move:areBanksVisible() then return end
    
    m.grp = grp
    m.src = src
    m.dest = dest
    
    if #m.grp >= m.grpIndex then --iterator
        
        m.srcItem = m.grp[m.grpIndex].item
        
        local _, link = GetItemInfo( m.srcItem)
        if not m.need then m.need = m.grp[m.grpIndex].quantity end
        
        if m.need == 0 or ( m.src[ m.srcItem] and #m.src[ m.srcItem] == 0 ) then  
            m.src[m.srcItem] = nil 
            m.grpIndex = m.grpIndex + 1
            m.need = nil
            move:moveStuff(m.grp,m.src,m.dest)
            return
        end
        
        if  m.src[ m.srcItem] then
           
            m.srcIndex  = #m.src[m.srcItem]
            m.srcBag    = m.src[m.srcItem][m.srcIndex].bag
            m.srcSlot   = m.src[m.srcItem][m.srcIndex].slot
            m.srcQuan   = m.src[m.srcItem][m.srcIndex].quantity
            
            local _, link = GetItemInfo( m.srcItem)
            move:moveItem()
            
        else
             m.need = 0
             move:moveStuff(m.grp,m.src,m.dest)
        end  
    else
        --we are done now
        timeout:Show()
    end
    
end

function move:reset()
    m.srcItem = nil 
    m.need = nil
    m.srcIndex = nil
    m.srcBag = nil   
    m.srcSlot = nil
    m.srcQuan = nil
    m.itemtype = nil
    m.destIndex = nil 
    m.stackSize = nil
    m.maxSize = nil
    m.destBag = nil
    m.destSlot = nil
    m.grpIndex = 1
    m.count = 1
end

function move:getGroupTable(grpName,src,isGuildBank)

    if grpName == "all" then
        return TSM.data:getEmptyRestoreGroup(src ,isGuildBank),TSM.data:ScanSrc(src)
    elseif grpName == "restore" then
        return TSM.db.factionrealm.BagState,TSM.data:ScanSrc(src)
    else --warehousing/crafting/auctioning
        local module,grp = strsplit(":",grpName)
        if string.lower(module) == "warehousing" then
            local data = TSM.bankui:getWarehouseTable(grp)
            if data then
                return TSM.data:unIndexTableWarehousing(data),TSM.data:ScanSrc(src)
            end
        elseif string.lower(module) == "auctioning" then
            local data = TSMAPI:GetData("auctioningGroups")
            if data[grp] then 
                return TSM.data:unIndexTableAuctioning2(src,data[grp]),TSM.data:ScanSrc(src)
            end
        elseif string.lower(module) == "categories" then
            local data = TSMAPI:GetData("auctioningCategories")
            if data[grp] then 
                return --not done yet
            end
        elseif string.lower(module) == "crafting" then
            local data = TSMAPI:GetData("shopping", grp)
            if data and grp then
                local newData,stuff = TSM.data:unIndexTableCrafting(data,grp) 
                return newData, TSM.data:ScanSrcForCrafting(src,grp,stuff)
            end
        end
    end
    
    TSM:Print("Group/Queue may not exist.")
    
end

function move:getContainerTable(cnt)
    local t = {}
    
    if cnt == "bank" then       
        local numSlots, _ = GetNumBankSlots()

        for i=1, numSlots +1 do 
            if i == 1 then
                t[i] = -1
            else
                t[i] = i+3
            end
        end
        
        return t
        
    elseif cnt == "guildbank" then
        for i=1, GetNumGuildBankTabs() do 
            local canView, canDeposit, stacksPerDay = GetGuildBankTabInfo(i);
            if canView and canDeposit and stacksPerDay then   
            t[i] = i
            end
        end
        
        return t
    elseif cnt == "bags" then
        for i=1,NUM_BAG_SLOTS+1  do t[i] = i-1 end
        
        return t
        
    end
    
end

function move:areBanksVisible()
    if BagnonFrameguildbank and BagnonFrameguildbank:IsVisible() then
        return true
    elseif BagnonFramebank and BagnonFramebank:IsVisible() then
        return true
    elseif GuildBankFrame and GuildBankFrame:IsVisible() then
        return true
    elseif BankFrame and BankFrame:IsVisible() then
        return true
    elseif (ARKINV_Frame4 and ARKINV_Frame4:IsVisible()) or (ARKINV_Frame3 and ARKINV_Frame3:IsVisible())then
        return true
    elseif (BagginsBag8 and BagginsBag8:IsVisible()) or (BagginsBag9 and BagginsBag9:IsVisible()) or 
           (BagginsBag10 and BagginsBag10:IsVisible()) or (BagginsBag11 and BagginsBag11:IsVisible()) or 
           (BagginsBag12 and BagginsBag12:IsVisible()) then
        return true
    elseif (CombuctorFrame2 and CombuctorFrame2:IsVisible()) then
        return true
    elseif (BaudBagContainer2_1 and BaudBagContainer2_1:IsVisible()) then
        return true
    elseif (AdiBagsContainer2 and AdiBagsContainer2:IsVisible()) then
        return true
    elseif (OneBankFrame and OneBankFrame:IsVisible()) then
        return true
    elseif (EngBank_frame and EngBank_frame:IsVisible()) then
        return true
    elseif (TBnkFrame and TBnkFrame:IsVisible()) then
        return true
    elseif (famBankFrame and famBankFrame:IsVisible()) then
        return true
    elseif (LUIBank and LUIBank:IsVisible())then
        return true
    elseif (ElvUINormBag1_1 and ElvUINormBag1_1:IsVisible())then
        return true
    end
    bagEvent:Hide()
    TSM:Print("Canceled")
    return nil
end
