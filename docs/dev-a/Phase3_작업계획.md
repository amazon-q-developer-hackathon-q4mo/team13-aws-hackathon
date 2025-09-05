# Phase 3: 핵심 기능 개발 (4시간) - 개발자 A

## 목표
이벤트 수집 Lambda 함수 완성, 세션 관리 로직 구현

## 작업 내용

### 1. 이벤트 수집 Lambda 함수 개발 (120분)

**lambda_function.py**
```python
import json
import boto3
import os
import uuid
from datetime import datetime, timedelta
from decimal import Decimal

dynamodb = boto3.resource('dynamodb', region_name='ap-northeast-2')
events_table = dynamodb.Table(os.environ['EVENTS_TABLE'])
sessions_table = dynamodb.Table(os.environ['SESSIONS_TABLE'])
active_sessions_table = dynamodb.Table(os.environ['ACTIVE_SESSIONS_TABLE'])

def lambda_handler(event, context):
    try:
        # 요청 데이터 파싱
        body = json.loads(event['body'])
        
        # 이벤트 데이터 생성
        event_data = create_event_data(body)
        
        # 세션 관리
        session_data = manage_session(event_data)
        
        # 데이터 저장
        save_event_data(event_data, session_data)
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
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
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def create_event_data(body):
    timestamp = int(datetime.now().timestamp() * 1000)
    event_id = f"evt_{timestamp}_{str(uuid.uuid4())[:8]}"
    
    return {
        'event_id': event_id,
        'timestamp': timestamp,
        'user_id': body.get('user_id', f"user_{str(uuid.uuid4())[:8]}"),
        'session_id': body.get('session_id'),
        'event_type': body.get('event_type', 'page_view'),
        'page_url': body.get('page_url', ''),
        'referrer': body.get('referrer', ''),
        'user_agent': body.get('user_agent', ''),
        'ip_address': get_client_ip(body)
    }

def get_client_ip(body):
    # API Gateway에서 클라이언트 IP 추출
    return body.get('ip_address', '127.0.0.1')
```

### 2. 세션 관리 로직 구현 (120분)

**세션 관리 함수**
```python
def manage_session(event_data):
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
            'session_duration': 0
        }
    else:
        # 기존 세션 업데이트
        try:
            response = sessions_table.get_item(Key={'session_id': session_id})
            if 'Item' in response:
                session_data = response['Item']
                session_data['last_activity'] = timestamp
                session_data['exit_page'] = event_data['page_url']
                session_data['total_events'] += 1
                session_data['session_duration'] = timestamp - session_data['start_time']
            else:
                # 세션이 없으면 새로 생성
                return manage_session({**event_data, 'session_id': None})
        except Exception as e:
            print(f"Session lookup error: {e}")
            return manage_session({**event_data, 'session_id': None})
    
    # 활성 세션 업데이트
    update_active_session(session_data)
    
    return session_data

def update_active_session(session_data):
    expires_at = int((datetime.now() + timedelta(minutes=30)).timestamp())
    
    active_session_data = {
        'session_id': session_data['session_id'],
        'user_id': session_data['user_id'],
        'last_activity': session_data['last_activity'],
        'current_page': session_data['exit_page'],
        'expires_at': expires_at
    }
    
    active_sessions_table.put_item(Item=active_session_data)
```

### 3. DynamoDB 저장 로직 (60분)

**데이터 저장 함수**
```python
def save_event_data(event_data, session_data):
    try:
        # 이벤트 저장
        events_table.put_item(Item=convert_to_dynamodb_format(event_data))
        
        # 세션 저장
        sessions_table.put_item(Item=convert_to_dynamodb_format(session_data))
        
        print(f"Saved event: {event_data['event_id']}, session: {session_data['session_id']}")
        
    except Exception as e:
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
        else:
            converted[key] = str(value) if value is not None else ''
    return converted
```

### 4. API Gateway 연동 테스트 (60분)

**테스트 스크립트**
```python
import requests
import json
import time

def test_event_collection():
    api_url = "https://YOUR_API_GATEWAY_URL/events"
    
    test_events = [
        {
            "user_id": "test_user_1",
            "event_type": "page_view",
            "page_url": "https://example.com/home",
            "referrer": "https://google.com"
        },
        {
            "user_id": "test_user_1",
            "session_id": "sess_123",
            "event_type": "page_view",
            "page_url": "https://example.com/products"
        }
    ]
    
    for event_data in test_events:
        response = requests.post(api_url, json=event_data)
        print(f"Response: {response.status_code}, {response.json()}")
        time.sleep(1)

if __name__ == "__main__":
    test_event_collection()
```

## 완료 기준
- [ ] Lambda 함수 완전 구현
- [ ] 세션 생성 및 관리 로직 완성
- [ ] DynamoDB 저장 로직 구현
- [ ] API Gateway 연동 테스트 통과
- [ ] 에러 처리 및 로깅 구현