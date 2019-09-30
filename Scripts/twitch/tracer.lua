local base = _G

module("twitch.tracer")

local require = base.require
local io = base.io
local os = base.os
local lfs = require('lfs')

local Tracer = {}
local Tracer_mt = {__index = Tracer}

local function getInstance(file)
	if not _instance then
		_instance = base.setmetatable({}, Tracer_mt)
		_instance.file = io.open(file, "w")
	end

	return _instance
end

function Tracer:info(str)
	self:write("INFO : "..(str or ""))
end

function Tracer:warn(str)
	self:write("WARN : "..(str or ""))
end

function Tracer:error(str)
	self:write("ERROR: "..(str or ""))
end

function Tracer:debug(str)
	self:write("DEBUG: "..(str or ""))
end

function Tracer:write(str)
	if not str or not self.file then
		return
	end

	self.file:write("["..os.date("%H:%M:%S").."] "..str.."\r\n")
	self.file:flush()
end

return getInstance(lfs.writedir()..[[Logs\Twitch2DCS.log]])