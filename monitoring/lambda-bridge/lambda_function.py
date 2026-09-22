import os
import json
import urllib.request
import urllib.error

def lambda_handler(event, context):
    """
    AWS Lambda function to forward CloudWatch/SNS alarms to Alertmanager.
    Alertmanager runs in the us-west-2 monitoring VPC.
    """
    print(f"Received event: {json.dumps(event)}")
    
    # Alertmanager private IP or internal ALB reachable via VPC Peering
    ALERTMANAGER_URL = os.environ.get("ALERTMANAGER_URL", "http://<ALERTMANAGER_PRIVATE_IP>:9093/api/v1/alerts")
    
    for record in event.get('Records', []):
        try:
            # 1. Extract the SNS message which contains the CloudWatch Alarm JSON
            sns_message = record['SnsMessage']['Messages']
            
            # TODO: Parse 'sns_message' string into a JSON dictionary
            alarm_data = {}  # <-- Parse it here!
            
            # Extract basic alarm info (fallback to unknown if missing)
            alarm_name = alarm_data.get("AlarmName", "UnknownAlarm")
            alarm_desc = alarm_data.get("AlarmDescription", "No description")
            new_state_reason = alarm_data.get("NewStateReason", "State changed")
            
            # 2. Format the payload for Alertmanager
            # Alertmanager expects an array of alert objects:
            alert_payload = [
                {
                    "labels": {
                        "alertname": alarm_name,
                        "severity": "critical",
                        "source": "cloudwatch"
                        # TODO: You can add more labels here if you want!
                    },
                    "annotations": {
                        "summary": alarm_desc,
                        "description": new_state_reason
                    }
                }
            ]
            
            payload_bytes = json.dumps(alert_payload).encode('utf-8')
            print(f"Sending to Alertmanager: {json.dumps(alert_payload)}")
            
            # 3. Send HTTP POST request to Alertmanager
            # TODO: Create a urllib.request.Request object with the ALERTMANAGER_URL
            # TODO: Set method to "POST" and headers to {'Content-Type': 'application/json'}
            # TODO: Send the request using urllib.request.urlopen
            
            # req = ...
            # response = urllib.request.urlopen(req)
            # print(f"Response status: {response.getcode()}")
            
        except Exception as e:
            print(f"Error processing record: {e}")
            raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Event processed successfully')
    }
