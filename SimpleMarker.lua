--[[
SimpleMarker/SimpleMarker.lua

Copyright 2008 Peter Provost

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

--[[ Addon declaration ]]
SimpleMarker = LibStub("AceAddon-3.0"):NewAddon("SimpleMarker", "AceConsole-3.0", "AceEvent-3.0")
SimpleMarker.revision = tonumber(("$Revision: 25 $"):match("%d+"))
SimpleMarker.date = ("$Date: 2008-08-22 18:50:01 -0600 (Fri, 22 Aug 2008) $"):match("%d%d%d%d%-%d%d%-%d%d")

--[[ Private locals ]]
local db = nil
local L = LibStub("AceLocale-3.0"):GetLocale("SimpleMarker")
local iconNames = {
	[0] = L["SYMBOL_NAME_BLANK"],
	[1] = L["SYMBOL_NAME_STAR"],
	[2] = L["SYMBOL_NAME_CIRCLE"],
	[3] = L["SYMBOL_NAME_DIAMOND"],
	[4] = L["SYMBOL_NAME_TRIANGLE"],
	[5] = L["SYMBOL_NAME_MOON"],
	[6] = L["SYMBOL_NAME_SQUARE"],
	[7] = L["SYMBOL_NAME_CROSS"],
	[8] = L["SYMBOL_NAME_SKULL"],
}

local options = {
	type = "group",
	handler = SimpleMarker,
	args = {
		lock = {
			name = "Lock",
			desc = "Lock/unlock the raid marks frame.",
			type = "toggle",
			get = function() return db.isLocked end,
			set = function(val) 
				db.isLocked = true
				SimpleMarker:ToggleFrameLock() 
			end,
		},

		config = {
			name = "Config",
			desc = "Opens the configuration dialog",
			type = "execute",
			func = function() LibStub("AceConfigDialog-3.0"):Open("SimpleMarker") end,
			guiHidden = true,
		}
	}
}

local defaults = {
	profile = {
		isLocked = false,
	}
}

--[[ Constructor ]]
function SimpleMarker:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SimpleMarkerDB", defaults, "Default")
	db = self.db.profile

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("SimpleMarker", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SimpleMarker", "SimpleMarker")
	LibStub("AceConfigCmd-3.0"):CreateChatCommand("simplemarker", "SimpleMarker")

	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "CheckFrameVisibility")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "CheckFrameVisibility")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "CheckFrameVisibility")
end

local function CreateSimpleMarkerFrame()
	-- Parent anchor frame
	local frame = CreateFrame("Frame", "SimpleMarker_Frame", UIParent)
	frame:SetWidth(168)
	frame:SetHeight(24)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, -155)
	frame:SetScale(0.8)
	frame:Hide()

	-- TODO: Get rid of this once I know it is in the right place
	--[[
	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	frame:SetBackdropColor(0.25,0.25,0.25,1)
	frame:SetBackdropBorderColor(0.75,0.75,0.75,1)
	]]

	for i = 0,8 do
		local button = CreateFrame("Button", nil, frame)
		button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4+(-18*i), -4)
		button:SetWidth(16)
		button:SetHeight(16)
		button:RegisterForClicks("AnyUp")
		button:SetScript("OnClick", function(self)
			SetRaidTarget("target", i)
		end)
		button:SetScript("OnEnter", function(self)
			GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
			GameTooltip:SetText(iconNames[i])
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		local raidIcon = button:CreateTexture(nil, "ARTWORK")
		raidIcon:SetAllPoints()
		if i == 0 then
			raidIcon:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
			raidIcon:SetVertexColor(0,0,0)
		else
			raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
			SetRaidTargetIconTexture(raidIcon, i)
		end
	end

	return frame
end

function SimpleMarker:OnEnable()
	self.frame = CreateSimpleMarkerFrame()
end

local function CanSetRaidMarks()
	return (GetNumPartyMembers() > 0 and IsPartyLeader()) or
				 (GetNumRaidMembers() > 0 and (IsRaidLeader() or IsRaidOfficer()))
end

function SimpleMarker:CheckFrameVisibility()
	if CanSetRaidMarks() and UnitExists("target") then
		self.frame:Show()
	else
		self.frame:Hide()
	end
end

function SimpleMarker:ToggleFrameLock()
	-- TODO
end
