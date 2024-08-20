# management/commands/delete_scheduled_accounts.py
from django.core.management.base import BaseCommand
from django.utils import timezone
from myapp.models import ScheduledDeletion

class Command(BaseCommand):
    help = 'Delete accounts that are past their scheduled deletion date.'

    def handle(self, *args, **kwargs):
        deletions = ScheduledDeletion.objects.filter(scheduled_date__lte=timezone.now())
        count, _ = deletions.delete()
        self.stdout.write(f'Deleted {count} user accounts.')
