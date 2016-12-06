local base = _G

package.path  = package.path..";.\\LuaSocket\\?.lua;"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'
package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

module("Twitch")

local socket = require("socket")
local connection = nil

Twitch = {

}

function Twitch:new(username, oauth) 
    connection = socket.tcp()
end

function Twitch:connect(hostAddress, port)
    local ip = socket.dns.toip(hostAddress)
    local success = assert(twitch.connection:connect(ip, port))
    
end