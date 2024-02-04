package com.stockmq

import org.msgpack.MessagePack
import org.zeromq.SocketType
import org.zeromq.ZContext
import org.zeromq.ZMQ

class RPCRuntimeError(message: String) : Exception(message)
class RPCTimeoutError(message: String) : Exception(message)

class RPCClient(uri: String = "tcp://127.0.0.1:8004", private val timeout: Int = 5000) : AutoCloseable {
    private val zmqCtx = ZContext(1)
    private val zmqSkt = zmqCtx.createSocket(SocketType.REQ).apply {
        this.receiveTimeOut = timeout
        this.linger = 0
        connect(uri)
    }

    fun call(method: String, vararg args: Any, timeout: Int? = null): Any {
        zmqSkt.send(MessagePack.pack(listOf(method, *args)))

        val poller = zmqCtx.createPoller(1).apply {
            register(zmqSkt, ZMQ.Poller.POLLIN)
        }

        if (poller.poll((timeout ?: this.timeout).toLong()) == ZMQ.Poller.POLLIN) {
            val status = zmqSkt.recvStr()
            val result = zmqSkt.recv()
            if (status == RPC_OK) {
                return MessagePack.unpack(result)
            } else {
                throw RPCRuntimeError(result.toString())
            }
        } else {
            throw RPCTimeoutError("Timeout error")
        }
    }

    override fun close() {
        zmqSkt.close()
        zmqCtx.close()
    }

    companion object {
        const val RPC_OK = "OK"
    }
}

/*
    StockMQ Kotlin Example
    Result {"param_image":"276.64","result":"1","param_value":"276.640000","param_type":"1"}
 */
fun main() {
    println("StockMQ Kotlin Example")
    RPCClient("tcp://10.211.55.3:8004").use { rpc ->
        val res = rpc.call("getParamEx2", "TQBR", "SBER", "LAST")
        println("Result $res")
    }
}