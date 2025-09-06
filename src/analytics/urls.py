from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EventViewSet, SessionViewSet, StatisticsViewSet, EventCollectionView

router = DefaultRouter()
router.register(r'events', EventViewSet, basename='event')
router.register(r'sessions', SessionViewSet, basename='session')
router.register(r'statistics', StatisticsViewSet, basename='statistics')

urlpatterns = [
    path('events/', EventCollectionView.as_view(), name='event-collection'),
    path('', include(router.urls)),
]