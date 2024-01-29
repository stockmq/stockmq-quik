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

-- Callbacks
function OnFirm(msg)
    stockmq_publish("OnFirm", {ts=stockmq_time(), msg=msg})
end

function OnAllTrade(msg)
    stockmq_publish("OnAllTrade", {ts=stockmq_time(), msg=msg})
end

function OnTrade(msg)
    stockmq_publish("OnTrade", {ts=stockmq_time(), msg=msg})
end

function OnOrder(msg)
    stockmq_publish("OnOrder", {ts=stockmq_time(), msg=msg})
end

function OnAccountBalance(msg)
    stockmq_publish("OnAccountBalance", {ts=stockmq_time(), msg=msg})
end

function OnFuturesLimitChange(msg)
    stockmq_publish("OnFuturesLimitChange", {ts=stockmq_time(), msg=msg})
end

function OnFuturesLimitDelete(msg)
    stockmq_publish("OnFuturesLimitDelete", {ts=stockmq_time(), msg=msg})
end

function OnFuturesClientHolding(msg)
    stockmq_publish("OnFuturesClientHolding", {ts=stockmq_time(), msg=msg})
end

function OnMoneyLimit(msg)
    stockmq_publish("OnMoneyLimit", {ts=stockmq_time(), msg=msg})
end

function OnMoneyLimitDelete(msg)
    stockmq_publish("OnMoneyLimitDelete", {ts=stockmq_time(), msg=msg})
end

function OnDepoLimit(msg)
    stockmq_publish("OnDepoLimit", {ts=stockmq_time(), msg=msg})
end

function OnDepoLimitDelete(msg)
    stockmq_publish("OnDepoLimitDelete", {ts=stockmq_time(), msg=msg})
end

function OnAccountPosition(msg)
    stockmq_publish("OnAccountPosition", {ts=stockmq_time(), msg=msg})
end

function OnNegDeal(msg)
    stockmq_publish("OnNegDeal", {ts=stockmq_time(), msg=msg})
end

function OnNegTrade(msg)
    stockmq_publish("OnNegTrade", {ts=stockmq_time(), msg=msg})
end

function OnStopOrder(msg)
    stockmq_publish("OnStopOrder", {ts=stockmq_time(), msg=msg})
end

function OnTransReply(msg)
    stockmq_publish("OnTransReply", {ts=stockmq_time(), msg=msg})
end

function OnParam(msg1, msg2)
    stockmq_publish("OnParam", {ts=stockmq_time(), msg={class_code=msg1, sec_code=msg2}})
end

function OnQuote(msg1, msg2)
    stockmq_publish("OnQuote", {ts=stockmq_time(), msg={class_code=msg1, sec_code=msg2}})
end

function OnDisconnected()
    stockmq_publish("OnDisconnected", {ts=stockmq_time(), msg=nil})
end

function OnConnected(msg)
    stockmq_publish("OnConnected", {ts=stockmq_time(), msg=msg})
end

function OnCleanUp()
    stockmq_publish("OnCleanUp", {ts=stockmq_time(), msg=nil})
end
