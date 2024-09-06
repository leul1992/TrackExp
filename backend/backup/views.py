from django.conf import settings
from django.shortcuts import get_object_or_404
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
import pymongo
from bson import ObjectId, errors
from .models import ScheduledDeletion
from rest_framework.views import APIView

# Initialize MongoDB client
mongo_client = pymongo.MongoClient(settings.MONGODB_SETTINGS['host'])
mongo_db = mongo_client[settings.MONGODB_SETTINGS['db']]

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def backup_user_data(request):
    data = request.data
    email = data.get('email')
    display_name = data.get('displayName')

    if not email:
        return Response({'error': 'Email is required'}, status=400)

    users_collection = mongo_db.users
    user_doc = {
        'email': email,
        'username': email.split('@')[0],
        'first_name': display_name.split(' ')[0] if display_name else '',
        'last_name': ' '.join(display_name.split(' ')[1:]) if display_name else '',
    }

    result = users_collection.update_one(
        {'email': email},
        {'$set': user_doc},
        upsert=True
    )

    if result.upserted_id:
        print(f'User created with email {email}')
    else:
        print(f'User updated with email {email}')

    return Response({'status': 'success'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def backup_data(request):
    user = request.user
    trips_data = request.data.get('trips', [])
    expenses_data = request.data.get('expenses', [])
    
    if not isinstance(trips_data, list) or not all(isinstance(item, dict) for item in trips_data):
        return Response({'error': 'Invalid trips data format'}, status=400)

    if not isinstance(expenses_data, list) or not all(isinstance(item, dict) for item in expenses_data):
        return Response({'error': 'Invalid expenses data format'}, status=400)
    trips_collection = mongo_db.trips
    expenses_collection = mongo_db.expenses

    for trip_data in trips_data:
        if '_id' not in trip_data or not trip_data['_id']:
            return Response({'error': 'Trip ID missing'}, status=400)
        trip_data['user_id'] = str(user.id)
        trips_collection.update_one(
            {'_id': trip_data['_id'], 'user_id': str(user.id)},
            {'$set': trip_data},
            upsert=True
        )
    for expense_data in expenses_data:
        if '_id' not in expense_data or not expense_data['_id']:
            return Response({'error': 'Expense ID missing'}, status=400)
        expense_data['user_id'] = str(user.id)
        expenses_collection.update_one(
            {'_id': expense_data['_id'], 'user_id': str(user.id)},
            {'$set': expense_data},
            upsert=True
        )
    return Response({'status': 'success'})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def fetch_data(request):
    user = request.user
    trips_collection = mongo_db.trips
    expenses_collection = mongo_db.expenses

    trips = list(trips_collection.find({'user_id': str(user.id)}))
    expenses = list(expenses_collection.find({'user_id': str(user.id)}))

    for trip in trips:
        trip['_id'] = str(trip['_id'])  # Convert ObjectId to string

    for expense in expenses:
        expense['_id'] = str(expense['_id'])  # Convert ObjectId to string

    return JsonResponse({"trips": trips, "expenses": expenses})

class ScheduleAccountDeletionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        deletion, created = ScheduledDeletion.objects.get_or_create(user=user)
        deletion.schedule_deletion()
        return Response({'status': 'success', 'message': 'Account deletion scheduled in 30 days.'})

class CheckAndReactivateAccountView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        deletion = ScheduledDeletion.objects.filter(user=user).first()

        if deletion and deletion.is_past_due():
            return Response({'error': 'Account deletion already processed.'}, status=403)

        if deletion and not deletion.is_past_due():
            reactivate = request.data.get('reactivate', False)
            if reactivate:
                deletion.delete()
                return Response({'status': 'success', 'message': 'Account reactivated.'})
            else:
                return Response({'message': 'Account not reactivated.'}, status=403)

        return Response({'message': 'Account is active.'})

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_user_data(request):
    user = request.user

    # Final account deletion check
    deletion = ScheduledDeletion.objects.filter(user=user).first()
    if deletion and not deletion.is_past_due():
        return Response({'error': 'Account is scheduled for deletion, but the 30-day period has not passed yet.'}, status=403)

    # MongoDB deletion
    users_collection = mongo_db.users
    result = users_collection.delete_one({'email': user.email})
    trips_collection = mongo_db.trips
    expenses_collection = mongo_db.expenses
    trips_collection.delete_many({'user_id': str(user.id)})
    expenses_collection.delete_many({'user_id': str(user.id)})

    # Django model deletion
    user.delete()

    return Response({'status': 'success', 'message': 'User account and data deleted successfully.'})

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_data(request, data_type, data_id):
    user = request.user

    # Validate the data_type
    if data_type not in ['trips', 'expenses']:
        return Response({'error': 'Invalid data type'}, status=400)

    # Fetch the appropriate collection based on data_type
    collection = mongo_db[data_type]

    # Validate the incoming data
    data = request.data
    if not isinstance(data, dict):
        return Response({'error': f'Invalid {data_type} data'}, status=400)

    # Try to convert data_id to ObjectId if it's a valid ObjectId
    try:
        object_id = ObjectId(data_id)
    except errors.InvalidId:
        object_id = data_id  # If it's not a valid ObjectId, treat it as a string

    # Update the data in the database
    result = collection.update_one(
        {'_id': object_id, 'user_id': str(user.id)},
        {'$set': data}
    )

    if result.matched_count == 0:
        return Response({'error': f'{data_type.capitalize()} not found or unauthorized'}, status=404)

    return Response({'status': 'success', 'message': f'{data_type.capitalize()} updated successfully'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def fetch_specific_data(request, data_type, data_id):
    user = request.user
    if data_type not in ['trips', 'expenses']:
        return Response({'error': 'Invalid data type'}, status=400)

    collection = mongo_db[data_type]

    try:
        # Try to convert data_id to ObjectId
        data_id = ObjectId(data_id)
    except errors.InvalidId:
        # If it's not a valid ObjectId, leave it as a string
        pass

    # Find the document by _id and user_id
    data = collection.find_one({'_id': data_id, 'user_id': str(user.id)})

    if not data:
        return Response({'error': 'Data not found or unauthorized'}, status=404)

    data['_id'] = str(data['_id'])  # Convert ObjectId to string for JSON response
    return JsonResponse(data)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_data(request, data_type, data_id):
    user = request.user

    # Validate the data_type
    if data_type not in ['trips', 'expenses']:
        return Response({'error': 'Invalid data type'}, status=400)

    # Fetch the appropriate collection based on data_type
    collection = mongo_db[data_type]

    try:
        # Try to convert data_id to ObjectId
        object_id = ObjectId(data_id)
    except errors.InvalidId:
        # If it's not a valid ObjectId, treat it as a string
        object_id = data_id

    # Find the document by _id and user_id
    document = collection.find_one({'_id': object_id, 'user_id': str(user.id)})

    if not document:
        return Response({'error': 'Data not found or unauthorized'}, status=404)

    if data_type == 'trips':
        # Delete all expenses associated with the trip
        expenses_collection = mongo_db.expenses
        expenses_collection.delete_many({'trip_id': str(object_id), 'user_id': str(user.id)})

    # Delete the main document
    collection.delete_one({'_id': object_id, 'user_id': str(user.id)})

    return Response({'status': 'success', 'message': f'{data_type.capitalize()} and associated data deleted successfully.'})
