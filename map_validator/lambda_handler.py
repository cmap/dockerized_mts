import os
import sys
from slack_sdk.webhook import WebhookClient
import map_validator as map_validator
import boto3

def postSlack(src_file,errorMessage):
    hook_url = os.getenv('SLACK_HOOK_URL')
    if(hook_url):
        webhook = WebhookClient(hook_url)
        response = webhook.send_dict(
         body={
                    "text": "Map SRC: " + src_file + " " + errorMessage,
                    "response_type": "in_channel"
                }
        )
        assert response.status_code == 200
        assert response.body == "ok"
    return

def handler(event, context):
    s3 = boto3.resource('s3')
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    file_key = event['Records'][0]['s3']['object']['key']
    s3obj = s3.Object(bucket_name, file_key)
    file_content = s3obj.get()['Body'].read()
    missing_fields = map_validator.validate(file_content,False,False)

    if (len(missing_fields) > 0):
        errorMessage = file_key + ' missing following required fields: {}'.format(', '.join(missing_fields))
        postSlack(file_key,errorMessage)
        raise Exception(errorMessage)
    else:
        message = 'map validated successfully'
        print(message)
        return message


