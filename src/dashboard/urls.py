from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('statistics/', views.statistics, name='statistics'),

    path('api/sessions/active/', views.api_active_sessions, name='api_active_sessions'),
    path('api/sessions/<str:session_id>/events/', views.api_session_events, name='api_session_events'),
    path('api/statistics/hourly/', views.api_hourly_stats, name='api_hourly_stats'),
    path('api/statistics/pages/', views.api_page_stats, name='api_page_stats'),
    path('api/statistics/summary/', views.api_summary_stats, name='api_summary_stats'),
    path('api/statistics/referrers/', views.api_referrer_stats, name='api_referrer_stats'),
    path('api/hourly-details/', views.api_hourly_details, name='api_hourly_details'),
    path('api/page-details/', views.api_page_details, name='api_page_details'),
]