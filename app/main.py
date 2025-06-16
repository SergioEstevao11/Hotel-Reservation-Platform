import boto3
import os
import time

sns_topic_arn = os.environ.get("SNS_TOPIC_ARN")
sns = boto3.client("sns", region_name=os.environ.get("AWS_REGION", "eu-west-1"))

def handler():
    print("Reservation Received! Sending message to SNS...")
    sns.publish(
        TopicArn=sns_topic_arn,
        Message="Booking event: room reserved",
        Subject="New Booking"
    )
    print("Message sent.")

if __name__ == "__main__":
    time.sleep(2)
    handler()
