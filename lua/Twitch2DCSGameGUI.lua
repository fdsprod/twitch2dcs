local settings = { 
    username = "",      -- Your twitch username
    oathToken = "",     -- Go to https://twitchapps.com/tmi/ connect your account and generate a key. Copy paste the full value including the "oauth:" example: "oauth:2mwce4mdsgasddg3ml99k3phwa9l7"
    caps = {
        "twitch.tv/membership",
    },
    hostAddress = "irc.chat.twitch.tv",
    port = 6667,
    hotkey = "Ctrl+Alt+Tab",
    timeout = 0,
}

local base = _G

package.path  = package.path..";.\\LuaSocket\\?.lua;"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'
package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

local socket            = require("socket") 
local DCS               = require("DCS") 
local U                 = require('me_utilities')
local lfs 				= require('lfs')
local Skin				= require('Skin')
local Gui               = require('dxgui')
local DialogLoader      = require('DialogLoader')
local EditBox           = require('EditBox')
local ListBoxItem       = require('ListBoxItem')
local Tools 			= require('tools')

local _modes = {     
    read = "read",
    write = "write",
}

local _isWindowCreated = false
local _currentMode = _modes.read
local _currentWheelValue = 0
local _chatWindowPosition = {} 
local _listStatics = {}
local _listMessages = {}


local twitch = { 
    username = settings.username,
    oathToken = settings.oathToken,
    caps = settings.caps,
    hostAddress = settings.hostAddress,
    port = settings.port,
    hotkey = settings.hotkey,
    timeout = settings.timeout,
    connection = nil,
    logFile = io.open(lfs.writedir()..[[Logs\mul_twitch_chat.log]], "w"),
    lastPing = 0,
}

function twitch.createServer()   
    twitch.connection = socket.tcp()

    local ip = socket.dns.toip(twitch.hostAddress)
    local success = assert(twitch.connection:connect(ip, twitch.port))
    
    if not success then
        twitch.log("Unable to connect to "..twitch.hostAddress.."["..ip.."]:"..twitch.port)
    else
        twitch.log("Conncted to "..twitch.hostAddress.."["..ip.."]:"..twitch.port)
       
        twitch.connection:settimeout(twitch.timeout)   -- REALLY short timeout.  Asynchronous operation required.
        
        twitch.send("CAP REQ : "..table.concat(twitch.caps, " "))
        twitch.send("PASS "..twitch.oathToken)
        twitch.send("NICK "..twitch.username)
        twitch.send("JOIN #"..twitch.username)
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

function twitch.checkPing()
    if(twitch.lastPing - socket.gettime() > 30) then
        twitch.send("PING")
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
                    --twitch.log("prefix: "..(prefix or "(nil)").." cmd: "..(cmd or "(nil)").." param: "..(param or "(nil)"))
                    if cmd == "376" then
                        twitch.send("JOIN #"..twitch.username)
                    end
                    if param ~= nil then
                        param = string.sub(param,2)
                        param1, param2 = string.match(param,"^([^:]+) :(.*)$")
                        --twitch.log("param1: "..(param1 or "(nil)").." param2: "..(param2 or "(nil)"))
                        if cmd == "PRIVMSG" then
                            user, userhost = string.match(prefix,"^([^!]+)!(.*)$")
                            --twitch.log("user: "..(user or "(nil)").." userhost: "..(userhost or "(nil)"))
                            twitch.addMessage(param2, user, typesMessage.sys)
                        elseif cmd == "JOIN" then
                            user, userhost = string.match(prefix,"^([^!]+)!(.*)$")
                            --twitch.log("user: "..(user or "(nil)").." userhost: "..(userhost or "(nil)"))
                            twitch.addMessage(user.." joined", "", typesMessage.my)
                        elseif cmd == "PART" then
                            user, userhost = string.match(prefix,"^([^!]+)!(.*)$")
                            --twitch.log("user: "..(user or "(nil)").." userhost: "..(userhost or "(nil)"))
                            twitch.addMessage(user.." left", "", typesMessage.my)
                        end
                    end
                end
            end
        else 
            --twitch.log("Err: "..err)
        end
    until err
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
    twitch.log("Adding message - "..name..": "..message)
    local date = os.date('*t')
	local dateStr = string.format("%i:%02i:%02i", date.hour, date.min, date.sec)

    local name = name
    if name ~= "" or skin ~= typesMessage.sys then
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
    for k,v in base.pairs(_listStatics) do
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
    
    window:addHotKeyCallback(twitch.hotkey, twitch.onHotkey)
    pMsg:addMouseWheelCallback(twitch.onMouseWheel_eMessage)
    
    vsScroll:setRange(1,1)
    vsScroll:setValue(1)

    _currentWheelValue = 1
    
    widthChat, heightChat = pMsg:getSize()
    
    skinModeWrite = pNoVisible.pModeWrite:getSkin()
    skinModeRead = pNoVisible.pModeRead:getSkin()
    
    skinSelAllies   = pNoVisible.sSelAllies:getSkin()
    skinNoSelAllies = pNoVisible.sNoSelAllies:getSkin()
    
    skinNoSelAll    = pNoVisible.sSelAll:getSkin()
    skinSelAll      = pNoVisible.sNoSelAll:getSkin()
        
    eMx,eMy,eMw = eMessage:getBounds()

    typesMessage =
    {
        my          = pNoVisible.eYellowText:getSkin(),
        red         = pNoVisible.eRedText:getSkin(),
        blue        = pNoVisible.eBlueText:getSkin(),
        sys         = pNoVisible.eWhiteText:getSkin(),
    }
    
    testStatic = EditBox.new()
    testStatic:setSkin(typesMessage.sys)
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
                 twitch.send("PRIVMSG #"..twitch.username.." :"..text)
                 twitch.addMessage(text, twitch.username, typesMessage.blue).
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
    
    _chatWindowPosition.x = w-360-300
    _chatWindowPosition.y = 0
    
    twitch.load_chatWindowPosition()
    
    twitch.resize(w, h)
    twitch.resizeEditMessage()
    
    twitch.setMode("write")    
    
    window:addPositionCallback(twitch.positionCallback)     
    twitch.positionCallback()

    _isWindowCreated = true

    twitch.log("Window created")
