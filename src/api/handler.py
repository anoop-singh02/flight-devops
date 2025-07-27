import os, json, boto3, decimal

TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])

def handler(event, _ctx):
    # pull the latest 20 items
    items = TABLE.scan(Limit=20)["Items"]

    # build the HTTP response
    response = {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(items, default=str)
    }

    # ←— ADD THIS LINE:
    print("RETURNING:", json.dumps(response))

    return response
