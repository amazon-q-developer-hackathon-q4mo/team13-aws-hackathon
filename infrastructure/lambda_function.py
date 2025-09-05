import json
import boto3
import os
import uuid
from datetime import datetime, timedelta
from decimal import Decimal
from botocore.exceptions import ClientError

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
            
            # 이벤트 데이터 생성
            event_data = create_event_data(body, event)
            
            # 세션 관리
            session_data = manage_session(event_data)
            
            # 데이터 저장
            save_event_data(event_data, session_data)
            
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'message': 'Event processed successfully',
                    'event_id': event_data['event_id'],
                    'session_id': event_data['session_id']
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

def create_event_data(body, event):
    """이벤트 데이터 생성 및 검증"""
    now = datetime.now()
    timestamp = int(now.timestamp() * 1000)
    event_id = f"evt_{now.strftime('%Y%m%d_%H%M%S')}_{str(uuid.uuid4())[:8]}"
    
    # 클라이언트 IP 추출
    client_ip = get_client_ip(event)
    
    return {
        'event_id': event_id,
        'timestamp': timestamp,
        'user_id': body.get('user_id', f"user_{str(uuid.uuid4())[:8]}"),
        'session_id': body.get('session_id'),
        'event_type': body.get('event_type', 'page_view'),
        'page_url': body.get('page_url', ''),
        'referrer': body.get('referrer', ''),
        'user_agent': body.get('user_agent', ''),
        'ip_address': client_ip
    }

def get_client_ip(event):
    """API Gateway에서 클라이언트 IP 추출"""
    headers = event.get('headers', {})
    
    # X-Forwarded-For 헤더 확인
    forwarded_for = headers.get('X-Forwarded-For')
    if forwarded_for:
        return forwarded_for.split(',')[0].strip()
    
    # 직접 IP 확인
    return event.get('requestContext', {}).get('identity', {}).get('sourceIp', '127.0.0.1')

def manage_session(event_data):
    """세션 생성 및 관리"""
    user_id = event_data['user_id']
    session_id = event_data.get('session_id')
    timestamp = event_data['timestamp']
    
    if not session_id:
        # 새 세션 생성
        session_id = f"sess_{timestamp}_{user_id[:8]}"
        event_data['session_id'] = session_id
        
        session_data = {
            'session_id': session_id,
            'user_id': user_id,
            'start_time': timestamp,
            'last_activity': timestamp,
            'is_active': True,
            'entry_page': event_data['page_url'],
            'exit_page': event_data['page_url'],
            'referrer': event_data['referrer'],
            'total_events': 1,
            'session_duration': 0,
            'ip_address': event_data['ip_address']
        }
    else:
        # 기존 세션 업데이트
        try:
            response = sessions_table.get_item(Key={'session_id': session_id})
            if 'Item' in response:
                session_data = response['Item']
                session_data['last_activity'] = timestamp
                session_data['exit_page'] = event_data['page_url']
                session_data['total_events'] = int(session_data.get('total_events', 0)) + 1
                session_data['session_duration'] = timestamp - int(session_data['start_time'])
                session_data['is_active'] = True
            else:
                # 세션이 없으면 새로 생성
                event_data['session_id'] = None
                return manage_session(event_data)
        except ClientError as e:
            print(f"Session lookup error: {e}")
            event_data['session_id'] = None
            return manage_session(event_data)
    
    # 활성 세션 업데이트
    update_active_session(session_data)
    
    return session_data

def update_active_session(session_data):
    """활성 세션 테이블 업데이트 (TTL 30분)"""
    expires_at = int((datetime.now() + timedelta(minutes=30)).timestamp())
    
    active_session_data = {
        'session_id': session_data['session_id'],
        'user_id': session_data['user_id'],
        'last_activity': session_data['last_activity'],
        'current_page': session_data['exit_page'],
        'expires_at': expires_at
    }
    
    try:
        active_sessions_table.put_item(Item=active_session_data)
    except ClientError as e:
        print(f"Active session update error: {e}")

def save_event_data(event_data, session_data):
    """이벤트 및 세션 데이터 저장"""
    try:
        # 이벤트 저장
        events_table.put_item(Item=convert_to_dynamodb_format(event_data))
        
        # 세션 저장
        sessions_table.put_item(Item=convert_to_dynamodb_format(session_data))
        
        print(f"Saved event: {event_data['event_id']}, session: {session_data['session_id']}")
        
    except ClientError as e:
        print(f"Save error: {e}")
        raise e

def convert_to_dynamodb_format(data):
    """Python 데이터를 DynamoDB 형식으로 변환"""
    converted = {}
    for key, value in data.items():
        if isinstance(value, float):
            converted[key] = Decimal(str(value))
        elif isinstance(value, int):
            converted[key] = value
        elif isinstance(value, bool):
            converted[key] = value
        elif value is None:
            converted[key] = ''
        else:
            converted[key] = str(value)
    return converted