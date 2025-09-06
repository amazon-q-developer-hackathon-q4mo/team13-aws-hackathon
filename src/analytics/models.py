from django.db import models

class Event(models.Model):
    event_id = models.CharField(max_length=100, primary_key=True)
    timestamp = models.BigIntegerField()
    user_id = models.CharField(max_length=100)
    session_id = models.CharField(max_length=100)
    event_type = models.CharField(max_length=50)
    page_url = models.URLField(blank=True)
    referrer = models.URLField(blank=True)
    user_agent = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(blank=True, null=True)
    
    class Meta:
        managed = False  # DynamoDB 사용

class Session(models.Model):
    session_id = models.CharField(max_length=100, primary_key=True)
    user_id = models.CharField(max_length=100)
    start_time = models.BigIntegerField()
    last_activity = models.BigIntegerField()
    is_active = models.BooleanField(default=True)
    entry_page = models.URLField(blank=True)
    exit_page = models.URLField(blank=True)
    referrer = models.URLField(blank=True)
    total_events = models.IntegerField(default=0)
    session_duration = models.IntegerField(default=0)
    
    class Meta:
        managed = False  # DynamoDB 사용
