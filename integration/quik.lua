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

-- Load C++ extension
require("StockMQ")

-- Global variables
STOCKMQ_RPC_TIMEOUT = 10
STOCKMQ_RPC_URI = "tcp://0.0.0.0:8004"
STOCKMQ_RUN = false

-- Load StockMQ standard library
require("stockmq-core")
require("stockmq-transactions")

-- Main function
function main()
    sleep(1000)

    local rpc = StockMQ.bind(STOCKMQ_RPC_URI)

    message("StockMQ is listening on "..STOCKMQ_RPC_URI, 1)

    while STOCKMQ_RUN do
        if rpc:process() ~= 0 then
            message("StockMQ Error: code " .. tostring(rpc:errno()), 1)
        end
    end
end

-- Callbacks
function OnInit(script_path)
    STOCKMQ_RUN = true
end

function OnStop(signal)
    STOCKMQ_RUN = false
    return STOCKMQ_RPC_TIMEOUT
end

function OnTransReply(msg)
    stockmq_process_trans_reply(msg)
end
