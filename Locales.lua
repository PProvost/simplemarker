--[[
SimpleMarker/Locales.lua

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

local AceLocale = LibStub("AceLocale-3.0")

local L = AceLocale:NewLocale("SimpleMarker", "enUS", true)
if L then
	L["SYMBOL_NAME_BLANK"] = "Blank"
	L["SYMBOL_NAME_STAR"] = "Star"
	L["SYMBOL_NAME_CIRCLE"] = "Circle"
	L["SYMBOL_NAME_DIAMOND"] = "Diamond"
	L["SYMBOL_NAME_TRIANGLE"] = "Triangle"
	L["SYMBOL_NAME_MOON"] = "Moon"
	L["SYMBOL_NAME_SQUARE"] = "Square"
	L["SYMBOL_NAME_CROSS"] = "Cross"
	L["SYMBOL_NAME_SKULL"] = "Skull"
end
