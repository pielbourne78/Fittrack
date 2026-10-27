// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class DeviceSecureStore implements SecureStore {
  const DeviceSecureStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class FitTrackStore {
  FitTrackStore({SecureStore? secureStorage})
    : _secureStorage = secureStorage ?? const DeviceSecureStore();

  static const String _storageKey = 'fittrack_local_data';
  static const int _passwordIterations = 120000;

  final SecureStore _secureStorage;
  final Pbkdf2 _passwordHasher = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _passwordIterations,
    bits: 256,
  );

  final List<User> _users = <User>[];
  final List<DailyLog> _logs = <DailyLog>[];
  int? _session_user_id;
  int _next_user_id = 1;
  int _next_log_id = 1;

  User? get current_user {
    final int? id = _session_user_id;
    if (id == null) return null;
    for (final User user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  Future<void> initialize() async {
    final String? serialized = await _secureStorage.read(_storageKey);
    if (serialized == null) return;

    final Map<String, dynamic> data =
        jsonDecode(serialized) as Map<String, dynamic>;
    final List<dynamic> users_data = data['users'] as List<dynamic>? ?? [];
    final List<dynamic> logs_data = data['logs'] as List<dynamic>? ?? [];

    _users
      ..clear()
      ..addAll(
        users_data.map(
          (dynamic item) => User.fromJson(item as Map<String, dynamic>),
        ),
      );
    _logs
      ..clear()
      ..addAll(
        logs_data.map(
          (dynamic item) => DailyLog.fromJson(item as Map<String, dynamic>),
        ),
      );
    _session_user_id = data['session_user_id'] as int?;
    _next_user_id = _users.fold<int>(
      1,
      (int current, User user) => max(current, user.id + 1),
    );
    _next_log_id = _logs.fold<int>(
      1,
      (int current, DailyLog log) => max(current, log.id + 1),
    );

    if (current_user == null) {
      _session_user_id = null;
      await _persist();
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String fullname,
    required int age,
    required String gender,
  }) async {
    final String normalized_email = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized_email)) {
      throw ArgumentError.value(email, 'email', 'Enter a valid email address.');
    }
    if (password.length < 8) {
      throw ArgumentError.value(
        password.length,
        'password',
        'Use at least 8 characters.',
      );
    }
    if (fullname.trim().isEmpty) {
      throw ArgumentError.value(fullname, 'fullname', 'Enter your name.');
    }
    if (age < 13 || age > 120) {
      throw ArgumentError.value(age, 'age', 'Use an age from 13 to 120.');
    }
    if (!const <String>{'Male', 'Female', 'Other'}.contains(gender)) {
      throw ArgumentError.value(gender, 'gender');
    }
    if (_users.any((User user) => user.email == normalized_email)) {
      throw StateError('An account with this email already exists.');
    }

    final int? previous_session_user_id = _session_user_id;
    final Uint8List salt = Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final SecretKey secretKey = await _passwordHasher.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final List<int> password_hash = await secretKey.extractBytes();
    final String encoded_password =
        '${base64UrlEncode(salt)}:${base64UrlEncode(password_hash)}';
    final User new_user = User(
      id: _next_user_id++,
      email: normalized_email,
      password: encoded_password,
      fullname: fullname.trim(),
      age: age,
      gender: gender,
    );

    _users.add(new_user);
    _session_user_id = null;
    try {
      await _persist();
    } catch (_) {
      _users.remove(new_user);
      _session_user_id = previous_session_user_id;
      _next_user_id = new_user.id;
      rethrow;
    }
    return new_user;
  }

  Future<User> update_account_info({
    required int user_id,
    required String fullname,
    required String email,
    required int age,
    required String gender,
    String? current_password,
    String? new_password,
  }) async {
    final User user = _find_user(user_id);
    final String normalized_email = email.trim().toLowerCase();
    final String normalized_fullname = fullname.trim();
    if (normalized_fullname.isEmpty) {
      throw ArgumentError.value(fullname, 'fullname', 'Enter your name.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized_email)) {
      throw ArgumentError.value(email, 'email', 'Enter a valid email address.');
    }
    if (_users.any(
      (User candidate) =>
          candidate.id != user_id && candidate.email == normalized_email,
    )) {
      throw StateError('An account with this email already exists.');
    }
    if (age < 13 || age > 120) {
      throw ArgumentError.value(age, 'age', 'Use an age from 13 to 120.');
    }
    if (!const <String>{'Male', 'Female', 'Other'}.contains(gender)) {
      throw ArgumentError.value(gender, 'gender');
    }

    final bool changing_password =
        (current_password?.isNotEmpty ?? false) ||
        (new_password?.isNotEmpty ?? false);
    String? updated_password;
    if (changing_password) {
      if (current_password == null || current_password.isEmpty) {
        throw ArgumentError.value(
          current_password,
          'current_password',
          'Enter your current password to change it.',
        );
      }
      if (new_password == null || new_password.length < 8) {
        throw ArgumentError.value(
          new_password,
          'new_password',
          'Use at least 8 characters for your new password.',
        );
      }
      final List<String> password_parts = user.password.split(':');
      if (password_parts.length != 2) {
        throw StateError('This account password cannot be verified.');
      }
      final Uint8List salt = Uint8List.fromList(
        base64Url.decode(base64Url.normalize(password_parts[0])),
      );
      final SecretKey current_key = await _passwordHasher.deriveKey(
        secretKey: SecretKey(utf8.encode(current_password)),
        nonce: salt,
      );
      final String current_hash = base64UrlEncode(
        await current_key.extractBytes(),
      );
      if (current_hash != password_parts[1]) {
        throw StateError('Your current password is incorrect.');
      }

      final Uint8List new_salt = Uint8List.fromList(
        List<int>.generate(16, (_) => Random.secure().nextInt(256)),
      );
      final SecretKey new_key = await _passwordHasher.deriveKey(
        secretKey: SecretKey(utf8.encode(new_password)),
        nonce: new_salt,
      );
      updated_password =
          '${base64UrlEncode(new_salt)}:'
          '${base64UrlEncode(await new_key.extractBytes())}';
    }

    final String previous_fullname = user.fullname;
    final String previous_email = user.email;
    final int previous_age = user.age;
    final String previous_gender = user.gender;
    final String previous_password = user.password;
    user
      ..fullname = normalized_fullname
      ..email = normalized_email
      ..age = age
      ..gender = gender;
    if (updated_password != null) user.password = updated_password;
    try {
      await _persist();
    } catch (_) {
      user
        ..fullname = previous_fullname
        ..email = previous_email
        ..age = previous_age
        ..gender = previous_gender
        ..password = previous_password;
      rethrow;
    }
    return user;
  }

  Future<User> login({required String email, required String password}) async {
    final String normalized_email = email.trim().toLowerCase();
    User? user;
    for (final User candidate in _users) {
      if (candidate.email == normalized_email) {
        user = candidate;
        break;
      }
    }
    if (user == null) {
      throw StateError('Invalid email or password.');
    }

    final List<String> password_parts = user.password.split(':');
    if (password_parts.length != 2) {
      throw StateError('This account password cannot be verified.');
    }
    final Uint8List salt = Uint8List.fromList(
      base64Url.decode(base64Url.normalize(password_parts[0])),
    );
    final SecretKey secretKey = await _passwordHasher.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final List<int> password_hash = await secretKey.extractBytes();
    final String encoded_password = base64UrlEncode(password_hash);

    if (encoded_password != password_parts[1]) {
      throw StateError('Invalid email or password.');
    }

    _session_user_id = user.id;
    await _persist();
    return user;
  }

  Future<void> logout() async {
    final int? previous_user_id = _session_user_id;
    _session_user_id = null;
    try {
      await _persist();
    } catch (_) {
      _session_user_id = previous_user_id;
      rethrow;
    }
  }

  Future<User> update_user({
    required int user_id,
    required double weight,
    required double height,
    required int age,
    required double target_weight,
    required int target_days,
    String? activity_level,
  }) async {
    final User user = _find_user(user_id);
    if (!weight.isFinite || weight < 25 || weight > 350) {
      throw ArgumentError.value(weight, 'weight');
    }
    if (!height.isFinite || height < 100 || height > 250) {
      throw ArgumentError.value(height, 'height');
    }
    if (age < 13 || age > 120) {
      throw ArgumentError.value(age, 'age');
    }
    if (!target_weight.isFinite || target_weight < 25 || target_weight > 350) {
      throw ArgumentError.value(target_weight, 'target_weight');
    }
    if (target_days < 1 || target_days > 365) {
      throw ArgumentError.value(target_days, 'target_days');
    }
    if (activity_level != null &&
        !const <String>{
          'Sedentary',
          'Lightly active',
          'Moderately active',
          'Very active',
        }.contains(activity_level)) {
      throw ArgumentError.value(activity_level, 'activity_level');
    }
    final double? previous_weight = user.weight;
    final double? previous_height = user.height;
    final int previous_age = user.age;
    final double? previous_target_weight = user.target_weight;
    final int? previous_target_days = user.target_days;
    final String previous_activity_level = user.activity_level;
    final double? previous_bmi = user.bmi;
    final String? previous_category = user.category;
    user.weight = weight;
    user.height = height;
    user.age = age;
    user.target_weight = target_weight;
    user.target_days = target_days;
    if (activity_level != null) user.activity_level = activity_level;

    final double bmi_val = weight / ((height / 100) * (height / 100));
    user.bmi = double.parse(bmi_val.toStringAsFixed(2));
    late final String category_val;
    if (user.bmi! < 18.5) {
      category_val = 'Underweight';
    } else if (user.bmi! < 25) {
      category_val = 'Normal weight';
    } else if (user.bmi! < 30) {
      category_val = 'Overweight';
    } else {
      category_val = 'Obese';
    }
    user.category = category_val;

    try {
      await _persist();
    } catch (_) {
      user
        ..weight = previous_weight
        ..height = previous_height
        ..age = previous_age
        ..target_weight = previous_target_weight
        ..target_days = previous_target_days
        ..activity_level = previous_activity_level
        ..bmi = previous_bmi
        ..category = previous_category;
      rethrow;
    }
    return user;
  }

  Future<void> add_log({
    required int user_id,
    required int calories_in,
    required String workout,
  }) async {
    _find_user(user_id);
    if (calories_in < 0 || calories_in > 10000) {
      throw ArgumentError.value(calories_in, 'calories_in');
    }
    const Map<String, int> burn_estimates = <String, int>{
      'Push Day': 450,
      'Pull Day': 400,
      'Leg Day': 600,
      'Rest': 0,
    };
    if (!burn_estimates.containsKey(workout)) {
      throw ArgumentError.value(workout, 'workout');
    }

    final int calories_out = burn_estimates[workout]!;
    final DailyLog new_entry = DailyLog(
      id: _next_log_id++,
      calories_consumed: calories_in,
      calories_burned: calories_out,
      workout_type: workout,
      date_logged: DateTime.now(),
      user_id: user_id,
    );
    _logs.add(new_entry);
    try {
      await _persist();
    } catch (_) {
      _logs.remove(new_entry);
      _next_log_id = new_entry.id;
      rethrow;
    }
  }

  Future<void> update_log({
    required int user_id,
    required int log_id,
    required int calories_in,
    required String workout,
  }) async {
    _find_user(user_id);
    final int log_index = _logs.indexWhere(
      (DailyLog log) => log.id == log_id && log.user_id == user_id,
    );
    if (log_index < 0) {
      throw StateError('The requested activity could not be found.');
    }
    if (calories_in < 0 || calories_in > 10000) {
      throw ArgumentError.value(calories_in, 'calories_in');
    }
    const Map<String, int> burn_estimates = <String, int>{
      'Push Day': 450,
      'Pull Day': 400,
      'Leg Day': 600,
      'Rest': 0,
    };
    if (!burn_estimates.containsKey(workout)) {
      throw ArgumentError.value(workout, 'workout');
    }

    final DailyLog previous_log = _logs[log_index];
    final DailyLog updated_log = DailyLog(
      id: previous_log.id,
      calories_consumed: calories_in,
      calories_burned: burn_estimates[workout]!,
      workout_type: workout,
      date_logged: previous_log.date_logged,
      user_id: previous_log.user_id,
    );
    _logs[log_index] = updated_log;
    try {
      await _persist();
    } catch (_) {
      _logs[log_index] = previous_log;
      rethrow;
    }
  }

  Future<void> delete_log({required int user_id, required int log_id}) async {
    _find_user(user_id);
    final int log_index = _logs.indexWhere(
      (DailyLog log) => log.id == log_id && log.user_id == user_id,
    );
    if (log_index < 0) {
      throw StateError('The requested activity could not be found.');
    }

    final DailyLog deleted_log = _logs.removeAt(log_index);
    try {
      await _persist();
    } catch (_) {
      _logs.insert(log_index, deleted_log);
      rethrow;
    }
  }

  Future<void> reset_diet(int user_id) async {
    final User user = _find_user(user_id);
    final double? previous_weight = user.weight;
    final double? previous_height = user.height;
    final double? previous_bmi = user.bmi;
    final String? previous_category = user.category;
    final double? previous_target_weight = user.target_weight;
    final List<DailyLog> previous_logs = _logs
        .where((DailyLog log) => log.user_id == user_id)
        .toList();
    user
      ..weight = 0
      ..height = 0
      ..bmi = null
      ..category = null
      ..target_weight = 0;
    _logs.removeWhere((DailyLog log) => log.user_id == user_id);
    try {
      await _persist();
    } catch (_) {
      user
        ..weight = previous_weight
        ..height = previous_height
        ..bmi = previous_bmi
        ..category = previous_category
        ..target_weight = previous_target_weight;
      _logs.addAll(previous_logs);
      rethrow;
    }
  }

  Future<void> delete_user(int user_id) async {
    final User user_to_delete = _find_user(user_id);
    final List<DailyLog> user_logs = _logs
        .where((DailyLog log) => log.user_id == user_id)
        .toList();
    final int? previous_session_user_id = _session_user_id;
    _users.removeWhere((User user) => user.id == user_id);
    _logs.removeWhere((DailyLog log) => log.user_id == user_id);
    if (_session_user_id == user_id) _session_user_id = null;
    try {
      await _persist();
    } catch (_) {
      _users.add(user_to_delete);
      _logs.addAll(user_logs);
      _session_user_id = previous_session_user_id;
      rethrow;
    }
  }

  Future<void> save_completed_days({
    required int user_id,
    required List<String> completed_list,
  }) async {
    final User user = _find_user(user_id);
    final String previous_completed_days = user.completed_days;
    user.completed_days = completed_list.join(',');
    try {
      await _persist();
    } catch (_) {
      user.completed_days = previous_completed_days;
      rethrow;
    }
  }

  List<DailyLog> get_logs(int user_id) {
    final List<DailyLog> user_logs = _logs
        .where((DailyLog log) => log.user_id == user_id)
        .toList();
    user_logs.sort(
      (DailyLog first, DailyLog second) =>
          second.date_logged.compareTo(first.date_logged),
    );
    return user_logs;
  }

  User _find_user(int user_id) {
    for (final User user in _users) {
      if (user.id == user_id) return user;
    }
    throw StateError('The requested account could not be found.');
  }

  Future<void> _persist() async {
    final Map<String, Object?> data = <String, Object?>{
      'users': _users.map((User user) => user.toJson()).toList(),
      'logs': _logs.map((DailyLog log) => log.toJson()).toList(),
      'session_user_id': _session_user_id,
    };
    await _secureStorage.write(_storageKey, jsonEncode(data));
  }
}
