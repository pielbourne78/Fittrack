from flask import Flask, request, jsonify, render_template, redirect, url_for, flash
from models import db, User, DailyLog
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)

# --- CONFIGURATION ---
app.secret_key = 'some_very_random_string_here'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///fittracks.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

# Create the database tables
with app.app_context():
    db.create_all()

# --- ROUTES ---

@app.route('/')
def home():
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'GET':
        return render_template('register.html')
    
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        fullname = request.form.get('fullname')
        age = request.form.get('age')
        gender = request.form.get('gender')

        # Check if user exists
        if User.query.filter_by(email=email).first():
            return "Email already exists! <a href='/register'>Try again</a>", 400

        hashed_pw = generate_password_hash(password, method='pbkdf2:sha256')
        
        new_user = User(
            email=email, 
            password=hashed_pw, 
            fullname=fullname, 
            age=age, 
            gender=gender
        )
        
        db.session.add(new_user)
        db.session.commit()
        
        return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        return render_template('login.html')

    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')

        user = User.query.filter_by(email=email).first()

        if user and check_password_hash(user.password, password):
            return redirect(url_for('dashboard', user_id=user.id))
        else:
            return "Invalid email or password. <a href='/login'>Try again</a>", 401
        
#------------------------------------
# FEATURE 1: DIET PLAN/BMI CALCULATOR
#------------------------------------

@app.route('/update_user/<int:user_id>', methods=['POST'])
def update_user(user_id):
    user = User.query.get_or_404(user_id)
    try:
        # We use .get() with a default of 0 to prevent the 'NoneType' error
        weight = float(request.form.get('weight', 0))
        height = float(request.form.get('height', 0))
        age = int(request.form.get('age', user.age)) # Fallback to existing age
        target_weight = float(request.form.get('target_weight', 0))
        target_days = int(request.form.get('target_days', 0))

        # --- CALCULATE BMI ---
        if height > 0:
            bmi_val = round(weight / ((height / 100) ** 2), 2)
            if bmi_val < 18.5: category_val = "Underweight"
            elif bmi_val < 25: category_val = "Normal weight"
            elif bmi_val < 30: category_val = "Overweight"
            else: category_val = "Obese"
        else:
            bmi_val, category_val = 0, "Unknown"

        # Update the existing user's fields
        user.height = height
        user.weight = weight
        user.age = age
        user.target_weight = target_weight
        user.target_days = target_days
        user.bmi = bmi_val
        user.category = category_val

        db.session.commit()
        return redirect(url_for('dashboard', user_id=user.id))

    except Exception as e:
        db.session.rollback()
        return f"Error updating stats: {e}", 400

#------------------------------------------------
# FEATURE 2: DASHBOARD WITH LOG PROGRESS TRACKING
#------------------------------------------------

@app.route('/add_log/<int:user_id>', methods=['POST'])
def add_log(user_id):
    try:
        # 1. Get the data from the dashboard form
        calories_in= int(request.form.get('calories', 0))
        workout = request.form.get('workout_type', 'Rest')
        
        # Simple estimation logic
        burn_estimates = {
            "Push Day": 450,
            "Pull Day": 400,
            "Leg Day": 600,
            "Rest": 0
        }
        # Get the burn value based on the workout, default to 0 if not found
        calories_out = burn_estimates.get(workout, 0)
        
        # 2. Create the new log entry
        new_entry = DailyLog(
            calories_consumed=calories_in,
            calories_burned=calories_out, # Save the calculated burn
            workout_type=workout,
            user_id=user_id
        )
        
        # 3. Save to database
        db.session.add(new_entry)
        db.session.commit()
        
        return redirect(url_for('dashboard', user_id=user_id))
    except Exception as e:
        db.session.rollback()
        return f"Error logging activity: {e}", 400


#---------------------------------------
# RESET DIET PLAN (OPTIONAL, NOT IN MVP)
#---------------------------------------
@app.route('/reset_diet/<int:user_id>')
def reset_diet(user_id):
    user = User.query.get_or_404(user_id)
    
    # 1. Clear the health stats (this triggers the 'else' block in your HTML)
    user.weight = 0.0
    user.height = 0.0
    user.bmi = None
    user.category = None
    user.target_weight = 0.0
    
    # 2. Clear the daily logs if you want a total reset
    DailyLog.query.filter_by(user_id=user_id).delete()
    
    # 3. Save changes
    db.session.commit()
    
    # 4. Redirect back to the dashboard
    return redirect(url_for('dashboard', user_id=user.id))
