from flask import Flask, request, jsonify, url_for
#from flask_jwt_extended import get_jwt
#import psycopg2
import json
from Crypto.Cipher import AES
#from Crypto.Random import get_random_bytes
from Crypto.Util.Padding import pad, unpad
import base64
import os
from dotenv import load_dotenv
import jwt
import datetime
from functools import wraps
from flask_sqlalchemy import SQLAlchemy
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
import uuid
from authlib.integrations.flask_client import OAuth


app = Flask(__name__)

app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://ishak:RKQEj6FuEtcGncfol1On9HrljTXyE7Nk@dpg-d0qesubipnbc73eaq1ug-a/cardiobase'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

ph = PasswordHasher()


# Google OAuth Config
oauth = OAuth(app)
google = oauth.register(
    name='google',
    client_id=os.environ.get("GOOGLE_CLIENT_ID"),
    client_secret=os.environ.get("GOOGLE_CLIENT_SECRET"),
    access_token_url='https://accounts.google.com/o/oauth2/token',
    access_token_params=None,
    authorize_url='https://accounts.google.com/o/oauth2/auth',
    authorize_params=None,
    api_base_url='https://www.googleapis.com/oauth2/v1/',
    server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
    userinfo_endpoint='https://www.googleapis.com/oauth2/v1/userinfo',  # Needed for user info
    client_kwargs={'scope': 'openid email profile'},
)

load_dotenv(dotenv_path="C:/Users/ishak/OneDrive/Documents/programation/cardiotrack_server/keys.env")
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')
AES_KEY = base64.b64decode(os.getenv('AES_KEY'))


class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    name = db.Column(db.String(100), nullable=False)
    password = db.Column(db.Text, nullable=True)
    attempts = db.Column(db.Integer, default=0)
    locked_until = db.Column(db.DateTime, nullable=True)
    proche_name = db.Column(db.String(100), nullable=True)
    proche_number = db.Column(db.String(20), nullable=True)
    docteur_name = db.Column(db.String(100), nullable=True)
    docteur_number = db.Column(db.String(20), nullable=True)

class Signal(db.Model):
    __tablename__ = 'signals'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False, index=True)
    signal_data = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, nullable=False, server_default=db.func.now())
    bpm = db.Column(db.Integer)

def encrypt_data(plaintext):
    cipher = AES.new(AES_KEY, AES.MODE_CBC)
    iv = cipher.iv
    ciphertext = cipher.encrypt(pad(plaintext.encode(), AES.block_size))
    return base64.b64encode(iv + ciphertext).decode()

def decrypt_data(encoded):
    data = base64.b64decode(encoded)
    iv = data[:16]
    ciphertext = data[16:]
    cipher = AES.new(AES_KEY, AES.MODE_CBC, iv=iv)
    plaintext = unpad(cipher.decrypt(ciphertext), AES.block_size)
    return plaintext.decode()



def token_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = None

        # Check if token is provided in the Authorization header
        if 'Authorization' in request.headers:
            token = request.headers['Authorization'].split(' ')[1]  # Get the token part of the header

        if not token:
            return jsonify({'error': 'Token is missing!'}), 403

        try:
            # Decode the token and get the user information
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
            current_user = User.query.get(data['user_id'])
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token expired!'}), 403
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token!'}), 403

        return f(current_user, *args, **kwargs)

    return decorated_function



@app.route('/')
def home():
    return "the server is online!"

@app.route('/sign-in', methods=['POST'])
def sign_in():
    data = request.get_json()

    if not data or 'email' not in data or 'name' not in data or 'password' not in data:
        return jsonify({'error': 'Email , name and password are required'}), 400

    email = data['email']
    name = data['name']

    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({'error': 'User already exists'}), 400

    password = ph.hash(data['password'])

    #create the user
    new_user = User(
        email=email,
        name=name,
        password=password
    )

    #save the user
    db.session.add(new_user)
    db.session.commit()

    return jsonify({'message': 'User added successfully!'}), 201

@app.route('/google_login', methods=['GET'])
def login():
    redirect_uri = url_for('callback', _external=True)
    return google.authorize_redirect(redirect_uri)

@app.route('/callback', methods=['GET'])
def callback():
    token = google.authorize_access_token()
    resp = google.get('userinfo')
    user_info = resp.json()

    email = user_info.get('email')
    name = user_info.get('name')

    if not email:
        return jsonify({'error': 'Google login failed: email not found'}), 400

    user = User.query.filter_by(email=email).first()
    if not user:
        # If user doesn't exist, create it
        user = User(email=email, name=name, password=None)
        db.session.add(user)
        db.session.commit()

    # Generate JWT tokens
    jti = str(uuid.uuid4())
    access_token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    }, app.config['SECRET_KEY'], algorithm='HS256')

    refresh_token = jwt.encode({
        'user_id': user.id,
        'jti': jti,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=365)
    }, app.config['SECRET_KEY'], algorithm='HS256')

    return jsonify({
        'message': 'Google login successful',
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': {
            'id': user.id,
            'email': user.email,
            'name': user.name
        }
    }), 200


