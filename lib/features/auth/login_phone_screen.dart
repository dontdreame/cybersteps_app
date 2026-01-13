import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../ui/components/cs_button.dart';
import 'login_otp_screen.dart';

class LoginPhoneScreen extends ConsumerStatefulWidget {
  const LoginPhoneScreen({super.key});

  static const String routeName = 'login_phone';
  static const String routePath = '/login/phone';

  @override
  ConsumerState<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends ConsumerState<LoginPhoneScreen> {
  final _phone = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دخول الهاتف', textDirection: TextDirection.rtl),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (مثال: +9627xxxxxxxx)',
              ),
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
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
              label: 'إرسال كود OTP',
              isLoading: session.isBusy,
              icon: Icons.sms_rounded,
              onPressed: session.isBusy
                  ? null
                  : () async {
                      if (!mounted) return;
                      setState(() => _error = null);
                      final phone = _phone.text.trim();
                      try {
                        await ref.read(authSessionProvider).startPhoneLogin(phone);
                        if (mounted) context.go(LoginOtpScreen.routePath);
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _error = e.toString());
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
