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


-- Create order
function stockmq_create_order(account, client, board, ticker, time_in_force, side, price, quantity)
    return stockmq_create_tx({
        ACTION="NEW_ORDER",
        ACCOUNT=account,
        CLIENT_CODE=client,
        CLASSCODE=board,
        SECCODE=ticker,
        TYPE="L",
        EXECUTION_CONDITION=time_in_force,
        OPERATION=side,
        PRICE=price,
        QUANTITY=quantity,
    })
end

-- Create stop order
function stockmq_create_simple_stop_order(account, client, board, ticker, time_in_force, side, price, stop_price, quantity)
    return stockmq_create_tx({
        ACTION="NEW_STOP_ORDER",
        ACCOUNT=account,
        CLIENT_CODE=client,
        CLASSCODE=board,
        SECCODE=ticker,
        TYPE="L",
        STOP_ORDER_KIND="SIMPLE_STOP_ORDER",
        EXECUTION_CONDITION=time_in_force,
        OPERATION=side,
        PRICE=price,
        STOPPRICE=stop_price,
        QUANTITY=quantity,
    })
end

-- Cancel order
function stockmq_cancel_order(account, client, board, ticker, order_id)
    return stockmq_create_tx({
        ACTION="KILL_ORDER",
        ACCOUNT=account,
        CLIENT_CODE=client,
        CLASSCODE=board,
        SECCODE=ticker,
        ORDER_KEY=order_id,
    })
end

-- Cancel stop order
function stockmq_cancel_stop_order(account, client, board, ticker, order_id)
    return stockmq_create_tx({
        ACTION="KILL_STOP_ORDER",
        ACCOUNT=account,
        CLIENT_CODE=client,
        CLASSCODE=board,
        SECCODE=ticker,
        STOP_ORDER_KEY=order_id,
    })
end

-- Update order
function stockmq_update_order(board, id)
    local order = getOrderByNumber(board, id)

    return {
        id=id,
        trans_id=order.trans_id,
        board=order.class_code,
        ticker=order.sec_code,
        flags=order.flags,
    }
end
