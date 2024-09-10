import pymongo
from django.conf import settings
from .models import CustomUser

# Initialize MongoDB connection
mongo_client = pymongo.MongoClient(settings.MONGODB_SETTINGS['host'])
mongo_db = mongo_client[settings.MONGODB_SETTINGS['db']]

def delete_user_and_data(user):
    """
    Delete a user and their associated data from both MongoDB and Django.
    """
    # MongoDB deletion
    users_collection = mongo_db.users
    users_collection.delete_one({'email': user.email})
    
    trips_collection = mongo_db.trips
    expenses_collection = mongo_db.expenses
    
    trips_collection.delete_many({'user_id': str(user.id)})
    expenses_collection.delete_many({'user_id': str(user.id)})

    # Django model deletion
    user.delete()

    return {'status': 'success', 'message': 'User account and data deleted successfully.'}
