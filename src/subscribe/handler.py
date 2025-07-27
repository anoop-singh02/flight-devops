import os, json, boto3, re
SNS   = boto3.client("sns")
TOPIC = os.environ["TOPIC_ARN"]
EMAIL = re.compile(r"[^@]+@[^@]+\.[^@]+")

def handler(event, _):
    body   = json.loads(event.get("body") or "{}")
    email  = body.get("email", "").strip()
    flight = body.get("flightId", "").strip().upper()

    if not EMAIL.fullmatch(email) or not flight:
        return {"statusCode":400,
                "body":json.dumps({"error":"Bad request"})}

    SNS.subscribe(
        TopicArn   = TOPIC,
        Protocol   = "email",
        Endpoint   = email,
        Attributes = {
            "FilterPolicy": json.dumps({"FlightId":[flight]})
        }
    )
    return {"statusCode":200,
            "headers":{"Access-Control-Allow-Origin":"*"},
            "body":json.dumps({"message":"Check your e‑mail to confirm"})}
