from django.urls import path, include
from .views import backup_data, fetch_data, backup_user_data, update_data, fetch_specific_data, delete_user_data, ScheduleAccountDeletionView, CheckAndReactivateAccountView

from rest_framework.routers import DefaultRouter


urlpatterns = [
    path('backup/', backup_data, name='backup_data'),
    path('fetch/', fetch_data, name='fetch_data'),
    path('backup_user_data/', backup_user_data, name='backup_user_data'),
    path('delete_user_data/', delete_user_data, name='delete_user_data'),
    # path('delete_data/<str:data_type>/<str:data_id>/', delete_data, name='delete_data'),
    path('schedule_account_deletion/', ScheduleAccountDeletionView.as_view(), name='ScheduleAccountDeletionView'),
    path('check_and_reactivate_account/', CheckAndReactivateAccountView.as_view(), name='CheckAndReactivateAccountView'),
    path('update_data/<str:data_type>/<str:data_id>/', update_data, name='update_data'),
    path('fetch_specific_data/<str:data_type>/<str:data_id>/', fetch_specific_data, name='fetch_specific_data'),
]
