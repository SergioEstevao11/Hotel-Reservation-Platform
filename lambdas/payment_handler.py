import os
import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DDB_TABLE_NAME"])

def handler(event, context):
    for record in event["Records"]:
        try:
            body = json.loads(record["body"])
            user_id = body["user_id"]
            reservation_id = body["reservation_id"]

            print(f"💳 Processing payment for reservation {reservation_id} by user {user_id}")

            # Example: update 'paid' field to true
            response = table.update_item(
                Key={
                    "user_id": user_id,
                    "reservation_id": reservation_id
                },
                UpdateExpression="SET paid = :p",
                ExpressionAttributeValues={":p": True}
            )

            print(f"✅ Payment marked as complete for {reservation_id}")

        except Exception as e:
            print(f"❌ Error processing payment: {e}")
