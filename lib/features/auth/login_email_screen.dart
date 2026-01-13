import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../ui/components/cs_button.dart';
import 'login_phone_screen.dart';

class LoginEmailScreen extends ConsumerStatefulWidget {
  const LoginEmailScreen({super.key});

  static const String routeName = 'login';
  static const String routePath = '/login';

  @override
  ConsumerState<LoginEmailScreen> createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends ConsumerState<LoginEmailScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _doEmailLogin() async {
    final session = ref.read(authSessionProvider);
    setState(() => _error = null);
    try {
      await session.loginWithEmailPassword(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _doMockLogin() async {
    final session = ref.read(authSessionProvider);
    setState(() => _error = null);
    try {
      await session.mockLogin();
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول', textDirection: TextDirection.rtl),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'الإيميل',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 10),
            ],
            CsButton(
              label: 'دخول',
              isLoading: session.isBusy,
              icon: Icons.login_rounded,
              onPressed: session.isBusy ? null : _doEmailLogin,
            ),
            const SizedBox(height: 10),
            CsButton(
              label: 'دخول تجريبي (بدون باك)',
              isLoading: session.isBusy,
              icon: Icons.bolt_rounded,
              onPressed: session.isBusy ? null : _doMockLogin,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go(LoginPhoneScreen.routePath),
              child: const Text('تسجيل الدخول برقم الهاتف (OTP)'),
            ),
            const SizedBox(height: 8),
            const Text(
              'ملاحظة: الدخول الحقيقي يعتمد على Firebase Auth ثم تبادل idToken مع Backend للحصول على JWT.\nزر "دخول تجريبي" للتطوير مؤقتًا فقط.',
              style: TextStyle(fontSize: 12),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
