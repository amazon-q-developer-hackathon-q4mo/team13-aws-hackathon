import json
import boto3
import os
from datetime import datetime, timedelta

def handler(event, context):
    """
    월간 백업 복원 테스트 Lambda 함수
    """
    backup_client = boto3.client('backup')
    dynamodb = boto3.client('dynamodb')
    
    backup_vault_name = os.environ['BACKUP_VAULT_NAME']
    project_name = os.environ['PROJECT_NAME']
    
    try:
        # 최근 백업 포인트 조회
        response = backup_client.list_recovery_points(
            BackupVaultName=backup_vault_name,
            MaxResults=10
        )
        
        recovery_points = response.get('RecoveryPoints', [])
        
        if not recovery_points:
            return {
                'statusCode': 404,
                'body': json.dumps('No recovery points found')
            }
        
        # 가장 최근 백업 포인트 선택
        latest_backup = recovery_points[0]
        recovery_point_arn = latest_backup['RecoveryPointArn']
        
        print(f"Testing recovery point: {recovery_point_arn}")
        
        # 테스트용 테이블 이름 생성
        test_table_name = f"{project_name}-backup-test-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # 복원 작업 시작 (테스트용)
        restore_response = backup_client.start_restore_job(
            RecoveryPointArn=recovery_point_arn,
            Metadata={
                'NewTableName': test_table_name
            },
            IamRoleArn=f"arn:aws:iam::{context.invoked_function_arn.split(':')[4]}:role/{project_name}-backup-role"
        )
        
        restore_job_id = restore_response['RestoreJobId']
        
        print(f"Started restore job: {restore_job_id}")
        print(f"Test table name: {test_table_name}")
        
        # CloudWatch 메트릭 전송
        cloudwatch = boto3.client('cloudwatch')
        cloudwatch.put_metric_data(
            Namespace='LiveInsight/Backup',
            MetricData=[
                {
                    'MetricName': 'BackupTestExecuted',
                    'Value': 1,
                    'Unit': 'Count',
                    'Timestamp': datetime.utcnow()
                }
            ]
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Backup test initiated successfully',
                'restoreJobId': restore_job_id,
                'testTableName': test_table_name,
                'recoveryPointArn': recovery_point_arn
            })
        }
        
    except Exception as e:
        print(f"Error during backup test: {str(e)}")
        
        # 실패 메트릭 전송
        cloudwatch = boto3.client('cloudwatch')
        cloudwatch.put_metric_data(
            Namespace='LiveInsight/Backup',
            MetricData=[
                {
                    'MetricName': 'BackupTestFailed',
                    'Value': 1,
                    'Unit': 'Count',
                    'Timestamp': datetime.utcnow()
                }
            ]
        )
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Backup test failed'
            })
        }