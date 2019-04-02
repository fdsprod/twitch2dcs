--Some code below from https://github.com/FlightControl-Master/MOOSE/blob/master/Moose%20Development/Moose/Utilities/Routines.lua

local base = _G

local type = base.type
local table = base.table
local string = base.string
local pairs = base.pairs
local tostring = base.tostring
local tonumber = base.tonumber
local math = base.math

module("twitch.utils")

function IsSequential( t )
	local i = 1
	for key, value in pairs( t ) do
		if ( not tonumber( i ) or key ~= i ) then return false end
		i = i + 1
	end
	return true
end

local function MakeTable( t, nice, indent, done )
	local str = ""
	local done = done or {}
	local indent = indent or 0
	local idt = ""
	if nice then idt = string.rep( "\t", indent ) end
	local nl, tab = "", ""
	if ( nice ) then nl, tab = "\n", "\t" end

	local sequential = IsSequential( t )

	for key, value in pairs( t ) do

		str = str .. idt .. tab .. tab

		if not sequential then
			if type( key ) == "number" or type( key ) == "boolean" then
				key = "[" .. tostring( key ) .. "]" .. tab .. "="
			else
				key = tostring( key ) .. tab .. "="
			end
		else
			key = ""
		end

		if ( type(value) == "table" and not done[ value ] ) then

			done [ value ] = true
			str = str .. key .. tab .. "{" .. nl .. MakeTable( value, nice, indent + 1, done )
			str = str .. idt .. tab .. tab .. tab .. tab .."},".. nl

		else

			if ( type( value ) == "string" ) then
				value = '"' .. tostring( value ) .. '"'
			elseif ( type( value ) == "Vector" ) then
				value = "Vector(" .. value.x .. "," .. value.y .. "," .. value.z .. ")"
			elseif ( type( value ) == "Angle" ) then
				value = "Angle(" .. value.pitch .. "," .. value.yaw .. "," .. value.roll .. ")"
			else
				value = tostring( value )
			end

			str = str .. key .. tab .. value .. "," .. nl

		end

	end
	return str
end

function ToString( t, n, nice )
	local nl, tab  = "", ""
	if ( nice ) then nl, tab = "\n", "\t" end

	local str = ""
	if ( n ) then str = n .. tab .. "=" .. tab end
	return str .. "{" .. nl .. MakeTable( t, nice ) .. "}"
end

-- porting in Slmod's serialize_slmod2
function oneLineSerialize(tbl)  -- serialization of a table all on a single line, no comments, made to replace old get_table_string function

	lookup_table = {}

	local function _Serialize( tbl )

		if type(tbl) == 'table' then --function only works for tables!

			if lookup_table[tbl] then
				return lookup_table[object]
			end

			local tbl_str = {}
			
			lookup_table[tbl] = tbl_str
			
			tbl_str[#tbl_str + 1] = '{'

			for ind,val in pairs(tbl) do -- serialize its fields
				local ind_str = {}
				if type(ind) == "number" then
					ind_str[#ind_str + 1] = '['
					ind_str[#ind_str + 1] = tostring(ind)
					ind_str[#ind_str + 1] = ']='
				else --must be a string
					ind_str[#ind_str + 1] = '['
					ind_str[#ind_str + 1] = basicSerialize(ind)
					ind_str[#ind_str + 1] = ']='
				end

				local val_str = {}
				if ((type(val) == 'number') or (type(val) == 'boolean')) then
					val_str[#val_str + 1] = tostring(val)
					val_str[#val_str + 1] = ','
					tbl_str[#tbl_str + 1] = table.concat(ind_str)
					tbl_str[#tbl_str + 1] = table.concat(val_str)
			elseif type(val) == 'string' then
					val_str[#val_str + 1] = basicSerialize(val)
					val_str[#val_str + 1] = ','
					tbl_str[#tbl_str + 1] = table.concat(ind_str)
					tbl_str[#tbl_str + 1] = table.concat(val_str)
				elseif type(val) == 'nil' then -- won't ever happen, right?
					val_str[#val_str + 1] = 'nil,'
					tbl_str[#tbl_str + 1] = table.concat(ind_str)
					tbl_str[#tbl_str + 1] = table.concat(val_str)
				elseif type(val) == 'table' then
					if ind == "__index" then
					--	tbl_str[#tbl_str + 1] = "__index"
					--	tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
					else

						val_str[#val_str + 1] = _Serialize(val)
						val_str[#val_str + 1] = ','   --I think this is right, I just added it
						tbl_str[#tbl_str + 1] = table.concat(ind_str)
						tbl_str[#tbl_str + 1] = table.concat(val_str)
					end
				elseif type(val) == 'function' then
				--	tbl_str[#tbl_str + 1] = "function " .. tostring(ind)
				--	tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
				else
--					env.info('unable to serialize value type ' .. basicSerialize(type(val)) .. ' at index ' .. tostring(ind))
--					env.info( debug.traceback() )
				end

			end
			tbl_str[#tbl_str + 1] = '}'
			return table.concat(tbl_str)
		else
			return tostring(tbl)
		end
	end

	local objectreturn = _Serialize(tbl)
	return objectreturn
end
--porting in Slmod's "safestring" basic serialize
function basicSerialize(s)
	if s == nil then
		return "\"\""
	else
		if ((type(s) == 'number') or (type(s) == 'boolean') or (type(s) == 'function') or (type(s) == 'table') or (type(s) == 'userdata') ) then
			return tostring(s)
		elseif type(s) == 'string' then
			s = string.format('%q', s)
			return s
		end
	end
end

function rgbToHex(rgb)
	local hexadecimal = '0x'

	for key, value in pairs(rgb) do
		local hex = ''
		value = value * 255
		while(value > 0)do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789abcdef', index, index) .. hex
		end

		if(string.len(hex) == 0)then
			hex = '00'

		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end

		hexadecimal = hexadecimal .. hex
	end

	return hexadecimal .. 'ff'
end

return {
	rgbToHex = rgbToHex
}
