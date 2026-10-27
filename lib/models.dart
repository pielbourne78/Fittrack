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
    this.activity_level = 'Lightly active',
    this.height,
    this.weight,
    this.target_weight,
    this.target_days,
    this.bmi,
    this.category,
    this.completed_days = '',
  });

  final int id;
  String email;
  String password;
  String fullname;
  int age;
  String gender;
  String activity_level;
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
    if (age < 18) return <String, Object?>{};

    final double base_rmr = (10 * weight!) + (6.25 * height!) - (5 * age);
    final double estimated_rmr = switch (gender) {
      'Male' => base_rmr + 5,
      'Female' => base_rmr - 161,
      _ => base_rmr - 78,
    };
    const Map<String, double> activityFactors = <String, double>{
      'Sedentary': 1.4,
      'Lightly active': 1.6,
      'Moderately active': 1.8,
      'Very active': 2.0,
    };
    final double maintenance_calories =
        estimated_rmr * (activityFactors[activity_level] ?? 1.6);
    final double weight_diff = weight! - (target_weight ?? weight!);
    final int plan_days = max(1, target_days ?? 90);
    late final double daily_calories;
    late final String goal_type;
    var timeline_warning = false;
    var recommended_days = plan_days;

    if (weight_diff > 0) {
      goal_type = 'Weight Loss';
      final double requested_kg_per_week = weight_diff * 7 / plan_days;
      const double gradualKgPerWeek = 0.5;
      timeline_warning = requested_kg_per_week > gradualKgPerWeek;
      recommended_days = max(
        plan_days,
        (weight_diff / gradualKgPerWeek * 7).ceil(),
      );
      final double timeline_deficit = weight_diff * 7700 / plan_days;
      final double deficit = min(
        500,
        min(maintenance_calories * 0.2, timeline_deficit),
      );
      daily_calories = maintenance_calories - deficit;
    } else if (weight_diff < 0) {
      goal_type = 'Bulking';
      final double timeline_surplus = weight_diff.abs() * 7700 / plan_days;
      final double surplus = min(
        250,
        min(maintenance_calories * 0.1, timeline_surplus),
      );
      daily_calories = maintenance_calories + surplus;
    } else {
      goal_type = 'Maintenance';
      daily_calories = maintenance_calories;
    }

    // A balanced split keeps every displayed macro positive and consistent
    // with the estimated calorie target.
    final int protein_g = (daily_calories * 0.20 / 4).round();
    final int fats_g = (daily_calories * 0.30 / 9).round();
    final int carbs_g = (daily_calories * 0.50 / 4).round();

    return <String, Object?>{
      'calories': daily_calories.round(),
      'maintenance_calories': maintenance_calories.round(),
      'protein': protein_g,
      'fats': fats_g,
      'carbs': carbs_g,
      'goal': goal_type,
      'activity_level': activity_level,
      'timeline_warning': timeline_warning,
      'recommended_days': recommended_days,
    };
  }

  String get_suggestion() {
    final Map<String, Object?> diet = get_diet_plan();
    if (age < 18) {
      return 'Personalized calorie estimates are intended for adults. For teens, '
          'ask a qualified health professional for guidance that accounts for growth.';
    }
    if (weight == null || height == null || weight! <= 0 || height! <= 0) {
      return 'Add your current and target weight to see a personalized estimate.';
    }
    if (diet.isEmpty) return 'Update your profile to see a calorie estimate.';
    if (target_weight == null) {
      return 'Your estimated maintenance target is ${diet['calories']} kcal/day. '
          'Set a target weight to get a goal-specific estimate.';
    }

    final double weight_diff = (weight! - target_weight!).abs();
    final String calories = '${diet['calories']}';
    final String sex_note = gender == 'Other'
        ? ' The equation uses a midpoint because its standard versions use male and female inputs.'
        : '';
    final String macros =
        'A starting macro split is ${diet['protein']} g protein, '
        '${diet['carbs']} g carbohydrates, and ${diet['fats']} g fat.';
    if (weight_diff == 0) {
      return 'Your current and target weights match. Estimated maintenance is '
          '$calories kcal/day. $macros$sex_note Review your trend over a few weeks and adjust if needed.';
    }
    if (weight! > target_weight!) {
      final String timeline = diet['timeline_warning'] == true
          ? ' Your requested timeline is faster than this estimate’s conservative pace; consider allowing at least '
                '${diet['recommended_days']} days.'
          : '';
      return 'For gradual weight loss, start near $calories kcal/day '
          '(estimated maintenance: ${diet['maintenance_calories']} kcal/day). '
          '$macros$sex_note$timeline These are estimates; adjust based on your trend and how you feel.';
    }
    return 'For gradual weight gain, start near $calories kcal/day '
        '(estimated maintenance: ${diet['maintenance_calories']} kcal/day). '
        '$macros$sex_note Review your weight trend after a few weeks and adjust gradually.';
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'email': email,
    'password': password,
    'fullname': fullname,
    'age': age,
    'gender': gender,
    'activity_level': activity_level,
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
    activity_level: json['activity_level'] as String? ?? 'Lightly active',
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
