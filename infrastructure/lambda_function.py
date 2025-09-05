import json
import boto3
import os
import uuid
from datetime import datetime, timedelta
from decimal import Decimal

# 환경 변수 사용 (필수)
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
events_table = dynamodb.Table(os.environ['EVENTS_TABLE'])
sessions_table = dynamodb.Table(os.environ['SESSIONS_TABLE'])
active_sessions_table = dynamodb.Table(os.environ['ACTIVE_SESSIONS_TABLE'])

def lambda_handler(event, context):
    # CORS 헤더 필수
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    }
    
    try:
        # OPTIONS 요청 처리
        if event['httpMethod'] == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'CORS preflight'})
            }
        
        # POST 요청 처리
        if event['httpMethod'] == 'POST':
            body = json.loads(event['body'])
            
            # 현재 시간
            now = datetime.now()
            timestamp = int(now.timestamp() * 1000)
            
            # 이벤트 ID 생성
            event_id = f"evt_{now.strftime('%Y%m%d_%H%M%S')}_{str(uuid.uuid4())[:8]}"
            
            # 세션 ID 처리
            session_id = body.get('session_id')
            if not session_id:
                session_id = f"sess_{now.strftime('%Y%m%d')}_{str(uuid.uuid4())[:8]}"
            
            # 이벤트 데이터 구성
            event_data = {
                'event_id': event_id,
                'timestamp': timestamp,
                'user_id': body.get('user_id', 'anonymous'),
                'session_id': session_id,
                'event_type': body.get('event_type', 'page_view'),
                'page_url': body.get('page_url', ''),
                'referrer': body.get('referrer', '')
            }
            
            # Events 테이블에 저장
            events_table.put_item(Item=event_data)
            
            # ActiveSessions 업데이트 (30분 TTL)
            expires_at = int((now + timedelta(minutes=30)).timestamp())
            active_sessions_table.put_item(
                Item={
                    'session_id': session_id,
                    'user_id': event_data['user_id'],
                    'last_activity': timestamp,
                    'current_page': event_data['page_url'],
                    'expires_at': expires_at
                }
            )
            
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'message': 'Event processed successfully',
                    'event_id': event_id,
                    'session_id': session_id
                })
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }
    
    return {
        'statusCode': 405,
        'headers': headers,
        'body': json.dumps({'error': 'Method not allowed'})
    }