import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../ui/components/cs_button.dart';

class LoginOtpScreen extends ConsumerStatefulWidget {
  const LoginOtpScreen({super.key});

  static const String routeName = 'login_otp';
  static const String routePath = '/login/otp';

  @override
  ConsumerState<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends ConsumerState<LoginOtpScreen> {
  final _otp = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد OTP', textDirection: TextDirection.rtl),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'أدخل الكود اللي وصلك على SMS',
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otp,
              decoration: const InputDecoration(labelText: 'OTP'),
              keyboardType: TextInputType.number,
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
              label: 'تأكيد ودخول',
              isLoading: session.isBusy,
              icon: Icons.verified_rounded,
              onPressed: session.isBusy
                  ? null
                  : () async {
                      if (!mounted) return;
                      setState(() => _error = null);
                      try {
                        await ref.read(authSessionProvider).verifyOtp(_otp.text.trim());
                        if (mounted) context.go('/home');
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _error = e.toString());
                      }
                    },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/login/phone'),
              child: const Text('رجوع'),
            )
          ],
        ),
      ),
    );
  }
}
