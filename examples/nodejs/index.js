"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const zeromq_1 = require("zeromq");
const msgpack_1 = require("@msgpack/msgpack");
const url = 'tcp://10.211.55.3:8004';
async function run() {
    const sock = new zeromq_1.Request();
    sock.connect(url);
    console.log(`RPC Client connected to ${url}`);
    await sock.send((0, msgpack_1.encode)(['isConnected']));
    const [status, result] = await sock.receive();
    console.log(`Status: ${status.toString()}`);
    console.log(`Result: ${(0, msgpack_1.decode)(result)}`);
}
run();
