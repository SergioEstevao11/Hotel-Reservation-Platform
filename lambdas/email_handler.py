import os, json, boto3
from jinja2 import Environment, FileSystemLoader, select_autoescape

dynamodb = boto3.resource("dynamodb")
ses = boto3.client("ses")

USER_TABLE = dynamodb.Table(os.environ["USER_TABLE_NAME"])
TEMPLATES_PATH = os.path.join(os.path.dirname(__file__), "templates")
SOURCE_EMAIL = os.environ["SOURCE_EMAIL"]

SUBJECT_MAP = {
    "ReservationCreated": "Your reservation has been created",
    "ReservationUpdated": "Your reservation has been updated",
    "ReservationCancelled": "Your reservation has been cancelled"
}

TEMPLATE_MAP = {
    "ReservationCreated": "created.html",
    "ReservationUpdated": "updated.html",
    "ReservationCancelled": "cancelled.html"
}

# Jinja2 environment
jinja_env = Environment(
    loader=FileSystemLoader(TEMPLATES_PATH),
    autoescape=select_autoescape(["html"])
)

def render_template(template_name, context):
    try:
        template = jinja_env.get_template(template_name)
        return template.render(**context)
    except Exception as e:
        print(f"Failed to render template {template_name}: {e}")
        return "<p>Error rendering template</p>"

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
            Source=SOURCE_EMAIL,
            Destination={"ToAddresses": [to_address]},
            Message={
                "Subject": {"Data": subject},
                "Body": {"Html": {"Data": html_body}},
            }
        )
        print(f"Email sent to {to_address}")
    except Exception as e:
        print(f"Failed to send email: {e}")

def handler(event, context):
    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            event_type = body.get("eventType")
            user_id = body.get("user_id")

            if event_type not in TEMPLATE_MAP:
                print(f"Unknown eventType: {event_type}")
                continue

            user_email = get_user_email(user_id)
            if not user_email:
                print(f"No email for user {user_id}")
                continue

            subject = SUBJECT_MAP[event_type]
            template_name = TEMPLATES_PATH[event_type]
            html_body = render_template(template_name, context=body)

            send_email(user_email, subject, html_body)

        except Exception as e:
            print(f"Error processing event: {e}")
