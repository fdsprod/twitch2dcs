local base = _G
local require           = base.require
local io 			    = base.io
local lfs 			    = require('lfs')

local Tracer = { }

function Tracer:new(file)
      local self = {}
      
      setmetatable(self, Tracer)

      self.__index = self
      self.file = io.open(file, "w")

      return self
end 

function Tracer:info(str)
    self:write(" INFO : "..(str or ""))
end

function Tracer:warn(str)
    self:write(" WARN : "..(str or ""))
end

function Tracer:error(str)
    self:write(" ERROR: "..(str or ""))
end

function Tracer:debug(str)
    self:write(" DEBUG: "..(str or ""))
end

function Tracer:write(str)
    if not str then 
        return
    end
    if self.file then
        self.file:write("["..os.date("%H:%M:%S").."] "..str.."\r\n")
        self.file:flush()
    end
end

default = Tracer:new(lfs.writedir()..[[Logs\Twitch2DCS.log]])

return Tracer

