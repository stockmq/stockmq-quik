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
        for i in ("trades", "orders", "stop_orders"):
            path = f"s3://trades/{date.today()}.{i}.csv"
            logger.info(f"Exporting {path}")
            df = pd.DataFrame.from_records(QuikTable(rpc, i))
            df.to_csv(path, storage_options=config['storage_options'])


if __name__ == "__main__":
    main()