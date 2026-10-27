// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'fittrack_store.dart';
import 'models.dart';

const Color _accent = Color(0xFFEF6428);
const Color _ink = Color(0xFF202D3A);
const Color _muted = Color(0xFF687785);
const Color _canvas = Color(0xFFF6F7F9);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitTrackApp());
}

class FitTrackApp extends StatefulWidget {
  const FitTrackApp({this.store, super.key});

  final FitTrackStore? store;

  @override
  State<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends State<FitTrackApp> {
  late final FitTrackStore _store;
  late Future<void> _ready;
  User? _user;
  Object? _startupError;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? FitTrackStore();
    _ready = _initialize();
  }

  Future<void> _initialize() async {
    final Stopwatch startupTimer = Stopwatch()..start();
    try {
      await _store.initialize();
      _user = _store.current_user;
    } catch (error) {
      _startupError = error;
    }
    const Duration introDuration = Duration(milliseconds: 1250);
    final Duration remaining = introDuration - startupTimer.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (mounted) setState(() => _initialized = true);
  }

  void _authenticated(User user) => setState(() => _user = user);

  void _retryInitialization() {
    setState(() {
      _initialized = false;
      _startupError = null;
      _ready = _initialize();
    });
  }

  Future<void> _logout() async {
    await _store.logout();
    if (mounted) setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          primary: _accent,
          surface: Colors.white,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _ink,
          displayColor: _ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E8EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E8EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFEAEDF0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: Color(0xFFE0E5E9)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: FutureBuilder<void>(
        future: _ready,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (!_initialized) {
            return const _LoadingScreen();
          }
          if (_startupError != null) {
            return _StartupErrorScreen(
              error: _startupError!,
              onRetry: _retryInitialization,
            );
          }
          final User? user = _user;
          if (user == null) {
            return AuthScreen(store: _store, onAuthenticated: _authenticated);
          }
          return MainShell(
            key: ValueKey<int>(user.id),
            user: user,
            store: _store,
            onLogout: _logout,
            onAccountDeleted: () => setState(() => _user = null),
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..forward();

  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.55,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  late final Animation<double> _logoRotation = Tween<double>(
    begin: -0.12,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
  );

  late final Animation<Offset> _textSlide =
      Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFFF1E8), Color(0xFFF6F7F9)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.24),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              builder: (BuildContext context, Widget? child) =>
                  Transform.rotate(
                    angle: _logoRotation.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  ),
            ),
            const SizedBox(height: 22),
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: const Column(
                  children: <Widget>[
                    Text(
                      'FitTrack',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'YOUR FITNESS, IN FOCUS',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 34),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _accent.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: _accent),
              const SizedBox(height: 16),
              const Text(
                'FitTrack could not load your saved data.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.store,
    required this.onAuthenticated,
    super.key,
  });

