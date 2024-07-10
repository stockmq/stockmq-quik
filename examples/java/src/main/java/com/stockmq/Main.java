package com.stockmq;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.msgpack.jackson.dataformat.MessagePackFactory;
import org.zeromq.SocketType;
import org.zeromq.ZContext;
import org.zeromq.ZMQ.Socket;
import org.zeromq.ZMQ.Poller;

import java.io.IOException;
import java.util.Arrays;
import java.util.Map;
import java.util.stream.Stream;

class RPCRuntimeException extends RuntimeException {
    public RPCRuntimeException(String message) {
        super(message);
    }
}

class RPCTimeoutException extends RuntimeException {
    public RPCTimeoutException() {
        super();
    }
}

class RPCClient implements AutoCloseable {
    private static final String RPC_OK = "OK";
    private final ZContext zmqCtx;
    private final Socket zmqSkt;
    private final int timeout;

    public RPCClient(String uri, int timeout) {
        this.timeout = timeout;
        zmqCtx = new ZContext(1);
        zmqSkt = zmqCtx.createSocket(SocketType.REQ);
        zmqSkt.setReceiveTimeOut(timeout);
        zmqSkt.setLinger(0);
        zmqSkt.connect(uri);
    }

    public <T> T call(String method, Object... args) throws IOException {
        ObjectMapper objectMapper = new ObjectMapper(new MessagePackFactory());

        zmqSkt.send(objectMapper.writeValueAsBytes(Stream.concat(Stream.of(method), Arrays.stream(args)).toList()));
        Poller poller = zmqCtx.createPoller(1);
        poller.register(zmqSkt, Poller.POLLIN);
        if (poller.poll(timeout) == Poller.POLLIN) {
            String status = zmqSkt.recvStr();
            byte[] result = zmqSkt.recv();
            if (RPC_OK.equals(status)) {
                return objectMapper.readValue(result, new TypeReference<>() {
                });
            } else {
                throw new RPCRuntimeException(objectMapper.readValue(result, new TypeReference<>() {}));
            }
        } else {
            throw new RPCTimeoutException();
        }
    }

    @Override
    public void close() {
        zmqSkt.close();
        zmqCtx.close();
    }
}

public class Main {
    public static void main(String[] args) {
        System.out.println("StockMQ Java Example");
        try (RPCClient rpc = new RPCClient("tcp://127.0.0.1:8004", 1000)) {
            Map<String, String> res = rpc.call("getParamEx2", "TQBR", "SBER", "LAST");
            System.out.println("Result " + res);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
