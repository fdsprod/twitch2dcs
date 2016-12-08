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

local _modes = {     
    hidden = "hidden",
    read = "read",
    write = "write",
}

local UI = {
    _isWindowCreated = false,
    _currentWheelValue = 0,
    _listStatics = {},
    _listMessages = {},
    _nextChatColorIndex = 1,
    _currentMode = _modes.read,
    _x,
    _y
}

function UI:onChange_vsScroll(self)
    self._currentWheelValue = self.vsScroll:getValue()
    self:updateListM()
end

function UI:addMessage(message, skin)
    self.testStatic:setText(message)

    local newW, newH = self.testStatic:calcSize()       
    local msg = {message = message, skin = skin, height = newH}

    table.insert(self._listMessages, msg)
        
    local minR, maxR = self.vsScroll:getRange()
    
    if ((self._currentWheelValue+1) >= maxR) then
        self.vsScroll:setRange(1,#self._listMessages)
        self.vsScroll:setThumbValue(1)
        self.vsScroll:setValue(#self._listMessages)
        self._currentWheelValue = #self._listMessages
    else    
        self.vsScroll:setRange(1,#self._listMessages)
        self.vsScroll:setThumbValue(1)
    end   
    
    self:updateListM()
end

function UI:onMouseWheel_eMessage(self, x, y, clicks)
    self._currentWheelValue = self._currentWheelValue - clicks*0.1

    if self._currentWheelValue < 0 then
        self._currentWheelValue = 0
    end

    if self._currentWheelValue > #self._listMessages-1 then
        self._currentWheelValue = #self._listMessages-1
    end
    
    self.vsScroll:setValue(self._currentWheelValue)
    self:updateListM()
end

function UI:updateListM()
    for k,v in pairs(self._listStatics) do
        v:setText("")    
    end
   
    local offset = 0
    local curMsg = self.vsScroll:getValue() + self.vsScroll:getThumbValue()  --#_listMessages
    local curStatic = 1
    local num = 0    

    if self._listMessages[curMsg] then          
        while curMsg > 0 and heightChat > (offset + self._listMessages[curMsg].height) do
            local msg = self._listMessages[curMsg]
            self._listStatics[curStatic]:setSkin(msg.skin)                                 
            self._listStatics[curStatic]:setBounds(0,heightChat-offset-msg.height,widthChat,msg.height) 
            self._listStatics[curStatic]:setText(msg.message)            
            offset = offset + msg.height
            curMsg = curMsg - 1
            curStatic = curStatic + 1
            num = num + 1
        end
    end    
end

--[[
{
    onUISendMessage({message})
    onUIModeChanged({mode})
    onUIPositionChanged({x,y})
}
]]--

function UI:setCallbacks(callbacks)
    self.callbacks = callbacks
end

function UI:onCallback(callback, args)
    if self.callbacks then
        self.callbacks[callback](args)
    end
end

function UI:new(hotkey, defaultMode, x, y)
    local self = {}
      
    setmetatable(self, UI)

    self.__index = self            
    self.window = DialogLoader.spawnDialogFromFile(lfs.writedir() .. 'Scripts\\dialogs\\twitch_chat.dlg', cdata)
    self.box = self.window.Box
    self.pDown = self.box.pDown
    self.eMessage = self.pDown.eMessage
    self.pMsg = self.box.pMsg
    self.vsScroll = self.box.vsScroll
    self._x = x
    self._y = y

    self.vsScroll.onChange = self:onChange_vsScroll
    self.eMessage.onChange = self:onChange_eMessage    
    
    self.window:addHotKeyCallback(hotkey, self:nextMode)
    self.pMsg:addMouseWheelCallback(self:onMouseWheel_eMessage)
    
    self.vsScroll:setRange(1,1)
    self.vsScroll:setValue(1)

    self._currentWheelValue = 1
    
    self.widthChat, self.heightChat = self.pMsg:getSize()
    
    self.skinFactory = self.window.pNoVisible.eWhiteText;
    self.skinModeWrite = self.pNoVisible.pModeWrite:getSkin()
    self.skinModeRead = self.pNoVisible.pModeRead:getSkin()
            
    self.eMx, self.eMy, self.eMw = self.eMessage:getBounds()

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
            local text = self.eMessage:getText()            
            if text ~= "\n" and text ~= nil then
                text = string.sub(text, 1, (string.find(text, '%s+$') or 0) - 1)
                self:onCallback("onUISendMessage", {message = message})
            end
            self.eMessage:setText("")
            self.eMessage:setSelectionNew(0,0,0,0)
            self:resizeEditMessage()
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
    
    if defaultMode == _modes.hidden then
        self:readMode()
    else if defaultMode == _modes.read then
        self:writeMode()
    else
        self:hiddenMode()
    end  
    
    self.window:addPositionCallback(twitch.positionCallback)     
    self:positionCallback()

    self._isWindowCreated = true

    tracer.default:info("Window created")

    self:setVisible(true)

    return self
end

function UI:setVisible(b)
    self.window:setVisible(b)
end

function UI:hiddenMode()
    self:onCallback("onUIModeChanged", {mode=_modes.hidden})
    self.box:setVisible(false)
    self.twitch.setVisible(false)
    self.vsScroll:setVisible(false)
    self.pDown:setVisible(false)
    self.eMessage:setFocused(false)
    self.DCS.banKeyboard(false)

    twitch.updateListM()
    twitch.saveConfiguration()
end

function UI:writeMode()
    self:onCallback("onUIModeChanged", {mode=_modes.write})
    self.box:setVisible(true)
    self:setVisible(true)
    self.window:setSize(360, 455)
    self.box:setSkin(self.skinModeWrite)
    self.vsScroll:setVisible(true)
    self.pDown:setVisible(true)     
    self.window:setSkin(Skin.windowSkinChatWrite())		
    self.eMessage:setFocused(true)
        
    DCS.banKeyboard(true)

    self:updateListM()
    self:saveConfiguration()
end

function UI:readMode()
    self:onCallback("onUIModeChanged", {mode=_modes.read})
    self.box:setVisible(true)
    self:setVisible(true)
    self.window:setSize(360, 455)
    self.box:setSkin(self.skinModeRead)
    self.vsScroll:setVisible(false)
    self.pDown:setVisible(false)
    self.eMessage:setFocused(false)
    self.window:setSkin(Skin.windowSkinChatMin())

    DCS.banKeyboard(false)

    self:updateListM()
    self:saveConfiguration()
end

function UI:nextMode()
    if mode == _modes.hidden then
        self:readMode()
    else if mode == _modes.read then
        self:writeMode()
    else
        self:hiddenMode()
    end
end

function UI:resize(w, h)
    self.window:setBounds(self._x, self._y, 360, 455)    
    self.box:setBounds(0, 0, 360, 400)
end

function UI:positionCallback()
    local x, y = self.window:getPosition()

    self._x = x = math.max(math.min(x, w-360), 0)
    self._y = y = math.max(math.min(y, h-400), 0)
    
    self.window:setPosition(x, y)
    self:onCallback("onUIPositionChanged", {x = x, y = y})
end

function UI:resizeEditMessage()
    local text = self.eMessage:getText()
    
    self.testE:setText(text)
    local newW, newH = self.testE:calcSize()  

    self.eMessage:setBounds(self.Mx,self.eMy,self.eMw,newH)
    
    local x,y,w,h = self.box:getBounds()
    self.box:setBounds(x,0,w,self.eMy+newH+317)
    
    local x,y,w,h = self.pDown:getBounds()
    self.pDown:setBounds(x,y,w,self.eMy+newH+117)
    
    local x,y,w,h = self.window:getBounds()
    self.window:setSize(w,self.eMy+newH+317+55)
end

return UI