// ignore_for_file: non_constant_identifier_names

import 'dart:math';

class User {
  User({
    required this.id,
    required this.email,
    required this.password,
    required this.fullname,
    required this.age,
    required this.gender,
    this.height,
    this.weight,
    this.target_weight,
    this.target_days,
    this.bmi,
    this.category,
    this.completed_days = '',
  });

  final int id;
  final String email;
  final String password;
  final String fullname;
  int age;
  final String gender;
  double? height;
  double? weight;
  double? target_weight;
  int? target_days;
  double? bmi;
  String? category;
  String completed_days;

  Map<String, Object?> get_diet_plan() {
    if (weight == null || height == null || weight! <= 0 || height! <= 0) {
      return <String, Object?>{};
    }

    final double bmr = gender == 'Male'
        ? (10 * weight!) + (6.25 * height!) - (5 * age) + 5
        : (10 * weight!) + (6.25 * height!) - (5 * age) - 161;
    final double weight_diff = weight! - (target_weight ?? weight!);
    late final double daily_calories;
    late final String goal_type;

    if (weight_diff > 0) {
      daily_calories = max(1200, bmr - 500).toDouble();
      goal_type = 'Weight Loss';
    } else if (weight_diff < 0) {
      daily_calories = max(1200, bmr + 500).toDouble();
      goal_type = 'Bulking';
    } else {
      daily_calories = max(1200, bmr).toDouble();
      goal_type = 'Maintenance';
    }

    final double protein_g = weight! * 2.0;
    final double fats_g = (daily_calories * 0.25) / 9;
    final double carbs_g = max(
      0,
      (daily_calories - (protein_g * 4) - (fats_g * 9)) / 4,
    ).toDouble();

    return <String, Object?>{
      'calories': daily_calories.round(),
      'protein': protein_g.round(),
      'fats': fats_g.round(),
      'carbs': carbs_g.round(),
      'goal': goal_type,
    };
  }

  String get_suggestion() {
    final Map<String, Object?> diet = get_diet_plan();
    if (diet.isEmpty || target_weight == null || weight == null) {
      return 'Add your current and target weight to see a personalized estimate.';
    }

    final double weight_diff = (weight! - target_weight!).abs();
    if (weight! > target_weight!) {
      return 'To lose ${weight_diff.toStringAsFixed(1)} kg, aim for '
          '${diet['calories']} kcal and include protein-rich foods in balanced meals.';
    }
    if (weight! < target_weight!) {
      return 'To gain ${weight_diff.toStringAsFixed(1)} kg, aim for '
          '${diet['calories']} kcal and fuel your workouts with balanced meals.';
    }
    return 'You are at your target weight. Keep up a balanced routine and '
        'adjust your plan as your needs change.';
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'email': email,
    'password': password,
    'fullname': fullname,
    'age': age,
    'gender': gender,
    'height': height,
    'weight': weight,
    'target_weight': target_weight,
    'target_days': target_days,
    'bmi': bmi,
    'category': category,
    'completed_days': completed_days,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    email: json['email'] as String,
    password: json['password'] as String,
    fullname: json['fullname'] as String,
    age: json['age'] as int,
    gender: json['gender'] as String,
    height: (json['height'] as num?)?.toDouble(),
    weight: (json['weight'] as num?)?.toDouble(),
    target_weight: (json['target_weight'] as num?)?.toDouble(),
    target_days: json['target_days'] as int?,
    bmi: (json['bmi'] as num?)?.toDouble(),
    category: json['category'] as String?,
    completed_days: json['completed_days'] as String? ?? '',
  );
}

class DailyLog {
  DailyLog({
    required this.id,
    required this.calories_consumed,
    required this.calories_burned,
    required this.workout_type,
    required this.date_logged,
    required this.user_id,
  });

  final int id;
  final int calories_consumed;
  final int calories_burned;
  final String workout_type;
  final DateTime date_logged;
  final int user_id;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'calories_consumed': calories_consumed,
    'calories_burned': calories_burned,
    'workout_type': workout_type,
    'date_logged': date_logged.toIso8601String(),
    'user_id': user_id,
  };

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
    id: json['id'] as int,
    calories_consumed: json['calories_consumed'] as int,
    calories_burned: json['calories_burned'] as int,
    workout_type: json['workout_type'] as String,
    date_logged: DateTime.parse(json['date_logged'] as String),
    user_id: json['user_id'] as int,
  );
}
