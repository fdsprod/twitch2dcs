local base = _G

package.path  = package.path..";.\\LuaSocket\\?.lua;"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'..lfs.writedir()..'Scripts\\?.lua;'
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

local tracer 			= require('twitch.tracer')
local Config 			= require('twitch.config')
local Server 			= require('twitch.server')
local UI 			    = require('twitch.ui')

local TwitchClient = { 
    config = nil,
    server = nil,
    ui = nil,
    joinPartSkin = nil,
    userSkins = {},
    nextUserIndex = 1
}
local TwitchClient_mt = { __index = TwitchClient }
local client = nil

function TwitchClient:new() 
    local self = base.setmetatable(self, TwitchClient_mt)

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

    if self.config.mode == self.ui.modes.write then
        self.ui:readMode()
    else
        self.ui:writeMode()
    end

    return self;
end

function TwitchClient:getSkinForUser(user) 
    if not self.userSkins[user] then    
        local userSkin = self.ui.skinFactory:getSkin()
        local color = self.config.skins.messageColors[self.nextUserIndex]

        userSkin.skinData.states.released[2].text.color =  color        
        self.userSkins[user] = userSkin        
        
        self.nextUserIndex = self.nextUserIndex + 1

        if self.nextUserIndex > table.getn(self.config.skins) then
            self.nextUserIndex = 1
        end

        tracer:info("User "..user.." gets color r:"..color.r.." g:"..color.g.." b:"..color.b)
    end

    return self.userSkins[user]
end

function TwitchClient:canLogin()
    return (self.config.username ~= nil and self.config.username ~= '') and 
           (self.config.oathToken ~= nil and self.config.oathToken ~= '')
end

function TwitchClient.onUISendMessage(args)
    local username = client.config.username
    local skin = client:getSkinForUser(username)

    client.server:send("PRIVMSG #"..username.." :"..args.message)
    client.ui:addMessage(client:getTimeStamp().." "..username..": "..args.message, skin)
end

function TwitchClient.onUIModeChanged(args)
    client.config.mode = args.mode
    client.config:save()
end

function TwitchClient.onUIPositionChanged(args)
    client.config.windowPosition.x = args.x
    client.config.windowPosition.y = args.y
    client.config:save()
end

function TwitchClient.onUserPart(cmd)
    client.ui:addMessage(client:getTimeStamp().." "..cmd.user.." left.", client.joinPartSkin)
end

function TwitchClient.onUserJoin(cmd)
    client.ui:addMessage(client:getTimeStamp().." "..cmd.user.." joined.", client.joinPartSkin)
end

function TwitchClient.onUserMessage(cmd)
    local skin = client:getSkinForUser(cmd.user)
    client.ui:addMessage(client:getTimeStamp().." "..cmd.user..": "..cmd.param2, skin)
end

function TwitchClient:connect() 
    self.server:addCommandHandler("PRIVMSG", self.onUserMessage)
    self.server:addCommandHandler("JOIN", self.onUserJoin)
    self.server:addCommandHandler("PART", self.onUserPart)

    self.ui:setCallbacks(self)

    self.server:connect(
        self.config.username, 
        self.config.oathToken, 
        self.config.caps, 
        self.config.timeout)
end

function TwitchClient:receive() 
    self.server:receive()
end

function TwitchClient:getTimeStamp()
    local date = os.date('*t')
	return string.format("%i:%02i:%02i", date.hour, date.min, date.sec)
end

local callacks = { 
    onSimulationFrame = function() 
        if client == nil then
            client = TwitchClient:new()

            if not client:canLogin() then 
                tracer:warn("Unable to login, please add your twitch username and oauth key to Config/Twitch2DCSConfig.lua")
                return
            end
        
            client:connect()
        end

        if not client:canLogin() then 
            return
        end
        
        client:receive()
    end
}

DCS.setUserCallbacks(callacks)

net.log("Loaded - Twitch2DCS GameGUI")