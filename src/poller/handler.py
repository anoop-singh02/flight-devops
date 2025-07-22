import json, os, boto3, datetime, random

TABLE_NAME = os.environ["TABLE_NAME"]
table = boto3.resource("dynamodb").Table(TABLE_NAME)

def handler(event, context):
    now       = datetime.datetime.utcnow().isoformat(timespec="seconds")
    flight_id = f"FAKE-{random.randint(100,999)}"
    status    = random.choice(["ON_TIME", "DELAYED", "CANCELLED"])

    item = {"FlightId": flight_id, "Timestamp": now, "Status": status}
    table.put_item(Item=item)
    return {"statusCode": 200, "body": json.dumps(item)}
