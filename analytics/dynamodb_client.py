import boto3
from django.conf import settings
from decimal import Decimal
import json

class DynamoDBClient:
    def __init__(self):
        self.dynamodb = boto3.resource(
            'dynamodb',
            region_name=settings.AWS_DEFAULT_REGION,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
        )
        self.events_table = self.dynamodb.Table(settings.EVENTS_TABLE)
        self.sessions_table = self.dynamodb.Table(settings.SESSIONS_TABLE)
        self.active_sessions_table = self.dynamodb.Table(settings.ACTIVE_SESSIONS_TABLE)
    
    def get_active_sessions(self):
        try:
            response = self.active_sessions_table.scan()
            return response.get('Items', [])
        except Exception as e:
            print(f"Error getting active sessions: {e}")
            return []
    
    def get_session_events(self, session_id):
        try:
            response = self.events_table.query(
                IndexName='SessionIndex',
                KeyConditionExpression='session_id = :sid',
                ExpressionAttributeValues={':sid': session_id}
            )
            return response.get('Items', [])
        except Exception as e:
            print(f"Error getting session events: {e}")
            return []
    
    def get_hourly_stats(self, hours=24):
        # 시간대별 통계 조회 (간단한 구현)
        try:
            from datetime import datetime, timedelta
            end_time = datetime.now()
            start_time = end_time - timedelta(hours=hours)
            
            response = self.events_table.scan(
                FilterExpression='#ts BETWEEN :start AND :end',
                ExpressionAttributeNames={'#ts': 'timestamp'},
                ExpressionAttributeValues={
                    ':start': int(start_time.timestamp() * 1000),
                    ':end': int(end_time.timestamp() * 1000)
                }
            )
            return response.get('Items', [])
        except Exception as e:
            print(f"Error getting hourly stats: {e}")
            return []
    
    def get_page_stats(self):
        try:
            response = self.events_table.scan(
                FilterExpression='event_type = :et',
                ExpressionAttributeValues={':et': 'page_view'}
            )
            
            # 페이지별 집계
            page_counts = {}
            for item in response.get('Items', []):
                page_url = item.get('page_url', 'Unknown')
                page_counts[page_url] = page_counts.get(page_url, 0) + 1
            
            return [{'page': k, 'views': v} for k, v in page_counts.items()]
        except Exception as e:
            print(f"Error getting page stats: {e}")
            return []

# 싱글톤 인스턴스
db_client = DynamoDBClient()