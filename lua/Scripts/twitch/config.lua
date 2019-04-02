local base = _G

module("twitch.config")

local require = base.require
local table = base.table
local string = base.string
local math = base.math
local type = base.type
local assert = base.assert
local pairs = base.pairs
local ipairs = base.ipairs

local OptionsData = require('Options.Data')
local utils = require('twitch.utils')

Config = {}

local Config_mt = { __index = Config }

function Config:new()
	local config = base.setmetatable({}, Config_mt)
	return config
end

function Config:getOption(name)
	return OptionsData.getPlugin("Twitch2DCS", name)
end

function Config:setOption(name, value)
	OptionsData.setPlugin("Twitch2DCS", name, value)
	OptionsData.saveChanges()
end

function Config:isEnabled()
	return self:getOption("isEnabled")
end

function Config:getPosition()
	return self:getOption("position")
end

function Config:getMessageColors()
	return self:getOption("messageColors")
end

function Config:getFontSize()
	return self:getOption("fontSize")
end

function Config:getHideShowHotkey()
	return self:getOption("hideShowHotkey")
end

function Config:getJoinPartColor()
	return utils.rgbToHex(self:getOption("joinPartColor"))
end

function Config:getShowJoinPartMessages()
	return self:getOption("showJoinPart")
end

function Config:getSelfColor()
	return utils.rgbToHex(self:getOption("selfColor"))
end

function Config:getLockUIPosition()
	return self:getOption("lockUIPosition")
end

function Config:setPosition(value)
	return self:getOption("position", value)
end

function Config:getAuthInfo()
	return {
		username = self:getOption("username"),
		oauthToken = self:getOption("oauth"),
		hostAddress = self:getOption("hostAddress"),
		port = self:getOption("port"),
		caps = self:getOption("caps"),
		timeout = self:getOption("timeout"),
	}
end

return Config
