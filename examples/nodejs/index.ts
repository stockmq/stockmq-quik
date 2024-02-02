import { Request } from 'zeromq';
import { encode, decode } from '@msgpack/msgpack';

const url = 'tcp://10.211.55.3:8004';

async function run() {
  const sock = new Request();

  sock.connect(url);
  console.log(`RPC Client connected to ${url}`);

  await sock.send(encode(['isConnected']));
  const [status, result] = await sock.receive();

  console.log(`Status: ${status.toString()}`);
  console.log(`Result: ${decode(result)}`);
}

run()