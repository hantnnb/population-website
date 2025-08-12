from flask import Blueprint, render_template

main_bp = Blueprint('main', __name__)


@main_bp.route('/')
def index():
    return render_template('home.html')


@main_bp.route('/profile')
def profile():
    return render_template('profile.html')


@main_bp.route('/news')
def news():
    return render_template('news.html')


@main_bp.route('/population')
def population():
    return render_template('population-list.html')
