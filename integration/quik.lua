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

-- Global constants
STOCKMQ_ZMQ_REP = 4
STOCKMQ_ZMQ_PUB = 1

STOCKMQ_RPC_TIMEOUT = 10
STOCKMQ_RPC_URI = "tcp://0.0.0.0:8004"

STOCKMQ_PUB_ENABLED = false
STOCKMQ_PUB_URI = "tcp://0.0.0.0:8005"

-- Global variables
STOCKMQ_RUN = false
STOCKMQ_PUB = nil

-- Load StockMQ standard library
require("stockmq-core")
require("stockmq-transactions")
require("stockmq-orders")
require("stockmq-ds")

-- Set global variables which is used by main() function
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


-- Callbacks
function OnFirm(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnFirm", {ts=StockMQ.time(), msg=msg})
    end
end

function OnAllTrade(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnAllTrade", {ts=StockMQ.time(), msg=msg})
    end
end

function OnTrade(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnTrade", {ts=StockMQ.time(), msg=msg})
    end
end

function OnOrder(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnOrder", {ts=StockMQ.time(), msg=msg})
    end
end

function OnAccountBalance(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnAccountBalance", {ts=StockMQ.time(), msg=msg})
    end
end

function OnFuturesLimitChange(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnFuturesLimitChange", {ts=StockMQ.time(), msg=msg})
    end
end

function OnFuturesLimitDelete(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnFuturesLimitDelete", {ts=StockMQ.time(), msg=msg})
    end
end

function OnFuturesClientHolding(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnFuturesClientHolding", {ts=StockMQ.time(), msg=msg})
    end
end

function OnMoneyLimit(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnMoneyLimit", {ts=StockMQ.time(), msg=msg})
    end
end

function OnMoneyLimitDelete(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnMoneyLimitDelete", {ts=StockMQ.time(), msg=msg})
    end
end

function OnDepoLimit(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnDepoLimit", {ts=StockMQ.time(), msg=msg})
    end
end

function OnDepoLimitDelete(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnDepoLimitDelete", {ts=StockMQ.time(), msg=msg})
    end
end

function OnAccountPosition(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnAccountPosition", {ts=StockMQ.time(), msg=msg})
    end
end

function OnNegDeal(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnNegDeal", {ts=StockMQ.time(), msg=msg})
    end
end

function OnNegTrade(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnNegTrade", {ts=StockMQ.time(), msg=msg})
    end
end

function OnStopOrder(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnStopOrder", {ts=StockMQ.time(), msg=msg})
    end
end

function OnParam(msg1, msg2)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnParam", {ts=StockMQ.time(), msg={class_code=msg1, sec_code=msg2}})
    end
end

function OnQuote(msg1, msg2)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnQuote", {ts=StockMQ.time(), msg={class_code=msg1, sec_code=msg2}})
    end
end

function OnDisconnected()
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnDisconnected", {ts=StockMQ.time(), msg=nil})
    end
end

function OnConnected(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnConnected", {ts=StockMQ.time(), msg=msg})
    end
end

function OnCleanUp()
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnCleanUp", {ts=StockMQ.time(), msg=nil})
    end
end

function OnTransReply(msg)
    if STOCKMQ_PUB_ENABLED then
        stockmq_publish("OnTransReply", {ts=StockMQ.time(), msg=msg})
    end

    stockmq_process_trans_reply(reply)
end
