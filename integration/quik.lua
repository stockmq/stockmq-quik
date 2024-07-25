--[[
 * This file is part of the StockMQ distribution (https://github.com/StockMQ)
 * Copyright (c) 2022-2024 Alexander Nusov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
]]

-- Configure LUA_PATH
package.path = package.path .. ';'
    .. getScriptPath() .. "\\src\\?.lua"

-- Configure LUA_CPATH
package.cpath = package.cpath .. ';' 
    .. getScriptPath() .. "\\lib\\"
    .. _VERSION:gsub("Lua (%d).(%d)", "lua%1%2").. "\\Release\\?.dll"

-- Load C++ extension and core library
require("stockmq")
require("stockmq-core")
require("stockmq-user")

-- Global variables
STOCKMQ_RUN = false
STOCKMQ_RPC_TIMEOUT = 10

STOCKMQ_RPC_URI = "tcp://127.0.0.1:8004"
STOCKMQ_PUB_URI = "tcp://127.0.0.1:8005"

-- Main function
function main()
    local rpc = stockmq.rpc(STOCKMQ_RPC_URI)
    message("StockMQ is listening on" 
        .. "\nRPC: " .. STOCKMQ_RPC_URI
        .. "\nPUB: " .. STOCKMQ_PUB_URI, 1)

    while STOCKMQ_RUN do
        if rpc:process() ~= 0 then
            message("StockMQ error: code " .. tostring(rpc:errno()), 1)
        end
    end
end

-- Callbacks
function OnInit(script_path)
    STOCKMQ_PUB = stockmq.pub(STOCKMQ_PUB_URI)
    STOCKMQ_RUN = true
end

function OnStop(signal)
    STOCKMQ_RUN = false
    return STOCKMQ_RPC_TIMEOUT
end
