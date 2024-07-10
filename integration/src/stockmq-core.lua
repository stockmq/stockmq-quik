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

-- Used to test serialization/deserialization
function stockmq_test(...)
    return table.unpack({...})
end

-- REPL helper function
function stockmq_repl(s)
    return assert(load(s))()
end

--- Return current UNIX time
function stockmq_time()
    return StockMQ.time()
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
