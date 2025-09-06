from django.core.management.base import BaseCommand
from django.conf import settings
from django.contrib.staticfiles.management.commands.collectstatic import Command as CollectStaticCommand
import os

class Command(BaseCommand):
    help = 'Collect static files and upload to S3'

    def handle(self, *args, **options):
        # S3 버킷이 설정되어 있는지 확인
        if not settings.STATIC_FILES_BUCKET:
            self.stdout.write(
                self.style.ERROR('STATIC_FILES_BUCKET 환경변수가 설정되지 않았습니다.')
            )
            return

        # 기본 collectstatic 실행
        self.stdout.write('정적 파일을 수집하고 S3에 업로드합니다...')
        
        # Django의 기본 collectstatic 명령어 실행
        collect_command = CollectStaticCommand()
        collect_command.handle(interactive=False, verbosity=1)
        
        self.stdout.write(
            self.style.SUCCESS(f'정적 파일이 S3 버킷 {settings.STATIC_FILES_BUCKET}에 업로드되었습니다.')
        )