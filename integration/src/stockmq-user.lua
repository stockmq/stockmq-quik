-- Place custom functions here.

--  Variables
local STOCKMQ_FLAKE_ID = 0
local STOCKMQ_FLAKE_SLOTS = 64
local STOCKMQ_TRANSACTIONS = {}

-- Constants
local STOCKMQ_ACCEPTED = "ACCEPTED"
local STOCKMQ_REJECTED = "REJECTED"
local STOCKMQ_EXECUTED = "EXECUTED"

-- Get last flake id
function stockmq_last_flake()
    return STOCKMQ_FLAKE_ID
end

-- Get next flake id ((Time - Epoch) * N + x) and throttle (N per second)
-- Epoch starts Jan 01 YEAR 00:00:00 GMT+0000
-- 64 transactions (flakes) per second allowed otherwise zero returned
function stockmq_next_flake()
    local e = os.time({year=os.date("%Y"), month=1, day=1, hour=0, min=0, sec=0})
    local t = math.floor(os.time() - e)
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

-- Send transaction
function stockmq_create_tx(tx)
    local rx = {
        id=tx.TRANS_ID or stockmq_next_flake(),
        action=tx.ACTION,
        board=tx.CLASSCODE,
        order_id=0,
        created_ts=stockmq_time(),
        updated_ts=0,
        state=STOCKMQ_REJECTED,
        message=""
    }

    -- Check transaction id
    if rx.id > 0 then
        tx.TRANS_ID = tostring(rx.id)
    else
        rx.message = "No free transaction slots"
        return rx
    end

    -- Format price and stop price
    if (tx["ACTION"] == "NEW_ORDER" or tx["ACTION"] == "NEW_STOP_ORDER") then
        local info = getSecurityInfo(tx["CLASSCODE"], tx["SECCODE"])
        if info ~= nil then
            tx["QUANTITY"] = tostring(tx["QUANTITY"])
            tx["PRICE"] = stockmq_format_price(tx["PRICE"], info["scale"])
            if tx["STOPPRICE"] ~= nil then
                tx["STOPPRICE"] = stockmq_format_price(tx["STOPPRICE"], info["scale"])
            end
        else
            rx.message = "Cannot get scale information"
            return rx
        end
    end

    if tx.ACTION == "KILL_ORDER" then
        rx.order_id = tx.ORDER_KEY
        tx.ORDER_KEY = tostring(tx.ORDER_KEY)
    elseif tx.ACTION == "KILL_STOP_ORDER" then
        rx.order_id = tx.STOP_ORDER_KEY
        tx.STOP_ORDER_KEY = tostring(tx.STOP_ORDER_KEY)
    end

    -- Send transaction
    rx.message = sendTransaction(tx)
    if rx.message == "" then
        rx.state = STOCKMQ_ACCEPTED
    end

    return rx
end

-- Update transaction using data from callbacks
function stockmq_update_tx_callbacks(tx)
    local reply = STOCKMQ_TRANSACTIONS[tx.id]
    if reply ~= nil then
        if reply.status == 3 then
            tx.state = STOCKMQ_EXECUTED
        elseif reply.status > 1 then
            tx.state = STOCKMQ_REJECTED
        end
        tx.order_id = reply.order_num
        tx.message = reply.result_msg
    end
    tx.updated_ts = stockmq_time()
    return tx
end

-- Update transaction using tables
function stockmq_update_tx_tables(tx)
    tx.message = ""

    local new_order_tables = {
        NEW_ORDER = "orders",
        NEW_STOP_ORDER = "stop_orders"
    }

    local t1 = new_order_tables[tx.action]
    if t1 ~= nil then
        for i = getNumberOf(t1) - 1, 0, -1 do
            local item = getItem(t1, i)
            if item.class_code == tx.board and item.trans_id == tx.id then
                tx.message = "polling: Order " .. tostring(item.order_num) .. " successfully registered" 
                tx.order_id = item.order_num
                tx.state = STOCKMQ_EXECUTED
            end
        end
    end

    local kill_order_tables = {
        KILL_ORDER = "orders",
        KILL_STOP_ORDER = "stop_orders"
    }

    local t2 = kill_order_tables[tx.action]
    if t2 ~= nil then
        for i = getNumberOf(t2) - 1, 0, -1 do
            local item = getItem(t2, i)
            if item.class_code == tx.board and item.order_num == tx.order_id then
                if bit.test(item.flags, 1) then
                    tx.message = "polling: Order " .. tostring(item.order_num) .. " has been cancelled"
                    tx.state = STOCKMQ_EXECUTED
                elseif bit.test(item.flags, 0) == false then
                    tx.message = "polling: Order " .. tostring(item.order_num) .. " was already executed"
                    tx.state = STOCKMQ_REJECTED
                end
            end
        end
    end
 
    tx.updated_ts = stockmq_time()
    return tx
end

-- Update transaction
function stockmq_update_tx(tx)
    tx = stockmq_update_tx_callbacks(tx)
    if tx.state ~= STOCKMQ_ACCEPTED then
        return tx
    end
    return stockmq_update_tx_tables(tx)
end

-- OnTransReply handler
function stockmq_process_trans_reply(reply)
    local id = reply.trans_id
    if STOCKMQ_TRANSACTIONS[id] == nil or (stockmq_datetime(reply["date_time"]) > stockmq_datetime(STOCKMQ_TRANSACTIONS[id]["date_time"])) then
        STOCKMQ_TRANSACTIONS[id] = reply
    end
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

function OnTransReply(msg)
    stockmq_process_trans_reply(reply)
end
