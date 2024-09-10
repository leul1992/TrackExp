from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission

class CustomUser(AbstractUser):
    groups = models.ManyToManyField(
        Group,
        related_name='custom_customuser_set',
        blank=True,
    )
    user_permissions = models.ManyToManyField(
        Permission,
        related_name='custom_customuser_set',
        blank=True,
    )
    scheduled_deletion_date = models.DateTimeField(null=True, blank=True)

class ScheduledDeletion(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE)
    scheduled_date = models.DateTimeField()

    def schedule_deletion(self):
        self.scheduled_date = timezone.now() + timedelta(seconds=30)
        self.save()

    def is_past_due(self):
        return timezone.now() >= self.scheduled_date

class Trip(models.Model):
    id = models.CharField(max_length=100, primary_key=True)
    name = models.CharField(max_length=200)
    total_money = models.DecimalField(max_digits=10, decimal_places=2)
    start_date = models.DateField()
    end_date = models.DateField()
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)

class Expense(models.Model):
    id = models.CharField(max_length=100, primary_key=True)
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE)
    name = models.CharField(max_length=200)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    is_sale = models.BooleanField(default=False)
    sold_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