#----------------------------------------
#  PLAN DELETE (OPTIONAL, NOT IN MVP)
#----------------------------------------
@app.route('/delete_user/<int:user_id>')
def delete_user(user_id):
    """ CRUD: DELETE - Removes the entire user and their history """
    user_to_delete = User.query.get_or_404(user_id)
    
    try:
        db.session.delete(user_to_delete)
        db.session.commit()
        # Redirect to login since the user no longer exists
        return redirect(url_for('dashboard')) 
    except Exception as e:
        db.session.rollback()
        return f"Error deleting account: {e}"
        
@app.route('/dashboard/<int:user_id>')
def dashboard(user_id):
    # Fetch the user by their ID
    user = User.query.get_or_404(user_id)
    return render_template('dashboard.html', user=user)       

#--------------------------------------
# LOG REPORTS (FEATURE 3: Log Reports)
#---------------------------------------
@app.route('/report/<int:user_id>')
def view_report(user_id):
    user = User.query.get_or_404(user_id)
    
    # Fetch all logs for this user, newest first
    # This works because of the 'logs' relationship in your User model
    user_logs = DailyLog.query.filter_by(user_id=user_id).order_by(DailyLog.date_logged.desc()).all()
    
    # Optional: Calculate total calories or average for a quick summary
    total_entries = len(user_logs)
    
    return render_template('report.html', user=user, logs=user_logs, total_entries=total_entries)

#--------------------------------------
# GYM PROGRAM ORGANIZER
#--------------------------------------
@app.route('/gym_program/<int:user_id>', methods=['GET', 'POST'])
def gym_program(user_id):
    user = User.query.get_or_404(user_id)
    
    # Handle progress saving
    if request.method == 'POST':
        completed = request.form.getlist('completed_days')
        user.completed_days = ",".join(completed)
        db.session.commit()
        return redirect(url_for('gym_program', user_id=user.id))

    # 1. Define your exercises and calorie estimates
    rotation = [
        {
            "name": "Push Day (Chest, Shoulders, Triceps)",
            "exercises": [
                {"name": "Flat Bench Press", "cal": 45}, {"name": "Incline DB Press", "cal": 40}, 
                {"name": "Chest Flyes", "cal": 30}, {"name": "Shoulder Press", "cal": 40},
                {"name": "Tricep Pushdowns", "cal": 20}, {"name": "Dips", "cal": 35}
            ],
            "alt": "Express Push: 3 sets of DB Chest Press + Lateral Raises (15 mins)"
        },
        {
            "name": "Pull Day (Back, Biceps)",
            "exercises": [
                {"name": "Deadlifts", "cal": 60}, {"name": "Pull-ups", "cal": 45}, 
                {"name": "Bent Over Rows", "cal": 40}, {"name": "Barbell Curls", "cal": 20}, 
                {"name": "Hammer Curls", "cal": 20}
            ],
            "alt": "Express Pull: 3 sets of Seated Rows + Hammer Curls (15 mins)"
        },
        {
            "name": "Leg Day (Quads, Hamstrings, Calves)",
            "exercises": [
                {"name": "Back Squats", "cal": 65}, {"name": "Leg Press", "cal": 45}, 
                {"name": "Stiff Leg Deadlifts", "cal": 45}, {"name": "Calf Raises", "cal": 20}
            ],
            "alt": "Express Legs: 3 sets of Goblet Squats + KB Swings (15 mins)"
        },
        {
            "name": "Rest & Recovery",
            "exercises": [
                {"name": "Light Stretching", "cal": 15}, {"name": "Hydration Focus", "cal": 0}, 
                {"name": "Full Recovery Sleep", "cal": 0}
            ],
            "alt": "Active Recovery: 15 mins Low-Intensity Walk"
        }
    ]

    # 2. Build the schedule based on your target timeline
    full_schedule = []
    completed_list = user.completed_days.split(',') if user.completed_days else []
    
    # Use your target_days from the database (like the 10 or 40 days in your screenshots)
    limit = user.target_days if user.target_days else 30

    for i in range(limit):
        day_num = i + 1
        rot_item = rotation[i % 4] # This ensures the 4-day pattern repeats
        
        # This is where you put the code you asked about:
        full_schedule.append({
            "day_num": day_num,
            "name": rot_item["name"],
            "exercises": rot_item["exercises"], # Passes the list to HTML
            "alt": rot_item["alt"],
            "is_done": str(day_num) in completed_list
        })

    return render_template('gym_program.html', user=user, schedule=full_schedule)


# --- START THE SERVER ---
# This MUST be at the very bottom of the file
if __name__ == '__main__':
    app.run(debug=True)
    