end

function twitch.setVisible(b)
    window:setVisible(b)
end

function twitch.setMode(mode)
    --twitch.log("setMode called "..mode)
    _currentMode = mode 
    
    if window == nil then
        return
    end
    
    box:setVisible(true)
    twitch.setVisible(true)
    window:setSize(360, 455)

    if _currentMode == "read" then
        box:setSkin(skinModeRead)
        vsScroll:setVisible(false)
        pDown:setVisible(false)
        eMessage:setFocused(false)
        DCS.banKeyboard(false)
        window:setSkin(Skin.windowSkinChatMin())
    end
    
    if _currentMode == "write" then
        box:setSkin(skinModeWrite)
        vsScroll:setVisible(true)
        pDown:setVisible(true)        
        DCS.banKeyboard(true)
        window:setSkin(Skin.windowSkinChatWrite())		
        eMessage:setFocused(true)
    end    
    twitch.updateListM()
end

function twitch.getMode()
    return _currentMode
end

function twitch.onHotkey()
    if (twitch.getMode() == _modes.write) then
        twitch.setMode(_modes.read)
    else
        twitch.setMode(_modes.write)            
    end 
end

function twitch.resize(w, h)
    window:setBounds(_chatWindowPosition.x, _chatWindowPosition.y, 360, 455)    
    box:setBounds(0, 0, 360, 400)
end

function twitch.load_chatWindowPosition()
    local tbl = Tools.safeDoFile(lfs.writedir() .. 'MissionEditor/Twitch_chatWindowPositionition.lua', false)
    if (tbl and tbl._chatWindowPosition and tbl._chatWindowPosition.x and tbl._chatWindowPosition.y) then
        _chatWindowPosition.x = tbl._chatWindowPosition.x
        _chatWindowPosition.y = tbl._chatWindowPosition.y
    end      
end

function twitch.save_chatWindowPosition()
    _chatWindowPosition.x, _chatWindowPosition.y = window:getPosition()
    U.saveInFile(_chatWindowPosition, '_chatWindowPosition', lfs.writedir() .. 'MissionEditor/Twitch_chatWindowPositionition.lua')	
end

function twitch.positionCallback()
    local x, y = window:getPosition()

    if x < 0 then
        x = 0
    end

    if y < 0 then
        y = 0
    end

    if x > (w-360) then
        x = w-360
    end

    if y > (h-400)then
        y = h-400
    end

    --twitch.log("Setting window position: "..x..", "..y)
    
    window:setPosition(x, y)
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
        twitch.save_chatWindowPosition()
    end
    
    twitch.setVisible(b)
end

function twitch.onSimulationFrame()
    if (twitch.username == nil or twitch.username == '')  or (twitch.oathToken == nil or twitch.oathToken == '') then 
        -- We cannot login without either of these
        return
    end

    if not window then 
        twitch.log("Creating window...")
        twitch.show(true)
    end
    
    if not twitch.connection then
        twitch.log("Connecting to twitch...")
        twitch.createServer()
    end

    twitch.receive()
end 

DCS.setUserCallbacks(twitch)

net.log("Loaded - Twitch2DCS GameGUI")