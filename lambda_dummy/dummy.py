def handler(event, context):
    """더미 Lambda 함수 - 인프라 테스트용"""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': '{"message": "LiveInsight API - Coming Soon"}'
    }