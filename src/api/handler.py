import os, json, boto3, decimal

TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])

def handler(event, _ctx):
    # latest row = highest sort‑key (Timestamp) for the partition you care about.
    # demo: just return **any** one of the newest 20 rows.
    items = TABLE.scan(Limit=20)["Items"]
    return {
        "statusCode": 200,
        "headers": {"Content‑Type": "application/json"},
        "body": json.dumps(items, default=str)   # decimal → str
    }
