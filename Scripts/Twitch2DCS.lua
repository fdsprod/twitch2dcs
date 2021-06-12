local status, err = pcall(function()

	local base = _G

	package.path = package.path..";.\\LuaSocket\\?.lua;"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'..lfs.writedir()..'Scripts\\?.lua;'
	package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

	local os = base.os
	local require = base.require
	local io = base.io
	local table = base.table
	local string = base.string
	local math = base.math
	local assert = base.assert
	local pairs = base.pairs
	local ipairs = base.ipairs
	local world = base.world

	local net = require('net')
	local MsgWindow = require('MsgWindow')

	local utils = require('twitch.utils')
	local tracer = require('twitch.tracer')
	local Server = require('twitch.server')
	local Config = require('twitch.config')
	local UI = require('twitch.ui')

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
	local config = Config:new()
	local lastlockUIPosition = config:getLockUIPosition()
	local lastFontSize = config:getFontSize()

	function TwitchClient:new()
		local self = base.setmetatable(self, TwitchClient_mt)

		tracer:info("Creating server")

		local isEnabled = config:isEnabled()
		local authInfo = config:getAuthInfo()
		local fontSize = config:getFontSize()
		local joinPartColor = config:getJoinPartColor()
		local selfColor = config:getSelfColor()

		self.server = Server:new(authInfo.hostAddress, authInfo.port)

		tracer:info("Creating ui")

		local ok, err = pcall(
			function(i)
				self.ui = UI:new()
				self.ui.lockUIPosition = config:getLockUIPosition()
				self.ui:readMode()
			end, self)

		if err ~= nil then
			tracer:info("ERROR: "..err)
		end

		tracer:info("Setting up theme")

		self.joinPartSkin = self.ui.skinFactory:getSkin()
		self.joinPartSkin.skinData.states.released[2].text.color = joinPartColor
		self.joinPartSkin.skinData.states.released[2].text.fontSize = fontSize

		if isEnabled and authInfo.username ~= nil and authInfo.username ~= "" then
			local userSkin = self.ui.skinFactory:getSkin()

			userSkin.skinData.states.released[2].text.color = selfColor
			userSkin.skinData.states.released[2].text.fontSize = fontSize

			self.userSkins[authInfo.username] = userSkin
		end

		return self
	end

	function TwitchClient:getSkinForUser(user)
		if not self.userSkins[user] then
			local messageColors = config:getMessageColors()
			local userSkin = self.ui.skinFactory:getSkin()
			local color = utils.rgbToHex(messageColors[self.nextUserIndex]);

			userSkin.skinData.states.released[2].text.color = color
			userSkin.skinData.states.released[2].text.fontSize = config:getFontSize()

			self.userSkins[user] = userSkin
			self.nextUserIndex = self.nextUserIndex + 1

			if self.nextUserIndex > #messageColors then
				self.nextUserIndex = 1
			end

			tracer:info("User "..user.." gets color "..color)
		end

		return self.userSkins[user]
	end

	function TwitchClient:canLogin()
		local isEnabled = config:isEnabled()
		local authInfo = config:getAuthInfo()
		return isEnabled and
			(authInfo.username ~= nil and authInfo.username ~= '') and
			(authInfo.oauthToken ~= nil and authInfo.oauthToken ~= '')
	end

	function TwitchClient:addViewer(user)
		local authInfo = config:getAuthInfo()
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
		local authInfo = config:getAuthInfo()
		local selfColor = config:getSelfColor()
		local username = authInfo.username
		local skin = config:getSkinForUser(username)
		local color = selfColor
		local userSkin = client.ui.skinFactory:getSkin()

		userSkin.skinData.states.released[2].text.color = color
		userSkin.skinData.states.released[2].text.fontSize = config:getFontSize()

		client.server:send("PRIVMSG #"..username.." :"..args.message)
		client.ui:addMessage(client:getTimeStamp().." "..username..": ", client:getTimeStamp().." "..username..": "..args.message, skin, userSkin)
	end

	function TwitchClient.onUIPositionChanged(args)
		config:setOption("position", {x = args.x, y = args.y})
	end

	function TwitchClient.onUserPart(cmd)
		client:removeViewer(cmd.user)
		if not config:getShowJoinPartMessages() then
			return
		end
		client.ui:addMessage(client:getTimeStamp().." "..cmd.user.." left.", client:getTimeStamp().." "..cmd.user.." left.", client.joinPartSkin, client.joinPartSkin)
	end

	function TwitchClient.onUserJoin(cmd)
		client:addViewer(cmd.user)

		local authInfo = config:getAuthInfo()

		if not config:getShowJoinPartMessages() or cmd.user == authInfo.username then
			return
		end

		client.ui:addMessage(client:getTimeStamp().." "..cmd.user.." joined.", client:getTimeStamp().." "..cmd.user.." joined.", client.joinPartSkin, client.joinPartSkin)
	end

	function TwitchClient.onUserMessage(cmd)
		client:addViewer(cmd.user)

		local skin = client:getSkinForUser(cmd.user)
		local selfColor = config:getSelfColor()
		tracer:info(selfColor)
		local userSkin = client.ui.skinFactory:getSkin()

		userSkin.skinData.states.released[2].text.color = selfColor
		userSkin.skinData.states.released[2].text.fontSize = config:getFontSize()

		client.ui:addMessage(client:getTimeStamp().." "..cmd.user..": ", client:getTimeStamp().." "..cmd.user..": "..cmd.param2, skin, userSkin)
	end

	function TwitchClient:updateTitle()
		local viewerCount = #client.userNames
		client.ui:setTitle(viewerCount)
	end

	function TwitchClient:connect()
		tracer:info("Connecting")
		self.server:addCommandHandler("PRIVMSG", self.onUserMessage)
		self.server:addCommandHandler("JOIN", self.onUserJoin)
		self.server:addCommandHandler("PART", self.onUserPart)

		self.ui:setCallbacks(self)

		local authInfo = config:getAuthInfo()

		self.server:connect(
			authInfo.username,
			authInfo.oauthToken,
			authInfo.caps,
			authInfo.timeout)
		tracer:info("Connected")
	end

	function TwitchClient:receive()
		local err = self.server:receive()

		if err and err ~= "timeout" and err == "closed" and config:isEnabled() then
			self.server:reset()

			local authInfo = config:getAuthInfo()

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

	local err = nil;
	local callacks = {
		onSimulationFrame = function()
			if err then
				return
			end
			local status, innerError = pcall(function()
				if client == nil then
					tracer:info("Creating client")
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

				local fontSize = config:getFontSize()

				if fontSize ~= lastFontSize then
					client.ui:setFontSize(fontSize)
					lastFontSize = fontSize
				end

				local lockUIPosition = config:getLockUIPosition()

				if lockUIPosition ~= lastlockUIPosition then
					client.ui.lockUIPosition = lockUIPosition
					client.ui:readMode()
					lastlockUIPosition = lockUIPosition
				end

				client:receive()
			end)

			err = innerError

			if err ~= nil then
				net.log("Twitch2DCS failed to start - "..err)
				MsgWindow.warning(err, "Twitch2DCS"):show()
			end
		end
	}

	DCS.setUserCallbacks(callacks)

	tracer:info("Loaded");
	net.log("Loaded - Twitch2DCS GameGUI")
end)

if err ~= nil then
	net.log("Twitch2DCS failed to load - "..err)
	MsgWindow.warning(err, "Twitch2DCS Failure"):show()
end