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

-- Variables
local STOCKMQ_FLAKE_ID = 0
local STOCKMQ_FLAKE_EPOCH = 1704067200
local STOCKMQ_FLAKE_SLOTS = 64

local STOCKMQ_DS = {}
local STOCKMQ_DS_INTERVALS = {
    TICK = INTERVAL_TICK,
    M1   = INTERVAL_M1,
    M2   = INTERVAL_M2,
    M3   = INTERVAL_M3,
    M4   = INTERVAL_M4,
    M5   = INTERVAL_M5,
    M6   = INTERVAL_M6,
    M10  = INTERVAL_M10,
    M15  = INTERVAL_M15,
    M20  = INTERVAL_M20,
    M30  = INTERVAL_M30,
    H1   = INTERVAL_H1,
    H2   = INTERVAL_H2,
    H4   = INTERVAL_H4,
    D1   = INTERVAL_D1,
    W1   = INTERVAL_W1,
    MN1  = INTERVAL_MN1,
}

-- Initialize flakes
function stockmq_init_flake(epoch)
    if epoch ~= nil then
        STOCKMQ_FLAKE_EPOCH = epoch
    end

    sleep(1000)
end

-- Get last flake id
function stockmq_last_flake()
    return STOCKMQ_FLAKE_ID
end

-- Get next flake id ((Time - Epoch) * N + x) and throttle (N per second)
-- Epoch starts Jan 01 2024 00:00:00 GMT+0000
-- 64 transactions (flakes) per second allowed otherwise zero returned
function stockmq_next_flake()
    local t = math.floor(os.time() - STOCKMQ_FLAKE_EPOCH)
    local l = stockmq_last_flake()
    local n = 0

    if t == l // STOCKMQ_FLAKE_SLOTS then
        n = l % STOCKMQ_FLAKE_SLOTS + 1
        if n >= STOCKMQ_FLAKE_SLOTS then
            return 0
        end
    end

    t = t * STOCKMQ_FLAKE_SLOTS + n
    if t > 0x7FFFFFFF then
        error("Integer overflow")
    end

    STOCKMQ_FLAKE_ID = t
    return STOCKMQ_FLAKE_ID
end

-- Used to test serialization/deserialization
function stockmq_test(...)
    return table.unpack({...})
end

-- REPL helper function
function stockmq_repl(s)
    return assert(load(s))()
end

-- Convert datetime (with ms, mcs to unix timestamp)
function stockmq_datetime(d)
    local t = 0.0
    if d.year > 1601 then
        t = t + os.time(d)
        if d["mcs"] ~= nil then
            t = t + (d["mcs"] / 1000000.0)
        end
    end
    return t
end

--- Return current UNIX time
function stockmq_time()
    return StockMQ.time()
end

-- Format price with scale
function stockmq_format_price(price, scale)
    s = string.format("%."..scale.."f", price)
    if tonumber(s) ~= price then
        error("Incorrect price "..s.." != "..tostring(price))
    end
    return s
end

-- Get item from table or throw an error
function stockmq_table_get(t, i)
    if t[i] ~= nil then
        return t[i]
    end

    error("Invalid key "..tostring(i))
end

-- Get table keys
function stockmq_get_keys(t)
    local keys = {}
    for key,_ in pairs(t) do
      table.insert(keys, key)
    end
    return keys
end

-- Get item and fix fields
function stockmq_get_item(t, i)
    local item = getItem(t, i)
    if item ~= nil then
        for i, name in ipairs({"datetime", "withdraw_datetime", "canceled_datetime"}) do
            if item[name] ~= nil then
                item[name] = stockmq_datetime(item[name])
            end
        end
    end
    return item
end

-- Create new datasource
function stockmq_ds_create(ds_name, board, ticker, interval)
    local name = table.concat({ds_name, board, ticker, interval}, ":")

    if STOCKMQ_DS[name] ~= nil then
        return name
    end

    if STOCKMQ_DS_INTERVALS[interval] ~= nil then
        error("Invalid interval "..interval)
    end

    local ds, err = CreateDataSource(board, ticker, STOCKMQ_DS_INTERVALS[interval])
    if err ~= nil then
        error(err)
    end

    ds:SetEmptyCallback()

    STOCKMQ_DS[name] = ds
    return name
end

-- Delete datasource
function stockmq_ds_delete(name)
    STOCKMQ_DS[name]:SetEmptyCallback()
    STOCKMQ_DS[name]:Close()
    STOCKMQ_DS[name] = nil
end

-- Get size of the datasouce
function stockmq_ds_size(name)
    return STOCKMQ_DS[name]:Size()
end

-- Get record from the datasource (index starts from 0)
function stockmq_ds_peek(name, index)
    local ds = STOCKMQ_DS[name]
    local ix = index + 1
    if ix >= 1 and ix <= ds:Size() then
        return {
            O = ds:O(ix),
            H = ds:H(ix),
            L = ds:L(ix),
            C = ds:C(ix),
            V = ds:V(ix),
            T = os.time(ds:T(ix)),
        }
    end
end

