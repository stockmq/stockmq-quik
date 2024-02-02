package com.stockmq

import org.msgpack.MessagePack
import org.zeromq.SocketType
import org.zeromq.ZContext

/*
    StockMQ Kotlin Example
    Status OK
    Result {"param_image":"276.64","result":"1","param_value":"276.640000","param_type":"1"}
 */
fun main() {
    println("StockMQ Kotlin Example")
    ZContext().use { context ->
        val socket = context.createSocket(SocketType.REQ)
        socket.connect("tcp://10.211.55.3:8004")

        val req = MessagePack.pack(arrayOf("getParamEx2", "TQBR", "SBER", "LAST"))
        socket.send(req)

        val status = socket.recvStr()
        val result = socket.recv()

        println("Status $status")
        println("Result ${MessagePack.unpack(result)}")
    }
}