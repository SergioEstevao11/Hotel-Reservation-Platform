import boto3, os, json
from uuid import uuid4
from fastapi import FastAPI, Request

app = FastAPI()
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

table = dynamodb.Table(os.environ["DDB_TABLE_NAME"])

@app.post("/reserve")
async def reserve(req: Request):
    body = await req.json()
    reservation_id = str(uuid4())
    item = {
        "user_id": body["user_id"],
        "reservation_id": reservation_id,
        "hotel_name": body["hotel"],
        "check_in": body["check_in"],
        "check_out": body["check_out"],
        "status": "pending",
        "paid": False
    }
    table.put_item(Item=item)

    sns.publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Message=json.dumps(item),
        Subject="ReservationCreated"
    )

    return {"reservation_id": reservation_id}
