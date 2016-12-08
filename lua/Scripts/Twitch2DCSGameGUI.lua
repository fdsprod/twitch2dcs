local base = _G

package.path  = package.path..";.\\LuaSocket\\?.lua;"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'
package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

module("Twitch2DCS")

local require           = base.require
local os 			    = base.os
local io 			    = base.io
local table             = base.table
local string            = base.string
local math              = base.math
local assert        	= base.assert
local pairs         	= base.pairs

local lfs 			    = require('lfs')
local net               = require('net')
local DCS               = require("DCS") 
local MulChat 			= require('mul_chat')

local Tracer 			= require('twitch.tracer')
local Config 			= require('twitch.config')
local Server 			= require('twitch.server')
local UI 			    = require('twitch.uitracer')

local Twitch = { 
    config = nil,
    server = nil,
    ui = nil,
    joinPartSkin = nil,
    userSkins = {},
}

local twitch = nil

function twitch:new() 
    local self = {}
      
    setmetatable(self, Twitch)

    self.__index = self    

    self.config = Config:new(lfs.writedir() .. 'Config/Twitch2DCSConfig.lua')
    self.server = Server:new(self.config.hostAddress, self.config.port)
    self.ui = UI:new(self.config.hotkey, self.config.mode, self.config.windowPosition.x, self.config.windowPosition.y)
    self.joinPartSkin = self.ui.skinFactory:getSkin()

    self.joinPartSkin.skinData.states.released[2].text.color =  self.config.skins.joinPartColor

    if self.config.username ~= nil and self.config.username ~= "" then
        local color = self.config.skins.selfColor   
        local userSkin = self.ui.skinFactory:getSkin()
        
        userSkin.skinData.states.released[2].text.color =  color
        self.userSkins[self.config.username] = userSkin
    end

    return self;
end

function twitch:getSkinForUser(user) 
    if not self.userSkins[user] then    
        local userSkin = self.ui.skinFactory:getSkin()
        local color = self.config.skins.messageColors[math.random(#self.config.skins.messageColors)]
        
        userSkin.skinData.states.released[2].text.color =  color
        
        self.userSkins[user] = userSkin
    end

    return self.userSkins[user]
end

function twitch:canLogin()
    return (self.config.username ~= nil and self.config.username ~= '') and 
           (self.config.oathToken ~= nil and self.config.oathToken ~= '')
end

function twitch:onUISendMessage(args)
    local username = self.config.username
    local skin = self:getSkinForUser()

    self.server:send("PRIVMSG #"..username.." :"..self.message)
    self.ui:addMessage(self:getTimeStamp().." "..username..": "..self.message, skin)
end

function twitch:onUIModeChanged(args)
    self.config.mode = args.mode
    self.config:save()
end

function twitch:onUIPositionChanged(args)
    self.config.windowPosition.x = args.x
    self.config.windowPosition.y = args.y
    self.config:save()
end

function twitch:onUserPart(cmd)
    self.ui:addMessage(self:getTimeStamp().." "..cmd.user.." left.", self.joinPartSkin)
end

function twitch:onUserJoin(cmd)
    self.ui:addMessage(self:getTimeStamp().." "..cmd.user.." joined.", self.joinPartSkin)
end

function twitch:onUserMessage(cmd)
    local skin = self:getSkinForUser(self.config.username)
    self.ui:addMessage(self:getTimeStamp().." "..cmd.user..": "..cmd.param2, skin)
end

function twitch:connect() 
    self.server:addCommandHandler("PRIVMSG", twitch:onUserMessage)
    self.server:addCommandHandler("JOIN", twitch:onUserJoin)
    self.server:addCommandHandler("PART", twitch:onUserPart)

    self.ui:setCallbacks(self)

    self.server:connect(
        self.config.username, 
        self.config.oauthToken, 
        self.config.caps, 
        self.config.timeout)
end

function twitch:onSimulationFrame()
    if twitch == nil then
        twitch = Twitch:new()
        twitch:connect()
    end

    if not twitch:canLogin() then 
        return
    end
    
    self.server:receive()
end 

function twitch:getTimeStamp()
    local date = os.date('*t')
	return string.format("%i:%02i:%02i", date.hour, date.min, date.sec)
end

DCS.setUserCallbacks(twitch)

net.log("Loaded - Twitch2DCS GameGUI")