  final FitTrackStore store;
  final ValueChanged<User> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _fullname = '';
  String _email = '';
  String _password = '';
  String _age = '';
  bool _registering = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String _gender = 'Male';
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      if (_registering) {
        await widget.store.register(
          email: _email,
          password: _password,
          fullname: _fullname,
          age: int.parse(_age),
          gender: _gender,
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        _emailController.text = _email;
        _passwordController.clear();
        setState(() {
          _registering = false;
          _busy = false;
          _success = 'Account created. Sign in with your new account.';
        });
        return;
      }
      final User user = await widget.store.login(
        email: _email,
        password: _password,
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      widget.onAuthenticated(user);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(error);
          _busy = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _registering = !_registering;
      _error = null;
      _success = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 780;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFFFF1E8), Color(0xFFF6F7F9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 960 : 440),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const Expanded(child: _AuthIntroduction()),
                          const SizedBox(width: 48),
                          Expanded(child: _authCard()),
                        ],
                      )
                    : _authCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authCard() => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutCubic,
    builder: (BuildContext context, double value, Widget? child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - value)),
        child: child,
      ),
    ),
    child: Card(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!MediaQuery.sizeOf(context).width.isNaN &&
                    MediaQuery.sizeOf(context).width < 780)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: _Brand(),
                  ),
                Text(
                  _registering ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _registering
                      ? 'Build a routine that works for you.'
                      : 'Sign in to continue your progress.',
                  style: const TextStyle(color: _muted, fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (_registering) ...<Widget>[
                  TextFormField(
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onSaved: (String? value) => _fullname = value?.trim() ?? '',
                    validator: (String? value) =>
                        value == null || value.trim().isEmpty
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  onSaved: (String? value) => _email = value?.trim() ?? '',
                  validator: (String? value) {
                    final String email = value?.trim() ?? '';
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Enter a valid email address';
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: _registering
                      ? const <String>[AutofillHints.newPassword]
                      : const <String>[AutofillHints.password],
                  onSaved: (String? value) => _password = value ?? '',
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your password';
                    }
                    if (_registering && value.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    return null;
                  },
                ),
                if (_registering) ...<Widget>[
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final Widget ageField = TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              suffixText: 'years',
                            ),
                            onSaved: (String? value) =>
                                _age = value?.trim() ?? '',
                            validator: (String? value) {
                              final int? age = int.tryParse(value ?? '');
                              return age != null && age >= 13 && age <= 120
                                  ? null
                                  : 'Use an age from 13 to 120';
                            },
                          );
                          final Widget genderField =
                              DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: const InputDecoration(
                                  labelText: 'Sex',
                                ),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                    value: 'Male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Female',
                                    child: Text('Female'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Other',
                                    child: Text('Other'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() => _gender = value);
                                  }
                                },
                              );
                          if (constraints.maxWidth < 360) {
                            return Column(
                              children: <Widget>[
                                ageField,
                                const SizedBox(height: 12),
                                genderField,
                              ],
                            );
                          }
                          return Row(
                            children: <Widget>[
                              Expanded(child: ageField),
                              const SizedBox(width: 12),
                              Expanded(child: genderField),
                            ],
                          );
                        },
                  ),
                ],
                if (_success != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _success!,
                      style: const TextStyle(color: Color(0xFF246B45)),
                    ),
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _InlineError(_error!),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_registering ? 'Create account' : 'Sign in'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        _registering
                            ? 'Already have an account? '
                            : 'New to FitTrack? ',
                        style: const TextStyle(color: _muted),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _toggleMode,
                        child: Text(
                          _registering ? 'Sign in' : 'Create account',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your data stays on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _AuthIntroduction extends StatelessWidget {
  const _AuthIntroduction();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Brand(),
        SizedBox(height: 34),
        Text(
          'Small steps.\nStronger you.',
          style: TextStyle(
            fontSize: 48,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        SizedBox(height: 18),
        Text(
          'Bring your goals, meals, and workouts together in one calm, '
          'personal fitness space.',
          style: TextStyle(fontSize: 17, height: 1.6, color: _muted),
        ),
        SizedBox(height: 28),
        _Benefit(
          icon: Icons.track_changes,
          label: 'Set goals that feel achievable',
        ),
        SizedBox(height: 12),
        _Benefit(
          icon: Icons.favorite_outline,
          label: 'Track progress at your pace',
        ),
        SizedBox(height: 12),
        _Benefit(
          icon: Icons.lock_outline,
          label: 'Keep your data on your device',
        ),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, color: _accent, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          maxLines: 2,
          style: const TextStyle(color: _ink, fontSize: 14),
        ),
      ),
    ],
  );
}

class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.fitness_center, color: Colors.white),
      ),
      const SizedBox(width: 11),
      if (!compact)
        const Text(
          'FitTrack',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
    ],
  );
}

class MainShell extends StatefulWidget {
  const MainShell({
    required this.user,
    required this.store,
    required this.onLogout,
    required this.onAccountDeleted,
    super.key,
  });

  final User user;
  final FitTrackStore store;
  final Future<void> Function() onLogout;
  final VoidCallback onAccountDeleted;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _refresh() => setState(() {});

  Future<void> _logout() async {
    try {
      await widget.onLogout();
    } catch (error) {
      if (mounted) _showMessage(context, _friendlyError(error), isError: true);
    }
  }

