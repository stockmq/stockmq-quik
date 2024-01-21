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
    .. getScriptPath() .. "\\lib\\?.dll"

-- Load C++ extension
require("StockMQ")

-- Global constants
STOCKMQ_ZMQ_REP = 4
STOCKMQ_ZMQ_PUB = 1

STOCKMQ_RPC_TIMEOUT = 10
STOCKMQ_RPC_URI = "tcp://0.0.0.0:8004"
STOCKMQ_PUB_URI = "tcp://0.0.0.0:8005"

-- Global variables
STOCKMQ_RUN = false
STOCKMQ_PUB = nil

-- Load StockMQ standard library
require("stockmq-core")
require("stockmq-transactions")
require("stockmq-orders")
require("stockmq-ds")

-- Set global variable which is used by main() function
function OnInit(script_path)
    STOCKMQ_PUB = StockMQ.bind(STOCKMQ_PUB_URI, STOCKMQ_ZMQ_PUB)
    STOCKMQ_RUN = true
end

-- Callback called when the script is stopped
function OnStop(signal)
    STOCKMQ_RUN = false
    return STOCKMQ_RPC_TIMEOUT
end

-- Main function
function main()
    stockmq_init_flake()
    local rpc = StockMQ.bind(STOCKMQ_RPC_URI, STOCKMQ_ZMQ_REP)

    message("StockMQ is listening on "..STOCKMQ_RPC_URI, 1)

    while STOCKMQ_RUN do
        if rpc:process() ~= 0 then
            message("StockMQ Error: code " .. tostring(rpc:errno()), 1)
        end
    end
end

-- Callback to process transaction replies
function OnTransReply(reply)
    stockmq_process_trans_reply(reply)
end
