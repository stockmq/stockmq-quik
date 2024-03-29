package com.stockmq;

import java.io.IOException;
import java.util.Map;

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
