#!/usr/bin/env python3
import threading
import time

from stockmq.api import Quik

def call(thread_id, n):
    api = Quik("tcp://10.211.55.3:8004")
    print(f"Thread {thread_id} started")

    for i in range(0, n):
        r = api.test(i)

def main():
    t0 = time.time()
    threads = []
    threads_count = 8
    calls_per_thread = 100000
    calls = 0
    for i in range(0, threads_count):
        calls += calls_per_thread
        threads.append(threading.Thread(target=call, args=(i, calls_per_thread)))

    for t in threads:
        t.start()

    for t in threads:
        t.join()

    t1 = time.time() - t0
    print(f"Calls {calls} RPS: {calls/t1}")

if __name__ == "__main__":
    main()
