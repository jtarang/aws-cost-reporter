import json
import os
from datetime import UTC, datetime

import boto3
import requests
from dateutil.relativedelta import relativedelta

SLACK_WEBHOOK_URL = os.environ['SLACK_WEBHOOK_URL']


def handler(event, context):
    ce_client = boto3.client('ce')

    # Default single target from environment variables (fallback)
    default_targets = [
        {
            "tag_key": os.environ['AWS_COST_TARGET_TAG'],
            "tag_value": os.environ['AWS_COST_TARGET_KEY']
        }
    ]

    # Resolve targets from event payload (Lambda direct invoke or API Gateway)
    targets = default_targets
    if 'cost_tracker_targets' in event:
        # Direct Lambda invoke via GitHub Actions pipeline
        targets = event['cost_tracker_targets']
    elif 'body' in event:
        # API Gateway POST request
        try:
            body = json.loads(event['body'])
            if 'cost_tracker_targets' in body:
                targets = body['cost_tracker_targets']
            else:
                # Legacy single tag_key/tag_value support
                targets = [
                    {
                        "tag_key": body.get('tag_key', default_targets[0]['tag_key']),
                        "tag_value": body.get('tag_value', default_targets[0]['tag_value'])
                    }
                ]
        except json.JSONDecodeError:
            return {'statusCode': 400, 'body': json.dumps({'error': 'Invalid JSON body'})}

    # Get today's date in UTC
    today = datetime.now(UTC).date()

    # Determine billing period
    start_date = (today - relativedelta(months=1) if today.day == 1 else today.replace(day=1)).strftime("%Y-%m-%d")
    end_date = today.strftime("%Y-%m-%d")

    # Collect results for all targets
    results = []
    for target in targets:
        tag_key = target['tag_key']
        tag_value = target['tag_value']
        cost = get_cost_by_tag(ce_client, start_date, end_date, tag_key, tag_value)
        results.append({"tag_key": tag_key, "tag_value": tag_value, "cost": cost})

    # Build a single consolidated Slack message
    message = build_slack_message(results, start_date, end_date)
    send_to_slack(message)

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Cost report sent to Slack!',
            'targets_processed': len(results),
            'results': [
                {
                 "tag_key": r["tag_key"], "tag_value": r["tag_value"], 
                 "cost": f"${r['cost']:.2f}"} for r in results]
        })
    }


def build_slack_message(results, start_date, end_date):
    lines = ["*AWS Cost Report*", f"📅 *Time Period:* {start_date} → {end_date}\n"]
    total = 0.0
    for r in results:
        lines.append(f"🔖 *Tag:* `{r['tag_key']}={r['tag_value']}`")
        lines.append(f"💰 *Cost:* ${r['cost']:.2f}\n")
        total += r['cost']
    if len(results) > 1:
        lines.append(f"📊 *Total Across All Tags:* ${total:.2f}")
    return "\n".join(lines)


def get_cost_by_tag(ce_client, start_date, end_date, tag_key, tag_value):
    response = ce_client.get_cost_and_usage(
        TimePeriod={'Start': str(start_date), 'End': str(end_date)},
        Granularity='DAILY',
        Filter={
            "Tags": {
                "Key": tag_key,
                "Values": [tag_value]
            }
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
    return {"message": "Cost report sent to Slack!"}
