from rest_framework import serializers
from .models import Event, Session

class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = '__all__'

class SessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Session
        fields = '__all__'

class ActiveSessionSerializer(serializers.Serializer):
    session_id = serializers.CharField()
    user_id = serializers.CharField()
    last_activity = serializers.IntegerField()
    current_page = serializers.URLField()
    duration = serializers.IntegerField()