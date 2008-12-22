--[[
SimpleMarker/SimpleMarker.lua

Copyright 2008 Quaiche

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

local defaults = {
	profile = {
		isLocked = false,
		point = "CENTER",
		relativePoint = "CENTER",
		xOfs = 0,
		yOfs = 0,
		scale = 0.8,
	}
}

local function SaveFrameLocation(frame)
	db.point, _, db.relativePoint, db.xOfs, db.yOfs = frame:GetPoint()
end

local options = {
	type = "group",
	handler = SimpleMarker,
	args = {
		lock = {
			name = "Lock",
			desc = "Lock/unlock the raid marks frame.",
			type = "toggle",
			get = function(info) return db.isLocked end,
			set = function(info, val) SimpleMarker:ToggleFrameLock() end,
		},

		scale = {
			name = "Scale",
			desc = "Sets the frame scale",
			type = "range",
			min = 0.25,
			max = 2.0,
			step = 0.05,
			get  = function(info) return db.scale end,
			set = function(info,val) SimpleMarker:SetFrameScale(val) end,
		},

		reset = {
			name = "Reset",
			desc = "Reset position to the center of the screen",
			type = "execute",
			func = function(info)
				SimpleMarker:SetFrameScale(defaults.profile.scale)
				SimpleMarker.frame:SetPoint(defaults.profile.point, UIParent, defaults.profile.relativePoint, defaults.profile.xOfs, defaults.profile.yOfs)
				SaveFrameLocation(SimpleMarker.frame)
			end
		},

		config = {
			name = "Config",
			desc = "Opens the configuration dialog",
			type = "execute",
			func = function(info) LibStub("AceConfigDialog-3.0"):Open("SimpleMarker") end,
			guiHidden = true,
		},
	}
}

--[[ Constructor ]]
function SimpleMarker:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SimpleMarkerDB", defaults, "Default")
	db = self.db.profile

	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "CheckFrameVisibility")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "CheckFrameVisibility")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "CheckFrameVisibility")

	LibStub("AceConfig-3.0"):RegisterOptionsTable("SimpleMarker", options, {"simplemarker"} )

	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SimpleMarker", "SimpleMarker")
	LibStub("tekKonfig-AboutPanel").new("SimpleMarker", "SimpleMarker")
end

local function CreateAnchorFrame()
	-- Parent anchor frame
	local frame = CreateFrame("Frame", "SimpleMarker_Frame", UIParent)
	frame:SetWidth(176)
	frame:SetHeight(32)
	frame:SetPoint(db.point, UIParent, db.relativePoint, db.xOfs, db.yOfs)
	frame:SetScale(db.scale)
	frame:Hide()

	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() this:StartMoving() end )
	frame:SetScript("OnDragStop", function() 
		this:StopMovingOrSizing() 
		SaveFrameLocation(this)
	end)

	frame.buttons = {}
	for i = 0,8 do
		local button = CreateFrame("Button", nil, frame)
		button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8+(-18*i), -8)
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

		frame.buttons[i] = button
	end

	return frame
end

function SimpleMarker:OnEnable()
	self.frame = CreateAnchorFrame()
	self:CheckFrameDraggable()
	self:CheckFrameVisibility()
end

local function CanSetRaidMarks()
	return (GetNumPartyMembers() > 0 and IsPartyLeader()) or
				 (GetNumRaidMembers() > 0 and (IsRaidLeader() or IsRaidOfficer()))
end

function SimpleMarker:CheckFrameVisibility()
	if (not db.isLocked) or (CanSetRaidMarks() and UnitExists("target")) then
		self.frame:Show()
	else
		self.frame:Hide()
	end
end

function SimpleMarker:ToggleFrameLock()
	db.isLocked = not db.isLocked
	self:CheckFrameDraggable()
	self:CheckFrameVisibility()
end

function SimpleMarker:CheckFrameDraggable()
	local frame = self.frame
	if not db.isLocked then
		frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})

		frame:SetMovable(true)
		frame:EnableMouse(true)
		for i = 0,8 do 
			frame.buttons[i]:Disable() 
			frame.buttons[i]:EnableMouse(false)
		end
	else
		frame:SetBackdrop(nil)
		frame:SetMovable(false)
		frame:EnableMouse(false)
		for i = 0,8 do 
			frame.buttons[i]:Enable() 
			frame.buttons[i]:EnableMouse(true)
		end
	end
end

function SimpleMarker:SetFrameScale(val)
	db.scale = val
	local frame = self.frame
	if frame then
		frame:SetScale(val)
	end
end

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

--[[ Setup the LDB launcher ]]
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
if LDB then 
	LDB:NewDataObject("SimpleMarker", {
		type = "launcher",
		icon = "Interface\\AddOns\\SimpleMarker\\Icon",
		text = "SimpleMarker",
		OnClick = function(frame, button)
			SimpleMarker:ToggleFrameLock() 
		end,
		OnEnter = function(frame)
			GameTooltip:SetOwner(frame, "ANCHOR_NONE")
			GameTooltip:SetPoint(GetTipAnchor(frame))
			GameTooltip:ClearLines()

			GameTooltip:AddLine("SimpleMarker")
			GameTooltip:AddLine("")
			GameTooltip:AddLine("Click to display the draggable anchor frame")

			GameTooltip:Show()
		end,
		OnHide = function()
			GameTooltip:Hide()
		end,
	})
end
