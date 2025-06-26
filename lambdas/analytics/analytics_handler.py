import json

def handler(event, context):
    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            event_type = body.get("eventType")
            print(f"Received event: {event_type}")
            print(f"Full payload: {body}")


        except Exception as e:
            print(f"Error processing record: {e}")