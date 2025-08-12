from flask import Blueprint, request, jsonify, session, redirect, url_for, render_template, abort
from werkzeug.security import generate_password_hash, check_password_hash
from extensions import mongo  

auth_bp = Blueprint('auth', __name__)

# 📌 Trang đăng ký (GET)
@auth_bp.route('/signup', methods=['GET'])
def signup_page():
    return render_template('register.html')

# 📌 API Đăng ký (POST)
@auth_bp.route('/signup', methods=['POST'])
def signup():
    data = request.json
    if not data or not all(k in data for k in ["full_name", "email", "password"]):
        abort(400, "Missing required fields")

    if mongo.db.users.find_one({'email': data['email']}):
        abort(400, "Email already registered")

    hashed_pw = generate_password_hash(data['password'])
    mongo.db.users.insert_one({
        "full_name": data['full_name'],
        "email": data['email'],
        "password": hashed_pw,
        "type": "user",
        "count": 0
    })
    return jsonify({"message": "User registered successfully"}), 201

# 📌 API Đăng nhập (POST)
@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    if not data or not all(k in data for k in ["email", "password"]):
        abort(400, "Missing email or password")

    user = mongo.db.users.find_one({'email': data['email']})
    if user and check_password_hash(user['password'], data['password']):
        session['user'] = {
            "email": user['email'],
            "full_name": user['full_name'],
            "type": user['type']
        }
        return jsonify({"message": "Login successful", "user": session['user']}), 200

    abort(401, "Invalid credentials")

# 📌 API Đăng xuất (GET)
@auth_bp.route('/logout', methods=['GET'])
def logout():
    session.pop('user', None)
    return jsonify({"message": "Logged out successfully"}), 200

# 📌 API Lấy thông tin user (GET)
@auth_bp.route('/profile', methods=['GET'])
def profile():
    if 'user' not in session:
        abort(401, "Unauthorized")

    return jsonify({"user": session['user']}), 200
