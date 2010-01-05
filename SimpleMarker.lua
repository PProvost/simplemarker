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

local addonName = "SimpleMarker"

local L = setmetatable({}, {__index=function(t,i) return i end})

local function Print(...) print("|cFF33FF99"..addonName.."|r:", ...) end
local function Debug(...) local debugf = tekDebug and tekDebug:GetFrame(addonName); if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end end
local function CanSetRaidMarks() return (GetNumPartyMembers() > 0 and GetNumRaidMembers() == 0) or (GetNumRaidMembers() > 0 and (IsRaidLeader() or IsRaidOfficer())) end
local function GetTipAnchor(frame)
	local x,y = frame:GetCenter(); if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end
local function GetSlashCommand(msg) -- returns: command, args
	if msg then
		local a,b,c = string.find(msg, "(%S+)");
		if a then return c, string.sub(msg, b+2); else	return ""; end
	end
end

local iconNames = {
	[0] = L["Blank"],
	[1] = L["Star"],
	[2] = L["Circle"],
	[3] = L["Diamond"],
	[4] = L["Triangle"],
	[5] = L["Moon"],
	[6] = L["Square"],
	[7] = L["Cross"],
	[8] = L["Skull"],
}

local db
local defaults = {
	isLocked = true,
	point = "CENTER",
	relativePoint = "CENTER",
	xOfs = 0,
	yOfs = 0,
	scale = 0.8,
	alpha = 1.0,
}

--[[ Addon frame ]]
SimpleMarker = CreateFrame("Frame")
SimpleMarker:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end )
SimpleMarker:RegisterEvent("ADDON_LOADED")

function SimpleMarker:ADDON_LOADED(event, addon)
  if addon:lower() ~= "simplemarker" then return end
 
  SimpleMarkerDB = setmetatable(SimpleMarkerDB or {}, {__index = defaults})
  db = SimpleMarkerDB
 
	self:RegisterEvent("PARTY_MEMBERS_CHANGED"); self.PARTY_MEMBERS_CHANGED = self.CheckFrameVisibility
	self:RegisterEvent("RAID_ROSTER_UPDATE"); self.RAID_ROSTER_UPDATE = self.CheckFrameVisibility
	self:RegisterEvent("PLAYER_TARGET_CHANGED"); self.PLAYER_TARGET_CHANGED = self.CheckFrameVisibility

	self:SetupLDBLauncher()
	self:SetupSlashCommands()
 
  LibStub("tekKonfig-AboutPanel").new(nil, addonName) -- Make first arg nil if no parent config panel
 
  self:UnregisterEvent("ADDON_LOADED")
  self.ADDON_LOADED = nil
 
  if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end
 
function SimpleMarker:PLAYER_LOGIN()
  self:RegisterEvent("PLAYER_LOGOUT")
 
	self:CreateAnchorFrame()
	self:CheckFrameDraggable()
	self:CheckFrameVisibility()
 
  self:UnregisterEvent("PLAYER_LOGIN")
  self.PLAYER_LOGIN = nil
end
 
function SimpleMarker:PLAYER_LOGOUT()
  for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
  -- Do anything you need to do as the player logs out
end

function SimpleMarker:CreateAnchorFrame()
	local frame = CreateFrame("Frame", "SimpleMarker_Frame", UIParent)
	frame:SetWidth(176)
	frame:SetHeight(32)
	frame:SetPoint(db.point, UIParent, db.relativePoint, db.xOfs, db.yOfs)
	frame:SetScale(db.scale)
	frame:SetAlpha(db.alpha)
	frame:Hide()

	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() this:StartMoving() end )
	frame:SetScript("OnDragStop", function() 
		this:StopMovingOrSizing() 
		self:SaveFrameLocation(this)
	end)

	frame.buttons = {}
	for i = 0,8 do
		local button = CreateFrame("Button", nil, frame)
		button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8+(-18*i), -8)
		button:SetWidth(16)
		button:SetHeight(16)
		button:RegisterForClicks("AnyUp")
		button:SetScript("OnClick", function(self) SetRaidTarget("target", i) end)
		button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		button:SetScript("OnEnter", function(self)
			GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
			GameTooltip:SetText(iconNames[i])
			GameTooltip:Show()
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

	self.frame = frame
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
	Print("Frame " .. (db.isLocked and "locked" or "unlocked"))
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
	if frame then frame:SetScale(val) end
end

function SimpleMarker:SetFrameAlpha(val)
	db.alpha = val
	local frame = self.frame
	if frame then frame:SetAlpha(val) end
end


function SimpleMarker:SetupLDBLauncher()
	local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
	if LDB then 
		LDB:NewDataObject(addonName, {
			type = "launcher",
			icon = "Interface\\AddOns\\" .. addonName .. "\\Icon",
			text = addonName,

			OnClick = function(frame, button)
				self:ToggleFrameLock() 
			end,

			OnEnter = function(frame)
				GameTooltip:SetOwner(frame, "ANCHOR_NONE")
				GameTooltip:SetPoint(GetTipAnchor(frame))
				GameTooltip:ClearLines()

				GameTooltip:AddLine(addonName)
				GameTooltip:AddLine("")
				GameTooltip:AddLine(L["Click to display the draggable anchor frame"])

				GameTooltip:Show()
			end,

			OnHide = function()
				GameTooltip:Hide()
			end,
		})
	end
end

function SimpleMarker:SaveFrameLocation(frame)
	db.point, _, db.relativePoint, db.xOfs, db.yOfs = frame:GetPoint()
end

function SimpleMarker:ResetOptions()
	SimpleMarker:SetFrameScale(defaults.scale)
	SimpleMarker:SetFrameAlpha(defaults.alpha)
	SimpleMarker.frame:SetPoint(defaults.point, UIParent, defaults.relativePoint, defaults.xOfs, defaults.yOfs)
	self:SaveFrameLocation(SimpleMarker.frame)
end

function SimpleMarker:SetupSlashCommands()
	SLASH_SIMPLEMARKER1 = L["/simplemarker"]
	SlashCmdList.SIMPLEMARKER = function(msg)
		local command, args = GetSlashCommand(msg)
		if command == "lock" then
			self:ToggleFrameLock()
		elseif command == "scale" then
			local n = tonumber(args)
			if n then self:SetFrameScale(n) else self:PrintUsage() end
		elseif command == "reset" then
			self:ResetOptions()
		elseif command == "alpha" then
			local n = tonumber(args)
			if n then	self:SetFrameAlpha(n) else self:PrintUsage() end
		else
			self:PrintUsage()
		end
	end
end

function SimpleMarker:PrintUsage()
	Print(L["Usage:"])
	print(L["/simplemarker lock - locks and unlocks the marking frame"])
	print(L["/simplemarker scale N - sets the frame scale to N"])
	print(L["/simplemarker reset - resets position and scale to defaults"])
	print(L["/simplemarker alpha N - sets the frame alpha to N"])
end
