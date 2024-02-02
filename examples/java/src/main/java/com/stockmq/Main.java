package com.stockmq;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.msgpack.core.MessageBufferPacker;
import org.msgpack.core.MessagePack;
import org.msgpack.core.MessageUnpacker;
import org.msgpack.jackson.dataformat.MessagePackFactory;
import org.zeromq.SocketType;
import org.zeromq.ZContext;
import org.zeromq.ZMQ;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

//TIP To <b>Run</b> code, press <shortcut actionId="Run"/> or
// click the <icon src="AllIcons.Actions.Execute"/> icon in the gutter.
public class Main {
    public static void main(String[] args) {
        //TIP Press <shortcut actionId="ShowIntentionActions"/> with your caret at the highlighted text
        // to see how IntelliJ IDEA suggests fixing it.
        System.out.println("StockMQ Java Example");

        try (ZContext context = new ZContext()) {
            // Connect to the QUIK RPC server
            ZMQ.Socket socket = context.createSocket(SocketType.REQ);
            socket.connect("tcp://10.211.55.3:8004");

            // Pack array in format (function name, ...arguments)
            MessageBufferPacker packer = MessagePack.newDefaultBufferPacker();
            packer
                    .packArrayHeader(1)
                    .packString("isConnected");
            packer.close();

            // Send message to the socket
            socket.send(packer.toByteArray());

            // Receive status and result
            String status = socket.recvStr();
            byte[] result = socket.recv();

            // Print status
            System.out.printf("Status %s\n", status);

            // Deserialize result which is int
            MessageUnpacker unpacker = MessagePack.newDefaultUnpacker(result);
            int isConnected = unpacker.unpackInt();

            // Print connection status to the broker
            System.out.printf("Connected: %b", isConnected > 0);

            // Pack SBER request
            ObjectMapper objectMapper = new ObjectMapper(new MessagePackFactory());
            List<String> list = List.of("getParamEx2", "TQBR", "SBER", "LAST");
            socket.send(objectMapper.writeValueAsBytes(list));

            String statusSBER = socket.recvStr();
            byte[] resultSBER = socket.recv();

            // Print SBER latest price data
            System.out.printf("Status %s\n", status);
            System.out.println("Result: ");
            System.out.println(objectMapper.readValue(resultSBER, new TypeReference<Map<String, String>>() {}));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}