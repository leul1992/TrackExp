from django.core.management.base import BaseCommand
from your_app.models import ScheduledDeletion, CustomUser
from django.utils import timezone

class Command(BaseCommand):
    help = 'Deletes users whose deletion is past due'

    def handle(self, *args, **kwargs):
        now = timezone.now()
        past_due_deletions = ScheduledDeletion.objects.filter(scheduled_date__lte=now)

        for deletion in past_due_deletions:
            user = deletion.user
            user.delete()
            deletion.delete()
            self.stdout.write(f'Deleted user {user.email}')
