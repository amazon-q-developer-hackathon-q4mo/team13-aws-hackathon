from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EventViewSet, SessionViewSet, StatisticsViewSet

router = DefaultRouter()
router.register(r'events', EventViewSet, basename='event')
router.register(r'sessions', SessionViewSet, basename='session')
router.register(r'statistics', StatisticsViewSet, basename='statistics')

urlpatterns = [
    path('', include(router.urls)),
]