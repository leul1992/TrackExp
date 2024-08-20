# backup/authentication.py
import firebase_admin
from firebase_admin import auth
from rest_framework import authentication
from rest_framework import exceptions
from .models import CustomUser

class FirebaseAuthentication(authentication.BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return None

        try:
            id_token = auth_header.split(' ')[1]
            decoded_token = auth.verify_id_token(id_token)
            uid = decoded_token['uid']
        except Exception as e:
            raise exceptions.AuthenticationFailed('Invalid Firebase ID token')

        try:
            user = CustomUser.objects.get(username=uid)
        except CustomUser.DoesNotExist:
            user = CustomUser.objects.create(
                username=uid,
                email=decoded_token.get('email', ''),
                first_name=decoded_token.get('name', '').split(' ')[0],
                last_name=' '.join(decoded_token.get('name', '').split(' ')[1:])
            )

        return (user, None)
