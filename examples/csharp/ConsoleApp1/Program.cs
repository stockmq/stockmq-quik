using MessagePack;
using NetMQ;
using NetMQ.Sockets;

var threads = new List<Thread>();
var threadsCount = 8;
var batchSize = 100000;
var count = 0;

var t0 = DateTime.Now;

for (int i = 0; i < threadsCount; i++)
{
    count += batchSize;
    threads.Add(new Thread(() =>
    {
        Console.WriteLine("Starting Thread");
        using (var client = new RequestSocket())
        {
            client.Connect("tcp://10.211.55.3:8004");

            for (int i = 0; i < batchSize; i++)
            {
                client.SendFrame(MessagePackSerializer.Serialize(new object[] { "stockmq_test", i }));
                var status = client.ReceiveFrameString();
                var result = client.ReceiveFrameBytes();
                var r = MessagePackSerializer.Deserialize<int[]>(result);
                if (r[0] != i)
                {
                    throw new Exception("Invalid response");
                }
            }
        }
    }));
}

foreach (var thread in threads)
{
    thread.Start();
}

foreach (var thread in threads)
{
    thread.Join();
}

var t1 = DateTime.Now - t0;
Console.WriteLine($"Requests {count}, Time {t1.TotalSeconds}, RPS {count/t1.TotalSeconds}");
