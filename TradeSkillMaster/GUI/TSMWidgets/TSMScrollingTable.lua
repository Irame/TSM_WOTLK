-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Type, Version = "TSMScrollingTable", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local private = {widgets={}}


-- ============================================================================
-- Widget Methods
-- ============================================================================

local methods = {
	["OnAcquire"] = function(self)
		self.st.rowData = nil
	end,

	["OnRelease"] = function(self)
		self.tag = nil
		self:SetData()
		self:SetColInfo()
		self:SetHeadFontSize()
		self:SetHandler()
	end,
	
	["OnWidthSet"] = function(self, width)
		self.st:SetAllPoints()
		self.st:Redraw()
	end,
	
	["OnHeightSet"] = function(self, height)
		self.st:SetAllPoints()
		self.st:Redraw()
	end,
	
	["SetTag"] = function(self, tag)
		TSMAPI:Assert(type(tag) == "string")
		TSMAPI:Assert(not private:GetSTWidgetFromTag(tag), "Widget with the specified tag already exists")
		self.tag = tag
	end,
	
	["SetHeadFontSize"] = function(self, ...)
		self.st:SetHeadFontSize(...)
	end,
	
	["SetColInfo"] = function(self, ...)
		self.st:SetColInfo(...)
	end,
	
	["SetHandler"] = function(self, ...)
		self.st:SetHandler(...)
	end,
	
	["SetData"] = function(self, ...)
		self.st:SetData(...)
	end,
	
	["EnableSorting"] = function(self, ...)
		self.st:EnableSorting(...)
	end,
	
	["DisableSelection"] = function(self, ...)
		self.st:DisableSelection(...)
	end,
}


-- ============================================================================
-- Constructor
-- ============================================================================

local function Constructor()
	local frame = CreateFrame("Frame")

	local st = TSM:CreateScrollingTable(frame)
	
	local widget = {
		frame = frame,
		st = st,
		tag = nil,
		type = Type,
	}
	
	for method, func in pairs(methods) do
		widget[method] = func
	end

	tinsert(private.widgets, widget)
	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function private:GetSTWidgetFromTag(tag)
	for _, widget in ipairs(private.widgets) do
		if widget.tag == tag then
			return widget
		end
	end
end

function TSMAPI.GUI:UpdateTSMScrollingTableData(tag, data)
	TSMAPI:Assert(type(tag) == "string")
	local widget = private:GetSTWidgetFromTag(tag)
	if widget then
		widget:SetData(data)
	end	
end