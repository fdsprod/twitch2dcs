local base = _G

module("twitch.ui")

local require = base.require
local table = base.table
local string = base.string
local math = base.math
local assert = base.assert
local pairs = base.pairs
local ipairs = base.ipairs

local lfs = require('lfs')
local os = require('os')
local net = require('net')
local DCS = require("DCS")
local U = require('me_utilities')
local Skin = require('Skin')
local SkinUtils = require('SkinUtils')
local Gui = require('dxgui')
local DialogLoader = require('DialogLoader')
local EditBox = require('EditBox')
local ListBoxItem = require('ListBoxItem')
local Tools = require('tools')
local MulChat = require('mul_chat')
local tracer = require("twitch.tracer")
local Config = require("twitch.config")
local UpdateManager = require('UpdateManager')
local Input = require('Input')

local modes = {
	hidden = "hidden",
	read = "read",
	--write = "write",
}

local UI = {
	_isWindowCreated = false,
	_currentWheelValue = 0,
	_listStatics = {},
	_listMessages = {},
	_currentMode = modes.read,
	_x = 0,
	_y = 0,
	_isKeyboardLocked = false,
	_title = "Twitch Chat",
	modes = modes,
	fontSize = 14,
	noReadMsg = 0,
	lockUIPosition = false,
	pressedKeys = {},
	config = nil
}
local UI_mt = { __index = UI }

function UI:isInBounds(x, y)
	local x_,y_,w_,h_ = self.window:getBounds()
	return x >= x_ and y >= y_ and x <= x_+w_ and y <= y_+h_
end

function UI:setVisibleBtnMail(b)
	if self.noReadMsg == 0 then
		self.btnMail:setVisible(false)
	else
		self.btnMail:setVisible(b)
	end
end

function UI:new()
	local ui = base.setmetatable({}, UI_mt)

	ui.config = Config:new()

	local fontSize = ui.config:getFontSize()
	local hideShowHotkey = ui.config:getHideShowHotkey()
	local position = ui.config:getPosition()

	ui.window = DialogLoader.spawnDialogFromFile(lfs.writedir() .. 'Scripts\\dialogs\\twitch_ChatWindow.dlg', cdata)
	ui._currentMode = defaultMode
	ui.box = ui.window.Box
	ui.btnMail = ui.window.btnMail
	ui.pNoVisible = ui.window.pNoVisible
	ui.pMsg = ui.box.pMsg
	ui.vsScroll = ui.box.vsScroll
	ui._x = position.x
	ui._y = position.y

	ui.vsScroll.onChange = ui.onChange_vsScroll

	if hideShowHotkey and hideShowHotkey ~= "" and hideShowHotkey ~= "NONE" then
		ui.window:addHotKeyCallback(hideShowHotkey, function() ui:nextMode() end)
	end

	ui.vsScroll:setRange(1,1)
	ui.vsScroll:setValue(1)

	ui._currentWheelValue = 1

	ui.widthChat, ui.heightChat = ui.pMsg:getSize()

	ui.skinFactory = ui.window.pNoVisible.eWhiteText;
	ui.skinModeWrite = ui.pNoVisible.pModeWrite:getSkin()
	ui.skinModeRead = ui.pNoVisible.pModeRead:getSkin()

	ui.skinMail = ui.btnMail:getSkin()

	local testSkin = ui.skinFactory:getSkin()

	testSkin.skinData.states.released[2].text.fontSize = fontSize

	ui.testStatic = EditBox.new()
	ui.testStatic:setSkin(testSkin)
	ui.testStatic:setReadOnly(true)
	ui.testStatic:setTextWrapping(true)
	ui.testStatic:setMultiline(true)
	ui.testStatic:setBounds(0,0,ui.widthChat,20)

	ui._listStatics = {}

	for i = 1, 40 do
		local staticNew = EditBox.new()
		table.insert(ui._listStatics, staticNew)
		staticNew:setReadOnly(true)
		staticNew:setTextWrapping(true)
		staticNew:setMultiline(true)
		ui.pMsg:insertWidget(staticNew)
	end

	ui.w, ui.h = Gui.GetWindowSize()

	ui:resize(ui.w, ui.h)

	ui:writeMode()
	ui:readMode()

	ui.window:addPositionCallback(function() ui:positionCallback() end)
	ui:positionCallback()

	ui._isWindowCreated = true

	tracer:info("Window created")

	ui:setVisible(true)

	return ui
end

function UI:writeMode()
	self._currentMode = modes.write
	tracer:info("Setting UI to write mode")

	self:setVisible(true)

	self.box:setVisible(true)
	self.box:setSkin(self.skinModeWrite)

	self.window:setSize(360, 455)
	self.window:setSkin(Skin.windowSkinChatWrite())

	self.vsScroll:setVisible(true)

	self:lockKeyboardInput(true)

	self:updateListM()

	self.hideTimerTime = nil
end

function UI:onChange_vsScroll(self)
	self._currentWheelValue = self.vsScroll:getValue()
	self:updateListM()
end

function UI:addMessage(user, message, skin, textSkin)
	self.testStatic:setText(message)

	local newW, newH = self.testStatic:calcSize()
	local msg = {user = user, message = message, skin = skin, textSkin = textSkin, height = newH, timeStart = DCS.getModelTime()}

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

	if self._currentMode == modes.hidden then
		self.noReadMsg = self.noReadMsg + 1
		self:updateNoReadMsg()
	else
		self:updateListM()
	end
