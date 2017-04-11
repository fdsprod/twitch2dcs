
local status, err = pcall(function() 
    local base = _G

    package.path  = package.path..";.\\LuaSocket\\?.lua;"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'..lfs.writedir()..'Scripts\\?.lua;'
    package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

    module("Twitch2DCS")

    local os 			    = base.os
    local require           = base.require
    local io 			    = base.io
    local table             = base.table
    local string            = base.string
    local math              = base.math
    local assert        	= base.assert
    local pairs         	= base.pairs
    local ipairs         	= base.ipairs
    local world             = base.world

    local lfs 			    = require('lfs')
    local net               = require('net')
    local DCS               = require("DCS") 
    local MulChat 			= require('mul_chat')
    local OptionsData	    = require('Options.Data')

    local utils 			= require('twitch.utils')
    local tracer 			= require('twitch.tracer')
    local Server 			= require('twitch.server')
    local UI 			    = require('twitch.ui')

    function table.removeValue(t, value)

        local remove = {}
        for i,v in ipairs(t) do
            if v == value then
                    table.insert(remove, i)
            end
        end

        for i,v in ipairs(remove) do
                table.remove(t, v)
        end
    end

    local TwitchClient = { 
        server = nil,
        ui = nil,
        joinPartSkin = nil,
        userSkins = {},
        nextUserIndex = 1,
        userNames = {}
    }
    local TwitchClient_mt = { __index = TwitchClient }
    local client = nil

    local function getOption(name)
        return OptionsData.getPlugin("Twitch2DCS", name)  
    end
    
    local function setOption(name, value)
        OptionsData.setPlugin("Twitch2DCS", name, value)
        OptionsData.saveChanges()  
    end

    local function isEnabled()
        return getOption("isEnabled")
    end

    local function getPosition()
        return getOption("position")
    end

    local function getMessageColors()
        return getOption("messageColors")
    end

    local function getFontSize()
        return getOption("fontSize")
    end 

    local function getHideShowHotkey()
        return getOption("hideShowHotkey")
    end 

    local function getJoinPartColor()
        return getOption("joinPartColor")
    end 

    local function getShowJoinPartMessages()
        return getOption("showJoinPart")
    end 

    local function getSelfColor()
        return getOption("selfColor")
    end 

    local function getLockUIPosition()
        return getOption("lockUIPosition")
    end 

    local function setPosition(value)
        return getOption("position", value)
    end

    local function getAuthInfo()
        return {
            username = getOption("username"),
            oauthToken = getOption("oauth"),
            hostAddress = getOption("hostAddress"),
            port = getOption("port"),
            caps  = getOption("caps"),
            timeout  = getOption("timeout"),
            }
    end

    function TwitchClient:new() 
        local self = base.setmetatable(self, TwitchClient_mt)

        net.log("Twitch2DCS - Creating server")

        local isEnabled = isEnabled()
        local authInfo =getAuthInfo()
        local position = getPosition()
        local fontSize = getFontSize()
        local hideShowHotkey =getHideShowHotkey()
        local joinPartColor = getJoinPartColor()
        local selfColor = getSelfColor()

        self.server = Server:new(authInfo.hostAddress, authInfo.port)
        
        net.log("Twitch2DCS - Creating ui")

        self.ui = UI:new(hideShowHotkey, position.x, position.y, fontSize)
        self.ui.lockUIPosition = getLockUIPosition()
        
        net.log("Twitch2DCS - Setting up theme")

        self.joinPartSkin = self.ui.skinFactory:getSkin()
        self.joinPartSkin.skinData.states.released[2].text.color = joinPartColor
        self.joinPartSkin.skinData.states.released[2].text.fontSize = fontSize

        if isEnabled and authInfo.username ~= nil and authInfo.username ~= "" then       
            local userSkin = self.ui.skinFactory:getSkin()
            
            userSkin.skinData.states.released[2].text.color = selfColor
            userSkin.skinData.states.released[2].text.fontSize = fontSize

            self.userSkins[authInfo.username] = userSkin
        end

        return self;
    end

    function TwitchClient:getSkinForUser(user) 
        if not self.userSkins[user] then    
            local messageColors = getMessageColors()
            local userSkin = self.ui.skinFactory:getSkin()
            local color = messageColors[self.nextUserIndex]

            userSkin.skinData.states.released[2].text.color = color        
            userSkin.skinData.states.released[2].text.fontSize = getFontSize()        

            self.userSkins[user] = userSkin                
            self.nextUserIndex = self.nextUserIndex + 1

            if self.nextUserIndex > #messageColors then
                self.nextUserIndex = 1
            end

            tracer:info("User "..user.." gets color r:"..color.r.." g:"..color.g.." b:"..color.b)
        end

        return self.userSkins[user]
    end

    function TwitchClient:canLogin()
        local isEnabled = isEnabled()
        local authInfo = getAuthInfo()
        return isEnabled and
            (authInfo.username ~= nil and authInfo.username ~= '') and 
            (authInfo.oauthToken ~= nil and authInfo.oauthToken ~= '')
    end

    function TwitchClient:addViewer(user)
        local authInfo = getAuthInfo()
        if user == authInfo.username then
            return
        end
        local function hasValue (tab, val)
            for index, value in ipairs (tab) do
                -- We grab the first index of our sub-table instead
                if value == val then
                    return true
                end
            end

            return false
        end
        if not hasValue(self.userNames, user) then
            table.insert(self.userNames,user)
        end
        client:updateTitle()
    end

    function TwitchClient:removeViewer(user)
        table.removeValue(self.userNames, user)
        client:updateTitle()
    end

    function TwitchClient.onUISendMessage(args)
        local authInfo = getAuthInfo()
        local selfColor = getSelfColor()
        local username = authInfo.username
        local skin = getSkinForUser(username)            
        local color = selfColor   
        local userSkin = client.ui.skinFactory:getSkin()
         
        userSkin.skinData.states.released[2].text.color = color
        userSkin.skinData.states.released[2].text.fontSize = getFontSize()

        client.server:send("PRIVMSG #"..username.." :"..args.message)
        client.ui:addMessage(client:getTimeStamp().." "..username..": ", client:getTimeStamp().." "..username..": "..args.message, skin, userSkin)
    end

    function TwitchClient.onUIPositionChanged(args)
        setOption("position", {x = args.x, y = args.y})
    end

    function TwitchClient.onUserPart(cmd)
        client:removeViewer(cmd.user)
        if not getShowJoinPartMessages() then
            return
        end
        client.ui:addMessage(client:getTimeStamp().." "..cmd.user.." left.", client:getTimeStamp().." "..cmd.user.." left.", client.joinPartSkin, client.joinPartSkin)
    end

    function TwitchClient.onUserJoin(cmd)
        client:addViewer(cmd.user)

        local authInfo = getAuthInfo()

        if not getShowJoinPartMessages() or cmd.user == authInfo.username then
            return
        end

        client.ui:addMessage(client:getTimeStamp().." "..cmd.user.." joined.", client:getTimeStamp().." "..cmd.user.." joined.", client.joinPartSkin, client.joinPartSkin)
    end

    function TwitchClient.onUserMessage(cmd)
        client:addViewer(cmd.user)

        local skin = client:getSkinForUser(cmd.user)
        local selfColor = getSelfColor()
        local color = selfColor   
        local userSkin = client.ui.skinFactory:getSkin()
         
        userSkin.skinData.states.released[2].text.color = color
        userSkin.skinData.states.released[2].text.fontSize = getFontSize()
        
        client.ui:addMessage(client:getTimeStamp().." "..cmd.user..": ", client:getTimeStamp().." "..cmd.user..": "..cmd.param2, skin, userSkin)
    end

    function TwitchClient:updateTitle()
        local viewerCount = #client.userNames
        client.ui:setTitle("Twitch Chat | "..viewerCount.." viewers")
    end

    function TwitchClient:connect() 
        net.log("Twitch2DCS - Connecting")
        self.server:addCommandHandler("PRIVMSG", self.onUserMessage)
        self.server:addCommandHandler("JOIN", self.onUserJoin)
        self.server:addCommandHandler("PART", self.onUserPart)

        self.ui:setCallbacks(self)

        local authInfo = getAuthInfo()

        self.server:connect(
            authInfo.username, 
            authInfo.oauthToken, 
            authInfo.caps, 
            authInfo.timeout)
        net.log("Twitch2DCS - Connected")
    end

    function TwitchClient:receive() 
        local err = self.server:receive()

        if err and err ~= "timeout" and err == "closed" and self:isEnabled() then
            self.server:reset()

            local authInfo = getAuthInfo()

            self.server:connect(
            authInfo.username, 
            authInfo.oauthToken, 
            authInfo.caps, 
            authInfo.timeout)
        end
    end

    function TwitchClient:getTimeStamp()
        local date = os.date('*t')
        return string.format("%i:%02i:%02i", date.hour, date.min, date.sec)
    end

    local lastlockUIPosition = getLockUIPosition();
    local lastFontSize = getFontSize();

    local callacks = { 
        onSimulationFrame = function() 
            if client == nil then
                 net.log("Twitch2DCS Creating client")
                client = TwitchClient:new()

                if client == nil or not client:canLogin() then 
                    tracer:warn("Unable to login, please add your twitch username and oauth key in the Special area of the DCS Options screen")
                    return
                end
            
                client:connect()
            end
            
            if not client:canLogin() then 
                return
            end

            local fontSize = getFontSize();

            if fontSize ~= lastFontSize then
                client.ui:setFontSize(fontSize)
                lastFontSize = fontSize
            end

            local lockUIPosition = getLockUIPosition();

            if lockUIPosition ~= lastFontSize then
                client.ui.lockUIPosition = lockUIPosition
                client.ui:readMode()
                lockUIPosition = lockUIPosition
            end
            
            client:receive()
        end
    }

    DCS.setUserCallbacks(callacks)

-- local InputData 			= require('Input.Data')
-- local ProfileDatabase 		= require('Input.ProfileDatabase')
-- local InputUtils 			= require('Input.Utils')
-- local Input 				= require('Input')

    net.log("Loaded - Twitch2DCS GameGUI")
end)

if err then
    local base = _G
    local require           = base.require
    local net               = require('net')
    local MsgWindow         = require('MsgWindow')
    
    net.log("Twitch2DCS failed to load - "..err)
    MsgWindow.warning("Twitch2DCS failed to load - "..err, _("OK")):show()
end