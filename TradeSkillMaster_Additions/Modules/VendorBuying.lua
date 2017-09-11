-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Additions                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_additions           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local VendorBuying = TSM:NewModule("VendorBuying", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Additions") -- loads the localization table

function VendorBuying:OnEnable()
	-- do enable stuff
	VendorBuying:SecureHookScript(StackSplitFrame, "OnShow", function() TSMAPI:CreateTimeDelay("splitStackShowDelay", 0.05, VendorBuying.HookSplitStack) end)
	VendorBuying:SecureHookScript(StackSplitFrame, "OnHide", function() TSMAPI:CreateTimeDelay("splitStackHideDelay", 0.05, VendorBuying.UnhookSplitStack) end)
end

function VendorBuying:OnDisable()
	-- do disable stuff
	VendorBuying:UnhookAll()
end

function VendorBuying:OnSplit(num)
	-- unhook SplitStack
	VendorBuying:UnhookSplitStack()
	
	-- call original SplitStack accordingly
	while (num > 0) do
		local stackSize = min(num, StackSplitFrame.maxStack)
		num = num - stackSize
		StackSplitFrame.owner:SplitStack(stackSize)
	end
end

function VendorBuying:HookSplitStack()
	if StackSplitFrame.owner:GetParent():GetParent() ~= MerchantFrame then return end
	StackSplitFrame._maxStack = StackSplitFrame.maxStack
	StackSplitFrame.maxStack = math.huge
	StackSplitFrame.owner._SplitStack = StackSplitFrame.owner.SplitStack
	StackSplitFrame.owner.SplitStack = VendorBuying.OnSplit
end

function VendorBuying:UnhookSplitStack()
	if not StackSplitFrame.owner._SplitStack then return end
	StackSplitFrame.owner.SplitStack = StackSplitFrame.owner._SplitStack
	StackSplitFrame.owner._SplitStack = nil
	StackSplitFrame.maxStack = StackSplitFrame._maxStack
	StackSplitFrame._maxStack = nil
end