end

function UI:setTitle(title)
	self._title = title;

	if self._currentMode == modes.read then
		self.window:setText(self._title)
	end
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
		while curMsg > 0 and self.heightChat > (offset + self._listMessages[curMsg].height) do
			local msg = self._listMessages[curMsg]
			msg.textSkin.skinData.states.released[2].text.fontSize = self.fontSize
			msg.skin.skinData.states.released[2].text.fontSize = self.fontSize
			self._listStatics[curStatic]:setSkin(msg.textSkin)
			self._listStatics[curStatic]:setBounds(0,self.heightChat-offset-msg.height,self.widthChat,msg.height)
			self._listStatics[curStatic]:setText(msg.message)
			self._listStatics[curStatic+1]:setSkin(msg.skin)
			self._listStatics[curStatic+1]:setBounds(0,self.heightChat-offset-msg.height,self.widthChat,msg.height)
			self._listStatics[curStatic+1]:setText(msg.user)
			offset = offset + msg.height
			curMsg = curMsg - 1
			curStatic = curStatic + 2
			num = num + 1
		end
	end
end

--[[ Callbacks
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

function UI:setVisible(b)
	self.window:setVisible(b)
end

function UI:setFontSize(fontSize)
	local testSkin = self.skinFactory:getSkin()

	testSkin.skinData.states.released[2].text.fontSize = fontSize

	self.fontSize = fontSize
	self.testStatic:setSkin(testSkin)
	self:updateListM()
end

function UI:readMode()
	self._currentMode = modes.read
	tracer:info("Setting UI to read mode")

	self:setVisible(true)
	self.window:setText(self._title)

	self.box:setVisible(true)
	self.box:setSkin(self.skinModeRead)

	local skin = Skin.windowSkinTransparent()

	skin.skinData.skins.header.skinData.states.disabled[1].bkg.center_center = 0x00000000
	skin.skinData.skins.header.skinData.states.released[1].bkg.center_center = 0x00000000
	skin.skinData.skins.header.skinData.states.released[2].bkg.center_center = 0x00000000

	self.window:setSize(360, 455)
	self.window:setSkin(skin)

	if self.lockUIPosition then
		self.window:setHasCursor(false)
	else
		self.window:setHasCursor(true)
	end

	self.vsScroll:setVisible(false)

	self:setVisibleBtnMail(false)
	self:lockKeyboardInput(false)

	self:updateListM()

	self.noReadMsg = 0
end

function UI:hideMode()
	self._currentMode = modes.hidden
	tracer:info("Setting UI to hidden mode")

	self.box:setVisible(false)
	self.box:setSkin(self.skinModeRead)
	self.window:setText("")

	local skin = Skin.windowSkinTransparent()

	skin.skinData.skins.header.skinData.states.disabled[1].bkg.center_center = 0x00000000
	skin.skinData.skins.header.skinData.states.released[1].bkg.center_center = 0x00000000
	skin.skinData.skins.header.skinData.states.released[2].bkg.center_center = 0x00000000

	--self.window:setSize(0, 0)
	self.window:setSkin(skin)

	self.vsScroll:setVisible(false)
	self.btnMail:setBounds(12, 0, 24, 55)

	self:setVisibleBtnMail(true)
	self:lockKeyboardInput(false)

	self:updateListM()
end

function UI:nextMode()
	if self._currentMode == modes.hidden then
		self:readMode()
	else
		self:hideMode()
	end
end

function UI:lockKeyboardInput(lock)
	if lock then
		if not self._isKeyboardLocked then
			-- блокируем все кнопки клавиатуры,
			-- кроме кнопок управления чатом
			local keyboardEvents = Input.getDeviceKeys(Input.getKeyboardDeviceName())
			local inputActions = Input.getEnvTable().Actions

			local removeCommandEvents = function(commandEvents)
				for i, commandEvent in ipairs(commandEvents) do
					-- из массива удаляем элементы с конца
					for j = #keyboardEvents, 1, -1 do
						if keyboardEvents[j] == commandEvent then
							table.remove(keyboardEvents, j)
							break
						end
					end
				end
			end

			DCS.lockKeyboardInput(keyboardEvents)
			self._isKeyboardLocked = true
		end
	else
		if self._isKeyboardLocked then
			DCS.unlockKeyboardInput()
			self._isKeyboardLocked = false
		end
	end
end

function UI:resize(w, h)
	self.window:setBounds(self._x, self._y, 360, 455)
	self.box:setBounds(0, 0, 360, 400)
	self.btnMail:setBounds(12, 0, 24, 55)
end

function UI:setVisibleBtnMail(b)
	if self.noReadMsg == 0 then
		self.btnMail:setVisible(false)
	else
		self.btnMail:setVisible(b)
	end
end

function UI:updateNoReadMsg()
	local txt
	if self.noReadMsg >= 100 then
		txt = "99+"
	else
		txt = base.tostring(self.noReadMsg)
	end

	if self._currentMode == modes.hidden and self.noReadMsg > 0 then
		self:setVisibleBtnMail(true)
	end

	self.btnMail:setText(txt)
end

function UI:positionCallback()
	local x, y = self.window:getPosition()

	x = math.max(math.min(x, self.w-360), 0)
	y = math.max(math.min(y, self.h-400), 0)

	self._x = x
	self._y = y

	self.window:setPosition(x, y)
	self:onCallback("onUIPositionChanged", {x = x, y = y})
end

return UI
