from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

# Define the User model
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(128), nullable=False)
    fullname = db.Column(db.String(120), nullable=False)
    age = db.Column(db.Integer, nullable=False)
    gender = db.Column(db.String(10), nullable=False)
    height = db.Column(db.Float, nullable=True)
    weight = db.Column(db.Float, nullable=True)
    target_weight = db.Column(db.Float, nullable=True)
    target_days = db.Column(db.Integer, nullable=True)
    bmi = db.Column(db.Float)
    category = db.Column(db.String(50))
    completed_days = db.Column(db.String(500), default="") 
    
    # Relationship to logs (One-to-Many)
    # Using 'DailyLog' in quotes is correct here!
    logs = db.relationship('DailyLog', backref='owner', lazy=True, cascade="all, delete-orphan")

#--------------------------------
# FEATURE 1: Diet Plan/BMI Calculator
#--------------------------------

    def get_diet_plan(self):
        # ... (your existing diet plan code) ...
        if not self.weight or not self.height:
            return None # Prevent crash if stats aren't set yet

        if self.gender == "Male":
            bmr = (10 * self.weight) + (6.25 * self.height) - (5 * self.age) + 5
        else:
            bmr = (10 * self.weight) + (6.25 * self.height) - (5 * self.age) - 161
        
        weight_diff = self.weight - (self.target_weight or self.weight)
        
        if weight_diff > 0:
            daily_calories = bmr - 500
            goal_type = "Weight Loss"
        elif weight_diff < 0:
            daily_calories = bmr + 500
            goal_type = "Bulking"
        else:
            daily_calories = bmr
            goal_type = "Maintenance"

        protein_g = self.weight * 2.0
        fats_g = (daily_calories * 0.25) / 9
        carbs_g = (daily_calories - (protein_g * 4) - (fats_g * 9)) / 4

        return {
            "calories": round(daily_calories),
            "protein": round(protein_g),
            "fats": round(fats_g),
            "carbs": round(carbs_g),
            "goal": goal_type
        }
        
        # IMPORTANT: This function fixes the 'get_suggestion' error in your UI
    def get_suggestion(self):
        diet = self.get_diet_plan()
        weight_diff = round(abs(self.weight - self.target_weight), 1)
        
        if self.weight > self.target_weight:
            return f"To lose {weight_diff}kg, stick to {diet['calories']} kcal. Focus on high protein ({diet['protein']}g) to maintain muscle while losing fat."
        elif self.weight < self.target_weight:
            return f"To gain {weight_diff}kg, aim for {diet['calories']} kcal. Ensure you hit {diet['carbs']}g of carbs for energy during workouts."
        else:
            return "You are at your target weight! Maintain your current activity and balanced macro intake."

#----------------------------------------------
# DAILY LOG MODEL (FEATURE 2: Daily Log Tracker)
#------------------------------------------------
class DailyLog(db.Model):
    __tablename__ = 'daily_logs'
    
    id = db.Column(db.Integer, primary_key=True)
    calories_consumed = db.Column(db.Integer, default=0)
    calories_burned = db.Column(db.Integer, default=0) # <--- Add this
    workout_type = db.Column(db.String(100), default="Rest") # Matches the <select> in your HTML
    date_logged = db.Column(db.DateTime, default=db.func.current_timestamp()) # Automatically sets the date
    
    # Foreign Key linking back to the User table
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    