@app.route('/log-in',methods=['POST'])
def log_in():
    data = request.get_json()

    if not data or 'email' not in data or 'password' not in data:
        return jsonify({'error': 'Email and password are required'}), 400

    
    user = User.query.filter_by(email=data['email']).first()

    if not user:
        return jsonify({'error': 'Email not found'}), 404    

    if user.attempts==5 and not user.locked_until:
        user.locked_until=datetime.datetime.utcnow() + datetime.timedelta(minutes=5) #account locked for 5 minutes
        db.session.commit()

    if user.locked_until: 
        if user.locked_until>datetime.datetime.utcnow():
            return jsonify({'error': 'account locked'}), 403
        else:
            user.locked_until= None
            user.attempts=0     
            db.session.commit()

    password = user.password
    try: 
        ph.verify(password ,data['password'])
    except VerifyMismatchError:
        user.attempts+=1
        db.session.commit()
        return jsonify({'error': 'password incorrect!!'}), 401

    jti = str(uuid.uuid4())

    access_token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1)  # Token expires in 1 hour
    }, app.config['SECRET_KEY'], algorithm='HS256')
    refresh_token = jwt.encode({
        'user_id': user.id,
        'jti': jti,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=365)  # Token expires in 1 hour
    }, app.config['SECRET_KEY'], algorithm='HS256')

    return jsonify({
        'message': 'Login successful',
        'access_token': access_token,
        'refresh_token': refresh_token
        }), 200


@app.route('/refresh', methods=['POST'])
def refresh_token():
    auth_header = request.headers.get('Authorization')

    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({'error': 'Refresh token is required'}), 400

    refresh_token = auth_header.split(" ")[1]

    try:
        decoded = jwt.decode(refresh_token, app.config['SECRET_KEY'], algorithms=["HS256"])
        user = User.query.get(decoded['user_id'])
        jti = decoded.get('jti')

        
        exp_time = datetime.datetime.utcfromtimestamp(decoded['exp'])

        if datetime.datetime.utcnow() > exp_time:
            return jsonify({'error': 'Refresh token expired'}), 403

        # Issue new access token
        new_access_token = jwt.encode({
            'user_id': user.id,
            'exp': datetime.datetime.utcnow() + datetime.timedelta(minutes=15)
        }, app.config['SECRET_KEY'], algorithm='HS256')

        return jsonify({'access_token': new_access_token}), 200

    except jwt.ExpiredSignatureError:
        return jsonify({'error': 'Refresh token expired'}), 403
    except jwt.InvalidTokenError:
        return jsonify({'error': 'Invalid refresh token'}), 403

@app.route('/data/<int:id>', methods=['GET'])
@token_required
def data(current_user,id):
    signal = Signal.query.filter_by(id=id,user_id=current_user.id).first()

    if not signal:
        return jsonify({'error': 'test not found'}), 404
    
    decrypted_json = decrypt_data(str(signal.signal_data))
    decrypted_signal = json.loads(decrypted_json)
    
    return jsonify({'id': signal.id,
                    'signal_data': decrypted_signal,
                    'bpm': signal.bpm
                }), 200

@app.route('/data', methods=['POST'])
@token_required
def handle_data(current_user):
    
    # Add a new ECG signal to the database (associating with the user_id)
    data = request.get_json()
    
    if not data or 'signal' not in data or 'bpm' not in data:
        return jsonify({'error': 'data and bpm are required'}), 400

    if data['bpm'] <= 55 or data['bpm'] >= 150:
        s = "critique"
    elif data['bpm'] >= 120:
        s = "élevé"
    elif 90 <= data['bpm'] < 120:
        s = "modéré"
    elif 60 <= data['bpm'] < 90:
        s = "normal"
    else:
        s = "basse"

    signal_json = json.dumps(data['signal'])
    encrypted_signal = encrypt_data(signal_json)

    # Create a new Signal entry in the database
    signal_entry = Signal(user_id=current_user.id, signal_data=encrypted_signal, bpm=data['bpm'],status=s)
    db.session.add(signal_entry)
    db.session.commit()

    return jsonify({"message": "Signal saved successfully"}), 201
    
@app.route('/me', methods=['GET'])
@token_required
def get_profile(current_user):
    return jsonify({
        'id': current_user.id,
        'email': current_user.email,
        'name': current_user.name
    }), 200


@app.route('/change_password', methods= ['POST'])
@token_required
def change_pass(current_user):
    data = request.get_json()

    if not data or 'password' not in data or 'newpass' not in data:
        return jsonify({'error': 'Refresh password is required'}), 400

   
    user = User.query.filter_by(id=current_user.id).first()

    if not user:
        return jsonify({'error': 'Email not found'}), 404    


    password = user.password
    try: 
        ph.verify(password ,data['password'])
    except VerifyMismatchError:
        return jsonify({'error': 'password incorrect!!'}), 401

    user.password = ph.hash(data['newpass'])
    db.session.commit()

    return jsonify({
        'message': 'password changed'
        }), 200


@app.route('/list_data', methods= ['GET'])
@token_required
def list_user_data(current_user):
    signals = Signal.query.filter_by(user_id=current_user.id).all()

    result = [
        {
            'id': signal.id,
            'timestamp': signal.timestamp.strftime("%d/%m/%Y a %H:%M"),
            'rythme': signal.bpm,
            'status': signal.status,
        }
        for signal in signals
    ]

    return jsonify(result), 200
    

@app.route('/delete_data/<int:id>', methods= ['DELETE'])
@token_required
def delete(current_user,id):    
    test = Signal.query.filter_by(id=id, user_id=current_user.id).first()

    if not test:
        return jsonify({'error': 'test not found'}), 404


    db.session.delete(test)
    db.session.commit() 
    
    return jsonify({'message': 'test deleted'}), 200
