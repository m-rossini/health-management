from flask import Flask, request, jsonify, session
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS  # Import Flask-CORS
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy.exc import IntegrityError, DataError
from datetime import datetime
import logging

app = Flask(__name__)
CORS(app,origins=['*'],supports_credentials=True)  # Enable CORS for the app

logging.basicConfig(level=logging.DEBUG)

app.secret_key = 'supersecretkey'  # Replace with a random secret key

#Network configurations
db_user='rossini'
db_host='postgres-pod'
db_name='user_db'
db_schema='users'
# 'protocol://user:password@host:port/database?options'
postgres_url='postgresql://'+db_user+':rossini@' + db_host + '/' + db_name
app.config['SQLALCHEMY_DATABASE_URI'] = postgres_url
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# User model
class Users(db.Model):
    __table_args__ = {"schema":db_schema}
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(100), nullable=False)
    preferred_name = db.Column(db.String(100), nullable=False)
    date_of_birth = db.Column(db.Date, nullable=False)
    email = db.Column(db.String(100), unique=True)
    password_hash = db.Column(db.String(128), nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

# Routes
@app.route('/test', methods=['GET'])
def test():
    return jsonify('OK'), 200

@app.route('/register', methods=['POST'])
def register():
    data = request.json
    app.logger.debug(">>>Registering new user: %s", data)
    full_name = data['full_name']
    preferred_name = data['preferred_name']
    date_of_birth = data['date_of_birth']
    email = data['email']
    password = data['password']
    date_of_birth = datetime.strptime(data.get('date_of_birth'), '%Y-%m-%d')

    if not email or not password:
        return jsonify({"message": "Email and password are required"}), 400    
    
    user = Users(full_name=full_name, preferred_name=preferred_name, date_of_birth=date_of_birth, email=email)
    user.set_password(password)

    try:
        db.session.add(user)
        db.session.commit() 
    except Exception as e:
        app.logger.error(e)
        if isinstance(e, IntegrityError) or isinstance(e, DataError):
            db.session.rollback()
            return jsonify({'success': False, 'message': 'User already exists, name or email already in use'}), 400     
        else:
            db.session.rollback()
            return jsonify({'success': False, 'message': 'Internal server error, try again later'}), 500
        
    return jsonify({'success': True}), 200

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    email = data['email']
    password = data['password']
    app.logger.info(">>>Logging in user: %s", email)
    user = Users.query.filter_by(email=email).first()
    
    if user and user.check_password(password):
        session['user_id'] = user.id
        session['preferred_name'] = user.preferred_name
        return jsonify({'success': True, 'preferred_name': user.preferred_name}), 200
    
    return jsonify({'success': False, 'message': 'Invalid credentials'}), 401

@app.route('/user_data', methods=['GET'])
def user_data():
    user_id = session.get('user_id')
    if not user_id:
        return jsonify({"message": "Not logged in"}), 401

    user = Users.query.get(user_id)
    if user:
        return jsonify({
            "user_id": user.id,
            "full_name": user.full_name,
            "preferred_name": user.preferred_name,
            "date_of_birth": user.date_of_birth.isoformat(),
            "email": user.email
        }), 200

    return jsonify({"message": "User not found"}), 404

@app.route('/logout', methods=['POST'])
def logout():
    session.clear()
    return jsonify({'success': True}), 200

#TODO Create args and change dockefiles
if __name__ == '__main__':
    print("Starting user service.")
    print("postgres url:",postgres_url )
    # db.create_all()
    app.run(host='0.0.0.0', port=5001)
