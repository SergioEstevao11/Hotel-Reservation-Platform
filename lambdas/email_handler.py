import boto3, os, json
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
ses = boto3.client("ses")

USER_TABLE = dynamodb.Table(os.environ["USER_TABLE_NAME"])
TEMPLATES_PATH = os.path.join(os.path.dirname(__file__), "templates")

def get_email_template(template_name):
    try:
        template_file = os.path.join(TEMPLATES_PATH, template_name)
        with open(template_file, "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        print(f"Failed to load local email template '{template_name}': {e}")
        return "<p>Template error</p>"

def get_user_email(user_id):
    try:
        response = USER_TABLE.get_item(Key={"user_id": user_id})
        return response["Item"]["email"]
    except Exception as e:
        print(f"Could not get user email: {e}")
        return None

def send_email(to_address, subject, html_body):
    try:
        ses.send_email(
            Source=os.environ["SES_SENDER"],
            Destination={"ToAddresses": [to_address]},
            Message={
                "Subject": {"Data": subject},
                "Body": {"Html": {"Data": html_body}},
            }
        )
        print(f"Email sent to {to_address}")
    except ClientError as e:
        print(f"Failed to send email: {e.response['Error']['Message']}")

def handler(event, context):
    print("Email Handler Triggered")
    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            event_type = body.get("eventType")
            user_id = body.get("user_id")

            print(f"Processing event {event_type} for user {user_id}")

            user_email = get_user_email(user_id)
            if not user_email:
                print(f"No email found for user {user_id}, skipping.")
                continue

            if event_type == "ReservationCreated":
                subject = "Your reservation has been created"
                template_name = "created.html"
            elif event_type == "ReservationUpdated":
                subject = "Your reservation has been updated"
                template_name = "updated.html"
            elif event_type == "ReservationCancelled":
                subject = "Your reservation has been cancelled"
                template_name = "cancelled.html"
            else:
                print(f"Unknown event type: {event_type}")
                continue

            html_template = get_email_template(template_name)
            send_email(user_email, subject, html_template)

        except Exception as e:
            print(f"Error processing record: {e}")
