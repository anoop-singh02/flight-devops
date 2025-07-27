import os, json, boto3
SNS = boto3.client("sns")
TOPIC = os.environ["TOPIC_ARN"]

def handler(event, _ctx):
    body = json.loads(event["body"] or "{}")
    fid  = body.get("flightId")
    email= body.get("email")
    if not fid or not email:
        return {"statusCode":400,
                "headers":{"Access-Control-Allow-Origin":"*"},
                "body":json.dumps({"error":"flightId and email required"})}

    resp = SNS.subscribe(
        TopicArn = TOPIC,
        Protocol = "email",
        Endpoint = email,
        Attributes={
            "FilterPolicy": json.dumps({"FlightId":[fid]})
        },
        ReturnSubscriptionArn=True
    )
    return {"statusCode":200,
            "headers":{"Access-Control-Allow-Origin":"*"},
            "body":json.dumps({"message":"Check your e‑mail to confirm"})}
