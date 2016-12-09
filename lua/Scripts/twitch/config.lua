local base = _G

module("twitch.config")

local require       = base.require
local table         = base.table
local string        = base.string
local math          = base.math
local assert        = base.assert
local pairs         = base.pairs
local ipairs        = base.ipairs

local tools 		= require('tools')
local lfs 			= require('lfs')
local U             = require('me_utilities')
local tracer        = require("twitch.tracer")

local Config = {
    version = 1,
    username = "",
    oathToken = "",
    debugMode = false,
    caps = {
        "twitch.tv/membership",
    },
    hostAddress = "irc.chat.twitch.tv",
    port = 6667,
    mode = "write",
    hotkey = "Ctrl+Shift+escape",
    timeout = 0,
    windowPosition = { x = 66, y = 13 },
    useMutiplayerChat = false,
    skins = {
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
local Config_mt = { __index = Config }

function Config:new(file)
    local config = base.setmetatable({}, Config_mt)
    local tbl = tools.safeDoFile(lfs.writedir() .. 'Config/Twitch2DCSConfig.lua', false)
    
    if (tbl and tbl.config) then
        for k,v in pairs(tbl.config) do
            config[k] = v 
        end
    else
        tracer:info("Configuration not found, using defaults...")
    end    

    return config 
end

function Config:save()
    U.saveInFile(self, 'config', lfs.writedir() .. 'Config/Twitch2DCSConfig.lua')	
end

return Config