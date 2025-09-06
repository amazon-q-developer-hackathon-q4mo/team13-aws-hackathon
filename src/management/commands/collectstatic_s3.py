import os
import boto3
from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.conf import settings


class Command(BaseCommand):
    help = 'Collect static files and upload to S3'

    def handle(self, *args, **options):
        # 정적 파일 수집
        self.stdout.write('Collecting static files...')
        call_command('collectstatic', '--noinput')
        
        # S3 업로드
        bucket_name = os.getenv('STATIC_FILES_BUCKET')
        if not bucket_name:
            self.stdout.write(self.style.WARNING('STATIC_FILES_BUCKET not set, skipping S3 upload'))
            return
            
        self.stdout.write(f'Uploading to S3 bucket: {bucket_name}')
        
        s3_client = boto3.client('s3')
        static_root = settings.STATIC_ROOT
        
        for root, dirs, files in os.walk(static_root):
            for file in files:
                local_path = os.path.join(root, file)
                relative_path = os.path.relpath(local_path, static_root)
                s3_key = f'static/{relative_path}'
                
                try:
                    s3_client.upload_file(local_path, bucket_name, s3_key)
                    self.stdout.write(f'Uploaded: {s3_key}')
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f'Failed to upload {s3_key}: {e}'))
        
        self.stdout.write(self.style.SUCCESS('Static files uploaded to S3'))