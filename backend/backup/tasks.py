from celery import shared_task
from django.core.management import call_command

@shared_task
def run_delete_scheduled_accounts():
    call_command('delete_scheduled_accounts')
