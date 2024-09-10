from celery import shared_task
from django.utils import timezone
from .models import ScheduledDeletion, CustomUser
from .utils import delete_user_and_data
import logging
logger = logging.getLogger(__name__)

@shared_task
def delete_past_due_users():
    logger.info("Task delete_past_due_users started.")
    
    now = timezone.now()
    past_due_deletions = ScheduledDeletion.objects.filter(scheduled_date__lte=now)
    
    logger.info(f"Found {past_due_deletions.count()} users to delete.")
    
    for deletion in past_due_deletions:
        user = deletion.user
        logger.info(f"Attempting to delete user: {user.id}")
        try:
            delete_user_and_data(user)
            deletion.delete()
            logger.info(f"User {user.id} deleted successfully.")
        except Exception as e:
            logger.error(f"Error deleting user {user.id}: {e}")
