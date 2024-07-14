import { Request } from 'zeromq';
import { encode, decode } from '@msgpack/msgpack';

class RPCRuntimeError extends Error {}
class RPCTimeoutError extends Error {}

class RPCClient {
    private static readonly RPC_OK: string = 'OK';
    private static readonly EAGAIN: string = 'EAGAIN';
    private zmq_skt: Request;

    constructor(uri: string = 'tcp://127.0.0.1:8004', timeout: number = 1000) {
        this.zmq_skt = new Request({receiveTimeout: timeout, immediate: false, linger: 0});
        this.zmq_skt.connect(uri);
    }

    public async call(method: string, ...args: any[]): Promise<any> {
        try {
            await this.zmq_skt.send(encode([method, ...args]));
            const [s1, s2] = await this.zmq_skt.receive();
            const status = s1.toString();
            const result = decode(s2);
            if (status === RPCClient.RPC_OK) {
                return result;
            } else {
                throw new RPCRuntimeError(String(result));
            }
        } catch (err) {
            if (Object(err).code === RPCClient.EAGAIN) {
                throw new RPCTimeoutError();
            } else {
                throw err;
            }
        }
    }

    public close(): void {
        this.zmq_skt.close();
    }
}

async function run() {
    console.log('StockMQ NodeJS Example');

    const rpc = new RPCClient('tcp://127.0.0.1:8004');
    const res = await rpc.call('getParamEx2', 'TQBR', 'SBER', 'LAST');
    
    console.log(`Result ${JSON.stringify(res)}`);
    rpc.close()
}

run()
