from django.shortcuts import render
from django.http import JsonResponse

def index(request):
    return render(request, 'dashboard/index.html')

def statistics(request):
    return render(request, 'dashboard/statistics.html')

def api_active_sessions(request):
    # 활성 세션 데이터는 Phase 3에서 구현
    return JsonResponse({'sessions': []})
