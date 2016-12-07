local base = _G

package.path  = package.path..";.\\LuaSocket\\?.lua;"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'
package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

local require       = base.require
local table         = base.table
local string        = base.string
local math          = base.math
local assert        = base.assert
local pairs         = base.pairs
local ipairs        = base.ipairs

local tracer        = require("twitch.tracer")
local net           = require('net')
local DCS           = require("DCS") 
local U             = require('me_utilities')
local Skin			= require('Skin')
local Gui           = require('dxgui')
local DialogLoader  = require('DialogLoader')
local EditBox       = require('EditBox')
local ListBoxItem   = require('ListBoxItem')
local Tools 		= require('tools')
local MulChat 		= require('mul_chat')

local UI = {
    _isWindowCreated = false,
    _currentWheelValue = 0,
    _listStatics = {},
    _listMessages = {},
    _nextChatColorIndex = 1,
}

local _modes = {     
    hidden = "hidden",
    read = "read",
    write = "write",
}

local function UI:onChange_vsScroll(self)
    self._currentWheelValue = self.vsScroll:getValue()
    self:updateListM()
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

function UI:new()
    local self = {}
      
    setmetatable(self, UI)

    self.__index = self            
    self.window = DialogLoader.spawnDialogFromFile(lfs.writedir() .. 'Scripts\\dialogs\\twitch_chat.dlg', cdata)
    self.box         = self.window.Box
    self.pDown       = self.box.pDown
    self.eMessage    = self.pDown.eMessage
    self.pMsg        = self.box.pMsg
    self.vsScroll    = self.box.vsScroll

    self.vsScroll.onChange = self:onChange_vsScroll
    self.eMessage.onChange = self:onChange_eMessage    
    
    self.window:addHotKeyCallback(config:get("hotkey"), self:onHotkey)
    self.pMsg:addMouseWheelCallback(self:onMouseWheel_eMessage)
    
    self.vsScroll:setRange(1,1)
    self.vsScroll:setValue(1)

    self._currentWheelValue = 1
    
    self.widthChat, self.heightChat = self.pMsg:getSize()
    
    self.skinFactory = self.window.pNoVisible.eWhiteText;
    self.skinModeWrite = self.pNoVisible.pModeWrite:getSkin()
    self.skinModeRead = self.pNoVisible.pModeRead:getSkin()
            
    self.eMx, self.eMy, self.eMw = self.eMessage:getBounds()

    self.typesMessage.user.skinData.states.released[2].text.color = twitch.config.skins.selfColor
    self.typesMessage.joinPart.skinData.states.released[2].text.color = twitch.config.skins.joinPartColor

    local testSkin = self.skinFactory:getSkin()

    self.testStatic = EditBox.new()
    self.testStatic:setSkin(testSkin)
    self.testStatic:setReadOnly(true)   
    self.testStatic:setTextWrapping(true)  
    self.testStatic:setMultiline(true) 
    self.testStatic:setBounds(0,0,self.widthChat,20)
    
    self._listStatics = {}
    
    for i = 1, 20 do
        local staticNew = EditBox.new()        
        table.insert(self._listStatics, staticNew)
        staticNew:setReadOnly(true)   
        staticNew:setTextWrapping(true)  
        staticNew:setMultiline(true) 
        self.pMsg:insertWidget(staticNew)
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
	
    self.testE = EditBox.new()    
    self.testE:setTextWrapping(true)  
    self.testE:setMultiline(true)  
    self.testE:setBounds(0,0,self.eMw,20)
    self.testE:setSkin(self.eMessage:getSkin())	

    self.w, self.h = Gui.GetWindowSize()
            
    self:resize(self.w, self.h)
    self:resizeEditMessage()
    
    self:setMode(twitch.config.mode)    
    
    self.window:addPositionCallback(twitch.positionCallback)     
    self:positionCallback()

    self._isWindowCreated = true

    tracer.log("Window created")

    return self
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