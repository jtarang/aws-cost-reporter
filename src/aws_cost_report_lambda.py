import json
import os
from datetime import datetime, timedelta

import boto3
import requests

SLACK_WEBHOOK_URL = os.environ['SLACK_WEBHOOK_URL']

def handler(event, context):
    ce_client = boto3.client('ce')

    # Define default values from environment variables
    tag_key = os.environ['AWS_COST_TARGET_TAG']
    tag_value = os.environ['AWS_COST_TARGET_KEY']

    # Override tag values if invoked via API Gateway (POST request with JSON body)
    if 'body' in event:
        try:
            body = json.loads(event['body'])
            tag_key = body.get('tag_key', tag_key)
            tag_value = body.get('tag_value', tag_value)
        except json.JSONDecodeError:
            return {'statusCode': 400, 'body': json.dumps({'error': 'Invalid JSON body'})}

    end_date = datetime.today().date()
    start_date = end_date - timedelta(days=30)

    resource_cost = get_cost_by_tag(ce_client, start_date, end_date, tag_key, tag_value)

    message = f"*AWS Cost Report*\n" \
              f"🔖 *Tag:* `{tag_key}={tag_value}`\n" \
              f"📅 *Time Period:* {start_date} → {end_date}\n" \
              f"💰 *Total Cost:* ${resource_cost:.2f}"

    send_to_slack(message)

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Cost report sent to Slack!', 'tag_key': tag_key, 'tag_value': tag_value})
    }

def get_cost_by_tag(ce_client, start_date, end_date, tag_key, tag_value):
    # Only use the Tags filter to query costs based on specific tags
    tag_filter = {
        "Key": tag_key,
        "Values": [tag_value]  # Filter by the specific tag key-value pair
    }

    response = ce_client.get_cost_and_usage(
        TimePeriod={'Start': str(start_date), 'End': str(end_date)},
        Granularity='DAILY',
        Filter={
            "Tags": tag_filter  # Apply the filter based on tags only
        },
        Metrics=['UnblendedCost']
    )
    return sum(float(entry["Total"]["UnblendedCost"]["Amount"]) for entry in response["ResultsByTime"])


def send_to_slack(message):
    payload = {"text": message}
    headers = {'Content-Type': 'application/json'}
    response = requests.post(SLACK_WEBHOOK_URL, data=json.dumps(payload), headers=headers)
    if response.status_code != 200:
        raise Exception(f"Slack API Error: {response.status_code}, Response: {response.text}")
    return  {"message": "Cost report sent to Slack!"}