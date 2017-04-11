local base = _G

module("twitch.config")

local require       = base.require
local table         = base.table
local string        = base.string
local math          = base.math
local type          = base.type
local assert        = base.assert
local pairs         = base.pairs
local ipairs        = base.ipairs

local tools 		= require('tools')
local lfs 			= require('lfs')
local U             = require('me_utilities')
local tracer        = require("twitch.tracer")

Config = {
    version = 2,
    debugMode = false,
    credentials = {        
        username = "",
        oauthToken = "",
    },
    twitch = {
        hostAddress = "irc.chat.twitch.tv",
        port = 6667,
        caps = {
            "twitch.tv/membership",
        },    
        timeout = 0,
    },
    ui = {
        hotkeys = {
            show = "[.]",
            switchModes = "Ctrl+Shift+escape",
        },
        inactivity = { 
            showOnHotkeyTimer = 10,
            showOnNewMessage = true,
            hideWhenInactive = true,
            hideTimer = 10,
        },
        notifications = {
            joinPart = true,
        },
        position = { x = 66, y = 13 },
        mode = "read",
        fontSize = 14,
        theme = {
            joinPartColor = 
            {
                b = 0.878,
                g = 0.878,
                r = 0.878,
            },
            selfColor = 
            {
                b = 1,
                g = 1,
                r = 1,
            },
            messageColors = {
                {
                    b = 1.000,
                    g = 0.000,
                    r = 0.000,
                },
                {
                    b = 0.314,
                    g = 0.498,
                    r = 1.000,
                },
                {
                    b = 1.000,
                    g = 0.565, 
                    r = 0.118,
                },
                {
                    b = 0.498,
                    g = 1.000, 
                    r = 0.000, 
                },
                {
                    b = 0.196,
                    g = 0.804, 
                    r = 0.604, 
                },
                {
                    b = 0.000,
                    g = 0.502,  
                    r = 0.000, 
                },
                {
                    b = 0.000,
                    g = 0.271,   
                    r = 1.000, 
                },
                {
                    b = 0.000,
                    g = 0.000,    
                    r = 1.000, 
                },
                {
                    b = 0.125,
                    g = 0.647,    
                    r = 0.855,  
                },
                {
                    b = 0.706,
                    g = 0.412,     
                    r = 1.000,  
                },
                {
                    b = 0.627,
                    g = 0.620,     
                    r = 0.373,  
                },
                {
                    b = 0.341,
                    g = 0.545,      
                    r = 0.180,  
                },
                {
                    b = 0.118,
                    g = 0.412,      
                    r = 0.824,   
                },
                {
                    b = 0.886,
                    g = 0.169,       
                    r = 0.541,    
                },
                {
                    b = 0.133,
                    g = 0.133,        
                    r = 0.698,    
                },     
            }
        }
    }
}

local Config_mt = { __index = Config }

local function cloneTable(t)
	local result = {}

	for k, v in pairs(t) do
		if 'table' == type(v) then
			result[k] = cloneTable(v)
		else
			result[k] = v
		end
	end

	return result
end

function Config:new(file)
    local self = base.setmetatable(cloneTable(self), Config_mt)
    local tbl = tools.safeDoFile(file, false)
    self.file = file
    if (tbl and tbl.config) then
        for k,v in pairs(tbl.config) do
            self[k] = v 
        end
    else
        tracer:info("Configuration not found, using defaults...")
    end    

    return self 
end

function Config:save()
    tracer:info("Saving configuration")
    U.saveInFile(self, 'config', self.file)	
end

return Config