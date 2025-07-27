import os, json, re, boto3, uuid

TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
SNS   = boto3.client("sns")
TOPIC = os.environ["TOPIC_ARN"]

# very simple validators
EMAIL_RE  = re.compile(r"^[^@]+@[^@]+\.[^@]+$")
FLIGHT_RE = re.compile(r"^[A-Z0-9\-]{3,10}$")

def handler(event, _ctx):
    # only allow POST
    if event.get("requestContext", {}).get("http", {}).get("method") != "POST":
        return _resp(405, {"error": "POST only"})

    # parse body
    try:
        body   = json.loads(event["body"] or "{}")
        flight = body.get("flightId", "").upper()
        email  = body.get("email", "")
    except ValueError:
        return _resp(400, {"error": "Invalid JSON"})

    # validate
    if not FLIGHT_RE.fullmatch(flight):
        return _resp(400, {"error": "Bad flightId"})
    if not EMAIL_RE.fullmatch(email):
        return _resp(400, {"error": "Bad e-mail"})

    # store in DynamoDB
    TABLE.put_item(Item={"FlightId": flight, "Email": email})

    # subscribe address to SNS topic (AWS will send confirmation e-mail)
    SNS.subscribe(
        TopicArn=TOPIC,
        Protocol="email",
        Endpoint=email,
        ReturnSubscriptionArn=False,                       # we don’t need the ARN now
        Attributes={"FilterPolicy": json.dumps({"FlightId": [flight]})},
    )

    return _resp(200, {"message": "Check your inbox for a confirmation e-mail!"})

def _resp(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"            # CORS header added
        },
        "body": json.dumps(body),
    }
