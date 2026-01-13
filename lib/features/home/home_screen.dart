import 'package:flutter/material.dart';

import '../../ui/components/cs_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = 'home';
  static const String routePath = '/home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية', textDirection: TextDirection.rtl),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Text(
                      'Patch 0 جاهز ✅',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'هنا راح نبدأ نبني Features (auth / dashboard / levels / exams...).',
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
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
