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

-- Create new datasource
function stockmq_ds_create(ds_name, board, ticker, interval, stream)
    local name = table.concat({stream and "S" or "D", ds_name, board, ticker, interval}, ":")

    if STOCKMQ_DS[name] ~= nil then
        return name
    end

    local ds, err = CreateDataSource(board, ticker, STOCKMQ_DS_INTERVALS[interval])
    if err ~= nil then
        error(err)
    end

    if stream then
        ds:SetUpdateCallback(stockmq_ds_callback(name))
    else
        ds:SetEmptyCallback()
    end

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

-- Callback clojure for the datasource
function stockmq_ds_callback(name)
    return function(index)
        stockmq_publish(name, {ts=stockmq_time(), msg=stockmq_ds_peek(name, index-1)})
    end
end
