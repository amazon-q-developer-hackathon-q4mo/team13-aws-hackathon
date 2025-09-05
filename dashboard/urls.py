from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('statistics/', views.statistics, name='statistics'),

    path('api/active-sessions/', views.api_active_sessions, name='api_active_sessions'),
]