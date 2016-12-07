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
local socket            = require("socket") 
local net               = require('net')
local DCS               = require("DCS") 
local U                 = require('me_utilities')
local Skin				= require('Skin')
local Gui               = require('dxgui')
local DialogLoader      = require('DialogLoader')
local EditBox           = require('EditBox')
local ListBoxItem       = require('ListBoxItem')
local Tools 			= require('tools')
local MulChat 			= require('mul_chat')

local _modes = {     
    hidden = "hidden",
    read = "read",
    write = "write",
}

local _isWindowCreated = false
local _currentWheelValue = 0
local _listStatics = {}
local _listMessages = {}
local _nextChatColorIndex = 1

local twitch = { 
    connection = nil,
    logFile = io.open(lfs.writedir()..[[Logs\Twitch2DCS.log]], "w")
}

function twitch.loadConfiguration()
    twitch.log("Loading config file...")
    local tbl = Tools.safeDoFile(lfs.writedir() .. 'Config/Twitch2DCSConfig.lua', false)
    if (tbl and tbl.config) then
        twitch.log("Configuration exists...")
        twitch.config = tbl.config
        
        if not twitch.config.version or twitch.config.version < 1 then
            twitch.appendConfigAdditionsForVersion1(twitch.config)
            twitch.saveConfiguration()
        end
    else
        twitch.log("Configuration not found, creating defaults...")
        twitch.config = twitch.newConfig()
        twitch.saveConfiguration()
    end    
end

function twitch.saveConfiguration()
    U.saveInFile(twitch.config, 'config', lfs.writedir() .. 'Config/Twitch2DCSConfig.lua')	
end


function twitch.createServer()   
    twitch.connection = socket.tcp()

    local ip = socket.dns.toip(twitch.config.hostAddress)
    local success = assert(twitch.connection:connect(ip, twitch.config.port))
    
    if not success then
        twitch.log("Unable to connect to "..twitch.config.hostAddress.."["..ip.."]:"..twitch.config.port)
    else
        twitch.log("Conncted to "..twitch.config.hostAddress.."["..ip.."]:"..twitch.config.port)
       
        twitch.connection:settimeout(twitch.config.timeout)  
        
        twitch.send("CAP REQ : "..table.concat(twitch.config.caps, " "))
        twitch.send("PASS "..twitch.config.oathToken)
        twitch.send("NICK "..twitch.config.username)
        twitch.send("JOIN #"..twitch.config.username)
    end
end

function twitch.send(data) 
    local count, err = twitch.connection:send(data.."\r\n")
    if err then
        twitch.log("DCS -> Twitch: "..err)
    else    
        twitch.log("DCS -> Twitch: "..data)
     end
end

function twitch.receive() 
    local buffer, err
    repeat
        buffer, err = twitch.connection:receive("*l")
        if not err then
            twitch.log("DCS <- Twitch: "..buffer)
            if buffer ~= nil then                 
                if string.sub(buffer,1,4) == "PING" then
                    twitch.send(string.gsub(buffer,"PING","PONG",1))
                else
                    local prefix, cmd, param, param1, param2
                    local user, userhost
                    prefix, cmd, param = string.match(buffer, "^:([^ ]+) ([^ ]+)(.*)$")
                    param = string.sub(param,2)
                    param1, param2 = string.match(param,"^([^:]+) :(.*)$")
                    user, userhost = string.match(prefix,"^([^!]+)!(.*)$")
                    if cmd == "376" then
                        twitch.send("JOIN #"..twitch.config.username)
                    end
                    if param ~= nil then
                        if cmd == "PRIVMSG" then     
                            if(user == twitch.config.username) then
                                twitch.addMessage(param2, user, typesMessage.user)
                            else
                                local userSkin = twitch.getSkinForUser(user)
                                twitch.addMessage(param2, user, userSkin)
                            end           
                        elseif cmd == "JOIN" then
                            twitch.addMessage(user.." joined", "", typesMessage.joinPart)
                        elseif cmd == "PART" then
                            twitch.addMessage(user.." left", "", typesMessage.joinPart)
                        end
                    end
                end
            end
        elseif err ~= "timeout" then
            twitch.log("Err: "..err)
        end
    until err
end

