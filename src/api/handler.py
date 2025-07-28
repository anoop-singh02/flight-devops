import os, json, boto3

TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])

def handler(event, _ctx):
    # return up to 50 most‑recent rows
    items = TABLE.scan(Limit=50).get("Items", [])
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps(items, default=str)
    }
