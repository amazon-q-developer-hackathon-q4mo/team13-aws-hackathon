import os
import boto3
from datetime import datetime
from typing import List, Optional, Dict, Any
from boto3.dynamodb.conditions import Key, Attr
from src.models.events import WebEvent
from src.models.sessions import UserSession

class DynamoDBService:
    def __init__(self):
        self.dynamodb = boto3.resource('dynamodb', region_name=os.getenv('AWS_REGION', 'ap-northeast-2'))
        self.events_table = self.dynamodb.Table(os.getenv('EVENTS_TABLE', 'liveinsight-events-dev'))
        self.sessions_table = self.dynamodb.Table(os.getenv('SESSIONS_TABLE', 'liveinsight-sessions-dev'))
    
    async def save_event(self, event: WebEvent) -> bool:
        """
        웹 이벤트를 DynamoDB Events 테이블에 저장
        
        Pydantic 모델을 DynamoDB 아이템 형식으로 변환하여 저장합니다.
        datetime 객체는 ISO 형식 문자열로 변환되어 저장됩니다.
        
        Args:
            event (WebEvent): 저장할 웹 이벤트 객체
        
        Returns:
            bool: 저장 성공 시 True, 실패 시 False
        
        Raises:
            Exception: DynamoDB 저장 중 오류 발생 시 (로그로 출력하고 False 반환)
        
        Note:
            - timestamp는 ISO 8601 형식으로 변환되어 저장
            - 오류 발생 시 예외를 발생시키지 않고 False 반환
            - 로그는 표준 출력으로 출력 (향후 CloudWatch로 대체 예정)
        """
        try:
            item = event.model_dump()
            item['timestamp'] = item['timestamp'].isoformat()
            self.events_table.put_item(Item=item)
            return True
        except Exception as e:
            print(f"Error saving event: {e}")
            return False
    
    async def save_session(self, session: UserSession) -> bool:
        """
        사용자 세션 정보를 DynamoDB Sessions 테이블에 저장
        
        세션 생성 또는 업데이트 시 호출되며, datetime 필드들을
        ISO 형식 문자열로 변환하여 저장합니다.
        
        Args:
            session (UserSession): 저장할 사용자 세션 객체
        
        Returns:
            bool: 저장 성공 시 True, 실패 시 False
        
        Raises:
            Exception: DynamoDB 저장 중 오류 발생 시 (로그로 출력하고 False 반환)
        
        Note:
            - start_time과 last_activity는 ISO 8601 형식으로 변환
            - 기존 세션이 있으면 덮어쓰기 (기본 DynamoDB put_item 동작)
            - 오류 발생 시 예외를 발생시키지 않고 False 반환
        """
        try:
            item = session.model_dump()
            item['start_time'] = item['start_time'].isoformat()
            item['last_activity'] = item['last_activity'].isoformat()
            self.sessions_table.put_item(Item=item)
            return True
        except Exception as e:
            print(f"Error saving session: {e}")
            return False
    
    async def get_session(self, session_id: str) -> Optional[UserSession]:
        """
        세션 ID로 사용자 세션 정보를 조회
        
        DynamoDB에서 세션 데이터를 조회하고, ISO 형식 문자열로 저장된
        datetime 필드들을 Python datetime 객체로 변환하여 반환합니다.
        
        Args:
            session_id (str): 조회할 세션 ID
        
        Returns:
            Optional[UserSession]: 세션이 존재하면 UserSession 객체, 없으면 None
        
        Raises:
            Exception: DynamoDB 조회 또는 데이터 변환 중 오류 발생 시
                      (로그로 출력하고 None 반환)
        
        Note:
            - session_id를 Primary Key로 사용하여 조회
            - ISO 형식 문자열을 datetime 객체로 변환
            - 세션이 없으면 None 반환 (오류가 아님)
        """
        try:
            response = self.sessions_table.get_item(Key={'session_id': session_id})
            if 'Item' in response:
                item = response['Item']
                item['start_time'] = datetime.fromisoformat(item['start_time'])
                item['last_activity'] = datetime.fromisoformat(item['last_activity'])
                return UserSession(**item)
            return None
        except Exception as e:
            print(f"Error getting session: {e}")
            return None
    
    async def get_recent_events(self, limit: int = 100) -> List[Dict[str, Any]]:
        """
        최근 이벤트 목록을 지정된 개수만큼 조회
        
        DynamoDB Events 테이블을 스캔하여 최근 이벤트들을 반환합니다.
        실제 프로덕션에서는 GSI를 사용하여 시간순 정렬로 개선 예정입니다.
        
        Args:
            limit (int): 조회할 이벤트 최대 개수 (기본값: 100)
        
        Returns:
            List[Dict[str, Any]]: 이벤트 데이터 리스트 (DynamoDB 아이템 형태)
        
        Raises:
            Exception: DynamoDB 스캔 중 오류 발생 시 (로그로 출력하고 빈 리스트 반환)
        
        Note:
            - 현재는 단순 scan 사용 (비효율적)
            - 향후 timestamp 기반 GSI로 개선 예정
            - limit은 DynamoDB의 스캔 제한에 따라 적용
            - 오류 발생 시 빈 리스트 반환
        """
        try:
            response = self.events_table.scan(Limit=limit)
            return response.get('Items', [])
        except Exception as e:
            print(f"Error getting recent events: {e}")
            return []