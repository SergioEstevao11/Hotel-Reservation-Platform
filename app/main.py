import boto3, os, json
from uuid import uuid4
from fastapi import FastAPI, Request, HTTPException

app = FastAPI()
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

table = dynamodb.Table(os.environ["DDB_TABLE_NAME"])

def publish_event(item: dict, event_type: str):
    message = item.copy()
    message["event_type"] = event_type
    try:
        sns.publish(
            TopicArn=os.environ["SNS_TOPIC_ARN"],
            Message=json.dumps(message),
            Subject=event_type
        )
    except Exception as e:
        print(f"Failed to publish to SNS: {e}")

@app.get("/")
def health_check():
    return {"status": "healthy"}

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
    publish_event(item, "ReservationCreated")
    return {"reservation_id": reservation_id}

@app.put("/reserve/{reservation_id}")
async def update_reservation(reservation_id: str, req: Request):
    body = await req.json()
    try:
        table.update_item(
            Key={
                "user_id": body["user_id"],
                "reservation_id": reservation_id
            },
            UpdateExpression="SET check_in = :ci, check_out = :co, hotel_name = :hn, status = :st",
            ExpressionAttributeValues={
                ":ci": body["check_in"],
                ":co": body["check_out"],
                ":hn": body["hotel"],
                ":st": "updated"
            },
            ConditionExpression="attribute_exists(reservation_id)"
        )

        item = {
            "user_id": body["user_id"],
            "reservation_id": reservation_id,
            "check_in": body["check_in"],
            "check_out": body["check_out"],
            "hotel_name": body["hotel"],
            "status": "updated"
        }
        publish_event(item, "ReservationUpdated")
        return {"message": "Reservation updated"}

    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/reserve/{reservation_id}")
async def cancel_reservation(reservation_id: str, req: Request):
    body = await req.json()
    try:
        table.update_item(
            Key={
                "user_id": body["user_id"],
                "reservation_id": reservation_id
            },
            UpdateExpression="SET status = :st",
            ExpressionAttributeValues={":st": "cancelled"},
            ConditionExpression="attribute_exists(reservation_id)"
        )

        item = {
            "user_id": body["user_id"],
            "reservation_id": reservation_id,
            "status": "cancelled"
        }
        publish_event(item, "ReservationCancelled")
        return {"message": "Reservation cancelled"}

    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
