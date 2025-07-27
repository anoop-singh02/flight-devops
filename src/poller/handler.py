import os, json, boto3, decimal, datetime
from decimal import Decimal

DDB   = boto3.resource("dynamodb")
TABLE = DDB.Table(os.environ["TABLE_NAME"])
SNS   = boto3.client("sns")
TOPIC = os.environ["TOPIC_ARN"]           # <- add this env in Terraform if missing

def handler(event, _ctx):
    # ─── poll some external API (omitted – your existing code) ───────────
    flights = fake_flights()  # returns list of {'FlightId','Status', …}

    # fetch previous snapshot by FlightId
    prev = {i["FlightId"]: i["Status"]
            for i in TABLE.scan(ProjectionExpression="FlightId, #S",
                               ExpressionAttributeNames={"#S": "Status"})["Items"]}

    # write any rows & publish status changes
    with TABLE.batch_writer() as bw:
        for row in flights:
            fid, status = row["FlightId"], row["Status"]
            row["Timestamp"] = datetime.datetime.utcnow().isoformat(timespec="seconds")
            # Dynamo wants Decimals, not floats
            row = json.loads(json.dumps(row), parse_float=Decimal)

            bw.put_item(Item=row)

            if prev.get(fid) and prev[fid] != status:
                # ---------- PUBLISH TO SNS ----------
                SNS.publish(
                    TopicArn=TOPIC,
                    Subject=f"Flight {fid} status changed to {status}",
                    Message=json.dumps({"FlightId": fid, "Status": status}),
                    MessageAttributes={
                        "FlightId": {
                            "DataType": "String",
                            "StringValue": fid
                        }
                    }
                )

def fake_flights():
    # … your existing generator …
    return []
