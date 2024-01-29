--[[
 * This file is part of the StockMQ distribution (https://github.com/StockMQ).
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
STOCKMQ_PUB_URI = "tcp://0.0.0.0:8005"

-- Global variables
STOCKMQ_RUN = false
STOCKMQ_PUB = nil

-- Used to test serialization/deserialization
function stockmq_test(...)
    return table.unpack({...})
end

-- REPL helper function
function stockmq_repl(s)
    return assert(load(s))()
end

-- Publish messages if STOCKMQ_PUB is defined
function stockmq_publish(topic, message)
    if STOCKMQ_PUB ~= nil then 
        STOCKMQ_PUB:send(topic, message)
    end
end

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
    local rpc = StockMQ.bind(STOCKMQ_RPC_URI, STOCKMQ_ZMQ_REP)
    while STOCKMQ_RUN do
        if rpc:process() ~= 0 then
            message("StockMQ Error: code " .. tostring(rpc:errno()), 1)
        end
    end
end

-- Callbacks
function OnFirm(msg)
    stockmq_publish("OnFirm", {ts=StockMQ.time(), msg=msg})
end

function OnAllTrade(msg)
    stockmq_publish("OnAllTrade", {ts=StockMQ.time(), msg=msg})
end

function OnTrade(msg)
    stockmq_publish("OnTrade", {ts=StockMQ.time(), msg=msg})
end

function OnOrder(msg)
    stockmq_publish("OnOrder", {ts=StockMQ.time(), msg=msg})
end

function OnAccountBalance(msg)
    stockmq_publish("OnAccountBalance", {ts=StockMQ.time(), msg=msg})
end

function OnFuturesLimitChange(msg)
    stockmq_publish("OnFuturesLimitChange", {ts=StockMQ.time(), msg=msg})
end

function OnFuturesLimitDelete(msg)
    stockmq_publish("OnFuturesLimitDelete", {ts=StockMQ.time(), msg=msg})
end

function OnFuturesClientHolding(msg)
    stockmq_publish("OnFuturesClientHolding", {ts=StockMQ.time(), msg=msg})
end

function OnMoneyLimit(msg)
    stockmq_publish("OnMoneyLimit", {ts=StockMQ.time(), msg=msg})
end

function OnMoneyLimitDelete(msg)
    stockmq_publish("OnMoneyLimitDelete", {ts=StockMQ.time(), msg=msg})
end

function OnDepoLimit(msg)
    stockmq_publish("OnDepoLimit", {ts=StockMQ.time(), msg=msg})
end

function OnDepoLimitDelete(msg)
    stockmq_publish("OnDepoLimitDelete", {ts=StockMQ.time(), msg=msg})
end

function OnAccountPosition(msg)
    stockmq_publish("OnAccountPosition", {ts=StockMQ.time(), msg=msg})
end

function OnNegDeal(msg)
    stockmq_publish("OnNegDeal", {ts=StockMQ.time(), msg=msg})
end

function OnNegTrade(msg)
    stockmq_publish("OnNegTrade", {ts=StockMQ.time(), msg=msg})
end

function OnStopOrder(msg)
    stockmq_publish("OnStopOrder", {ts=StockMQ.time(), msg=msg})
end

function OnTransReply(msg)
    stockmq_publish("OnTransReply", {ts=StockMQ.time(), msg=msg})
end

function OnParam(msg1, msg2)
    stockmq_publish("OnParam", {ts=StockMQ.time(), msg={class_code=msg1, sec_code=msg2}})
end

function OnQuote(msg1, msg2)
    stockmq_publish("OnQuote", {ts=StockMQ.time(), msg={class_code=msg1, sec_code=msg2}})
end

function OnDisconnected()
    stockmq_publish("OnDisconnected", {ts=StockMQ.time(), msg=nil})
end

function OnConnected(msg)
    stockmq_publish("OnConnected", {ts=StockMQ.time(), msg=msg})
end

function OnCleanUp()
    stockmq_publish("OnCleanUp", {ts=StockMQ.time(), msg=nil})
end
