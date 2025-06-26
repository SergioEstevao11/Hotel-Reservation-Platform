import os
import json
import boto3
import stripe

# AWS resources
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DDB_TABLE_NAME"])

# Stripe setup (requires STRIPE_SECRET_KEY in env vars)
stripe.api_key = os.environ.get("STRIPE_SECRET_KEY")

def handle_payment_creation(user_id, reservation_id):
    # Simulate creating a Stripe charge or a PaymentIntent (PaymentIntent would have to be returned to the frontend)
    print(f"Creating payment for reservation {reservation_id}...")

    # Example: create a PaymentIntent in Stripe (requires amount & currency)
    # payment_intent = stripe.PaymentIntent.create(
    #     amount=10000,  # in cents
    #     currency="eur",
    #     metadata={"reservation_id": reservation_id, "user_id": user_id}
    # )

    # Update the DynamoDB item to mark as paid
    table.update_item(
        Key={"user_id": user_id, "reservation_id": reservation_id},
        UpdateExpression="SET paid = :p",
        ExpressionAttributeValues={":p": True}
    )

    print(f"Payment processed and marked for {reservation_id}")


def handle_payment_update(user_id, reservation_id):
    print(f"Reservation {reservation_id} was updated — no payment action taken.")


def handle_payment_refund(user_id, reservation_id):
    print(f"Processing refund for reservation {reservation_id}...")

    # Simulate refunding a Stripe payment
    # Possibility: store payment_intent_id in Dynamo and use it like:
    # stripe.Refund.create(payment_intent="pi_XXX")

    # Update the DynamoDB item to reflect cancellation/refund
    table.update_item(
        Key={"user_id": user_id, "reservation_id": reservation_id},
        UpdateExpression="SET paid = :p, status = :s",
        ExpressionAttributeValues={
            ":p": False,
            ":s": "cancelled"
        }
    )

    print(f"Refund recorded for reservation {reservation_id}")

def handler(event, context):
    for record in event["Records"]:
        try:
            body = json.loads(record["body"])
            user_id = body["user_id"]
            reservation_id = body["reservation_id"]
            event_type = body.get("eventType", "ReservationCreated")
            print(f"Received event type: {event_type}")

            if event_type == "ReservationCreated":
                handle_payment_creation(user_id, reservation_id)
            elif event_type == "ReservationUpdated":
                handle_payment_update(user_id, reservation_id)
            elif event_type == "ReservationCancelled":
                handle_payment_refund(user_id, reservation_id)
            else:
                print(f"Ignoring unsupported event type: {event_type}")

        except Exception as e:
            print(f"Error processing payment event: {e}")