  Future<void> _editAccountInfo() async {
    final _AccountInfoValues? values = await showDialog<_AccountInfoValues>(
      context: context,
      builder: (BuildContext dialogContext) => _AccountInfoDialog(
        user: widget.user,
        onDeleteRequested: () {
          Navigator.of(dialogContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _deleteAccount();
          });
        },
      ),
    );
    if (values == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 16),
                Text('Saving account details…'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      await widget.store.update_account_info(
        user_id: widget.user.id,
        fullname: values.fullname,
        email: values.email,
        age: values.age,
        gender: values.gender,
        current_password: values.currentPassword,
        new_password: values.newPassword,
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.of(context).pop();
      _refresh();
      _showMessage(context, 'Account details updated.');
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage(context, _friendlyError(error), isError: true);
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this account?'),
        content: const Text(
          'This permanently removes your profile and activity history from '
          'this device.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.store.delete_user(widget.user.id);
      widget.onAccountDeleted();
    } catch (error) {
      if (mounted) _showMessage(context, _friendlyError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      DashboardTab(
        user: widget.user,
        store: widget.store,
        onUserChanged: _refresh,
        onSelectTab: (int index) => setState(() => _selectedIndex = index),
      ),
      GymProgramTab(
        user: widget.user,
        store: widget.store,
        onUserChanged: _refresh,
      ),
      ReportsTab(
        user: widget.user,
        store: widget.store,
        onLogsChanged: _refresh,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _canvas,
        surfaceTintColor: _canvas,
        title: _Brand(compact: MediaQuery.sizeOf(context).width < 520),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                'Hi, ${widget.user.fullname.split(' ').first}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account options',
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFE5D6),
              child: Icon(Icons.person_outline, color: _accent, size: 20),
            ),
            onSelected: (String value) {
              if (value == 'logout') _logout();
              if (value == 'edit_account') _editAccountInfo();
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit_account',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.manage_accounts_outlined),
                      title: Text('Edit Account Info'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text('Sign out'),
                    ),
                  ),
                ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) =>
            setState(() => _selectedIndex = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Program',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({
    required this.user,
    required this.store,
    required this.onUserChanged,
    required this.onSelectTab,
    super.key,
  });

  final User user;
  final FitTrackStore store;
  final VoidCallback onUserChanged;
  final ValueChanged<int> onSelectTab;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final GlobalKey<FormState> _logFormKey = GlobalKey<FormState>();
  final TextEditingController _calories = TextEditingController();
  String workout_type = 'Push Day';
  bool _savingLog = false;

  @override
  void dispose() {
    _calories.dispose();
    super.dispose();
  }

  bool get _hasStats =>
      (widget.user.weight ?? 0) > 0 && (widget.user.height ?? 0) > 0;

  Future<void> _showGoalEditor() async {
    final _GoalValues? saved = await showDialog<_GoalValues>(
      context: context,
      builder: (BuildContext context) => _GoalEditorDialog(user: widget.user),
    );
    if (saved != null && mounted) {
      try {
        await widget.store.update_user(
          user_id: widget.user.id,
          weight: saved.weight,
          height: saved.height,
          age: saved.age,
          target_weight: saved.target_weight,
          target_days: saved.target_days,
          activity_level: saved.activity_level,
        );
        widget.onUserChanged();
        if (mounted) _showMessage(context, 'Your goals have been updated.');
      } catch (error) {
        if (mounted) {
          _showMessage(context, _friendlyError(error), isError: true);
        }
      }
    }
  }

  Future<void> _saveLog() async {
    if (!_logFormKey.currentState!.validate()) return;
    setState(() => _savingLog = true);
    try {
      await widget.store.add_log(
        user_id: widget.user.id,
        calories_in: int.parse(_calories.text),
        workout: workout_type,
      );
      _calories.clear();
      if (mounted) {
        setState(() => _savingLog = false);
        _showMessage(context, 'Today’s activity was saved.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _savingLog = false);
        _showMessage(context, _friendlyError(error), isError: true);
      }
    }
  }

  Future<void> _resetPlan() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear goals and progress?'),
        content: const Text(
          'This removes your body measurements, goal weight, and all activity '
          'logs. Your profile will remain.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.store.reset_diet(widget.user.id);
      widget.onUserChanged();
      if (mounted) {
        _showMessage(context, 'Goals and activity logs were cleared.');
      }
    } catch (error) {
      if (mounted) _showMessage(context, _friendlyError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Object?> diet = widget.user.get_diet_plan();
    final List<DailyLog> logs = widget.store.get_logs(widget.user.id);
    final int todayCalories = logs
        .where((DailyLog log) => _isToday(log.date_logged))
        .fold<int>(
          0,
          (int total, DailyLog log) => total + log.calories_consumed,
        );
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _PageHeading(
          eyebrow: 'YOUR FITNESS SPACE',
          title: 'Welcome back, ${widget.user.fullname.split(' ').first}',
          subtitle: 'Keep your focus on the next small step.',
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            _SummaryTile(
              label: 'Current weight',
              value: _hasStats
                  ? '${_formatNumber(widget.user.weight!)} kg'
                  : '—',
              icon: Icons.monitor_weight_outlined,
              color: const Color(0xFFFFF0E7),
              animated: true,
            ),
            _SummaryTile(
              label: 'BMI estimate',
              value: _hasStats ? widget.user.bmi!.toStringAsFixed(1) : '—',
              icon: Icons.favorite_outline,
              color: const Color(0xFFEAF5F0),
              animated: true,
            ),
            _SummaryTile(
              label: 'Today’s intake',
              value: '$todayCalories kcal',
              icon: Icons.local_fire_department_outlined,
              color: const Color(0xFFFFF5DB),
              animated: true,
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 740) {
              return Column(
                children: <Widget>[
                  _goalCard(),
                  const SizedBox(height: 16),
                  _dietCard(diet),
                  const SizedBox(height: 16),
                  _dailyLogCard(),
                ],
              );
            }
            return Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 4, child: _goalCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: _dietCard(diet)),
                  ],
                ),
                const SizedBox(height: 16),
                _dailyLogCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Recent activity',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: () => widget.onSelectTab(2),
              icon: const Icon(Icons.arrow_forward, size: 17),
              label: const Text('All reports'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          const _EmptyState(
            icon: Icons.edit_calendar_outlined,
            title: 'No activity logged yet',
            message: 'Add a daily log above to start seeing your progress.',
          )
        else
          ...logs.take(3).map(_ActivityRow.new),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: content,
        ),
      ),
    );
  }

  Widget _goalCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _CardHeading(
            icon: Icons.track_changes,
            title: 'Your profile',
            subtitle: 'A quick look at your basics',
            animated: true,
          ),
          const SizedBox(height: 20),
          _ProfileLine(label: 'Full name', value: widget.user.fullname),
          const Divider(height: 22),
          _ProfileLine(label: 'Age', value: '${widget.user.age} years'),
          const Divider(height: 22),
          _ProfileLine(label: 'Sex', value: widget.user.gender),
          const Divider(height: 22),
          _ProfileLine(label: 'Activity', value: widget.user.activity_level),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showGoalEditor,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(_hasStats ? 'Update goals' : 'Set your goals'),
            ),
          ),
          if (_hasStats) ...<Widget>[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _resetPlan,
                child: const Text('Clear goals and progress'),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _dietCard(Map<String, Object?> diet) {
    if (widget.user.age < 18) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _CardHeading(
                icon: Icons.restaurant_menu,
                title: 'Your daily guide',
                subtitle: 'A simple, personalized estimate',
                animated: true,
              ),
              const SizedBox(height: 18),
              const _EmptyState(
                icon: Icons.health_and_safety_outlined,
                title: 'Personalized calorie estimates are for adults',
                message:
                    'Nutrition needs change during growth. Ask a qualified '
                    'health professional for guidance tailored to you.',
              ),
            ],
          ),
        ),
      );
    }
    if (!_hasStats || diet.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _CardHeading(
                icon: Icons.restaurant_menu,
                title: 'Your daily guide',
                subtitle: 'A simple, personalized estimate',
                animated: true,
              ),
              const SizedBox(height: 18),
              const _EmptyState(
                icon: Icons.monitor_weight_outlined,
                title: 'Your plan starts with your goals',
                message:
                    'Add your height and weight to see an estimated daily '
                    'calorie target and nutrition breakdown.',
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _showGoalEditor,
                icon: const Icon(Icons.add),
                label: const Text('Add measurements'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _CardHeading(
              icon: Icons.restaurant_menu,
              title: 'Your daily guide',
              subtitle: 'An estimate based on your current profile',
              animated: true,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFFFF2E9), Color(0xFFFFE4D4)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'ESTIMATED DAILY TARGET',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${diet['calories']} kcal',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '${diet['goal']} · BMI ${widget.user.bmi?.toStringAsFixed(1) ?? '—'} '
                    '(${widget.user.category ?? 'not available'})',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MacroTile(
                    label: 'Protein',
                    value: '${diet['protein']} g',
                    color: const Color(0xFFE9F4EE),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroTile(
                    label: 'Carbs',
                    value: '${diet['carbs']} g',
                    color: const Color(0xFFEAF1FB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroTile(
                    label: 'Fats',
                    value: '${diet['fats']} g',
                    color: const Color(0xFFFFF2DC),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.lightbulb_outline, color: _accent, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.user.get_suggestion(),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'These calorie and BMI figures are general estimates, not medical '
              'advice. Speak with a qualified health professional for guidance.',
              style: TextStyle(color: _muted, fontSize: 11, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyLogCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _logFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _CardHeading(
              icon: Icons.add_task,
              title: 'Log today',
              subtitle: 'Record your intake and activity',
              animated: true,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 560;
                final Widget caloriesField = TextFormField(
                  controller: _calories,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories consumed',
                    suffixText: 'kcal',
                    prefixIcon: Icon(Icons.local_dining_outlined),
                  ),
                  validator: (String? value) {
                    final int? calories = int.tryParse(value ?? '');
                    return calories != null &&
                            calories >= 0 &&
                            calories <= 10000
                        ? null
                        : 'Enter a value from 0 to 10,000';
                  },
                );
                final Widget workoutField = DropdownButtonFormField<String>(
                  initialValue: workout_type,
                  decoration: const InputDecoration(
                    labelText: 'Workout',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'Push Day',
                      child: Text('Push day'),
                    ),
                    DropdownMenuItem(
                      value: 'Pull Day',
                      child: Text('Pull day'),
                    ),
                    DropdownMenuItem(value: 'Leg Day', child: Text('Leg day')),
                    DropdownMenuItem(value: 'Rest', child: Text('Rest day')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) setState(() => workout_type = value);
                  },
                );
                if (compact) {
                  return Column(
                    children: <Widget>[
                      caloriesField,
                      const SizedBox(height: 12),
                      workoutField,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: caloriesField),
                    const SizedBox(width: 12),
                    Expanded(child: workoutField),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _savingLog ? null : _saveLog,
                icon: _savingLog
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save daily progress'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class GymProgramTab extends StatefulWidget {
  const GymProgramTab({
    required this.user,
    required this.store,
    required this.onUserChanged,
    super.key,
  });

  final User user;
  final FitTrackStore store;
  final VoidCallback onUserChanged;

  @override
  State<GymProgramTab> createState() => _GymProgramTabState();
}

class _GymProgramTabState extends State<GymProgramTab> {
  late Set<String> completed_list;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    completed_list = widget.user.completed_days.isEmpty
        ? <String>{}
        : widget.user.completed_days.split(',').toSet();
  }

  static const List<Map<String, Object>> rotation = <Map<String, Object>>[
    <String, Object>{
      'name': 'Push day',
      'focus': 'Chest, shoulders & triceps',
      'alt': 'Express push: chest press + lateral raises (15 min)',
      'exercises': <Map<String, Object>>[
        <String, Object>{'name': 'Flat bench press', 'cal': 45},
        <String, Object>{'name': 'Incline dumbbell press', 'cal': 40},
        <String, Object>{'name': 'Chest flyes', 'cal': 30},
        <String, Object>{'name': 'Shoulder press', 'cal': 40},
        <String, Object>{'name': 'Tricep pushdowns', 'cal': 20},
        <String, Object>{'name': 'Dips', 'cal': 35},
      ],
    },
    <String, Object>{
      'name': 'Pull day',
      'focus': 'Back & biceps',
      'alt': 'Express pull: seated rows + hammer curls (15 min)',
      'exercises': <Map<String, Object>>[
        <String, Object>{'name': 'Deadlifts', 'cal': 60},
        <String, Object>{'name': 'Pull-ups', 'cal': 45},
        <String, Object>{'name': 'Bent-over rows', 'cal': 40},
        <String, Object>{'name': 'Barbell curls', 'cal': 20},
        <String, Object>{'name': 'Hammer curls', 'cal': 20},
      ],
    },
    <String, Object>{
      'name': 'Leg day',
      'focus': 'Quads, hamstrings & calves',
      'alt': 'Express legs: goblet squats + kettlebell swings (15 min)',
      'exercises': <Map<String, Object>>[
        <String, Object>{'name': 'Back squats', 'cal': 65},
        <String, Object>{'name': 'Leg press', 'cal': 45},
        <String, Object>{'name': 'Stiff-leg deadlifts', 'cal': 45},
        <String, Object>{'name': 'Calf raises', 'cal': 20},
      ],
    },
    <String, Object>{
      'name': 'Rest & recovery',
      'focus': 'Mobility, hydration & sleep',
      'alt': 'Active recovery: 15-minute easy walk',
      'exercises': <Map<String, Object>>[
        <String, Object>{'name': 'Light stretching', 'cal': 15},
        <String, Object>{'name': 'Hydration focus', 'cal': 0},
        <String, Object>{'name': 'Full recovery sleep', 'cal': 0},
      ],
    },
  ];

  List<Map<String, Object>> get full_schedule {
    final List<Map<String, Object>> full_schedule = <Map<String, Object>>[];
    final int limit = widget.user.target_days ?? 30;
    final List<String> completed_list = this.completed_list.toList();
    for (int i = 0; i < limit; i++) {
      final int day_num = i + 1;
      final Map<String, Object> rot_item = rotation[i % 4];
      full_schedule.add(<String, Object>{
        'day_num': day_num,
        'name': rot_item['name']!,
        'focus': rot_item['focus']!,
        'alt': rot_item['alt']!,
        'exercises': rot_item['exercises']!,
        'is_done': completed_list.contains('$day_num'),
      });
    }
    return full_schedule;
  }

  Future<void> _saveProgress() async {
    setState(() => _saving = true);
    try {
      await widget.store.save_completed_days(
        user_id: widget.user.id,
        completed_list: completed_list.toList(),
      );
      widget.onUserChanged();
      if (mounted) {
        setState(() => _saving = false);
        _showMessage(context, 'Workout progress saved.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showMessage(context, _friendlyError(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, Object>> full_schedule = this.full_schedule;
    final int completedCount = full_schedule
        .where((Map<String, Object> item) => item['is_done']! as bool)
        .length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _PageHeading(
                eyebrow: 'YOUR TRAINING ROUTINE',
                title: 'Gym program',
                subtitle:
                    'A repeating four-day rhythm, paced to your ${widget.user.target_days ?? 30}-day timeline.',
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: _accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '$completedCount of ${full_schedule.length} days complete',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Check off each day and save your progress.',
                              style: TextStyle(color: _muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (full_schedule.isNotEmpty)
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: completedCount / full_schedule.length,
                            strokeWidth: 5,
                            backgroundColor: const Color(0xFFF0F1F3),
                            color: _accent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ...full_schedule.map(_dayCard),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveProgress,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save workout progress'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Exercise calorie figures are rough estimates and vary by '
                'person, intensity, and duration.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCard(Map<String, Object> item) {
    final int day_num = item['day_num']! as int;
    final bool is_done = completed_list.contains('$day_num');
    final List<Map<String, Object>> exercises =
        (item['exercises']! as List<Object>).cast<Map<String, Object>>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          leading: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: is_done
                  ? const Color(0xFFE5F3E9)
                  : const Color(0xFFFFF0E7),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              '$day_num',
              style: TextStyle(
                color: is_done ? const Color(0xFF318052) : _accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Text(
            '${item['name']}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${item['focus']} · ${item['alt']}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          trailing: Checkbox(
            value: is_done,
            activeColor: const Color(0xFF318052),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  completed_list.add('$day_num');
                } else {
                  completed_list.remove('$day_num');
                }
              });
            },
          ),
          children: <Widget>[
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...exercises.map(
              (Map<String, Object> exercise) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.circle, size: 7, color: Color(0xFFB3BDC5)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${exercise['name']}')),
                    Text(
                      '${exercise['cal']} kcal',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({
    required this.user,
    required this.store,
    required this.onLogsChanged,
    super.key,
  });

  final User user;
  final FitTrackStore store;
  final VoidCallback onLogsChanged;

  Future<void> _editLog(BuildContext context, DailyLog log) async {
    final _LogEditValues? values = await showDialog<_LogEditValues>(
      context: context,
      builder: (BuildContext context) => _LogEditDialog(log: log),
    );
    if (values == null) return;
    try {
      await store.update_log(
        user_id: user.id,
        log_id: log.id,
        calories_in: values.calories,
        workout: values.workout,
      );
      onLogsChanged();
      if (context.mounted) _showMessage(context, 'Activity updated.');
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, _friendlyError(error), isError: true);
      }
    }
  }

  Future<void> _deleteLog(BuildContext context, DailyLog log) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this activity?'),
        content: const Text('This activity entry will be permanently removed.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete activity'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.delete_log(user_id: user.id, log_id: log.id);
      onLogsChanged();
      if (context.mounted) _showMessage(context, 'Activity deleted.');
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, _friendlyError(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DailyLog> logs = store.get_logs(user.id);
    final int total_entries = logs.length;
    final int total_consumed = logs.fold<int>(
      0,
      (int total, DailyLog log) => total + log.calories_consumed,
    );
    final int total_burned = logs.fold<int>(
      0,
      (int total, DailyLog log) => total + log.calories_burned,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _PageHeading(
                eyebrow: 'YOUR HISTORY',
                title: 'Activity report',
                subtitle: 'A clear record of your meals and training days.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: <Widget>[
                  _SummaryTile(
                    label: 'Days tracked',
                    value: '$total_entries',
                    icon: Icons.event_note_outlined,
                    color: const Color(0xFFEAF1FB),
                  ),
                  _SummaryTile(
                    label: 'Calories consumed',
                    value: '$total_consumed kcal',
                    icon: Icons.local_dining_outlined,
                    color: const Color(0xFFFFF0E7),
                  ),
                  _SummaryTile(
                    label: 'Calories burned',
                    value: '$total_burned kcal',
                    icon: Icons.local_fire_department_outlined,
                    color: const Color(0xFFEAF5F0),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (logs.isEmpty)
                const _EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'Your report is ready when you are',
                  message:
                      'Log a meal or workout from the Overview tab and it will '
                      'show up here.',
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Daily entries · $total_entries',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        ...logs.map(
                          (DailyLog log) => _ActivityRow(
                            log,
                            onEdit: () => _editLog(context, log),
                            onDelete: () => _deleteLog(context, log),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              const Text(
                'Calories burned are estimates for the selected workout type, '
                'not a measurement of your actual activity.',
                style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.log, {this.onEdit, this.onDelete});

  final DailyLog log;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final String date =
        '${log.date_logged.year}-${_twoDigits(log.date_logged.month)}-${_twoDigits(log.date_logged.day)}';
    final int net = log.calories_consumed - log.calories_burned;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F2))),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  log.workout_type,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(date, style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '+${log.calories_consumed} / −${log.calories_burned} kcal',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 3),
              Text(
                'Net $net kcal',
                style: const TextStyle(
                  fontSize: 12,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (onEdit != null && onDelete != null)
            PopupMenuButton<String>(
              tooltip: 'Activity options',
              onSelected: (String action) {
                if (action == 'edit') onEdit!();
                if (action == 'delete') onDelete!();
              },
              itemBuilder: (BuildContext context) =>
                  const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit activity'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete activity'),
                      ),
                    ),
                  ],
            ),
        ],
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        eyebrow,
        style: const TextStyle(
          color: _accent,
          fontSize: 11,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
      ),
      const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 14)),
    ],
  );
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.animated = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool animated;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E7),
          borderRadius: BorderRadius.circular(13),
        ),
        child: animated
            ? _FloatingIcon(child: Icon(icon, color: _accent, size: 20))
            : Icon(icon, color: _accent, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
      ),
    ],
  );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.animated = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool animated;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: min(300, (MediaQuery.sizeOf(context).width - 54) / 2),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: animated
                  ? _FloatingIcon(child: Icon(icon, color: _ink, size: 20))
                  : Icon(icon, color: _ink, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FloatingIcon extends StatefulWidget {
  const _FloatingIcon({required this.child});

  final Widget child;

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleAnimationStatus);
    _schedulePulse();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.reverse();
    } else if (status == AnimationStatus.dismissed) {
      _schedulePulse();
    }
  }

  void _schedulePulse() {
    _pulseTimer?.cancel();
    _pulseTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (BuildContext context, Widget? child) {
      final double motion = Curves.easeInOutCubic.transform(_controller.value);
      return Transform.translate(
        offset: Offset(0, -3 * motion),
        child: Transform.scale(scale: 1 + (0.035 * motion), child: child),
      );
    },
  );
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      children: <Widget>[
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    ),
  );
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(label, style: const TextStyle(color: _muted)),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _LogEditValues {
  const _LogEditValues({required this.calories, required this.workout});

  final int calories;
  final String workout;
}

class _LogEditDialog extends StatefulWidget {
  const _LogEditDialog({required this.log});

  final DailyLog log;

  @override
  State<_LogEditDialog> createState() => _LogEditDialogState();
}

class _LogEditDialogState extends State<_LogEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _calories;
  late String _workout;

  static const List<String> _workouts = <String>[
    'Push Day',
    'Pull Day',
    'Leg Day',
    'Rest',
  ];

  @override
  void initState() {
    super.initState();
    _calories = TextEditingController(
      text: widget.log.calories_consumed.toString(),
    );
    _workout = widget.log.workout_type;
  }

  @override
  void dispose() {
    _calories.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _LogEditValues(calories: int.parse(_calories.text), workout: _workout),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit activity'),
    content: SizedBox(
      width: 400,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories consumed',
                suffixText: 'kcal',
              ),
              validator: (String? value) {
                final int? calories = int.tryParse(value ?? '');
                if (calories == null || calories < 0 || calories > 10000) {
                  return 'Enter a whole number from 0 to 10000';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _workout,
              decoration: const InputDecoration(labelText: 'Workout'),
              items: _workouts
                  .map(
                    (String workout) => DropdownMenuItem<String>(
                      value: workout,
                      child: Text(workout),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value != null) setState(() => _workout = value);
              },
            ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save changes')),
    ],
  );
}

class _AccountInfoValues {
  const _AccountInfoValues({
    required this.fullname,
    required this.email,
    required this.age,
    required this.gender,
    required this.currentPassword,
    required this.newPassword,
  });

  final String fullname;
  final String email;
  final int age;
  final String gender;
  final String? currentPassword;
  final String? newPassword;
}

class _AccountInfoDialog extends StatefulWidget {
  const _AccountInfoDialog({
    required this.user,
    required this.onDeleteRequested,
  });

  final User user;
  final VoidCallback onDeleteRequested;

  @override
  State<_AccountInfoDialog> createState() => _AccountInfoDialogState();
}

class _AccountInfoDialogState extends State<_AccountInfoDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullname;
  late final TextEditingController _email;
  late final TextEditingController _age;
  late final TextEditingController _currentPassword;
  late final TextEditingController _newPassword;
  late final TextEditingController _confirmPassword;
  late String _gender;
  bool _showPasswordFields = false;
  bool _obscurePasswords = true;

  @override
  void initState() {
    super.initState();
    _fullname = TextEditingController(text: widget.user.fullname);
    _email = TextEditingController(text: widget.user.email);
    _age = TextEditingController(text: widget.user.age.toString());
    _currentPassword = TextEditingController();
    _newPassword = TextEditingController();
    _confirmPassword = TextEditingController();
    _gender = widget.user.gender;
  }

  @override
  void dispose() {
    _fullname.dispose();
    _email.dispose();
    _age.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _AccountInfoValues(
        fullname: _fullname.text.trim(),
        email: _email.text.trim(),
        age: int.parse(_age.text),
        gender: _gender,
        currentPassword: _currentPassword.text.isEmpty
            ? null
            : _currentPassword.text,
        newPassword: _newPassword.text.isEmpty ? null : _newPassword.text,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) => TextFormField(
    controller: controller,
    obscureText: _obscurePasswords,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscurePasswords = !_obscurePasswords),
        icon: Icon(
          _obscurePasswords
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    ),
    onChanged: (String _) => setState(() {}),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) {
    final bool changingPassword =
        _currentPassword.text.isNotEmpty ||
        _newPassword.text.isNotEmpty ||
        _confirmPassword.text.isNotEmpty;
    return AlertDialog(
      title: const Text('Edit Account Info'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _fullname,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (String? value) =>
                      value == null || value.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address'),
                  validator: (String? value) {
                    final String email = value?.trim() ?? '';
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Enter a valid email address';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    suffixText: 'years',
                  ),
                  validator: (String? value) {
                    final int? age = int.tryParse(value ?? '');
                    return age != null && age >= 13 && age <= 120
                        ? null
                        : 'Use an age from 13 to 120';
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Sex'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) setState(() => _gender = value);
                  },
                ),
                const SizedBox(height: 4),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Change password'),
                  value: _showPasswordFields,
                  onChanged: (bool value) {
                    if (!value) {
                      _currentPassword.clear();
                      _newPassword.clear();
                      _confirmPassword.clear();
                    }
                    setState(() => _showPasswordFields = value);
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _showPasswordFields
                      ? Column(
                          children: <Widget>[
                            _passwordField(
                              controller: _currentPassword,
                              label: 'Current password',
                              validator: (String? value) =>
                                  changingPassword &&
                                      (value == null || value.isEmpty)
                                  ? 'Enter your current password'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _passwordField(
                              controller: _newPassword,
                              label: 'New password',
                              validator: (String? value) =>
                                  changingPassword &&
                                      (value == null || value.length < 8)
                                  ? 'Use at least 8 characters'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _passwordField(
                              controller: _confirmPassword,
                              label: 'Confirm new password',
                              validator: (String? value) =>
                                  value != _newPassword.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.onDeleteRequested,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save changes')),
      ],
    );
  }
}

class _GoalValues {
  const _GoalValues({
    required this.weight,
    required this.height,
    required this.age,
    required this.target_weight,
    required this.target_days,
    required this.activity_level,
  });

  final double weight;
  final double height;
  final int age;
  final double target_weight;
  final int target_days;
  final String activity_level;
}

class _GoalEditorDialog extends StatefulWidget {
  const _GoalEditorDialog({required this.user});

  final User user;

  @override
  State<_GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends State<_GoalEditorDialog> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController weight;
  late final TextEditingController height;
  late final TextEditingController age;
  late final TextEditingController target_weight;
  late final TextEditingController target_days;
  late String activity_level;

  @override
  void initState() {
    super.initState();
    weight = TextEditingController(
      text: (widget.user.weight ?? 0) > 0 ? widget.user.weight!.toString() : '',
    );
    height = TextEditingController(
      text: (widget.user.height ?? 0) > 0 ? widget.user.height!.toString() : '',
    );
    age = TextEditingController(text: widget.user.age.toString());
    target_weight = TextEditingController(
      text: (widget.user.target_weight ?? 0) > 0
          ? widget.user.target_weight!.toString()
          : '',
    );
    target_days = TextEditingController(
      text: (widget.user.target_days ?? 0) > 0
          ? widget.user.target_days!.toString()
          : '',
    );
    activity_level = widget.user.activity_level;
  }

  @override
  void dispose() {
    weight.dispose();
    height.dispose();
    age.dispose();
    target_weight.dispose();
    target_days.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _GoalValues(
        weight: double.parse(weight.text),
        height: double.parse(height.text),
        age: int.parse(age.text),
        target_weight: double.parse(target_weight.text),
        target_days: int.parse(target_days.text),
        activity_level: activity_level,
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String unit, {
    required num min,
    required num max,
    bool integer = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: unit),
      validator: (String? value) {
        final num? parsed = integer
            ? int.tryParse(value ?? '')
            : double.tryParse(value ?? '');
        if (parsed == null ||
            !parsed.isFinite ||
            parsed < min ||
            parsed > max) {
          return 'Enter a value from $min to $max';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Your fitness goals'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _numberField(weight, 'Current weight', 'kg', min: 25, max: 350),
              const SizedBox(height: 12),
              _numberField(height, 'Height', 'cm', min: 100, max: 250),
              const SizedBox(height: 12),
              _numberField(
                age,
                'Age',
                'years',
                min: 13,
                max: 120,
                integer: true,
              ),
              const SizedBox(height: 12),
              _numberField(
                target_weight,
                'Target weight',
                'kg',
                min: 25,
                max: 350,
              ),
              const SizedBox(height: 12),
              _numberField(
                target_days,
                'Target timeline',
                'days',
                min: 1,
                max: 365,
                integer: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: activity_level,
                decoration: const InputDecoration(
                  labelText: 'Usual activity level',
                  helperText:
                      'Include your normal daily movement and workouts.',
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(
                    value: 'Sedentary',
                    child: Text('Mostly sitting'),
                  ),
                  DropdownMenuItem(
                    value: 'Lightly active',
                    child: Text('Light activity'),
                  ),
                  DropdownMenuItem(
                    value: 'Moderately active',
                    child: Text('Moderate activity'),
                  ),
                  DropdownMenuItem(
                    value: 'Very active',
                    child: Text('Very active most days'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value != null) setState(() => activity_level = value);
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save goals')),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FB),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: <Widget>[
        Icon(icon, size: 30, color: const Color(0xFF9BA7B1)),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDEA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.error_outline, color: Color(0xFFB9382C), size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFF9C2F27), fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

bool _isToday(DateTime value) {
  final DateTime now = DateTime.now();
  return value.year == now.year &&
      value.month == now.month &&
      value.day == now.day;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

String _friendlyError(Object error) {
  if (error is StateError) return error.message;
  if (error is ArgumentError) return error.message.toString();
  return 'Something went wrong while saving. Please try again. ($error)';
}

void _showMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB9382C) : _ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
