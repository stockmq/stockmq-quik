package com.stockmq

import org.msgpack.MessagePack
import org.zeromq.SocketType
import org.zeromq.ZContext
import org.zeromq.ZMQ

class RPCRuntimeException(message: String) : Exception(message)
class RPCTimeoutException() : Exception()

class RPCClient(uri: String = "tcp://127.0.0.1:8004", private val timeout: Int = 1000) : AutoCloseable {
    private val zmqCtx = ZContext(1)
    private val zmqSkt = zmqCtx.createSocket(SocketType.REQ).apply {
        this.receiveTimeOut = timeout
        this.linger = 0
        connect(uri)
    }

    fun call(method: String, vararg args: Any, timeout: Long = 100): Any {
        zmqSkt.send(MessagePack.pack(listOf(method, *args)))

        val poller = zmqCtx.createPoller(1).apply {
            register(zmqSkt, ZMQ.Poller.POLLIN)
        }

        if (poller.poll(timeout) == ZMQ.Poller.POLLIN) {
            val status = zmqSkt.recvStr()
            val result = zmqSkt.recv()
            if (status == RPC_OK) {
                return MessagePack.unpack(result)
            } else {
                throw RPCRuntimeException(MessagePack.unpack(result).toString())
            }
        } else {
            throw RPCTimeoutException()
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

fun main() {
    println("StockMQ Kotlin Example")
    RPCClient("tcp://127.0.0.1:8004").use { rpc ->
        val res = rpc.call("getParamEx2", "TQBR", "SBER", "LAST")
        println("Result $res")
    }
}
