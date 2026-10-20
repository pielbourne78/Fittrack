import 'dart:convert';
import 'dart:ui' show Size;

import 'package:fittrack_flutter/fittrack_store.dart';
import 'package:fittrack_flutter/main.dart';
import 'package:fittrack_flutter/models.dart';
import 'package:flutter/material.dart' show TextFormField;
import 'package:flutter_test/flutter_test.dart';

class _MemorySecureStore implements SecureStore {
  final Map<String, String> _values = <String, String>{};
  bool failWrites = false;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('Test storage failure.');
    _values[key] = value;
  }
}

void main() {
  late _MemorySecureStore secureStorage;
  late FitTrackStore store;

  setUp(() async {
    secureStorage = _MemorySecureStore();
    store = FitTrackStore(secureStorage: secureStorage);
    await store.initialize();
  });

  test('calculates a bounded diet estimate and keeps original field names', () {
    final User user = User(
      id: 1,
      email: 'alex@example.com',
      password: 'salt:hash',
      fullname: 'Alex Morgan',
      age: 30,
      gender: 'Male',
      height: 180,
      weight: 80,
      target_weight: 70,
    );

    final Map<String, Object?> diet = user.get_diet_plan();

    expect(diet['calories'], 1280);
    expect(diet['protein'], 160);
    expect(diet['fats'], 36);
    expect(diet['carbs'], 80);
    expect(diet['goal'], 'Weight Loss');
    expect(
      user.toJson().keys,
      containsAll(<String>['target_weight', 'target_days', 'completed_days']),
    );
  });

  test(
    'registers, authenticates, and persists the profile and activity',
    () async {
      final User user = await store.register(
        email: 'Alex@Example.com',
        password: 'strong-pass-123',
        fullname: 'Alex Morgan',
        age: 30,
        gender: 'Male',
      );

      expect(user.email, 'alex@example.com');
      expect(user.password, isNot(contains('strong-pass-123')));
      await store.update_user(
        user_id: user.id,
        weight: 80,
        height: 180,
        age: 30,
        target_weight: 70,
        target_days: 60,
      );
      await store.add_log(
        user_id: user.id,
        calories_in: 2100,
        workout: 'Leg Day',
      );
      await store.save_completed_days(
        user_id: user.id,
        completed_list: <String>['1', '3'],
      );
      await store.logout();

      final FitTrackStore reloaded = FitTrackStore(
        secureStorage: secureStorage,
      );
      await reloaded.initialize();
      expect(reloaded.current_user, isNull);

      final User signedIn = await reloaded.login(
        email: ' ALEX@example.com ',
        password: 'strong-pass-123',
      );
      expect(signedIn.weight, 80);
      expect(signedIn.bmi, 24.69);
      expect(signedIn.category, 'Normal weight');
      expect(signedIn.completed_days, '1,3');
      expect(reloaded.get_logs(signedIn.id), hasLength(1));
      expect(reloaded.get_logs(signedIn.id).single.calories_burned, 600);
    },
  );

  test('rejects duplicate accounts and invalid activity values', () async {
    final User user = await store.register(
      email: 'alex@example.com',
      password: 'strong-pass-123',
      fullname: 'Alex Morgan',
      age: 30,
      gender: 'Male',
    );

    await expectLater(
      store.register(
        email: 'ALEX@example.com',
        password: 'strong-pass-123',
        fullname: 'Alex Morgan',
        age: 30,
        gender: 'Male',
      ),
      throwsStateError,
    );
    await expectLater(
      store.add_log(user_id: user.id, calories_in: -1, workout: 'Rest'),
      throwsArgumentError,
    );
  });

  test('rolls back in-memory changes when secure storage fails', () async {
    final User user = await store.register(
      email: 'alex@example.com',
      password: 'strong-pass-123',
      fullname: 'Alex Morgan',
      age: 30,
      gender: 'Male',
    );
    secureStorage.failWrites = true;

    await expectLater(
      store.update_user(
        user_id: user.id,
        weight: 80,
        height: 180,
        age: 30,
        target_weight: 70,
        target_days: 60,
      ),
      throwsStateError,
    );

    expect(user.weight, isNull);
    expect(user.height, isNull);
    expect(user.bmi, isNull);
  });

  testWidgets('shows the FitTrack sign-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(FitTrackApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Your data stays on this device.'), findsOneWidget);
  });

  testWidgets('shows a compact sign-in screen on phone-sized displays', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(FitTrackApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('registers from the form without disposing active controllers', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(FitTrackApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Jamie Lee');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'jamie@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'strong-pass-123');
    await tester.enterText(find.byType(TextFormField).at(3), '28');
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Jamie'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches between program and report after sign-in', (
    WidgetTester tester,
  ) async {
    final User user = User(
      id: 8,
      email: 'tabs@example.com',
      password: 'salt:hash',
      fullname: 'Taylor Reed',
      age: 30,
      gender: 'Other',
      weight: 70,
      height: 175,
      target_weight: 68,
      target_days: 4,
      bmi: 22.86,
      category: 'Normal weight',
    );
    secureStorage._values['fittrack_local_data'] = jsonEncode(<String, Object?>{
      'users': <Map<String, Object?>>[user.toJson()],
      'logs': <Object?>[],
      'session_user_id': user.id,
    });
    final FitTrackStore signedInStore = FitTrackStore(
      secureStorage: secureStorage,
    );
    await signedInStore.initialize();

    await tester.pumpWidget(FitTrackApp(store: signedInStore));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back, Taylor'), findsOneWidget);

    await tester.ensureVisible(find.text('Update goals'));
    await tester.tap(find.text('Update goals'));
    await tester.pumpAndSettle();
    final Finder textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(1), '71');
    await tester.enterText(textFields.at(2), '175');
    await tester.enterText(textFields.at(3), '30');
    await tester.enterText(textFields.at(4), '68');
    await tester.enterText(textFields.at(5), '4');
    await tester.tap(find.text('Save goals'));
    await tester.pumpAndSettle();
    expect(find.text('Your goals have been updated.'), findsOneWidget);

    await tester.tap(find.text('Program').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Gym program'), findsOneWidget);

    await tester.tap(find.text('Reports').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Activity report'), findsOneWidget);

    await tester.tap(find.text('Overview').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Welcome back, Taylor'), findsOneWidget);

    await tester.tap(find.byTooltip('Account options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
