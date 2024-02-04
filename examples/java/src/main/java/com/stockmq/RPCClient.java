package com.stockmq;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.msgpack.jackson.dataformat.MessagePackFactory;
import org.zeromq.SocketType;
import org.zeromq.ZContext;
import org.zeromq.ZMQ;

import java.io.IOException;
import java.util.Arrays;
import java.util.stream.Stream;

class RPCRuntimeError extends RuntimeException {
    public RPCRuntimeError(String message) {
        super(message);
    }
}

class RPCTimeoutError extends RuntimeException {
    public RPCTimeoutError(String message) {
        super(message);
    }
}

public class RPCClient implements AutoCloseable {
    private static final String RPC_OK = "OK";
    private ZContext zmqCtx;
    private ZMQ.Socket zmqSkt;
    private int timeout;

    public RPCClient() {
        this("tcp://127.0.0.1:8004", 5000);
    }

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
        ZMQ.Poller poller = zmqCtx.createPoller(1);
        poller.register(zmqSkt, ZMQ.Poller.POLLIN);
        if (poller.poll(timeout) == ZMQ.Poller.POLLIN) {
            String status = zmqSkt.recvStr();
            byte[] result = zmqSkt.recv();
            if (RPC_OK.equals(status)) {
                return objectMapper.readValue(result, new TypeReference<T>() {});
            } else {
                throw new RPCRuntimeError(new String(result));
            }
        } else {
            throw new RPCTimeoutError("Timeout error");
        }
    }

    @Override
    public void close() {
        zmqSkt.close();
        zmqCtx.close();
    }
}