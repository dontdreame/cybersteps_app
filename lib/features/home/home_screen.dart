import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../ui/components/cs_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routeName = 'home';
  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final me = session.me;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية', textDirection: TextDirection.rtl),
        actions: [
          IconButton(
            tooltip: 'تسجيل خروج',
            onPressed: session.isBusy ? null : () => ref.read(authSessionProvider).logout(),
            icon: const Icon(Icons.logout_rounded),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (me != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    me.toString(),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text('Logged in ✅', textDirection: TextDirection.rtl),
                ),
              ),
            const SizedBox(height: 12),
            CsButton(
              label: 'زر تجريبي',
              onPressed: () {},
              icon: Icons.check_circle_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
