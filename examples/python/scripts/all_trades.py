import time

import pandas as pd
import yaml
import logging
from datetime import date

from stockmq.api import QuikTable
from stockmq.rpc import RPCClient

logging.basicConfig()
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

with open('configs/reports.yaml') as f:
    config = yaml.safe_load(f)


def main():
    with RPCClient("tcp://10.211.55.3:8004") as rpc:
        path = f"s3://trades/{date.today()}.all_trades.csv"
        logger.info(f"Exporting {path}")
        table = QuikTable(rpc, "all_trades")
        records = []
        print(len(table))
        t0 = time.time()
        for i in table:
            records.append(i)

        print(f"done in {time.time()-t0}")
        df = pd.DataFrame.from_records(list(table))
        df.to_csv(path, storage_options=config['storage_options'])


if __name__ == "__main__":
    main()