function twitch.getSkinForUser(user) 
    if not typesMessage.users[user] then
    
        local userSkin = pNoVisible.eWhiteText:getSkin()
        local color = twitch.config.skins.messageColors[_nextChatColorIndex]
        
        userSkin.skinData.states.released[2].text.color =  color        
        typesMessage.users[user] = userSkin
        _nextChatColorIndex += 1 

        if _nextChatColorIndex > table.getn(twitch.config.skins.messageColors) then
            _nextChatColorIndex = 1 
        end
    end

    return typesMessage.users[user]
end

function twitch.log(str)
    if not str then 
        return
    end

    if twitch.logFile then
        twitch.logFile:write("["..os.date("%H:%M:%S").."] "..str.."\r\n")
        twitch.logFile:flush()
    end
end

function twitch.onChange_vsScroll(self)
    _currentWheelValue = vsScroll:getValue()
    twitch.updateListM()
end

function twitch.addMessage(message, name, skin)        

    if twitch.config.useMutiplayerChat then
        MulChat.addMessage(message, "Twitch-"..name, skin)
        return
    end
    
    local date = os.date('*t')
	local dateStr = string.format("%i:%02i:%02i", date.hour, date.min, date.sec)

    local name = name
    if name ~= "" or skin ~= typesMessage.joinPart then
        name = name..": "
    end
    
    local fullMessage = "["..dateStr.."] "..name..message
    testStatic:setText(fullMessage)
    local newW, newH = testStatic:calcSize()   
    
    local msg = {message = fullMessage, skin = skin, height = newH}
    table.insert(_listMessages, msg)
        
    local minR, maxR = vsScroll:getRange()
    
    if ((_currentWheelValue+1) >= maxR) then
        vsScroll:setRange(1,#_listMessages)
        vsScroll:setThumbValue(1)
        vsScroll:setValue(#_listMessages)
        _currentWheelValue = #_listMessages
    else
    
        vsScroll:setRange(1,#_listMessages)
        vsScroll:setThumbValue(1)
    end   
    
    twitch.updateListM()
end

function twitch.onMouseWheel_eMessage(self, x, y, clicks)
    _currentWheelValue = _currentWheelValue - clicks*0.1

    if _currentWheelValue < 0 then
        _currentWheelValue = 0
    end

    if _currentWheelValue > #_listMessages-1 then
        _currentWheelValue = #_listMessages-1
    end
    
    vsScroll:setValue(_currentWheelValue)
    twitch.updateListM()
end

function twitch.updateListM()
    for k,v in pairs(_listStatics) do
        v:setText("")    
    end
   
    local offset = 0
    local curMsg = vsScroll:getValue() + vsScroll:getThumbValue()  --#_listMessages
    local curStatic = 1
    local num = 0    

    if _listMessages[curMsg] then          
        while curMsg > 0 and heightChat > (offset + _listMessages[curMsg].height) do
            local msg = _listMessages[curMsg]
            _listStatics[curStatic]:setSkin(msg.skin)                                 
            _listStatics[curStatic]:setBounds(0,heightChat-offset-msg.height,widthChat,msg.height) 
            _listStatics[curStatic]:setText(msg.message)            
            offset = offset + msg.height
            curMsg = curMsg - 1
            curStatic = curStatic + 1
            num = num + 1
        end
    end    
end

function twitch.createWindow()
    window = DialogLoader.spawnDialogFromFile(lfs.writedir() .. 'Scripts\\dialogs\\twitch_chat.dlg', cdata)

    box         = window.Box
    pNoVisible  = window.pNoVisible
    pDown       = box.pDown
    eMessage    = pDown.eMessage
    pMsg        = box.pMsg
    vsScroll    = box.vsScroll

    vsScroll.onChange = twitch.onChange_vsScroll
    eMessage.onChange = onChange_eMessage    
    
    window:addHotKeyCallback(twitch.config.hotkey, twitch.onHotkey)
    pMsg:addMouseWheelCallback(twitch.onMouseWheel_eMessage)
    
    vsScroll:setRange(1,1)
    vsScroll:setValue(1)

    _currentWheelValue = 1
    
    widthChat, heightChat = pMsg:getSize()
    
    skinModeWrite = pNoVisible.pModeWrite:getSkin()
    skinModeRead = pNoVisible.pModeRead:getSkin()
            
    eMx,eMy,eMw = eMessage:getBounds()

    typesMessage =
    {
        user = pNoVisible.eWhiteText:getSkin(),
        joinPart = pNoVisible.eWhiteText:getSkin(),
        users = {}
    }

    typesMessage.user.skinData.states.released[2].text.color = twitch.config.skins.selfColor
    typesMessage.joinPart.skinData.states.released[2].text.color = twitch.config.skins.joinPartColor

    testStatic = EditBox.new()
    testStatic:setSkin(typesMessage.user)
    testStatic:setReadOnly(true)   
    testStatic:setTextWrapping(true)  
    testStatic:setMultiline(true) 
    testStatic:setBounds(0,0,widthChat,20)
    
    _listStatics = {}
    
    for i = 1, 20 do
        local staticNew = EditBox.new()        
        table.insert(_listStatics, staticNew)
        staticNew:setReadOnly(true)   
        staticNew:setTextWrapping(true)  
        staticNew:setMultiline(true) 
        pMsg:insertWidget(staticNew)
    end
    
    function eMessage:onKeyDown(key, unicode) 
        if 'return' == key then          
            local text = eMessage:getText()            
            if text ~= "\n" and text ~= nil then
                text = string.sub(text, 1, (string.find(text, '%s+$') or 0) - 1)
                 twitch.send("PRIVMSG #"..twitch.config.username.." :"..text)
                 twitch.addMessage(text, twitch.config.username, typesMessage.user)
            end
            eMessage:setText("")
            eMessage:setSelectionNew(0,0,0,0)
            twitch.resizeEditMessage()
        end
    end
	
    testE = EditBox.new()    
    testE:setTextWrapping(true)  
    testE:setMultiline(true)  
    testE:setBounds(0,0,eMw,20)
    testE:setSkin(eMessage:getSkin())	

    w, h = Gui.GetWindowSize()
            
    twitch.resize(w, h)
    twitch.resizeEditMessage()
    
    twitch.setMode(twitch.config.mode)    
    
    window:addPositionCallback(twitch.positionCallback)     
    twitch.positionCallback()

    _isWindowCreated = true

    twitch.log("Window created")
end

function twitch.setVisible(b)
    window:setVisible(b)
end

function twitch.setMode(mode)
    twitch.log("setMode called "..mode)
    twitch.config.mode = mode 
    
    if window == nil then
        return
    end
    
    if twitch.config.mode == _modes.hidden then
        box:setVisible(false)
        twitch.setVisible(false)
        vsScroll:setVisible(false)
        pDown:setVisible(false)
        eMessage:setFocused(false)
        DCS.banKeyboard(false)
    else
        box:setVisible(true)
        twitch.setVisible(true)
        window:setSize(360, 455)

        if twitch.config.mode == _modes.read then
            box:setSkin(skinModeRead)
            vsScroll:setVisible(false)
            pDown:setVisible(false)
            eMessage:setFocused(false)
            DCS.banKeyboard(false)
            window:setSkin(Skin.windowSkinChatMin())
        end
        
        if twitch.config.mode == _modes.write then
            box:setSkin(skinModeWrite)
            vsScroll:setVisible(true)
            pDown:setVisible(true)        
            DCS.banKeyboard(true)
            window:setSkin(Skin.windowSkinChatWrite())		
            eMessage:setFocused(true)
        end    
    end

    twitch.updateListM()
    twitch.saveConfiguration()
end

function twitch.getMode()
    return twitch.config.mode
end

function twitch.onHotkey()
    if (twitch.getMode() == _modes.write) then
        twitch.setMode(_modes.read)
    --elseif (twitch.getMode() == _modes.read) then
       -- twitch.setMode(_modes.hidden)
    else
        twitch.setMode(_modes.write)            
    end 
end

function twitch.resize(w, h)
    window:setBounds(twitch.config.windowPosition.x, twitch.config.windowPosition.y, 360, 455)    
    box:setBounds(0, 0, 360, 400)
end

function twitch.positionCallback()
    local x, y = window:getPosition()

    x = math.max(math.min(x, w-360), 0)
    y = math.max(math.min(y, h-400), 0)
    
    window:setPosition(x, y)

    twitch.config.windowPosition = { x = x, y = y }
    twitch.saveConfiguration()
end

function twitch.resizeEditMessage()
    local text = eMessage:getText()
    
    testE:setText(text)
    local newW, newH = testE:calcSize()  

    eMessage:setBounds(eMx,eMy,eMw,newH)
    
    local x,y,w,h = box:getBounds()
    box:setBounds(x,0,w,eMy+newH+317)
    
    local x,y,w,h = pDown:getBounds()
    pDown:setBounds(x,y,w,eMy+newH+117)
    
    local x,y,w,h = window:getBounds()
    window:setSize(w,eMy+newH+317+55)
end

function twitch.show(b)
    if _isWindowCreated == false then
        twitch.createWindow()
    end
    
    if b == false then
        twitch.saveConfiguration()
    end
    
    twitch.setVisible(b)
end

function twitch.onSimulationFrame()
    if twitch.config == nil then
        twitch.loadConfiguration()
    end

    if (twitch.config.username == nil or twitch.config.username == '')  or (twitch.config.oathToken == nil or twitch.config.oathToken == '') then 
        return
    end

    if window == nil then 
        if twitch.config.useMutiplayerChat then
            -- We still need to create the window for the skins
            if _isWindowCreated == false then
                twitch.createWindow()    
            end
        else
            twitch.show(true)
        end
    end
    
    if not twitch.connection then
        twitch.log("Connecting to twitch...")
        twitch.createServer()
    end

    twitch.receive()
end 

function twitch.newConfig()
    local config = { 
            username = "",
            oathToken = "",
            caps = {
                "twitch.tv/membership",
            },
            hostAddress = "irc.chat.twitch.tv",
            port = 6667,
            mode = "write",
            hotkey = "Ctrl+Shift+escape",
            timeout = 0,
            windowPosition = { x = 66, y = 13 }
        }

    twitch.appendConfigAdditionsForVersion1(config)

    return config
end

function twitch.appendConfigAdditionsForVersion1(config)     
    config["version"] = 1
    config["useMutiplayerChat"] = false
    config["skins"] = {
        ["joinPartColor"] = 
        {
            ["b"] = 0.878,
            ["g"] = 0.878,
            ["r"] = 0.878,
        },
        ["selfColor"] = 
        {
            ["b"] = 1,
            ["g"] = 1,
            ["r"] = 1,
        },
        ["messageColors"] = {
            {
                ["b"] = 1.000,
                ["g"] = 0.000,
                ["r"] = 0.000,
            },
            {
                ["b"] = 0.314,
                ["g"] = 0.498,
                ["r"] = 1.000,
            },
            {
                ["b"] = 1.000,
                ["g"] = 0.565, 
                ["r"] = 0.118,
            },
            {
                ["b"] = 0.498,
                ["g"] = 1.000, 
                ["r"] = 0.000, 
            },
            {
                ["b"] = 0.196,
                ["g"] = 0.804, 
                ["r"] = 0.604, 
            },
            {
                ["b"] = 0.000,
                ["g"] = 0.502,  
                ["r"] = 0.000, 
            },
            {
                ["b"] = 0.000,
                ["g"] = 0.271,   
                ["r"] = 1.000, 
            },
            {
                ["b"] = 0.000,
                ["g"] = 0.000,    
                ["r"] = 1.000, 
            },
            {
                ["b"] = 0.125,
                ["g"] = 0.647,    
                ["r"] = 0.855,  
            },
            {
                ["b"] = 0.706,
                ["g"] = 0.412,     
                ["r"] = 1.000,  
            },
            {
                ["b"] = 0.627,
                ["g"] = 0.620,     
                ["r"] = 0.373,  
            },
            {
                ["b"] = 0.341,
                ["g"] = 0.545,      
                ["r"] = 0.180,  
            },
            {
                ["b"] = 0.118,
                ["g"] = 0.412,      
                ["r"] = 0.824,   
            },
            {
                ["b"] = 0.886,
                ["g"] = 0.169,       
                ["r"] = 0.541,    
            },
            {
                ["b"] = 0.133,
                ["g"] = 0.133,        
                ["r"] = 0.698,    
            },     
        }
    }
end 

DCS.setUserCallbacks(twitch)

net.log("Loaded - Twitch2DCS GameGUI")